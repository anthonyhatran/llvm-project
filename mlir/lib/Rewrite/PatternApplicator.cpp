//===- PatternApplicator.cpp - Pattern Application Engine -------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements an applicator that applies pattern rewrites based upon a
// user defined cost model.
//
//===----------------------------------------------------------------------===//

#include "mlir/Rewrite/PatternApplicator.h"
#include "ByteCode.h"
#include "llvm/Support/DebugLog.h"

#ifndef NDEBUG
#include "llvm/ADT/ScopeExit.h"
#endif

#define DEBUG_TYPE "pattern-application"

using namespace mlir;
using namespace mlir::detail;

PatternApplicator::PatternApplicator(
    const FrozenRewritePatternSet &frozenPatternList)
    : frozenPatternList(frozenPatternList) {
  if (const PDLByteCode *bytecode = frozenPatternList.getPDLByteCode()) {
    mutableByteCodeState = std::make_unique<PDLByteCodeMutableState>();
    bytecode->initializeMutableState(*mutableByteCodeState);
  }
}
PatternApplicator::~PatternApplicator() = default;

#ifndef NDEBUG
/// Log a message for a pattern that is impossible to match.
static void logImpossibleToMatch(const Pattern &pattern) {
  llvm::dbgs() << "Ignoring pattern '" << pattern.getRootKind()
               << "' because it is impossible to match or cannot lead "
                  "to legal IR (by cost model)\n";
}

/// Log IR after pattern application.
static Operation *getDumpRootOp(Operation *op) {
  Operation *isolatedParent =
      op->getParentWithTrait<mlir::OpTrait::IsIsolatedFromAbove>();
  if (isolatedParent)
    return isolatedParent;
  return op;
}
static void logSucessfulPatternApplication(Operation *op) {
  LDBG(2) << "// *** IR Dump After Pattern Application ***\n" << *op << "\n";
}
#endif

void PatternApplicator::applyCostModel(CostModel model) {
  // Apply the cost model to the bytecode patterns first, and then the native
  // patterns.
  if (const PDLByteCode *bytecode = frozenPatternList.getPDLByteCode()) {
    for (const auto &it : llvm::enumerate(bytecode->getPatterns()))
      mutableByteCodeState->updatePatternBenefit(it.index(), model(it.value()));
  }

  // Copy over the patterns so that we can sort by benefit based on the cost
  // model. Patterns that are already impossible to match are ignored.
  patterns.clear();
  for (const auto &it : frozenPatternList.getOpSpecificNativePatterns()) {
    for (const RewritePattern *pattern : it.second) {
      if (pattern->getBenefit().isImpossibleToMatch())
        LLVM_DEBUG(logImpossibleToMatch(*pattern));
      else
        patterns[it.first].push_back(pattern);
    }
  }
  anyOpPatterns.clear();
  for (const RewritePattern &pattern :
       frozenPatternList.getMatchAnyOpNativePatterns()) {
    if (pattern.getBenefit().isImpossibleToMatch())
      LLVM_DEBUG(logImpossibleToMatch(pattern));
    else
      anyOpPatterns.push_back(&pattern);
  }

  // Sort the patterns using the provided cost model.
  llvm::SmallDenseMap<const Pattern *, PatternBenefit> benefits;
  auto cmp = [&benefits](const Pattern *lhs, const Pattern *rhs) {
    return benefits[lhs] > benefits[rhs];
  };
  auto processPatternList = [&](SmallVectorImpl<const RewritePattern *> &list) {
    // Special case for one pattern in the list, which is the most common case.
    if (list.size() == 1) {
      if (model(*list.front()).isImpossibleToMatch()) {
        LLVM_DEBUG(logImpossibleToMatch(*list.front()));
        list.clear();
      }
      return;
    }

    // Collect the dynamic benefits for the current pattern list.
    benefits.clear();
    for (const Pattern *pat : list)
      benefits.try_emplace(pat, model(*pat));

    // Sort patterns with highest benefit first, and remove those that are
    // impossible to match.
    llvm::stable_sort(list, cmp);
    while (!list.empty() && benefits[list.back()].isImpossibleToMatch()) {
      LLVM_DEBUG(logImpossibleToMatch(*list.back()));
      list.pop_back();
    }
  };
  for (auto &it : patterns)
    processPatternList(it.second);
  processPatternList(anyOpPatterns);
}

void PatternApplicator::walkAllPatterns(
    function_ref<void(const Pattern &)> walk) {
  for (const auto &it : frozenPatternList.getOpSpecificNativePatterns())
    for (const auto &pattern : it.second)
      walk(*pattern);
  for (const Pattern &it : frozenPatternList.getMatchAnyOpNativePatterns())
    walk(it);
  if (const PDLByteCode *bytecode = frozenPatternList.getPDLByteCode()) {
    for (const Pattern &it : bytecode->getPatterns())
      walk(it);
  }
}

LogicalResult PatternApplicator::matchAndRewrite(
    Operation *op, PatternRewriter &rewriter,
    function_ref<bool(const Pattern &)> canApply,
    function_ref<void(const Pattern &)> onFailure,
    function_ref<LogicalResult(const Pattern &)> onSuccess) {
  // Before checking native patterns, first match against the bytecode. This
  // won't automatically perform any rewrites so there is no need to worry about
  // conflicts.
  SmallVector<PDLByteCode::MatchResult, 4> pdlMatches;
  const PDLByteCode *bytecode = frozenPatternList.getPDLByteCode();
  if (bytecode)
    bytecode->match(op, rewriter, pdlMatches, *mutableByteCodeState);

  // Check to see if there are patterns matching this specific operation type.
  MutableArrayRef<const RewritePattern *> opPatterns;
  auto patternIt = patterns.find(op->getName());
  if (patternIt != patterns.end())
    opPatterns = patternIt->second;

  // Process the patterns for that match the specific operation type, and any
  // operation type in an interleaved fashion.
  unsigned opIt = 0, opE = opPatterns.size();
  unsigned anyIt = 0, anyE = anyOpPatterns.size();
  unsigned pdlIt = 0, pdlE = pdlMatches.size();
  LogicalResult result = failure();
  do {
    // Find the next pattern with the highest benefit.
    const Pattern *bestPattern = nullptr;
    unsigned *bestPatternIt = &opIt;

    /// Operation specific patterns.
    if (opIt < opE)
      bestPattern = opPatterns[opIt];
    /// Operation agnostic patterns.
    if (anyIt < anyE &&
        (!bestPattern ||
         bestPattern->getBenefit() < anyOpPatterns[anyIt]->getBenefit())) {
      bestPatternIt = &anyIt;
      bestPattern = anyOpPatterns[anyIt];
    }

    const PDLByteCode::MatchResult *pdlMatch = nullptr;
    /// PDL patterns.
    if (pdlIt < pdlE && (!bestPattern || bestPattern->getBenefit() <
                                             pdlMatches[pdlIt].benefit)) {
      bestPatternIt = &pdlIt;
      pdlMatch = &pdlMatches[pdlIt];
      bestPattern = pdlMatch->pattern;
    }

    if (!bestPattern)
      break;

    // Update the pattern iterator on failure so that this pattern isn't
    // attempted again.
    ++(*bestPatternIt);

    // Check that the pattern can be applied.
    if (canApply && !canApply(*bestPattern))
      continue;

    // Try to match and rewrite this pattern. The patterns are sorted by
    // benefit, so if we match we can immediately rewrite. For PDL patterns, the
    // match has already been performed, we just need to rewrite.
    bool matched = false;
    op->getContext()->executeAction<ApplyPatternAction>(
        [&]() {
          rewriter.setInsertionPoint(op);
#ifndef NDEBUG
          // Operation `op` may be invalidated after applying the rewrite
          // pattern.
          Operation *dumpRootOp = getDumpRootOp(op);
#endif
          if (pdlMatch) {
            result =
                bytecode->rewrite(rewriter, *pdlMatch, *mutableByteCodeState);
          } else {
            LDBG() << "Trying to match \"" << bestPattern->getDebugName()
                   << "\"";
            const auto *pattern =
                static_cast<const RewritePattern *>(bestPattern);

#ifndef NDEBUG
            OpBuilder::Listener *oldListener = rewriter.getListener();
            auto loggingListener =
                std::make_unique<RewriterBase::PatternLoggingListener>(
                    oldListener, pattern->getDebugName());
            rewriter.setListener(loggingListener.get());
            auto resetListenerCallback = llvm::make_scope_exit(
                [&] { rewriter.setListener(oldListener); });
#endif
            result = pattern->matchAndRewrite(op, rewriter);
            LDBG() << " -> matchAndRewrite "
                   << (succeeded(result) ? "successful" : "failed");
          }

          // Process the result of the pattern application.
          if (succeeded(result) && onSuccess && failed(onSuccess(*bestPattern)))
            result = failure();
          if (succeeded(result)) {
            LLVM_DEBUG(logSucessfulPatternApplication(dumpRootOp));
            matched = true;
            return;
          }

          // Perform any necessary cleanups.
          if (onFailure)
            onFailure(*bestPattern);
        },
        {op}, *bestPattern);
    if (matched)
      break;
  } while (true);

  if (mutableByteCodeState)
    mutableByteCodeState->cleanupAfterMatchAndRewrite();
  return result;
}
