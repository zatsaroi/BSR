!----------------------------------------------------------------------
!
!     Modules for processing the overlap determinant:
!
!     DET_list,  alloc_det, Iadd_det
!     DEF_list,  alloc_def, Iadd_def
!
!     NDET_list,  alloc_ndet, Iadd_ndet
!     NDEF_list,  alloc_ndef, Iadd_ndef
!
!     NDET_IDET
!
!     DET_list and DEF_list contain the overlap determinants 
!     and overlap factors for all configuration symmetries, 
!     whereas NDET_list and NDEF_list contain this information
!     for two configuration under consideration. 
!     These additional NDET, NDEF lists were introduced in hope 
!     to reduce the seeking time in large common lists DET,DEF. 
!
!     All four modules DET_list, DEF_list, NDET_list, NDEF_list 
!     have the identical structure and  differ only by names 
!     for variables. 
!
!     The connection between DET,DEF and NDET,NDEF lists is given
!     by subroutine NDET_IDET.
!
!----------------------------------------------------------------------



!======================================================================
      MODULE DET_list
!======================================================================
!
!     Containes the overlap determinants for all config. symmetries.
!
!----------------------------------------------------------------------

      Use param_br, ONLY: isd,jsd

      Implicit none
      Save

      Integer(4) :: ndet = 0       ! number of determinants
      Integer(4) :: mdet = 0       ! current dimension of the list
      Integer(4) :: idet = isd     ! initial dimension
      Integer(4) :: jdet = jsd     ! average size of one det. 
      Integer(4) :: kdet = 0       ! dimension of all det.s 
      
      Integer(4), Allocatable, Dimension(:) :: KPD,IPD,NPD   

      ! KPD(i) - dimension of i-th determinant 
      ! IPD(i) - its pointer in common list NPD

      End MODULE DET_list


!======================================================================
      Subroutine alloc_det(m)
!======================================================================

      Use inout_br, ONLY: nus, pri, mrecl
      Use DET_list

      Implicit none
      Integer(4), Intent(in) :: m
      Integer(4) :: k

      if(m.le.0) then
       if(allocated(KPD)) Deallocate (KPD,IPD,NPD)
       mdet = 0; ndet = 0; kdet =0
      elseif(.not.allocated(KPD)) then
       mdet = m; kdet = mdet*jdet
       Allocate(KPD(mdet),IPD(mdet),NPD(kdet))
      elseif(m.le.mdet) then
       Return
      elseif(ndet.eq.0) then
       Deallocate (KPD,IPD,NPD)
       mdet = m; kdet = mdet*jdet
       Allocate(KPD(mdet),IPD(mdet),NPD(kdet))
      else
       Open(nus,status='SCRATCH',form='UNFORMATTED'); rewind(nus)
       Call W_i4(nus,mrecl,ndet,KPD) 
       Call W_i4(nus,mrecl,ndet,IPD) 
       Call W_i4(nus,mrecl,kdet,NPD) 
       Deallocate (KPD,IPD,NPD)
       k=kdet; mdet = m; kdet = mdet*jdet
       Allocate(KPD(1:mdet),IPD(1:mdet),NPD(1:kdet))
       rewind(nus)
       Call R_i4(nus,mrecl,ndet,KPD) 
       Call R_i4(nus,mrecl,ndet,IPD) 
       Call R_i4(nus,mrecl,k   ,NPD) 
       Close(nus)
       write(*,*) ' Realloc_det: new dimension = ', mdet,jdet
       write(pri,*) ' Realloc_det: new dimension = ', mdet,jdet
      end if

      End Subroutine alloc_DET


!----------------------------------------------------------------------
      Integer(4) Function Iadd_det (kd,NP)
!----------------------------------------------------------------------
!
!     add new overlap determinant to DET_list
!
!----------------------------------------------------------------------

      Use det_list

      Implicit none 
      Integer(4) , Intent(in) :: kd
      Integer(4) , Intent(in), Dimension(kd) :: NP
      Integer(4) :: i,j,ip

      Iadd_det = 0
      if(kd.le.0) Return
      if(mdet.eq.0) Call Alloc_DET(idet)

! ... check if the same det. is already in the list:

      Do i=1,ndet
       if(KPD(i).ne.kd) Cycle
       ip=IPD(i); Iadd_det = i
       Do j=1,kd
        if(NP(j).eq.NPD(ip+j)) Cycle; Iadd_det = 0; Exit
       End do
       if(Iadd_det.ne.0) Return
      End do

! ... Add new det.:

      ndet=ndet+1; ip=0; if(ndet.gt.1) ip=IPD(ndet-1)+KPD(ndet-1)
      if(ndet.eq.mdet.or.ip+kd.gt.kdet) then
       jdet = kdet/ndet + 1; Call Alloc_det(mdet+idet)
      end if
      KPD(ndet)=kd; IPD(ndet)=ip; NPD(ip+1:ip+kd)=NP(1:kd)
      Iadd_det=ndet

      End Function Iadd_det



!======================================================================
      MODULE DEF_list
!======================================================================
!
!     Containes the overlap factors, as the list of the number of
!     involved overlap determinants and their positions in the 
!     common det_list.
!
!     KPF(i) - number of det.s in i-th overlap factor
!     IPF(i) - pointer on the list of corr. det.s in the NPF
!     NPF(ip+1:ip+kd) - list of pointers on det.s in the DET_list
!                       and their powers
!----------------------------------------------------------------------

      Use param_br, ONLY: isf,jsf

      Implicit none
      Save

      Integer(4) :: ndef = 0       ! number of determinants
      Integer(4) :: mdef = 0       ! current dimentsion of list
      Integer(4) :: idef = isf     ! supposed max. dimentsion  
      Integer(4) :: jdef = jsf     ! average number of det.s 
      Integer(4) :: kdef = 0       ! dimension of all def.s 
      
      Integer(4), Allocatable, Dimension(:) :: KPF,IPF,NPF   

      End MODULE DEF_list


!======================================================================
      Subroutine alloc_def(m)
!======================================================================

      USE def_list
      Use inout_br, ONLY: nus, pri, mrecl

      Implicit none
      Integer(4), Intent(in) :: m
      Integer(4) :: k

      if(m.le.0) then
       if(allocated(KPF)) Deallocate(KPF,IPF,NPF)
       mdef = 0; ndef = 0; kdef = 0
      elseif(.not.allocated(KPF)) then
       mdef = m; kdef = mdef*jdef
       Allocate(KPF(mdef),IPF(mdef),NPF(kdef))
      elseif(m.le.mdef) then
       Return
      elseif(ndef.eq.0) then
       Deallocate (KPF,IPF,NPF)
       mdef = m; kdef = mdef*jdef
       Allocate(KPF(mdef),IPF(mdef),NPF(kdef))
      else
       Open(nus,status='SCRATCH',form='UNFORMATTED'); rewind(nus)
       Call W_i4(nus,mrecl,ndef,KPF) 
       Call W_i4(nus,mrecl,ndef,IPF) 
       Call W_i4(nus,mrecl,kdef,NPF) 
       Deallocate (KPF,IPF,NPF)
       k=kdef; mdef = m; kdef = mdef*jdef
       Allocate(KPF(mdef),IPF(mdef),NPF(kdef))
       rewind(nus)
       Call R_i4(nus,mrecl,ndef,KPF) 
       Call R_i4(nus,mrecl,ndef,IPF) 
       Call R_i4(nus,mrecl,k   ,NPF) 
       Close(nus)
       write(*,*) ' Realloc_def: new dimension = ', mdef,jdef,ndef
       write(pri,*) ' Realloc_def: new dimension = ', mdef,jdef,ndef
      end if

      End Subroutine alloc_def



!----------------------------------------------------------------------
      Integer(4) Function Iadd_def (kd,NP)
!----------------------------------------------------------------------
!
!     add new overlap factor to DEF_list
!
!     kd    - number of det.s
!     NP(i) - pointer for the i-th det.
!
!----------------------------------------------------------------------

      USE def_list

      Implicit none
      Integer(4) , Intent(in) :: kd
      Integer(4) , Dimension(kd) :: NP
      Integer(4) :: i,j,ip

      if(kd.le.0) Return
      if(mdef.eq.0) Call Alloc_def(idef) 

! ... check: is the same def. in the list:

      Do i=1,ndef
       if(KPF(i).ne.kd) Cycle
       ip=IPF(i); Iadd_def = i
       Do j=1,kd
        if(NP(j).eq.NPF(ip+j)) Cycle; Iadd_def = 0; Exit
       End do
       if(Iadd_def.ne.0) Return
      End do

! ... Add new def.:

      ndef=ndef+1; ip=0; if(ndef.gt.1) ip=IPF(ndef-1)+KPF(ndef-1)
      if(ndef.eq.mdef.or.ip+kd.gt.kdef) then
       jdef = (ip+kd)/ndef + 1; Call Alloc_def(mdef+idef)
      end if
      KPF(ndef)=kd; IPF(ndef)=ip; NPF(ip+1:ip+kd)=NP(1:kd)
      Iadd_def=ndef

      End Function Iadd_def


!======================================================================
      MODULE NDET_list
!======================================================================
!
!     Containes the overlap determinants for two config. symmetries
!     under consideration
!
!----------------------------------------------------------------------

      Use param_br, ONLY: isd,jsd

      Implicit none
      Save

      Integer(4) :: ndet = 0       ! number of determinants
      Integer(4) :: mdet = 0       ! current dimentsion of list
      Integer(4) :: idet = isd     ! supposed max. dimentsion
      Integer(4) :: jdet = jsd     ! average size of one det. 
      Integer(4) :: kdet = 0       ! dimension of all det.s 
      
      Integer(4), Allocatable, Dimension(:) :: KPD,IPD,NPD   

      End MODULE NDET_list


!======================================================================
      Subroutine alloc_ndet(m)
!======================================================================

      Use inout_br, ONLY: nus, pri, mrecl
      Use NDET_list

      Implicit none
      Integer(4), Intent(in) :: m
      Integer(4) :: k

      if(m.le.0) then
       if(allocated(KPD)) Deallocate (KPD,IPD,NPD)
       mdet = 0; ndet = 0; kdet =0
      elseif(.not.allocated(KPD)) then
       mdet = m; kdet = mdet*jdet
       Allocate(KPD(mdet),IPD(mdet),NPD(kdet))
      elseif(m.le.mdet) then
       Return
      elseif(ndet.eq.0) then
       Deallocate (KPD,IPD,NPD)
       mdet = m; kdet = mdet*jdet
       Allocate(KPD(mdet),IPD(mdet),NPD(kdet))
      else
       Open(nus,status='SCRATCH',form='UNFORMATTED'); rewind(nus)
       Call W_i4(nus,mrecl,ndet,KPD) 
       Call W_i4(nus,mrecl,ndet,IPD) 
       Call W_i4(nus,mrecl,kdet,NPD) 
       Deallocate (KPD,IPD,NPD)
       k=kdet; mdet = m; kdet = mdet*jdet
       Allocate(KPD(1:mdet),IPD(1:mdet),NPD(1:kdet))
       rewind(nus)
       Call R_i4(nus,mrecl,ndet,KPD) 
       Call R_i4(nus,mrecl,ndet,IPD) 
       Call R_i4(nus,mrecl,k   ,NPD) 
       Close(nus)
       write(*,*) ' realloc_ndet: new dimension = ', mdet,kdet
       write(pri,*) ' realloc_ndet: new dimension = ', mdet,kdet
      end if

      End Subroutine alloc_NDET


!----------------------------------------------------------------------
      Integer(4) Function Nadd_det (kd,NP)
!----------------------------------------------------------------------
!
!     add the overlap determinant to NDET_list
!
!----------------------------------------------------------------------

      Use ndet_list

      Implicit none 
      Integer(4) , Intent(in) :: kd
      Integer(4) , Intent(in), Dimension(kd) :: NP
      Integer(4) :: i,j,ip

      Nadd_det = 0
      if(kd.le.0) Return
      if(mdet.eq.0) Call Alloc_NDET(idet)

! ... check: is the same det. in the list:

      Do i=1,ndet
       if(KPD(i).ne.kd) Cycle
       ip=IPD(i); Nadd_det = i
       Do j=1,kd
        if(NP(j).eq.NPD(ip+j)) Cycle; Nadd_det = 0; Exit
       End do
       if(Nadd_det.ne.0) Return
      End do

! ... Add new det.:

      ndet=ndet+1; ip=0; if(ndet.gt.1) ip=IPD(ndet-1)+KPD(ndet-1)
      if(ndet.eq.mdet.or.ip+kd.gt.kdet) then
       jdet = (ip+kd)/ndet + 1; Call Alloc_ndet(mdet+idet)
      end if
      KPD(ndet)=kd; IPD(ndet)=ip; NPD(ip+1:ip+kd)=NP(1:kd)
      Nadd_det=ndet

      End Function Nadd_det



!======================================================================
      MODULE NDEF_list
!======================================================================
!
!     Containes the overlap factors, as the list of the number of
!     involved overlap determinants and their positions in the 
!     common det_list.
!
!     KPF(i) - number of det.s in the overlap factor 'i'  (kd)
!     IPF(i) - pointer on the list of corr. det.s in the NPF  (ip)
!     NPF(ip+1:ip+kd) - list of pointers on det.s in the det_list
!                       and their powers
!----------------------------------------------------------------------

      Use param_br, ONLY: isf,jsf

      Implicit none
      Save

      Integer(4) :: ndef = 0       ! number of determinants
      Integer(4) :: mdef = 0       ! current dimentsion of list
      Integer(4) :: idef = isf     ! supposed max. dimentsion  
      Integer(4) :: jdef = jsf     ! average number of det.s 
      Integer(4) :: kdef = 0       ! dimension of all def.s 
      
      Integer(4), Allocatable, Dimension(:) :: KPF,IPF,NPF   

      End MODULE NDEF_list


!======================================================================
      Subroutine alloc_ndef(m)
!======================================================================

      USE ndef_list
      Use inout_br, ONLY: nus, pri, mrecl

      Implicit none
      Integer(4), Intent(in) :: m
      Integer(4) :: k

      if(m.le.0) then
       if(allocated(KPF)) Deallocate(KPF,IPF,NPF)
       mdef = 0; ndef = 0; kdef = 0
      elseif(.not.allocated(KPF)) then
       mdef = m; kdef = mdef*jdef
       Allocate(KPF(mdef),IPF(mdef),NPF(kdef))
      elseif(m.le.mdef) then
       Return
      elseif(ndef.eq.0) then
       Deallocate (KPF,IPF,NPF)
       mdef = m; kdef = mdef*jdef
       Allocate(KPF(mdef),IPF(mdef),NPF(kdef))
      else
       Open(nus,status='SCRATCH',form='UNFORMATTED'); rewind(nus)
       Call W_i4(nus,mrecl,ndef,KPF) 
       Call W_i4(nus,mrecl,ndef,IPF) 
       Call W_i4(nus,mrecl,kdef,NPF) 
       Deallocate (KPF,IPF,NPF)
       k=kdef; mdef = m; kdef = mdef*jdef
       Allocate(KPF(mdef),IPF(mdef),NPF(kdef))
       rewind(nus)
       Call R_i4(nus,mrecl,ndef,KPF) 
       Call R_i4(nus,mrecl,ndef,IPF) 
       Call R_i4(nus,mrecl,k   ,NPF) 
       Close(nus)
       write(*,*) ' Realloc_ndef: new dimension = ', mdef,jdef
       write(pri,*) ' Realloc_ndef: new dimension = ', mdef,jdef
      end if

      End Subroutine alloc_ndef



!----------------------------------------------------------------------
      Integer(4) Function Nadd_def (kd,NP)
!----------------------------------------------------------------------
!
!     add the overlap factor to def_list
!
!     kd    - number of det.s
!     NP(i) - pointer for the i-th det.
!
!----------------------------------------------------------------------

      USE ndef_list

      Implicit none
      Integer(4) , Intent(in) :: kd
      Integer(4) , Dimension(kd) :: NP
      Integer(4) :: i,j,ip

      if(kd.le.0) Return
      if(mdef.eq.0) Call Alloc_ndef(idef) 

! ... check: is the same def. in the list:

      Do i=1,ndef
       if(KPF(i).ne.kd) Cycle
       ip=IPF(i); Nadd_def = i
       Do j=1,kd
        if(NP(j).eq.NPF(ip+j)) Cycle; Nadd_def = 0; Exit
       End do
       if(Nadd_def.ne.0) Return
      End do

! ... Add new def.:

      ndef=ndef+1; ip=0; if(ndef.gt.1) ip=IPF(ndef-1)+KPF(ndef-1)
      if(ndef.eq.mdef.or.ip+kd.gt.kdef) then
       jdef = kdef/ndef + 1; Call Alloc_ndef(mdef+idef)
      end if
      KPF(ndef)=kd; IPF(ndef)=ip; NPF(ip+1:ip+kd)=NP(1:kd)
      Nadd_def=ndef

      End Function Nadd_def



!======================================================================
     Subroutine Ndet_Idet
!======================================================================
!
!    Convert NDET and NDEF lists to the common DET and DEF lists. 
!    Connection is given in IPF array.
!    The NDET and NDEF lists are then nulefied.
!
!----------------------------------------------------------------------

      Use NDET_list
      Use NDEF_list 

      Use param_br, ONLY: ibf
      USE spin_orbitals, ONLY: NP

      IMPLICIT NONE
      Integer(4) :: i,j,ip,jp,id,kd,ns
      Integer(4), External :: Iadd_det, Iadd_def, ISORT

      if(ndet.le.0) Stop ' NDET_IDET: ndet <= 0'
      Do id=1,ndet
       kd=KPD(id); ip=IPD(id); NP(1:kd)=NPD(ip+1:ip+kd)
       IPD(id) = Iadd_det(kd,NP)
      End do
      ndet = 0

      if(ndef.le.0) Stop ' NDET_IDET: ndef <= 0'
      Do id=1,ndef
       kd=KPF(id); ip=IPF(id)
       Do i=1,kd
        j=NPF(ip+i)/ibf; jp=IPD(j); ns=mod(NPF(ip+i),ibf)
        NP(i) = jp*ibf + ns 
       End do
       i = ISORT (kd,NP)                             
       IPF(id) = Iadd_def (kd,NP)
      End do
      ndef = 0

      End Subroutine Ndet_Idet


