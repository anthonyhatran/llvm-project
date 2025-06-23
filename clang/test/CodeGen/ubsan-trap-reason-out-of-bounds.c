// RUN: %clang -O0 -g -debug-info-kind=standalone -dwarf-version=5 -fsanitize=bounds \
// RUN: -fsanitize-trap=bounds -emit-llvm -S -c %s -o - | FileCheck %s

int out_of_bounds()
{
    int a[1] = {0};
    return a[1];
}

// CHECK: call void @llvm.ubsantrap(i8 18) {{.*}}!dbg [[LOC:![0-9]+]]
// CHECK: [[LOC]] = !DILocation(line: 0, scope: [[MSG:![0-9]+]], {{.+}})
// CHECK: distinct !DISubprogram(name: "__clang_trap_msg$