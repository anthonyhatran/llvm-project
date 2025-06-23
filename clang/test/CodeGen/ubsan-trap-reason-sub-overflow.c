// RUN: %clang_cc1 -triple x86_64-unknown-linux-gnu -O0 -debug-info-kind=standalone -dwarf-version=5 \
// RUN: -fsanitize=signed-integer-overflow -fsanitize-trap=signed-integer-overflow -emit-llvm %s -o - | FileCheck %s

int sub_overflow(int a, int b) {
    return a - b;
}

// CHECK: call void @llvm.ubsantrap(i8 21) {{.*}}!dbg [[LOC:![0-9]+]]
// CHECK: [[LOC]] = !DILocation(line: 0, scope: [[MSG:![0-9]+]], {{.+}})
// CHECK: distinct !DISubprogram(name: "__clang_trap_msg$UBSan Trap Reason