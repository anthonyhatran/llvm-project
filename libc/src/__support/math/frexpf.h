//===-- Implementation header for frexpf ------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIBC_SRC___SUPPORT_MATH_FREXPF_H
#define LLVM_LIBC_SRC___SUPPORT_MATH_FREXPF_H

#include "src/__support/FPUtil/ManipulationFunctions.h"
#include "src/__support/common.h"
#include "src/__support/macros/config.h"

namespace LIBC_NAMESPACE_DECL {

namespace math {

LIBC_INLINE static constexpr float frexpf(float x, int *exp) {
  return fputil::frexp(x, *exp);
}

} // namespace math

} // namespace LIBC_NAMESPACE_DECL

#endif // LLVM_LIBC_SRC___SUPPORT_MATH_FREXPF_H
