//===- StripDebugInfo.cpp - Pass to strip debug information ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Transforms/Passes.h"

#include "mlir/IR/Operation.h"
#include "mlir/Pass/Pass.h"

namespace mlir {
#define GEN_PASS_DEF_STRIPDEBUGINFO
#include "mlir/Transforms/Passes.h.inc"
} // namespace mlir

using namespace mlir;

namespace {
struct StripDebugInfo : public impl::StripDebugInfoBase<StripDebugInfo> {
  void runOnOperation() override;
};
} // namespace

void StripDebugInfo::runOnOperation() {
  auto unknownLoc = UnknownLoc::get(&getContext());

  // Strip the debug info from all operations.
  getOperation()->walk([&](Operation *op) {
    op->setLoc(unknownLoc);
    // Strip block arguments debug info.
    for (Region &region : op->getRegions()) {
      for (Block &block : region.getBlocks()) {
        for (BlockArgument &arg : block.getArguments()) {
          arg.setLoc(unknownLoc);
        }
      }
    }
  });
}

/// Creates a pass to strip debug information from a function.
std::unique_ptr<Pass> mlir::createStripDebugInfoPass() {
  return std::make_unique<StripDebugInfo>();
}
