; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 4
; RUN: opt -p loop-vectorize -force-vector-width=4 -enable-epilogue-vectorization -epilogue-vectorization-force-VF=4 -S %s | FileCheck %s

target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"

define i32 @any_of_reduction_epilog(ptr %src, i64 %N) {
; CHECK-LABEL: define i32 @any_of_reduction_epilog(
; CHECK-SAME: ptr [[SRC:%.*]], i64 [[N:%.*]]) {
; CHECK-NEXT:  iter.check:
; CHECK-NEXT:    [[TMP0:%.*]] = add i64 [[N]], 1
; CHECK-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ult i64 [[TMP0]], 4
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK]], label [[VEC_EPILOG_SCALAR_PH:%.*]], label [[VECTOR_MAIN_LOOP_ITER_CHECK:%.*]]
; CHECK:       vector.main.loop.iter.check:
; CHECK-NEXT:    [[MIN_ITERS_CHECK1:%.*]] = icmp ult i64 [[TMP0]], 4
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK1]], label [[VEC_EPILOG_PH:%.*]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    [[N_MOD_VF:%.*]] = urem i64 [[TMP0]], 4
; CHECK-NEXT:    [[N_VEC:%.*]] = sub i64 [[TMP0]], [[N_MOD_VF]]
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i64 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_PHI:%.*]] = phi <4 x i1> [ zeroinitializer, [[VECTOR_PH]] ], [ [[TMP5:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP2:%.*]] = getelementptr inbounds i8, ptr [[SRC]], i64 [[INDEX]]
; CHECK-NEXT:    [[WIDE_LOAD:%.*]] = load <4 x i8>, ptr [[TMP2]], align 1
; CHECK-NEXT:    [[TMP4:%.*]] = icmp eq <4 x i8> [[WIDE_LOAD]], zeroinitializer
; CHECK-NEXT:    [[TMP5]] = or <4 x i1> [[VEC_PHI]], [[TMP4]]
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i64 [[INDEX]], 4
; CHECK-NEXT:    [[TMP6:%.*]] = icmp eq i64 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP6]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop [[LOOP0:![0-9]+]]
; CHECK:       middle.block:
; CHECK-NEXT:    [[TMP7:%.*]] = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> [[TMP5]])
; CHECK-NEXT:    [[TMP8:%.*]] = freeze i1 [[TMP7]]
; CHECK-NEXT:    [[RDX_SELECT:%.*]] = select i1 [[TMP8]], i32 1, i32 0
; CHECK-NEXT:    [[CMP_N:%.*]] = icmp eq i64 [[TMP0]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[CMP_N]], label [[EXIT:%.*]], label [[VEC_EPILOG_ITER_CHECK:%.*]]
; CHECK:       vec.epilog.iter.check:
; CHECK-NEXT:    [[N_VEC_REMAINING:%.*]] = sub i64 [[TMP0]], [[N_VEC]]
; CHECK-NEXT:    [[MIN_EPILOG_ITERS_CHECK:%.*]] = icmp ult i64 [[N_VEC_REMAINING]], 4
; CHECK-NEXT:    br i1 [[MIN_EPILOG_ITERS_CHECK]], label [[VEC_EPILOG_SCALAR_PH]], label [[VEC_EPILOG_PH]]
; CHECK:       vec.epilog.ph:
; CHECK-NEXT:    [[VEC_EPILOG_RESUME_VAL:%.*]] = phi i64 [ [[N_VEC]], [[VEC_EPILOG_ITER_CHECK]] ], [ 0, [[VECTOR_MAIN_LOOP_ITER_CHECK]] ]
; CHECK-NEXT:    [[BC_MERGE_RDX:%.*]] = phi i32 [ [[RDX_SELECT]], [[VEC_EPILOG_ITER_CHECK]] ], [ 0, [[VECTOR_MAIN_LOOP_ITER_CHECK]] ]
; CHECK-NEXT:    [[TMP9:%.*]] = icmp ne i32 [[BC_MERGE_RDX]], 0
; CHECK-NEXT:    [[N_MOD_VF2:%.*]] = urem i64 [[TMP0]], 4
; CHECK-NEXT:    [[N_VEC3:%.*]] = sub i64 [[TMP0]], [[N_MOD_VF2]]
; CHECK-NEXT:    [[MINMAX_IDENT_SPLATINSERT:%.*]] = insertelement <4 x i1> poison, i1 [[TMP9]], i64 0
; CHECK-NEXT:    [[MINMAX_IDENT_SPLAT:%.*]] = shufflevector <4 x i1> [[MINMAX_IDENT_SPLATINSERT]], <4 x i1> poison, <4 x i32> zeroinitializer
; CHECK-NEXT:    br label [[VEC_EPILOG_VECTOR_BODY:%.*]]
; CHECK:       vec.epilog.vector.body:
; CHECK-NEXT:    [[INDEX5:%.*]] = phi i64 [ [[VEC_EPILOG_RESUME_VAL]], [[VEC_EPILOG_PH]] ], [ [[INDEX_NEXT8:%.*]], [[VEC_EPILOG_VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_PHI6:%.*]] = phi <4 x i1> [ [[MINMAX_IDENT_SPLAT]], [[VEC_EPILOG_PH]] ], [ [[TMP14:%.*]], [[VEC_EPILOG_VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP11:%.*]] = getelementptr inbounds i8, ptr [[SRC]], i64 [[INDEX5]]
; CHECK-NEXT:    [[WIDE_LOAD7:%.*]] = load <4 x i8>, ptr [[TMP11]], align 1
; CHECK-NEXT:    [[TMP13:%.*]] = icmp eq <4 x i8> [[WIDE_LOAD7]], zeroinitializer
; CHECK-NEXT:    [[TMP14]] = or <4 x i1> [[VEC_PHI6]], [[TMP13]]
; CHECK-NEXT:    [[INDEX_NEXT8]] = add nuw i64 [[INDEX5]], 4
; CHECK-NEXT:    [[TMP15:%.*]] = icmp eq i64 [[INDEX_NEXT8]], [[N_VEC3]]
; CHECK-NEXT:    br i1 [[TMP15]], label [[VEC_EPILOG_MIDDLE_BLOCK:%.*]], label [[VEC_EPILOG_VECTOR_BODY]], !llvm.loop [[LOOP3:![0-9]+]]
; CHECK:       vec.epilog.middle.block:
; CHECK-NEXT:    [[TMP16:%.*]] = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> [[TMP14]])
; CHECK-NEXT:    [[TMP17:%.*]] = freeze i1 [[TMP16]]
; CHECK-NEXT:    [[RDX_SELECT9:%.*]] = select i1 [[TMP17]], i32 1, i32 0
; CHECK-NEXT:    [[CMP_N4:%.*]] = icmp eq i64 [[TMP0]], [[N_VEC3]]
; CHECK-NEXT:    br i1 [[CMP_N4]], label [[EXIT]], label [[VEC_EPILOG_SCALAR_PH]]
; CHECK:       vec.epilog.scalar.ph:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i64 [ [[N_VEC3]], [[VEC_EPILOG_MIDDLE_BLOCK]] ], [ [[N_VEC]], [[VEC_EPILOG_ITER_CHECK]] ], [ 0, [[ITER_CHECK:%.*]] ]
; CHECK-NEXT:    [[BC_MERGE_RDX10:%.*]] = phi i32 [ [[RDX_SELECT9]], [[VEC_EPILOG_MIDDLE_BLOCK]] ], [ [[RDX_SELECT]], [[VEC_EPILOG_ITER_CHECK]] ], [ 0, [[ITER_CHECK]] ]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i64 [ [[BC_RESUME_VAL]], [[VEC_EPILOG_SCALAR_PH]] ], [ [[IV_NEXT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[RED:%.*]] = phi i32 [ [[BC_MERGE_RDX10]], [[VEC_EPILOG_SCALAR_PH]] ], [ [[SELECT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr inbounds i8, ptr [[SRC]], i64 [[IV]]
; CHECK-NEXT:    [[LOAD:%.*]] = load i8, ptr [[GEP]], align 1
; CHECK-NEXT:    [[ICMP:%.*]] = icmp eq i8 [[LOAD]], 0
; CHECK-NEXT:    [[SELECT]] = select i1 [[ICMP]], i32 1, i32 [[RED]]
; CHECK-NEXT:    [[IV_NEXT]] = add i64 [[IV]], 1
; CHECK-NEXT:    [[ICMP3:%.*]] = icmp eq i64 [[IV]], [[N]]
; CHECK-NEXT:    br i1 [[ICMP3]], label [[EXIT]], label [[LOOP]], !llvm.loop [[LOOP4:![0-9]+]]
; CHECK:       exit:
; CHECK-NEXT:    [[SELECT_LCSSA:%.*]] = phi i32 [ [[SELECT]], [[LOOP]] ], [ [[RDX_SELECT]], [[MIDDLE_BLOCK]] ], [ [[RDX_SELECT9]], [[VEC_EPILOG_MIDDLE_BLOCK]] ]
; CHECK-NEXT:    ret i32 [[SELECT_LCSSA]]
;
entry:
  br label %loop

loop:
  %iv = phi i64 [ 0, %entry ], [ %iv.next, %loop ]
  %red = phi i32 [ 0, %entry ], [ %select, %loop ]
  %gep = getelementptr inbounds i8, ptr %src, i64 %iv
  %load = load i8, ptr %gep, align 1
  %icmp = icmp eq i8 %load, 0
  %select = select i1 %icmp, i32 1, i32 %red
  %iv.next = add i64 %iv, 1
  %icmp3 = icmp eq i64 %iv, %N
  br i1 %icmp3, label %exit, label %loop

exit:
  ret i32 %select
}

define i32 @any_of_reduction_epilog_arg_as_start_value(ptr %src, i64 %N, i32 %start) {
; CHECK-LABEL: define i32 @any_of_reduction_epilog_arg_as_start_value(
; CHECK-SAME: ptr [[SRC:%.*]], i64 [[N:%.*]], i32 [[START:%.*]]) {
; CHECK-NEXT:  iter.check:
; CHECK-NEXT:    [[TMP0:%.*]] = add i64 [[N]], 1
; CHECK-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ult i64 [[TMP0]], 4
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK]], label [[VEC_EPILOG_SCALAR_PH:%.*]], label [[VECTOR_MAIN_LOOP_ITER_CHECK:%.*]]
; CHECK:       vector.main.loop.iter.check:
; CHECK-NEXT:    [[MIN_ITERS_CHECK1:%.*]] = icmp ult i64 [[TMP0]], 4
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK1]], label [[VEC_EPILOG_PH:%.*]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    [[N_MOD_VF:%.*]] = urem i64 [[TMP0]], 4
; CHECK-NEXT:    [[N_VEC:%.*]] = sub i64 [[TMP0]], [[N_MOD_VF]]
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i64 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_PHI:%.*]] = phi <4 x i1> [ zeroinitializer, [[VECTOR_PH]] ], [ [[TMP5:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP2:%.*]] = getelementptr inbounds i8, ptr [[SRC]], i64 [[INDEX]]
; CHECK-NEXT:    [[WIDE_LOAD:%.*]] = load <4 x i8>, ptr [[TMP2]], align 1
; CHECK-NEXT:    [[TMP4:%.*]] = icmp eq <4 x i8> [[WIDE_LOAD]], zeroinitializer
; CHECK-NEXT:    [[TMP5]] = or <4 x i1> [[VEC_PHI]], [[TMP4]]
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i64 [[INDEX]], 4
; CHECK-NEXT:    [[TMP6:%.*]] = icmp eq i64 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP6]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop [[LOOP5:![0-9]+]]
; CHECK:       middle.block:
; CHECK-NEXT:    [[TMP7:%.*]] = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> [[TMP5]])
; CHECK-NEXT:    [[TMP8:%.*]] = freeze i1 [[TMP7]]
; CHECK-NEXT:    [[RDX_SELECT:%.*]] = select i1 [[TMP8]], i32 1, i32 [[START]]
; CHECK-NEXT:    [[CMP_N:%.*]] = icmp eq i64 [[TMP0]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[CMP_N]], label [[EXIT:%.*]], label [[VEC_EPILOG_ITER_CHECK:%.*]]
; CHECK:       vec.epilog.iter.check:
; CHECK-NEXT:    [[N_VEC_REMAINING:%.*]] = sub i64 [[TMP0]], [[N_VEC]]
; CHECK-NEXT:    [[MIN_EPILOG_ITERS_CHECK:%.*]] = icmp ult i64 [[N_VEC_REMAINING]], 4
; CHECK-NEXT:    br i1 [[MIN_EPILOG_ITERS_CHECK]], label [[VEC_EPILOG_SCALAR_PH]], label [[VEC_EPILOG_PH]]
; CHECK:       vec.epilog.ph:
; CHECK-NEXT:    [[VEC_EPILOG_RESUME_VAL:%.*]] = phi i64 [ [[N_VEC]], [[VEC_EPILOG_ITER_CHECK]] ], [ 0, [[VECTOR_MAIN_LOOP_ITER_CHECK]] ]
; CHECK-NEXT:    [[BC_MERGE_RDX:%.*]] = phi i32 [ [[RDX_SELECT]], [[VEC_EPILOG_ITER_CHECK]] ], [ [[START]], [[VECTOR_MAIN_LOOP_ITER_CHECK]] ]
; CHECK-NEXT:    [[TMP9:%.*]] = icmp ne i32 [[BC_MERGE_RDX]], [[START]]
; CHECK-NEXT:    [[N_MOD_VF2:%.*]] = urem i64 [[TMP0]], 4
; CHECK-NEXT:    [[N_VEC3:%.*]] = sub i64 [[TMP0]], [[N_MOD_VF2]]
; CHECK-NEXT:    [[MINMAX_IDENT_SPLATINSERT:%.*]] = insertelement <4 x i1> poison, i1 [[TMP9]], i64 0
; CHECK-NEXT:    [[MINMAX_IDENT_SPLAT:%.*]] = shufflevector <4 x i1> [[MINMAX_IDENT_SPLATINSERT]], <4 x i1> poison, <4 x i32> zeroinitializer
; CHECK-NEXT:    br label [[VEC_EPILOG_VECTOR_BODY:%.*]]
; CHECK:       vec.epilog.vector.body:
; CHECK-NEXT:    [[INDEX5:%.*]] = phi i64 [ [[VEC_EPILOG_RESUME_VAL]], [[VEC_EPILOG_PH]] ], [ [[INDEX_NEXT8:%.*]], [[VEC_EPILOG_VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_PHI6:%.*]] = phi <4 x i1> [ [[MINMAX_IDENT_SPLAT]], [[VEC_EPILOG_PH]] ], [ [[TMP14:%.*]], [[VEC_EPILOG_VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP11:%.*]] = getelementptr inbounds i8, ptr [[SRC]], i64 [[INDEX5]]
; CHECK-NEXT:    [[WIDE_LOAD7:%.*]] = load <4 x i8>, ptr [[TMP11]], align 1
; CHECK-NEXT:    [[TMP13:%.*]] = icmp eq <4 x i8> [[WIDE_LOAD7]], zeroinitializer
; CHECK-NEXT:    [[TMP14]] = or <4 x i1> [[VEC_PHI6]], [[TMP13]]
; CHECK-NEXT:    [[INDEX_NEXT8]] = add nuw i64 [[INDEX5]], 4
; CHECK-NEXT:    [[TMP15:%.*]] = icmp eq i64 [[INDEX_NEXT8]], [[N_VEC3]]
; CHECK-NEXT:    br i1 [[TMP15]], label [[VEC_EPILOG_MIDDLE_BLOCK:%.*]], label [[VEC_EPILOG_VECTOR_BODY]], !llvm.loop [[LOOP6:![0-9]+]]
; CHECK:       vec.epilog.middle.block:
; CHECK-NEXT:    [[TMP16:%.*]] = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> [[TMP14]])
; CHECK-NEXT:    [[TMP17:%.*]] = freeze i1 [[TMP16]]
; CHECK-NEXT:    [[RDX_SELECT9:%.*]] = select i1 [[TMP17]], i32 1, i32 [[START]]
; CHECK-NEXT:    [[CMP_N4:%.*]] = icmp eq i64 [[TMP0]], [[N_VEC3]]
; CHECK-NEXT:    br i1 [[CMP_N4]], label [[EXIT]], label [[VEC_EPILOG_SCALAR_PH]]
; CHECK:       vec.epilog.scalar.ph:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i64 [ [[N_VEC3]], [[VEC_EPILOG_MIDDLE_BLOCK]] ], [ [[N_VEC]], [[VEC_EPILOG_ITER_CHECK]] ], [ 0, [[ITER_CHECK:%.*]] ]
; CHECK-NEXT:    [[BC_MERGE_RDX10:%.*]] = phi i32 [ [[RDX_SELECT9]], [[VEC_EPILOG_MIDDLE_BLOCK]] ], [ [[RDX_SELECT]], [[VEC_EPILOG_ITER_CHECK]] ], [ [[START]], [[ITER_CHECK]] ]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i64 [ [[BC_RESUME_VAL]], [[VEC_EPILOG_SCALAR_PH]] ], [ [[IV_NEXT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[RED:%.*]] = phi i32 [ [[BC_MERGE_RDX10]], [[VEC_EPILOG_SCALAR_PH]] ], [ [[SELECT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr inbounds i8, ptr [[SRC]], i64 [[IV]]
; CHECK-NEXT:    [[LOAD:%.*]] = load i8, ptr [[GEP]], align 1
; CHECK-NEXT:    [[ICMP:%.*]] = icmp eq i8 [[LOAD]], 0
; CHECK-NEXT:    [[SELECT]] = select i1 [[ICMP]], i32 1, i32 [[RED]]
; CHECK-NEXT:    [[IV_NEXT]] = add i64 [[IV]], 1
; CHECK-NEXT:    [[ICMP3:%.*]] = icmp eq i64 [[IV]], [[N]]
; CHECK-NEXT:    br i1 [[ICMP3]], label [[EXIT]], label [[LOOP]], !llvm.loop [[LOOP7:![0-9]+]]
; CHECK:       exit:
; CHECK-NEXT:    [[SELECT_LCSSA:%.*]] = phi i32 [ [[SELECT]], [[LOOP]] ], [ [[RDX_SELECT]], [[MIDDLE_BLOCK]] ], [ [[RDX_SELECT9]], [[VEC_EPILOG_MIDDLE_BLOCK]] ]
; CHECK-NEXT:    ret i32 [[SELECT_LCSSA]]
;
entry:
  br label %loop

loop:
  %iv = phi i64 [ 0, %entry ], [ %iv.next, %loop ]
  %red = phi i32 [ %start, %entry ], [ %select, %loop ]
  %gep = getelementptr inbounds i8, ptr %src, i64 %iv
  %load = load i8, ptr %gep, align 1
  %icmp = icmp eq i8 %load, 0
  %select = select i1 %icmp, i32 1, i32 %red
  %iv.next = add i64 %iv, 1
  %icmp3 = icmp eq i64 %iv, %N
  br i1 %icmp3, label %exit, label %loop

exit:
  ret i32 %select
}

define i1 @any_of_reduction_i1_epilog(i64 %N, i32 %a) {
; CHECK-LABEL: define i1 @any_of_reduction_i1_epilog(
; CHECK-SAME: i64 [[N:%.*]], i32 [[A:%.*]]) {
; CHECK-NEXT:  iter.check:
; CHECK-NEXT:    [[TMP0:%.*]] = add i64 [[N]], 1
; CHECK-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ult i64 [[TMP0]], 4
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK]], label [[VEC_EPILOG_SCALAR_PH:%.*]], label [[VECTOR_MAIN_LOOP_ITER_CHECK:%.*]]
; CHECK:       vector.main.loop.iter.check:
; CHECK-NEXT:    [[MIN_ITERS_CHECK1:%.*]] = icmp ult i64 [[TMP0]], 4
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK1]], label [[VEC_EPILOG_PH:%.*]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    [[N_MOD_VF:%.*]] = urem i64 [[TMP0]], 4
; CHECK-NEXT:    [[N_VEC:%.*]] = sub i64 [[TMP0]], [[N_MOD_VF]]
; CHECK-NEXT:    [[IND_END:%.*]] = trunc i64 [[N_VEC]] to i32
; CHECK-NEXT:    [[BROADCAST_SPLATINSERT:%.*]] = insertelement <4 x i32> poison, i32 [[A]], i64 0
; CHECK-NEXT:    [[BROADCAST_SPLAT:%.*]] = shufflevector <4 x i32> [[BROADCAST_SPLATINSERT]], <4 x i32> poison, <4 x i32> zeroinitializer
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i64 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_PHI:%.*]] = phi <4 x i1> [ zeroinitializer, [[VECTOR_PH]] ], [ [[TMP3:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_IND:%.*]] = phi <4 x i32> [ <i32 0, i32 1, i32 2, i32 3>, [[VECTOR_PH]] ], [ [[VEC_IND_NEXT:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP2:%.*]] = icmp ne <4 x i32> [[VEC_IND]], [[BROADCAST_SPLAT]]
; CHECK-NEXT:    [[TMP3]] = or <4 x i1> [[VEC_PHI]], [[TMP2]]
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i64 [[INDEX]], 4
; CHECK-NEXT:    [[VEC_IND_NEXT]] = add <4 x i32> [[VEC_IND]], splat (i32 4)
; CHECK-NEXT:    [[TMP4:%.*]] = icmp eq i64 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP4]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop [[LOOP8:![0-9]+]]
; CHECK:       middle.block:
; CHECK-NEXT:    [[TMP5:%.*]] = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> [[TMP3]])
; CHECK-NEXT:    [[TMP6:%.*]] = freeze i1 [[TMP5]]
; CHECK-NEXT:    [[RDX_SELECT:%.*]] = select i1 [[TMP6]], i1 false, i1 false
; CHECK-NEXT:    [[CMP_N:%.*]] = icmp eq i64 [[TMP0]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[CMP_N]], label [[EXIT:%.*]], label [[VEC_EPILOG_ITER_CHECK:%.*]]
; CHECK:       vec.epilog.iter.check:
; CHECK-NEXT:    [[IND_END6:%.*]] = trunc i64 [[N_VEC]] to i32
; CHECK-NEXT:    [[N_VEC_REMAINING:%.*]] = sub i64 [[TMP0]], [[N_VEC]]
; CHECK-NEXT:    [[MIN_EPILOG_ITERS_CHECK:%.*]] = icmp ult i64 [[N_VEC_REMAINING]], 4
; CHECK-NEXT:    br i1 [[MIN_EPILOG_ITERS_CHECK]], label [[VEC_EPILOG_SCALAR_PH]], label [[VEC_EPILOG_PH]]
; CHECK:       vec.epilog.ph:
; CHECK-NEXT:    [[VEC_EPILOG_RESUME_VAL:%.*]] = phi i64 [ [[N_VEC]], [[VEC_EPILOG_ITER_CHECK]] ], [ 0, [[VECTOR_MAIN_LOOP_ITER_CHECK]] ]
; CHECK-NEXT:    [[BC_MERGE_RDX:%.*]] = phi i1 [ [[RDX_SELECT]], [[VEC_EPILOG_ITER_CHECK]] ], [ false, [[VECTOR_MAIN_LOOP_ITER_CHECK]] ]
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i32 [ [[IND_END]], [[VEC_EPILOG_ITER_CHECK]] ], [ 0, [[VECTOR_MAIN_LOOP_ITER_CHECK]] ]
; CHECK-NEXT:    [[TMP7:%.*]] = icmp ne i1 [[BC_MERGE_RDX]], false
; CHECK-NEXT:    [[N_MOD_VF2:%.*]] = urem i64 [[TMP0]], 4
; CHECK-NEXT:    [[N_VEC3:%.*]] = sub i64 [[TMP0]], [[N_MOD_VF2]]
; CHECK-NEXT:    [[IND_END5:%.*]] = trunc i64 [[N_VEC3]] to i32
; CHECK-NEXT:    [[BROADCAST_SPLATINSERT4:%.*]] = insertelement <4 x i32> poison, i32 [[A]], i64 0
; CHECK-NEXT:    [[BROADCAST_SPLAT14:%.*]] = shufflevector <4 x i32> [[BROADCAST_SPLATINSERT4]], <4 x i32> poison, <4 x i32> zeroinitializer
; CHECK-NEXT:    [[BROADCAST_SPLATINSERT6:%.*]] = insertelement <4 x i1> poison, i1 [[TMP7]], i64 0
; CHECK-NEXT:    [[MINMAX_IDENT_SPLAT:%.*]] = shufflevector <4 x i1> [[BROADCAST_SPLATINSERT6]], <4 x i1> poison, <4 x i32> zeroinitializer
; CHECK-NEXT:    [[DOTSPLATINSERT:%.*]] = insertelement <4 x i32> poison, i32 [[BC_RESUME_VAL]], i64 0
; CHECK-NEXT:    [[DOTSPLAT:%.*]] = shufflevector <4 x i32> [[DOTSPLATINSERT]], <4 x i32> poison, <4 x i32> zeroinitializer
; CHECK-NEXT:    [[INDUCTION:%.*]] = add <4 x i32> [[DOTSPLAT]], <i32 0, i32 1, i32 2, i32 3>
; CHECK-NEXT:    br label [[VEC_EPILOG_VECTOR_BODY:%.*]]
; CHECK:       vec.epilog.vector.body:
; CHECK-NEXT:    [[INDEX9:%.*]] = phi i64 [ [[VEC_EPILOG_RESUME_VAL]], [[VEC_EPILOG_PH]] ], [ [[INDEX_NEXT15:%.*]], [[VEC_EPILOG_VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_PHI10:%.*]] = phi <4 x i1> [ [[MINMAX_IDENT_SPLAT]], [[VEC_EPILOG_PH]] ], [ [[TMP10:%.*]], [[VEC_EPILOG_VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_IND11:%.*]] = phi <4 x i32> [ [[INDUCTION]], [[VEC_EPILOG_PH]] ], [ [[VEC_IND_NEXT12:%.*]], [[VEC_EPILOG_VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP9:%.*]] = icmp ne <4 x i32> [[VEC_IND11]], [[BROADCAST_SPLAT14]]
; CHECK-NEXT:    [[TMP10]] = or <4 x i1> [[VEC_PHI10]], [[TMP9]]
; CHECK-NEXT:    [[INDEX_NEXT15]] = add nuw i64 [[INDEX9]], 4
; CHECK-NEXT:    [[VEC_IND_NEXT12]] = add <4 x i32> [[VEC_IND11]], splat (i32 4)
; CHECK-NEXT:    [[TMP11:%.*]] = icmp eq i64 [[INDEX_NEXT15]], [[N_VEC3]]
; CHECK-NEXT:    br i1 [[TMP11]], label [[VEC_EPILOG_MIDDLE_BLOCK:%.*]], label [[VEC_EPILOG_VECTOR_BODY]], !llvm.loop [[LOOP9:![0-9]+]]
; CHECK:       vec.epilog.middle.block:
; CHECK-NEXT:    [[TMP12:%.*]] = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> [[TMP10]])
; CHECK-NEXT:    [[TMP13:%.*]] = freeze i1 [[TMP12]]
; CHECK-NEXT:    [[RDX_SELECT16:%.*]] = select i1 [[TMP13]], i1 false, i1 false
; CHECK-NEXT:    [[CMP_N8:%.*]] = icmp eq i64 [[TMP0]], [[N_VEC3]]
; CHECK-NEXT:    br i1 [[CMP_N8]], label [[EXIT]], label [[VEC_EPILOG_SCALAR_PH]]
; CHECK:       vec.epilog.scalar.ph:
; CHECK-NEXT:    [[BC_RESUME_VAL4:%.*]] = phi i64 [ [[N_VEC3]], [[VEC_EPILOG_MIDDLE_BLOCK]] ], [ [[N_VEC]], [[VEC_EPILOG_ITER_CHECK]] ], [ 0, [[ITER_CHECK:%.*]] ]
; CHECK-NEXT:    [[BC_MERGE_RDX17:%.*]] = phi i1 [ [[RDX_SELECT16]], [[VEC_EPILOG_MIDDLE_BLOCK]] ], [ [[RDX_SELECT]], [[VEC_EPILOG_ITER_CHECK]] ], [ false, [[ITER_CHECK]] ]
; CHECK-NEXT:    [[BC_RESUME_VAL7:%.*]] = phi i32 [ [[IND_END5]], [[VEC_EPILOG_MIDDLE_BLOCK]] ], [ [[IND_END6]], [[VEC_EPILOG_ITER_CHECK]] ], [ 0, [[ITER_CHECK]] ]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i64 [ [[BC_RESUME_VAL4]], [[VEC_EPILOG_SCALAR_PH]] ], [ [[IV_NEXT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[RED_I1:%.*]] = phi i1 [ [[BC_MERGE_RDX17]], [[VEC_EPILOG_SCALAR_PH]] ], [ [[SEL:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[IV_2:%.*]] = phi i32 [ [[BC_RESUME_VAL7]], [[VEC_EPILOG_SCALAR_PH]] ], [ [[IV_2_NEXT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[CMP_1:%.*]] = icmp eq i32 [[IV_2]], [[A]]
; CHECK-NEXT:    [[SEL]] = select i1 [[CMP_1]], i1 [[RED_I1]], i1 false
; CHECK-NEXT:    [[IV_NEXT]] = add i64 [[IV]], 1
; CHECK-NEXT:    [[IV_2_NEXT]] = add i32 [[IV_2]], 1
; CHECK-NEXT:    [[CMP_2:%.*]] = icmp eq i64 [[IV]], [[N]]
; CHECK-NEXT:    br i1 [[CMP_2]], label [[EXIT]], label [[LOOP]], !llvm.loop [[LOOP10:![0-9]+]]
; CHECK:       exit:
; CHECK-NEXT:    [[SEL_LCSSA:%.*]] = phi i1 [ [[SEL]], [[LOOP]] ], [ [[RDX_SELECT]], [[MIDDLE_BLOCK]] ], [ [[RDX_SELECT16]], [[VEC_EPILOG_MIDDLE_BLOCK]] ]
; CHECK-NEXT:    ret i1 [[SEL_LCSSA]]
;
entry:
  br label %loop

loop:
  %iv = phi i64 [ 0, %entry ], [ %iv.next, %loop ]
  %red.i1 = phi i1 [ false, %entry ], [ %sel, %loop ]
  %iv.2 = phi i32 [ 0, %entry ], [ %iv.2.next, %loop ]
  %cmp.1 = icmp eq i32 %iv.2, %a
  %sel = select i1 %cmp.1, i1 %red.i1, i1 false
  %iv.next = add i64 %iv, 1
  %iv.2.next = add i32 %iv.2, 1
  %cmp.2 = icmp eq i64 %iv, %N
  br i1 %cmp.2, label %exit, label %loop

exit:
  ret i1 %sel

; uselistorder directives
  uselistorder i1 %sel, { 1, 0 }
}

define i1 @any_of_reduction_i1_epilog2(ptr %start, ptr %end, i64 %x) {
; CHECK-LABEL: define i1 @any_of_reduction_i1_epilog2(
; CHECK-SAME: ptr [[START:%.*]], ptr [[END:%.*]], i64 [[X:%.*]]) {
; CHECK-NEXT:  iter.check:
; CHECK-NEXT:    [[START2:%.*]] = ptrtoint ptr [[START]] to i64
; CHECK-NEXT:    [[END1:%.*]] = ptrtoint ptr [[END]] to i64
; CHECK-NEXT:    [[TMP0:%.*]] = add i64 [[END1]], -16
; CHECK-NEXT:    [[TMP1:%.*]] = sub i64 [[TMP0]], [[START2]]
; CHECK-NEXT:    [[TMP2:%.*]] = lshr i64 [[TMP1]], 4
; CHECK-NEXT:    [[TMP3:%.*]] = add nuw nsw i64 [[TMP2]], 1
; CHECK-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ult i64 [[TMP3]], 4
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK]], label [[VEC_EPILOG_SCALAR_PH:%.*]], label [[VECTOR_MAIN_LOOP_ITER_CHECK:%.*]]
; CHECK:       vector.main.loop.iter.check:
; CHECK-NEXT:    [[MIN_ITERS_CHECK3:%.*]] = icmp ult i64 [[TMP3]], 4
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK3]], label [[VEC_EPILOG_PH:%.*]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    [[N_MOD_VF:%.*]] = urem i64 [[TMP3]], 4
; CHECK-NEXT:    [[N_VEC:%.*]] = sub i64 [[TMP3]], [[N_MOD_VF]]
; CHECK-NEXT:    [[BROADCAST_SPLATINSERT:%.*]] = insertelement <4 x i64> poison, i64 [[X]], i64 0
; CHECK-NEXT:    [[BROADCAST_SPLAT:%.*]] = shufflevector <4 x i64> [[BROADCAST_SPLATINSERT]], <4 x i64> poison, <4 x i32> zeroinitializer
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i64 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_PHI:%.*]] = phi <4 x i1> [ zeroinitializer, [[VECTOR_PH]] ], [ [[RDX_SELECT_CMP:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[OFFSET_IDX:%.*]] = mul i64 [[INDEX]], 16
; CHECK-NEXT:    [[TMP4:%.*]] = add i64 [[OFFSET_IDX]], 0
; CHECK-NEXT:    [[TMP5:%.*]] = add i64 [[OFFSET_IDX]], 16
; CHECK-NEXT:    [[TMP6:%.*]] = add i64 [[OFFSET_IDX]], 32
; CHECK-NEXT:    [[TMP7:%.*]] = add i64 [[OFFSET_IDX]], 48
; CHECK-NEXT:    [[NEXT_GEP:%.*]] = getelementptr i8, ptr [[START]], i64 [[TMP4]]
; CHECK-NEXT:    [[NEXT_GEP4:%.*]] = getelementptr i8, ptr [[START]], i64 [[TMP5]]
; CHECK-NEXT:    [[NEXT_GEP5:%.*]] = getelementptr i8, ptr [[START]], i64 [[TMP6]]
; CHECK-NEXT:    [[NEXT_GEP6:%.*]] = getelementptr i8, ptr [[START]], i64 [[TMP7]]
; CHECK-NEXT:    [[TMP8:%.*]] = getelementptr inbounds i8, ptr [[NEXT_GEP]], i64 8
; CHECK-NEXT:    [[TMP9:%.*]] = getelementptr inbounds i8, ptr [[NEXT_GEP4]], i64 8
; CHECK-NEXT:    [[TMP10:%.*]] = getelementptr inbounds i8, ptr [[NEXT_GEP5]], i64 8
; CHECK-NEXT:    [[TMP11:%.*]] = getelementptr inbounds i8, ptr [[NEXT_GEP6]], i64 8
; CHECK-NEXT:    [[TMP12:%.*]] = load i64, ptr [[TMP8]], align 8
; CHECK-NEXT:    [[TMP13:%.*]] = load i64, ptr [[TMP9]], align 8
; CHECK-NEXT:    [[TMP14:%.*]] = load i64, ptr [[TMP10]], align 8
; CHECK-NEXT:    [[TMP15:%.*]] = load i64, ptr [[TMP11]], align 8
; CHECK-NEXT:    [[TMP16:%.*]] = insertelement <4 x i64> poison, i64 [[TMP12]], i32 0
; CHECK-NEXT:    [[TMP17:%.*]] = insertelement <4 x i64> [[TMP16]], i64 [[TMP13]], i32 1
; CHECK-NEXT:    [[TMP18:%.*]] = insertelement <4 x i64> [[TMP17]], i64 [[TMP14]], i32 2
; CHECK-NEXT:    [[TMP19:%.*]] = insertelement <4 x i64> [[TMP18]], i64 [[TMP15]], i32 3
; CHECK-NEXT:    [[TMP21:%.*]] = icmp ne <4 x i64> [[TMP19]], [[BROADCAST_SPLAT]]
; CHECK-NEXT:    [[RDX_SELECT_CMP]] = or <4 x i1> [[VEC_PHI]], [[TMP21]]
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i64 [[INDEX]], 4
; CHECK-NEXT:    [[TMP22:%.*]] = icmp eq i64 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP22]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop [[LOOP11:![0-9]+]]
; CHECK:       middle.block:
; CHECK-NEXT:    [[TMP23:%.*]] = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> [[RDX_SELECT_CMP]])
; CHECK-NEXT:    [[TMP47:%.*]] = freeze i1 [[TMP23]]
; CHECK-NEXT:    [[RDX_SELECT:%.*]] = select i1 [[TMP47]], i1 false, i1 true
; CHECK-NEXT:    [[CMP_N:%.*]] = icmp eq i64 [[TMP3]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[CMP_N]], label [[EXIT:%.*]], label [[VEC_EPILOG_ITER_CHECK:%.*]]
; CHECK:       vec.epilog.iter.check:
; CHECK-NEXT:    [[TMP24:%.*]] = mul i64 [[N_VEC]], 16
; CHECK-NEXT:    [[IND_END9:%.*]] = getelementptr i8, ptr [[START]], i64 [[TMP24]]
; CHECK-NEXT:    [[N_VEC_REMAINING:%.*]] = sub i64 [[TMP3]], [[N_VEC]]
; CHECK-NEXT:    [[MIN_EPILOG_ITERS_CHECK:%.*]] = icmp ult i64 [[N_VEC_REMAINING]], 4
; CHECK-NEXT:    br i1 [[MIN_EPILOG_ITERS_CHECK]], label [[VEC_EPILOG_SCALAR_PH]], label [[VEC_EPILOG_PH]]
; CHECK:       vec.epilog.ph:
; CHECK-NEXT:    [[VEC_EPILOG_RESUME_VAL:%.*]] = phi i64 [ [[N_VEC]], [[VEC_EPILOG_ITER_CHECK]] ], [ 0, [[VECTOR_MAIN_LOOP_ITER_CHECK]] ]
; CHECK-NEXT:    [[BC_MERGE_RDX:%.*]] = phi i1 [ [[RDX_SELECT]], [[VEC_EPILOG_ITER_CHECK]] ], [ true, [[VECTOR_MAIN_LOOP_ITER_CHECK]] ]
; CHECK-NEXT:    [[TMP48:%.*]] = icmp ne i1 [[BC_MERGE_RDX]], true
; CHECK-NEXT:    [[N_MOD_VF7:%.*]] = urem i64 [[TMP3]], 4
; CHECK-NEXT:    [[N_VEC8:%.*]] = sub i64 [[TMP3]], [[N_MOD_VF7]]
; CHECK-NEXT:    [[TMP25:%.*]] = mul i64 [[N_VEC8]], 16
; CHECK-NEXT:    [[IND_END:%.*]] = getelementptr i8, ptr [[START]], i64 [[TMP25]]
; CHECK-NEXT:    [[BROADCAST_SPLATINSERT18:%.*]] = insertelement <4 x i64> poison, i64 [[X]], i64 0
; CHECK-NEXT:    [[BROADCAST_SPLAT19:%.*]] = shufflevector <4 x i64> [[BROADCAST_SPLATINSERT18]], <4 x i64> poison, <4 x i32> zeroinitializer
; CHECK-NEXT:    [[BROADCAST_SPLATINSERT13:%.*]] = insertelement <4 x i1> poison, i1 [[TMP48]], i64 0
; CHECK-NEXT:    [[MINMAX_IDENT_SPLAT:%.*]] = shufflevector <4 x i1> [[BROADCAST_SPLATINSERT13]], <4 x i1> poison, <4 x i32> zeroinitializer
; CHECK-NEXT:    br label [[VEC_EPILOG_VECTOR_BODY:%.*]]
; CHECK:       vec.epilog.vector.body:
; CHECK-NEXT:    [[INDEX11:%.*]] = phi i64 [ [[VEC_EPILOG_RESUME_VAL]], [[VEC_EPILOG_PH]] ], [ [[INDEX_NEXT20:%.*]], [[VEC_EPILOG_VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_PHI12:%.*]] = phi <4 x i1> [ [[MINMAX_IDENT_SPLAT]], [[VEC_EPILOG_PH]] ], [ [[TMP43:%.*]], [[VEC_EPILOG_VECTOR_BODY]] ]
; CHECK-NEXT:    [[OFFSET_IDX13:%.*]] = mul i64 [[INDEX11]], 16
; CHECK-NEXT:    [[TMP26:%.*]] = add i64 [[OFFSET_IDX13]], 0
; CHECK-NEXT:    [[TMP27:%.*]] = add i64 [[OFFSET_IDX13]], 16
; CHECK-NEXT:    [[TMP28:%.*]] = add i64 [[OFFSET_IDX13]], 32
; CHECK-NEXT:    [[TMP29:%.*]] = add i64 [[OFFSET_IDX13]], 48
; CHECK-NEXT:    [[NEXT_GEP14:%.*]] = getelementptr i8, ptr [[START]], i64 [[TMP26]]
; CHECK-NEXT:    [[NEXT_GEP15:%.*]] = getelementptr i8, ptr [[START]], i64 [[TMP27]]
; CHECK-NEXT:    [[NEXT_GEP16:%.*]] = getelementptr i8, ptr [[START]], i64 [[TMP28]]
; CHECK-NEXT:    [[NEXT_GEP17:%.*]] = getelementptr i8, ptr [[START]], i64 [[TMP29]]
; CHECK-NEXT:    [[TMP30:%.*]] = getelementptr inbounds i8, ptr [[NEXT_GEP14]], i64 8
; CHECK-NEXT:    [[TMP31:%.*]] = getelementptr inbounds i8, ptr [[NEXT_GEP15]], i64 8
; CHECK-NEXT:    [[TMP32:%.*]] = getelementptr inbounds i8, ptr [[NEXT_GEP16]], i64 8
; CHECK-NEXT:    [[TMP33:%.*]] = getelementptr inbounds i8, ptr [[NEXT_GEP17]], i64 8
; CHECK-NEXT:    [[TMP34:%.*]] = load i64, ptr [[TMP30]], align 8
; CHECK-NEXT:    [[TMP35:%.*]] = load i64, ptr [[TMP31]], align 8
; CHECK-NEXT:    [[TMP36:%.*]] = load i64, ptr [[TMP32]], align 8
; CHECK-NEXT:    [[TMP37:%.*]] = load i64, ptr [[TMP33]], align 8
; CHECK-NEXT:    [[TMP38:%.*]] = insertelement <4 x i64> poison, i64 [[TMP34]], i32 0
; CHECK-NEXT:    [[TMP39:%.*]] = insertelement <4 x i64> [[TMP38]], i64 [[TMP35]], i32 1
; CHECK-NEXT:    [[TMP40:%.*]] = insertelement <4 x i64> [[TMP39]], i64 [[TMP36]], i32 2
; CHECK-NEXT:    [[TMP41:%.*]] = insertelement <4 x i64> [[TMP40]], i64 [[TMP37]], i32 3
; CHECK-NEXT:    [[TMP46:%.*]] = icmp ne <4 x i64> [[TMP41]], [[BROADCAST_SPLAT19]]
; CHECK-NEXT:    [[TMP43]] = or <4 x i1> [[VEC_PHI12]], [[TMP46]]
; CHECK-NEXT:    [[INDEX_NEXT20]] = add nuw i64 [[INDEX11]], 4
; CHECK-NEXT:    [[TMP44:%.*]] = icmp eq i64 [[INDEX_NEXT20]], [[N_VEC8]]
; CHECK-NEXT:    br i1 [[TMP44]], label [[VEC_EPILOG_MIDDLE_BLOCK:%.*]], label [[VEC_EPILOG_VECTOR_BODY]], !llvm.loop [[LOOP12:![0-9]+]]
; CHECK:       vec.epilog.middle.block:
; CHECK-NEXT:    [[TMP49:%.*]] = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> [[TMP43]])
; CHECK-NEXT:    [[TMP45:%.*]] = freeze i1 [[TMP49]]
; CHECK-NEXT:    [[RDX_SELECT22:%.*]] = select i1 [[TMP45]], i1 false, i1 true
; CHECK-NEXT:    [[CMP_N10:%.*]] = icmp eq i64 [[TMP3]], [[N_VEC8]]
; CHECK-NEXT:    br i1 [[CMP_N10]], label [[EXIT]], label [[VEC_EPILOG_SCALAR_PH]]
; CHECK:       vec.epilog.scalar.ph:
; CHECK-NEXT:    [[BC_MERGE_RDX23:%.*]] = phi i1 [ [[RDX_SELECT22]], [[VEC_EPILOG_MIDDLE_BLOCK]] ], [ [[RDX_SELECT]], [[VEC_EPILOG_ITER_CHECK]] ], [ true, [[ITER_CHECK:%.*]] ]
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi ptr [ [[IND_END]], [[VEC_EPILOG_MIDDLE_BLOCK]] ], [ [[IND_END9]], [[VEC_EPILOG_ITER_CHECK]] ], [ [[START]], [[ITER_CHECK]] ]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[RED:%.*]] = phi i1 [ [[BC_MERGE_RDX23]], [[VEC_EPILOG_SCALAR_PH]] ], [ [[SELECT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[IV:%.*]] = phi ptr [ [[BC_RESUME_VAL]], [[VEC_EPILOG_SCALAR_PH]] ], [ [[IV_NEXT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[GETELEMENTPTR5:%.*]] = getelementptr inbounds i8, ptr [[IV]], i64 8
; CHECK-NEXT:    [[LOAD6:%.*]] = load i64, ptr [[GETELEMENTPTR5]], align 8
; CHECK-NEXT:    [[ICMP7:%.*]] = icmp eq i64 [[LOAD6]], [[X]]
; CHECK-NEXT:    [[SELECT]] = select i1 [[ICMP7]], i1 [[RED]], i1 false
; CHECK-NEXT:    [[IV_NEXT]] = getelementptr inbounds i8, ptr [[IV]], i64 16
; CHECK-NEXT:    [[EC:%.*]] = icmp eq ptr [[IV_NEXT]], [[END]]
; CHECK-NEXT:    br i1 [[EC]], label [[EXIT]], label [[LOOP]], !llvm.loop [[LOOP13:![0-9]+]]
; CHECK:       exit:
; CHECK-NEXT:    [[SELECT_LCSSA:%.*]] = phi i1 [ [[SELECT]], [[LOOP]] ], [ [[RDX_SELECT]], [[MIDDLE_BLOCK]] ], [ [[RDX_SELECT22]], [[VEC_EPILOG_MIDDLE_BLOCK]] ]
; CHECK-NEXT:    ret i1 [[SELECT_LCSSA]]
;
entry:
  br label %loop

loop:                                              ; preds = %bb3, %bb2
  %red = phi i1 [ true, %entry ], [ %select, %loop ]
  %iv = phi ptr [ %start, %entry ], [ %iv.next, %loop ]
  %getelementptr5 = getelementptr inbounds i8, ptr %iv, i64 8
  %load6 = load i64, ptr %getelementptr5, align 8
  %icmp7 = icmp eq i64 %load6, %x
  %select = select i1 %icmp7, i1 %red, i1 false
  %iv.next = getelementptr inbounds i8, ptr %iv, i64 16
  %ec = icmp eq ptr %iv.next, %end
  br i1 %ec, label %exit, label %loop

exit:
  ret i1 %select
}

;.
; CHECK: [[LOOP0]] = distinct !{[[LOOP0]], [[META1:![0-9]+]], [[META2:![0-9]+]]}
; CHECK: [[META1]] = !{!"llvm.loop.isvectorized", i32 1}
; CHECK: [[META2]] = !{!"llvm.loop.unroll.runtime.disable"}
; CHECK: [[LOOP3]] = distinct !{[[LOOP3]], [[META1]], [[META2]]}
; CHECK: [[LOOP4]] = distinct !{[[LOOP4]], [[META2]], [[META1]]}
; CHECK: [[LOOP5]] = distinct !{[[LOOP5]], [[META1]], [[META2]]}
; CHECK: [[LOOP6]] = distinct !{[[LOOP6]], [[META1]], [[META2]]}
; CHECK: [[LOOP7]] = distinct !{[[LOOP7]], [[META2]], [[META1]]}
; CHECK: [[LOOP8]] = distinct !{[[LOOP8]], [[META1]], [[META2]]}
; CHECK: [[LOOP9]] = distinct !{[[LOOP9]], [[META1]], [[META2]]}
; CHECK: [[LOOP10]] = distinct !{[[LOOP10]], [[META2]], [[META1]]}
; CHECK: [[LOOP11]] = distinct !{[[LOOP11]], [[META1]], [[META2]]}
; CHECK: [[LOOP12]] = distinct !{[[LOOP12]], [[META1]], [[META2]]}
; CHECK: [[LOOP13]] = distinct !{[[LOOP13]], [[META2]], [[META1]]}
;.
