// We try to create options similar to lld's.  That way, options passed to clang
// -Xoffload-linker can be the same whether offloading to nvptx or amdgpu.

include "llvm/Option/OptParser.td"

def WrapperOnlyOption : OptionFlag;

def help : Flag<["-", "--"], "help">,
  HelpText<"Display available options (--help-hidden for more)">;

def help_hidden : Flag<["-", "--"], "help-hidden">,
  HelpText<"Display all available options">;

def verbose : Flag<["-"], "v">, HelpText<"Print verbose information">;
def version : Flag<["--"], "version">,
  HelpText<"Display the version number and exit">;

def cuda_path_EQ : Joined<["--"], "cuda-path=">, Flags<[WrapperOnlyOption]>,
  MetaVarName<"<dir>">, HelpText<"Set the system CUDA path">;
def ptxas_path_EQ : Joined<["--"], "ptxas-path=">, Flags<[WrapperOnlyOption]>,
  MetaVarName<"<dir>">, HelpText<"Set the 'ptxas' path">;

def o : JoinedOrSeparate<["-"], "o">, MetaVarName<"<path>">,
  HelpText<"Path to file to write output">;
def output : Separate<["--"], "output-file">, Alias<o>, Flags<[HelpHidden]>,
  HelpText<"Alias for -o">;

def library_path : JoinedOrSeparate<["-"], "L">, MetaVarName<"<dir>">,
  HelpText<"Add <dir> to the library search path">;
def library_path_S : Separate<["--", "-"], "library-path">, Flags<[HelpHidden]>,
  Alias<library_path>;
def library_path_EQ : Joined<["--", "-"], "library-path=">, Flags<[HelpHidden]>,
  Alias<library_path>;

def library : JoinedOrSeparate<["-"], "l">, MetaVarName<"<libname>">,
  HelpText<"Search for library <libname>">;
def library_S : Separate<["--", "-"], "library">, Flags<[HelpHidden]>,
  Alias<library_path>;
def library_EQ : Joined<["--", "-"], "library=">, Flags<[HelpHidden]>,
  Alias<library_path>;

def plugin : JoinedOrSeparate<["--", "-"], "plugin">,
  Flags<[HelpHidden, WrapperOnlyOption]>;

def arch : Separate<["--", "-"], "arch">,
  HelpText<"Specify the 'sm_' name of the target architecture">;
def : Joined<["--", "-"], "plugin-opt=mcpu=">,
  Flags<[HelpHidden, WrapperOnlyOption]>, Alias<arch>;

def g : Flag<["-"], "g">, HelpText<"Specify that this was a debug compile">;
def debug : Flag<["--"], "debug">, Alias<g>;

def lto_emit_llvm : Flag<["--"], "lto-emit-llvm">, Flags<[WrapperOnlyOption]>,
  HelpText<"Emit LLVM-IR bitcode">;
def lto_emit_asm : Flag<["--"], "lto-emit-asm">, Flags<[WrapperOnlyOption]>,
  HelpText<"Emit assembly code">;

def u : JoinedOrSeparate<["-"], "u">, HelpText<"Force undefined symbol during linking">;
def undefined : JoinedOrSeparate<["--"], "undefined">, Alias<u>;

def O : Joined<["--", "-"], "plugin-opt=O">,
  Flags<[WrapperOnlyOption]>, MetaVarName<"<O0, O1, O2, or O3>">,
  HelpText<"Optimization level for LTO">;

def thinlto : Joined<["--", "-"], "plugin-opt=thinlto">,
  Flags<[WrapperOnlyOption]>, HelpText<"Enable the thin-lto backend">;
def lto_partitions : Joined<["--", "-"], "plugin-opt=lto-partitions=">,
  Flags<[WrapperOnlyOption]>, HelpText<"Number of LTO codegen partitions">;
def jobs : Joined<["--", "-"], "plugin-opt=jobs=">,
  Flags<[WrapperOnlyOption]>, HelpText<"Number of LTO codegen partitions">;
def : Joined<["--", "-"], "plugin-opt=emit-llvm">,
  Flags<[WrapperOnlyOption]>, Alias<lto_emit_llvm>;
def : Joined<["--", "-"], "plugin-opt=emit-asm">,
  Flags<[WrapperOnlyOption]>, Alias<lto_emit_asm>;

def opt_remarks_filename : Joined<["--", "-"], "plugin-opt=opt-remarks-filename=">,
  Flags<[WrapperOnlyOption]>, HelpText<"YAML output file for optimization remarks">;
def opt_remarks_format : Joined<["--", "-"], "plugin-opt=opt-remarks-format=">,
  Flags<[WrapperOnlyOption]>, HelpText<"The format used for serializing remarks (default: YAML)">;
def opt_remarks_filter : Joined<["--", "-"], "plugin-opt=opt-remarks-filter=">, 
  Flags<[WrapperOnlyOption]>, HelpText<"Regex for the passes that need to be serialized to the output file">;
def opt_remarks_with_hotness : Flag<["--", "-"], "plugin-opt=opt-remarks-with-hotness">,
  Flags<[WrapperOnlyOption]>, HelpText<"Include hotness information in the optimization remarks file">;

def plugin_opt : Joined<["--", "-"], "plugin-opt=">, Flags<[WrapperOnlyOption]>,
  HelpText<"Options passed to LLVM, not including the Clang invocation. Use "
           "'--plugin-opt=--help' for a list of options.">;

def lto_newpm_passes : Joined<["--"], "lto-newpm-passes=">,
  Flags<[WrapperOnlyOption]>, HelpText<"Passes to run during LTO">;
def lto_debug_pass_manager : Flag<["--"], "lto-debug-pass-manager">,
  Flags<[WrapperOnlyOption]>,   HelpText<"Debug new pass manager">;

def save_temps : Flag<["--", "-"], "save-temps">,
  Flags<[WrapperOnlyOption]>, HelpText<"Save intermediate results">;

def relocatable : Flag<["--", "-"], "relocatable">,
  Flags<[WrapperOnlyOption]>, HelpText<"Perform a relocatable link (LTO only)">;
def r : Flag<["-"], "r">, Flags<[WrapperOnlyOption]>, Alias<relocatable>;

def whole_archive : Flag<["--", "-"], "whole-archive">,
  Flags<[WrapperOnlyOption, HelpHidden]>;
def no_whole_archive : Flag<["--", "-"], "no-whole-archive">,
  Flags<[WrapperOnlyOption, HelpHidden]>;

def mllvm : Separate<["-"], "mllvm">, Flags<[WrapperOnlyOption]>,
  MetaVarName<"<arg>">,
  HelpText<"Arguments passed to LLVM, including Clang invocations, for which "
           "the '-mllvm' prefix is preserved. Use '-mllvm --help' for a list "
           "of options.">;
def mllvm_EQ : Joined<["-"], "mllvm=">, Flags<[HelpHidden]>, Alias<mllvm>;

def dry_run : Flag<["--", "-"], "dry-run">, Flags<[WrapperOnlyOption]>,
  HelpText<"Print generated commands without running.">;
