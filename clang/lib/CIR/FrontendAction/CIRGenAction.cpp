//===--- CIRGenAction.cpp - LLVM Code generation Frontend Action ---------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "clang/CIR/FrontendAction/CIRGenAction.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/OwningOpRef.h"
#include "clang/Basic/DiagnosticFrontend.h"
#include "clang/CIR/CIRGenerator.h"
#include "clang/CIR/CIRToCIRPasses.h"
#include "clang/CIR/LowerToLLVM.h"
#include "clang/CodeGen/BackendUtil.h"
#include "clang/Frontend/CompilerInstance.h"
#include "llvm/IR/Module.h"

using namespace cir;
using namespace clang;

namespace cir {

static BackendAction
getBackendActionFromOutputType(CIRGenAction::OutputType Action) {
  switch (Action) {
  case CIRGenAction::OutputType::EmitCIR:
    assert(false &&
           "Unsupported output type for getBackendActionFromOutputType!");
    break; // Unreachable, but fall through to report that
  case CIRGenAction::OutputType::EmitAssembly:
    return BackendAction::Backend_EmitAssembly;
  case CIRGenAction::OutputType::EmitBC:
    return BackendAction::Backend_EmitBC;
  case CIRGenAction::OutputType::EmitLLVM:
    return BackendAction::Backend_EmitLL;
  case CIRGenAction::OutputType::EmitObj:
    return BackendAction::Backend_EmitObj;
  }
  // We should only get here if a non-enum value is passed in or we went through
  // the assert(false) case above
  llvm_unreachable("Unsupported output type!");
}

static std::unique_ptr<llvm::Module>
lowerFromCIRToLLVMIR(mlir::ModuleOp MLIRModule, llvm::LLVMContext &LLVMCtx) {
  return direct::lowerDirectlyFromCIRToLLVMIR(MLIRModule, LLVMCtx);
}

class CIRGenConsumer : public clang::ASTConsumer {

  virtual void anchor();

  CIRGenAction::OutputType Action;

  CompilerInstance &CI;

  std::unique_ptr<raw_pwrite_stream> OutputStream;

  ASTContext *Context{nullptr};
  IntrusiveRefCntPtr<llvm::vfs::FileSystem> FS;
  std::unique_ptr<CIRGenerator> Gen;
  const FrontendOptions &FEOptions;
  CodeGenOptions &CGO;

public:
  CIRGenConsumer(CIRGenAction::OutputType Action, CompilerInstance &CI,
                 CodeGenOptions &CGO, std::unique_ptr<raw_pwrite_stream> OS)
      : Action(Action), CI(CI), OutputStream(std::move(OS)),
        FS(&CI.getVirtualFileSystem()),
        Gen(std::make_unique<CIRGenerator>(CI.getDiagnostics(), std::move(FS),
                                           CI.getCodeGenOpts())),
        FEOptions(CI.getFrontendOpts()), CGO(CGO) {}

  void Initialize(ASTContext &Ctx) override {
    assert(!Context && "initialized multiple times");
    Context = &Ctx;
    Gen->Initialize(Ctx);
  }

  bool HandleTopLevelDecl(DeclGroupRef D) override {
    Gen->HandleTopLevelDecl(D);
    return true;
  }

  void HandleCXXStaticMemberVarInstantiation(clang::VarDecl *VD) override {
    Gen->HandleCXXStaticMemberVarInstantiation(VD);
  }

  void HandleInlineFunctionDefinition(FunctionDecl *D) override {
    Gen->HandleInlineFunctionDefinition(D);
  }

  void HandleTranslationUnit(ASTContext &C) override {
    Gen->HandleTranslationUnit(C);

    if (!FEOptions.ClangIRDisableCIRVerifier) {
      if (!Gen->verifyModule()) {
        CI.getDiagnostics().Report(
            diag::err_cir_verification_failed_pre_passes);
        llvm::report_fatal_error(
            "CIR codegen: module verification error before running CIR passes");
        return;
      }
    }

    mlir::ModuleOp MlirModule = Gen->getModule();
    mlir::MLIRContext &MlirCtx = Gen->getMLIRContext();

    if (!FEOptions.ClangIRDisablePasses) {
      // Setup and run CIR pipeline.
      if (runCIRToCIRPasses(MlirModule, MlirCtx, C,
                            !FEOptions.ClangIRDisableCIRVerifier,
                            CGO.OptimizationLevel > 0)
              .failed()) {
        CI.getDiagnostics().Report(diag::err_cir_to_cir_transform_failed);
        return;
      }
    }

    switch (Action) {
    case CIRGenAction::OutputType::EmitCIR:
      if (OutputStream && MlirModule) {
        mlir::OpPrintingFlags Flags;
        Flags.enableDebugInfo(/*enable=*/true, /*prettyForm=*/false);
        MlirModule->print(*OutputStream, Flags);
      }
      break;
    case CIRGenAction::OutputType::EmitLLVM:
    case CIRGenAction::OutputType::EmitBC:
    case CIRGenAction::OutputType::EmitObj:
    case CIRGenAction::OutputType::EmitAssembly: {
      llvm::LLVMContext LLVMCtx;
      std::unique_ptr<llvm::Module> LLVMModule =
          lowerFromCIRToLLVMIR(MlirModule, LLVMCtx);

      BackendAction BEAction = getBackendActionFromOutputType(Action);
      emitBackendOutput(
          CI, CI.getCodeGenOpts(), C.getTargetInfo().getDataLayoutString(),
          LLVMModule.get(), BEAction, FS, std::move(OutputStream));
      break;
    }
    }
  }

  void HandleTagDeclDefinition(TagDecl *D) override {
    PrettyStackTraceDecl CrashInfo(D, SourceLocation(),
                                   Context->getSourceManager(),
                                   "CIR generation of declaration");
    Gen->HandleTagDeclDefinition(D);
  }

  void HandleTagDeclRequiredDefinition(const TagDecl *D) override {
    Gen->HandleTagDeclRequiredDefinition(D);
  }

  void CompleteTentativeDefinition(VarDecl *D) override {
    Gen->CompleteTentativeDefinition(D);
  }

  void HandleVTable(CXXRecordDecl *RD) override { Gen->HandleVTable(RD); }
};
} // namespace cir

void CIRGenConsumer::anchor() {}

CIRGenAction::CIRGenAction(OutputType Act, mlir::MLIRContext *MLIRCtx)
    : MLIRCtx(MLIRCtx ? MLIRCtx : new mlir::MLIRContext), Action(Act) {}

CIRGenAction::~CIRGenAction() { MLIRMod.release(); }

static std::unique_ptr<raw_pwrite_stream>
getOutputStream(CompilerInstance &CI, StringRef InFile,
                CIRGenAction::OutputType Action) {
  switch (Action) {
  case CIRGenAction::OutputType::EmitAssembly:
    return CI.createDefaultOutputFile(false, InFile, "s");
  case CIRGenAction::OutputType::EmitCIR:
    return CI.createDefaultOutputFile(false, InFile, "cir");
  case CIRGenAction::OutputType::EmitLLVM:
    return CI.createDefaultOutputFile(false, InFile, "ll");
  case CIRGenAction::OutputType::EmitBC:
    return CI.createDefaultOutputFile(true, InFile, "bc");
  case CIRGenAction::OutputType::EmitObj:
    return CI.createDefaultOutputFile(true, InFile, "o");
  }
  llvm_unreachable("Invalid CIRGenAction::OutputType");
}

std::unique_ptr<ASTConsumer>
CIRGenAction::CreateASTConsumer(CompilerInstance &CI, StringRef InFile) {
  std::unique_ptr<llvm::raw_pwrite_stream> Out = CI.takeOutputStream();

  if (!Out)
    Out = getOutputStream(CI, InFile, Action);

  auto Result = std::make_unique<cir::CIRGenConsumer>(
      Action, CI, CI.getCodeGenOpts(), std::move(Out));

  return Result;
}

void EmitAssemblyAction::anchor() {}
EmitAssemblyAction::EmitAssemblyAction(mlir::MLIRContext *MLIRCtx)
    : CIRGenAction(OutputType::EmitAssembly, MLIRCtx) {}

void EmitCIRAction::anchor() {}
EmitCIRAction::EmitCIRAction(mlir::MLIRContext *MLIRCtx)
    : CIRGenAction(OutputType::EmitCIR, MLIRCtx) {}

void EmitLLVMAction::anchor() {}
EmitLLVMAction::EmitLLVMAction(mlir::MLIRContext *MLIRCtx)
    : CIRGenAction(OutputType::EmitLLVM, MLIRCtx) {}

void EmitBCAction::anchor() {}
EmitBCAction::EmitBCAction(mlir::MLIRContext *MLIRCtx)
    : CIRGenAction(OutputType::EmitBC, MLIRCtx) {}

void EmitObjAction::anchor() {}
EmitObjAction::EmitObjAction(mlir::MLIRContext *MLIRCtx)
    : CIRGenAction(OutputType::EmitObj, MLIRCtx) {}
