// RUN: %clang -fsyntax-only %s -fsanitize-trap=undefined 2>&1 | FileCheck %s --check-prefix=WARN
// RUN: %clang -fsyntax-only %s -fsanitize=undefined -fsanitize-trap=undefined 2>&1 | FileCheck %s --check-prefix=NOWARN
//
// WARN: warning: -fsanitize-trap=undefined has no effect because the "undefined" sanitizer is disabled; consider passing "fsanitize=undefined" to enable the sanitizer
// NOWARN-NOT: warning: -fsanitize-trap=undefined has no effect because the "undefined" sanitizer is disabled; consider passing "fsanitize=undefined" to enable the sanitizer

int main(void) { return 0; }
