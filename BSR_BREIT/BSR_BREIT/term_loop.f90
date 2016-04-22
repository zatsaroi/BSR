!======================================================================
      Subroutine TERM_loop
!======================================================================
!
!     Add to the common list (coef_list) the coeff.s between two 
!     determinants (zoef_list) weighted with term-dependent factors.
!     Check also if the specific coefficient is needed to be added
!     to the bank.
!
!----------------------------------------------------------------------

      USE param_br; USE inter; USE term_exp
      USE zoef_list; USE coef_list

      Implicit none
      Integer(4) :: i,k,m, it,jt, k1,k2
      Real(8) :: C

!----------------------------------------------------------------------
! ... find term-dependent coefficients between two determinants:

      k = 0
      Do k1=1,kt1; it=IP_kt1(k1) 
      Do k2=1,kt2; jt=IP_kt2(k2)  
       if(ic.eq.jc.and.it.gt.jt) Cycle
       k = k + 1;  Ctrm(k) = C_det1(k1,kd1)*C_det2(k2,kd2)
      End do; End do 
 
!----------------------------------------------------------------------
! ... define term- and operator-dependent coefficients:

      Do i = 1,noper
       if(joper(i).eq.0) Cycle
       CT_oper(:,i) = Coper(i)*JT_oper(1:ntrm,i)*Ctrm(1:ntrm)        
      End do

!----------------------------------------------------------------------
! ... add final coefficients:

      Do i=1,nzoef
       C = Zoef(i); if(abs(C).lt.EPS_c) Cycle
       int = IZ_int(i); idf = IZ_df(i);  m = int/jb8; jcase=m

       Select case (m)
        Case(3,4); if(joper(7).eq.0) Cycle; Ctrm(1:ntrm)=C*CT_oper(:,7)
        Case(5);   if(joper(3).eq.0) Cycle; Ctrm(1:ntrm)=C*CT_oper(:,3)
        Case(6);   if(joper(2).eq.0) Cycle; Ctrm(1:ntrm)=C*CT_oper(:,2)
        Case(7);   if(joper(4).eq.0) Cycle; Ctrm(1:ntrm)=C*CT_oper(:,4)
        Case(8,9); if(joper(5).eq.0) Cycle; Ctrm(1:ntrm)=C*CT_oper(:,5)
        Case(10);  if(joper(6).eq.0) Cycle; Ctrm(1:ntrm)=C*CT_oper(:,6)
        Case(11);  if(joper(1).eq.0) Cycle; Ctrm(1:ntrm)=C*CT_oper(:,1)
        Case Default;  Stop ' Term_loop: unknown integral '
       End select
       Call Add_coef 
      End do
      nzoef = 0

      End  Subroutine TERM_loop

