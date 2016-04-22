!======================================================================
      Subroutine DET_breit
!======================================================================
!
!     creates the common list of orbital symmetries for two input
!     determinants and call the subroutines for calculations of
!     coefficients between possible combinations of symmetries
!
!----------------------------------------------------------------------

      USE inter;  USE spin_orbitals;   USE configs, ONLY: ne

      Implicit none
      Integer(4) :: i,i1,i2, j,j1,j2, k,k1,k2
      Integer(4), External :: Isort

!----------------------------------------------------------------------
!                              creat common list of orbital symmetries:
      ksym1=1; ksym2=1

      NSYM = 0; k1 = 0;  k2 = 0; kz1=0; kz2=0

! ... exzaust the 1-st configuration:

      Do i = 1,ne 
       if(ksym1(i).eq.0) Cycle
       Nsym = Nsym + 1
       Lsym(Nsym)=Lsym1(i); Msym(Nsym)=Msym1(i); Ssym(Nsym)=Ssym1(i)
       k1=k1+1; IPsym1(Nsym)=k1; Isym1(k1)=i; ksym1(i)=0
!       kz1 = kz1 + (i-k1)  ! cd

! ... check for the same orbitals rest the 1-st configuration:      
 
       Do j = i+1,ne
        if(ksym1(j).eq.0) Cycle
        if(Lsym(Nsym).ne.Lsym1(j)) Cycle
        if(Msym(Nsym).ne.Msym1(j)) Cycle
        if(Ssym(Nsym).ne.Ssym1(j)) Cycle
        k1=k1+1; IPsym1(Nsym)=k1; Isym1(k1)=j; ksym1(j)=0
!        kz1 = kz1 + (j-k1)  ! cd
       End do        

       Jdet=Isym1(1:ne);  kz1 = Isort(ne,Jdet)

! ... check for the same orbitals the 2-nd configuration:      

       IPsym2(Nsym)=k2
       Do j = 1,ne
        if(ksym2(j).eq.0) Cycle
        if(Lsym(Nsym).ne.Lsym2(j)) Cycle
        if(Msym(Nsym).ne.Msym2(j)) Cycle
        if(Ssym(Nsym).ne.Ssym2(j)) Cycle
        k2=k2+1; IPsym2(Nsym)=k2; Isym2(k2)=j; ksym2(j)=0
!        kz2 = kz2 + (j-k2)  ! cd
       End do        
      End do
      if(k1.ne.ne) Stop 'Det_breit: k1 <> ne '

! ... exzaust the 2-st configuration:

      Do i = 1,ne 
       if(ksym2(i).eq.0) Cycle
       Nsym = Nsym + 1
       Lsym(Nsym)=Lsym2(i); Msym(Nsym)=Msym2(i); Ssym(Nsym)=Ssym2(i)
       k2=k2+1; IPsym2(Nsym)=k2; Isym2(k2)=i; ksym2(i)=0
       IPsym1(Nsym)=k1
!       kz2 = kz2 + (i-k2)

! ... check for the same orbitals rest of 2-st configuration:      
       
       Do j = i+1,ne
        if(ksym2(j).eq.0) Cycle
        if(Lsym(Nsym).ne.Lsym2(j)) Cycle
        if(Msym(Nsym).ne.Msym2(j)) Cycle
        if(Ssym(Nsym).ne.Ssym2(j)) Cycle
        k2=k2+1; IPsym2(Nsym)=k2; Isym2(k2)=j; ksym2(j)=0
        kz2 = kz2 + (j-k2)
       End do        
      End do
      if(k2.ne.ne) Stop 'Det_breit: k2 <> ne '

       Jdet=Isym2(1:ne);  kz2 = Isort(ne,Jdet)

!----------------------------------------------------------------------
!                              define the number of different orbitals:
      Ksym1(1)=ipsym1(1)
      Ksym2(1)=ipsym2(1)
      Do i = 2,NSYM
       Ksym1(i)=ipsym1(i)-ipsym1(i-1)
       Ksym2(i)=ipsym2(i)-ipsym2(i-1)
      End do

! ... how much different symmetries:

      k = 0
      Do i = 1,NSYM
       N1(i) = KSYM1(i)-KSYM2(i)
       N2(i) = KSYM2(i)-KSYM1(i)
       if(N1(i).gt.0) k = k + N1(i)
      End do

      if(k.gt.2) Return


!---------------------------------------------------------------------
!                                                         k = 2  case:
      Select case(k)

      Case(2)

       if(joper(3)+joper(5)+joper(6)+joper(7).eq.0) Return

       Do i=1,NSYM
        if(N1(i).le.0) Cycle; i1=i; N1(i)=N1(i)-1; Exit
       End do
       Do i=i1,NSYM
        if(N1(i).le.0) Cycle; i2=i; Exit
       End do
       Do i=1,NSYM
        if(N2(i).le.0) Cycle; j1=i; N2(i)=N2(i)-1; Exit
       End do
       Do i=j1,NSYM
        if(N2(i).le.0) Cycle; j2=i; Exit
       End do

       Call Zno_2ee(i1,i2,j1,j2)
  
!---------------------------------------------------------------------
!                                                         k = 1  case:
      Case(1)

       if(joper(3)+joper(5)+joper(6)+joper(7).eq.0) Return

       Do i=1,NSYM
        if(N1(i).le.0) Cycle; i1 = i; Exit
       End do
       Do i=1,NSYM
        if(N2(i).le.0) Cycle; j1 = i; Exit
       End do

       Do i = 1,Nsym
        if(Ksym1(i).eq.0) Cycle
        if(i.eq.i1.and.Ksym1(i).le.1) Cycle
        if(i.eq.j1.and.Ksym2(i).le.1) Cycle

        if(i.le.i1.and.i.le.j1)  then
          Call Zno_2ee(i,i1,i,j1)
        elseif(i.gt.i1.and.i.le.j1) then
          Call Zno_2ee(i1,i,i,j1)
        elseif(i.gt.i1.and.i.gt.j1) then
          Call Zno_2ee(i1,i,j1,i)
        elseif(i.le.i1.and.i.gt.j1) then
          Call Zno_2ee(i,i1,j1,i)
        end if

       End do

!---------------------------------------------------------------------
!                                                         k = 0  case:
      Case(0)

       if(joper(1).gt.0)           Call ZNO_0ee
       if(joper(2)+joper(4).gt.0)  Call ZNO_1ee

       if(joper(3)+joper(5)+joper(6)+joper(7).eq.0) Return

       Do i = 1,Nsym
        Do j = i,Nsym
         if(i.eq.j.and.Ksym1(i).le.1) Cycle
         Call Zno_2ee(i,j,i,j)
        End do
       End do

      End Select

      End Subroutine DET_breit
