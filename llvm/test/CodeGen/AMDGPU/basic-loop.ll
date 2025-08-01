; RUN: llc -O0 -mtriple=amdgcn -mcpu=tahiti < %s | FileCheck %s
; RUN: llc -O0 -mtriple=amdgcn -mcpu=tonga < %s | FileCheck %s

; CHECK-LABEL: {{^}}test_loop:
define amdgpu_kernel void @test_loop(ptr addrspace(1) noalias %out, ptr addrspace(1) noalias %in, i32 %val) nounwind {
entry:
  br label %loop.body

loop.body:
  %i = phi i32 [0, %entry], [%i.inc, %loop.body]
  store i32 222, ptr addrspace(1) %out
  %cmp = icmp ne i32 %i, %val
  %i.inc = add i32 %i, 1
  br i1 %cmp, label %loop.body, label %end

end:
  ret void
}
