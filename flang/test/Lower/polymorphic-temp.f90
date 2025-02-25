! Test creation of temporary from polymorphic enities
! RUN: bbc -polymorphic-type -emit-fir %s -o - | FileCheck %s

module poly_tmp
  type p1
    integer :: a
  end type

  type, extends(p1) :: p2
    integer :: b
  end type

contains
  subroutine pass_unlimited_poly_1d(x)
    class(*), intent(in) :: x(:)
  end subroutine


  subroutine test_temp_from_intrinsic_spread()
    class(*), pointer :: p
    class(*), pointer :: pa(:)
    allocate(p2::p)
    allocate(p2::pa(10))

    call pass_unlimited_poly_1d(spread(p, dim=1, ncopies=2))
    call pass_unlimited_poly_1d(spread(pa(1), dim=1, ncopies=2))
    
  end subroutine

! CHECK-LABEL: func.func @_QMpoly_tmpPtest_temp_from_intrinsic_spread() {
! CHECK: %[[TEMP_RES1:.*]] = fir.alloca !fir.class<!fir.heap<!fir.array<?xnone>>>
! CHECK: %[[TEMP_RES0:.*]] = fir.alloca !fir.class<!fir.heap<!fir.array<?xnone>>>
! CHECK: %[[P:.*]] = fir.alloca !fir.class<!fir.ptr<none>> {bindc_name = "p", uniq_name = "_QMpoly_tmpFtest_temp_from_intrinsic_spreadEp"}
! CHECK: %[[PA:.*]] = fir.alloca !fir.class<!fir.ptr<!fir.array<?xnone>>> {bindc_name = "pa", uniq_name = "_QMpoly_tmpFtest_temp_from_intrinsic_spreadEpa"}
! CHECK: fir.call @_FortranAPointerNullifyDerived
! CHECK: fir.call @_FortranAPointerAllocate
! CHECK: %[[LOAD_P:.*]] = fir.load %[[P]] : !fir.ref<!fir.class<!fir.ptr<none>>>
! CHECK: %[[C1:.*]] = arith.constant 1 : i32
! CHECK: %[[C2:.*]] = arith.constant 2 : i32
! CHECK: %[[ZERO:.*]] = fir.zero_bits !fir.heap<!fir.array<?xnone>>
! CHECK: %[[C0:.*]] = arith.constant 0 : index
! CHECK: %[[SHAPE:.*]] = fir.shape %[[C0]] : (index) -> !fir.shape<1>
! Make sure the fir.embox contains the source_box pointing to the polymoprhic entity
! CHECK: %[[BOX_RES:.*]] = fir.embox %[[ZERO]](%[[SHAPE]]) source_box %[[LOAD_P]] : (!fir.heap<!fir.array<?xnone>>, !fir.shape<1>, !fir.class<!fir.ptr<none>>) -> !fir.class<!fir.heap<!fir.array<?xnone>>>
! CHECK: fir.store %[[BOX_RES]] to %[[TEMP_RES0]] : !fir.ref<!fir.class<!fir.heap<!fir.array<?xnone>>>>
! CHECK: %[[RES_BOX_NONE:.*]] = fir.convert %[[TEMP_RES0]] : (!fir.ref<!fir.class<!fir.heap<!fir.array<?xnone>>>>) -> !fir.ref<!fir.box<none>>
! CHECK: %[[P_BOX_NONE:.*]] = fir.convert %[[LOAD_P]] : (!fir.class<!fir.ptr<none>>) -> !fir.box<none>
! CHECK: %[[C2_I64:.*]] = fir.convert %[[C2]] : (i32) -> i64
! CHECK: %{{.*}} = fir.call @_FortranASpread(%[[RES_BOX_NONE]], %[[P_BOX_NONE]], %[[C1]], %[[C2_I64]], %{{.*}}, %{{.*}}) fastmath<contract> : (!fir.ref<!fir.box<none>>, !fir.box<none>, i32, i64, !fir.ref<i8>, i32) -> none
! CHECK: %[[LOAD_RES:.*]] = fir.load %[[TEMP_RES0]] : !fir.ref<!fir.class<!fir.heap<!fir.array<?xnone>>>>
! CHECK: %[[RES_ADDR:.*]] = fir.box_addr %[[LOAD_RES]] : (!fir.class<!fir.heap<!fir.array<?xnone>>>) -> !fir.heap<!fir.array<?xnone>>
! CHECK: %[[REBOX:.*]] = fir.rebox %[[LOAD_RES]] : (!fir.class<!fir.heap<!fir.array<?xnone>>>) -> !fir.class<!fir.array<?xnone>>
! CHECK: fir.call @_QMpoly_tmpPpass_unlimited_poly_1d(%[[REBOX]]) {{.*}} : (!fir.class<!fir.array<?xnone>>) -> ()
! CHECK: fir.freemem %[[RES_ADDR]] : !fir.heap<!fir.array<?xnone>>
! CHECK: %[[LOAD_PA:.*]] = fir.load %[[PA]] : !fir.ref<!fir.class<!fir.ptr<!fir.array<?xnone>>>>
! CHECK: %[[COORD_PA_1:.*]] = fir.coordinate_of %[[LOAD_PA]], %{{.*}} : (!fir.class<!fir.ptr<!fir.array<?xnone>>>, i64) -> !fir.ref<none>
! CHECK: %[[EMBOX_PA_1:.*]] = fir.embox %[[COORD_PA_1]] source_box %[[LOAD_PA]] : (!fir.ref<none>, !fir.class<!fir.ptr<!fir.array<?xnone>>>) -> !fir.class<none>
! CHECK: %[[RES1_BOX_NONE:.*]] = fir.convert %[[TEMP_RES1]] : (!fir.ref<!fir.class<!fir.heap<!fir.array<?xnone>>>>) -> !fir.ref<!fir.box<none>>
! CHECK: %[[PA1_BOX_NONE:.*]] = fir.convert %[[EMBOX_PA_1]] : (!fir.class<none>) -> !fir.box<none>
! CHECK: %{{.*}} = fir.call @_FortranASpread(%[[RES1_BOX_NONE]], %[[PA1_BOX_NONE]], %{{.*}}, %{{.*}}, %{{.*}}, %{{.*}}) {{.*}} : (!fir.ref<!fir.box<none>>, !fir.box<none>, i32, i64, !fir.ref<i8>, i32) -> none

  subroutine test_temp_from_intrinsic_reshape(i)
    class(*), allocatable :: a(:,:)
    class(*), intent(in) :: i(20,20)
    allocate(a(10,10), source=reshape(i,[10,10]))
  end subroutine

! CHECK-LABEL: func.func @_QMpoly_tmpPtest_temp_from_intrinsic_reshape(
! CHECK-SAME: %[[I:.*]]: !fir.class<!fir.array<20x20xnone>> {fir.bindc_name = "i"}) {
! CHECK: %[[TMP_RES:.*]] = fir.alloca !fir.class<!fir.heap<!fir.array<?x?xnone>>>
! CHECK: %[[A:.*]] = fir.alloca !fir.class<!fir.heap<!fir.array<?x?xnone>>> {bindc_name = "a", uniq_name = "_QMpoly_tmpFtest_temp_from_intrinsic_reshapeEa"}
! CHECK: %[[EMBOX_WITH_SOURCE:.*]] = fir.embox %{{.*}}(%{{.*}}) source_box %[[I]] : (!fir.heap<!fir.array<?x?xnone>>, !fir.shape<2>, !fir.class<!fir.array<20x20xnone>>) -> !fir.class<!fir.heap<!fir.array<?x?xnone>>>
! CHECK: fir.store %[[EMBOX_WITH_SOURCE]] to %[[TMP_RES]] : !fir.ref<!fir.class<!fir.heap<!fir.array<?x?xnone>>>>
! CHECK: %[[RES_BOX_NONE:.*]] = fir.convert %[[TMP_RES]] : (!fir.ref<!fir.class<!fir.heap<!fir.array<?x?xnone>>>>) -> !fir.ref<!fir.box<none>>
! CHECK: %[[I_BOX_NONE:.*]] = fir.convert %[[I]] : (!fir.class<!fir.array<20x20xnone>>) -> !fir.box<none>
! CHECK: %{{.*}} = fir.call @_FortranAReshape(%[[RES_BOX_NONE]], %[[I_BOX_NONE]], %{{.*}}, %{{.*}}, %{{.*}}, %{{.*}}, %{{.*}}) {{.*}} : (!fir.ref<!fir.box<none>>, !fir.box<none>, !fir.box<none>, !fir.box<none>, !fir.box<none>, !fir.ref<i8>, i32) -> none
! CHECK: %[[LOAD_RES:.*]] = fir.load %[[TMP_RES]] : !fir.ref<!fir.class<!fir.heap<!fir.array<?x?xnone>>>>
! CHECK: %[[RANK:.*]] = arith.constant 2 : i32
! CHECK: %[[A_BOX_NONE:.*]] = fir.convert %[[A]] : (!fir.ref<!fir.class<!fir.heap<!fir.array<?x?xnone>>>>) -> !fir.ref<!fir.box<none>>
! CHECK: %[[RES_BOX_NONE:.*]] = fir.convert %[[LOAD_RES]] : (!fir.class<!fir.heap<!fir.array<?x?xnone>>>) -> !fir.box<none>
! CHECK: %{{.*}} = fir.call @_FortranAAllocatableApplyMold(%[[A_BOX_NONE]], %[[RES_BOX_NONE]], %[[RANK]]) {{.*}} : (!fir.ref<!fir.box<none>>, !fir.box<none>, i32) -> none

  subroutine check_pack(r)
    class(p1) :: r(:)
  end subroutine

  subroutine test_temp_from_intrinsic_pack(i, mask)
    class(p1), intent(in) :: i(20, 20)
    logical, intent(in) :: mask(20, 20)
    call check_pack(pack(i, mask))
  end subroutine

! CHECK-LABEL: func.func @_QMpoly_tmpPtest_temp_from_intrinsic_pack(
! CHECK-SAME: %[[I:.*]]: !fir.class<!fir.array<20x20x!fir.type<_QMpoly_tmpTp1{a:i32}>>> {fir.bindc_name = "i"}, %[[MASK:.*]]: !fir.ref<!fir.array<20x20x!fir.logical<4>>> {fir.bindc_name = "mask"}) {
! CHECK: %[[TMP_RES:.*]] = fir.alloca !fir.class<!fir.heap<!fir.array<?x!fir.type<_QMpoly_tmpTp1{a:i32}>>>>
! CHECK: %[[EMBOXED_MASK:.*]] = fir.embox %[[MASK]](%{{.*}}) : (!fir.ref<!fir.array<20x20x!fir.logical<4>>>, !fir.shape<2>) -> !fir.box<!fir.array<20x20x!fir.logical<4>>>
! CHECK: %[[ZERO:.*]] = fir.zero_bits !fir.heap<!fir.array<?x!fir.type<_QMpoly_tmpTp1{a:i32}>>>
! CHECK: %[[EMBOX_RES:.*]] = fir.embox %[[ZERO]](%{{.*}}) source_box %[[I]] : (!fir.heap<!fir.array<?x!fir.type<_QMpoly_tmpTp1{a:i32}>>>, !fir.shape<1>, !fir.class<!fir.array<20x20x!fir.type<_QMpoly_tmpTp1{a:i32}>>>) -> !fir.class<!fir.heap<!fir.array<?x!fir.type<_QMpoly_tmpTp1{a:i32}>>>>
! CHECK: fir.store %[[EMBOX_RES]] to %[[TMP_RES]] : !fir.ref<!fir.class<!fir.heap<!fir.array<?x!fir.type<_QMpoly_tmpTp1{a:i32}>>>>>
! CHECK: %[[RES_BOX_NONE:.*]] = fir.convert %[[TMP_RES]] : (!fir.ref<!fir.class<!fir.heap<!fir.array<?x!fir.type<_QMpoly_tmpTp1{a:i32}>>>>>) -> !fir.ref<!fir.box<none>>
! CHECK: %[[I_BOX_NONE:.*]] = fir.convert %[[I]] : (!fir.class<!fir.array<20x20x!fir.type<_QMpoly_tmpTp1{a:i32}>>>) -> !fir.box<none>
! CHECK: %[[MASK_BOX_NONE:.*]] = fir.convert %[[EMBOXED_MASK]] : (!fir.box<!fir.array<20x20x!fir.logical<4>>>) -> !fir.box<none>
! CHECK: %{{.*}} = fir.call @_FortranAPack(%[[RES_BOX_NONE]], %[[I_BOX_NONE]], %[[MASK_BOX_NONE]], %{{.*}}, %{{.*}}, %{{.*}}) {{.*}} : (!fir.ref<!fir.box<none>>, !fir.box<none>, !fir.box<none>, !fir.box<none>, !fir.ref<i8>, i32) -> none

  subroutine check_unpack(r)
    class(p1), intent(in) :: r(:,:)
  end subroutine

  subroutine test_temp_from_unpack(v, m, f)
    class(p1), intent(in) :: v(:), f(:,:)
    logical, intent(in) :: m(:,:)
    call check_unpack(unpack(v,m,f))
  end subroutine

! CHECK-LABEL: func.func @_QMpoly_tmpPtest_temp_from_unpack(
! CHECK-SAME: %[[V:.*]]: !fir.class<!fir.array<?x!fir.type<_QMpoly_tmpTp1{a:i32}>>> {fir.bindc_name = "v"}, %[[M:.*]]: !fir.box<!fir.array<?x?x!fir.logical<4>>> {fir.bindc_name = "m"}, %[[F:.*]]: !fir.class<!fir.array<?x?x!fir.type<_QMpoly_tmpTp1{a:i32}>>> {fir.bindc_name = "f"}) {
! CHECK: %[[TMP_RES:.*]] = fir.alloca !fir.class<!fir.heap<!fir.array<?x?x!fir.type<_QMpoly_tmpTp1{a:i32}>>>>
! CHECK: %[[TMP_BOX_NONE:.*]] = fir.convert %[[TMP_RES]] : (!fir.ref<!fir.class<!fir.heap<!fir.array<?x?x!fir.type<_QMpoly_tmpTp1{a:i32}>>>>>) -> !fir.ref<!fir.box<none>>
! CHECK: %[[V_BOX_NONE:.*]] = fir.convert %[[V]] : (!fir.class<!fir.array<?x!fir.type<_QMpoly_tmpTp1{a:i32}>>>) -> !fir.box<none>
! CHECK: %[[M_BOX_NONE:.*]] = fir.convert %[[M]] : (!fir.box<!fir.array<?x?x!fir.logical<4>>>) -> !fir.box<none>
! CHECK: %[[F_BOX_NONE:.*]] = fir.convert %[[F]] : (!fir.class<!fir.array<?x?x!fir.type<_QMpoly_tmpTp1{a:i32}>>>) -> !fir.box<none>
! CHECK: %{{.*}} = fir.call @_FortranAUnpack(%[[TMP_BOX_NONE]], %[[V_BOX_NONE]], %[[M_BOX_NONE]], %[[F_BOX_NONE]], %{{.*}}, %{{.*}}) {{.*}} : (!fir.ref<!fir.box<none>>, !fir.box<none>, !fir.box<none>, !fir.box<none>, !fir.ref<i8>, i32) -> none

end module
