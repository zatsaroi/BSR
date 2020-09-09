!======================================================================
!     PROGRAM   test_mult_2conf                      
!
!               C O P Y R I G H T -- 2013
!
!     Written by:   Oleg Zatsarinny
!                   email: oleg_zoi@yahoo.com
!======================================================================
!    it is a debug program to check subroutine     "mult_2conf" 
!    to generate angular coefficient for multipole one-electron operator
!    in case of orthogonal one-electron radial functions
!----------------------------------------------------------------------
!
!    INPUT ARGUMENTS:  name  or   cfg=...  tab=...  
!    
!----------------------------------------------------------------------
!
!    INPUT FILE:     AF_cfg    (default  - cfg.inp) 
!    OUTPUT FILES:   AF_tab    (default  - coef.tab)
!    
!----------------------------------------------------------------------     
      Implicit real(8) (A-H,O-Z) 

      Integer :: nu1=1; Character(80) :: AF_cfg1 
      Integer :: nu2=2; Character(80) :: AF_cfg2 
      Integer :: out=3; Character(80) :: AF_tab  

      Integer :: kpol = 1      !  multipole index 
      Character(2) :: atype='E1'
      Character(1) :: ktype 

      Integer, parameter :: msh = 8
      Integer :: no1, nn1(msh),ln1(msh),iq1(msh),kn1(msh), LS1(5,msh)
      Integer :: no2, nn2(msh),ln2(msh),iq2(msh),kn2(msh), LS2(5,msh)

      Character(8*msh), allocatable :: CONFIG(:), COUPLE(:) 
      Character(8*msh) :: AS
      Character(3) :: EL1, EL2, EL3, EL4
      Real(8) :: C, eps_C = 1.d-7
      Integer :: i,j, k, k1,k2,k3,k4, ic,jc, i1,i2,j1,j2, ncfg
      Integer, external :: Idef_ncfg 

      Integer, parameter :: mk = 100
      Integer :: nk,ik(mk),jk(mk)
      Real(8) :: ca(mk),cb(mk) 

!----------------------------------------------------------------------
! ... input data:     

      i = command_argument_count()
      if(i.lt.3) then
       write(*,*)
       write(*,*) 'Should be at least 3 command arguments:  name1.c nam12.c  E1|E2|.. [tab=..]'
       write(*,*)
       Stop ' '
      end if

      Call GET_COMMAND_ARGUMENT(1,AF_cfg1)
      Call GET_COMMAND_ARGUMENT(2,AF_cfg2)
      Call GET_COMMAND_ARGUMENT(3,atype)
      read(atype,'(a1,i1)') ktype, kpol

      Call Check_file(AF_cfg1)
      Open(nu1,file=AF_cfg1)
      ncfg1 = Idef_ncfg(nu1)
      Call Check_file(AF_cfg2)
      Open(nu2,file=AF_cfg2)
      ncfg2 = Idef_ncfg(nu2)

      Allocate(CONFIG(ncfg1+ncfg2),COUPLE(ncfg1+ncfg2))

      i1 = Len_trim(AF_cfg1)-2
      i2 = Len_trim(AF_cfg2)-2
      write(AF_tab,'(a,a,a,a)') 'tab_',AF_cfg1(1:i1),'_',AF_cfg2(1:i2)
      Call Read_aarg('tab',AF_tab)
      Open(out,file=AF_tab)

      rewind(nu1)
      Do ic = 1,ncfg1
      Do 
       read(nu1,'(a)') AS
       if(AS(5:5).ne.'(') Cycle
       CONFIG(ic) = AS
       read(nu1,'(a)') COUPLE(ic)
       Exit
      End do
      End do

      rewind(nu2)
      Do ic = ncfg1+1,ncfg1+ncfg2
      Do 
       read(nu2,'(a)') AS
       if(AS(5:5).ne.'(') Cycle
       CONFIG(ic) = AS
       read(nu2,'(a)') COUPLE(ic)
       Exit
      End do
      End do


      Do ic = 1,ncfg1
       Call Decode_cn (CONFIG(ic),COUPLE(ic),no1,nn1,ln1,iq1,kn1,LS1)

      Do jc = ncfg1+1,ncfg1+ncfg2
       Call Decode_cn (CONFIG(jc),COUPLE(jc),no2,nn2,ln2,iq2,kn2,LS2)

       Call mult_2conf(no1,nn1,ln1,iq1,LS1,no2,nn2,ln2,iq2,LS2, &
                       atype,nk,ca,cb,ik,jk)
       if(nk.eq.0) Cycle

       write(out,'(80("-"))')
       write(out,'(a,T70,i5)') trim(CONFIG(ic)),ic 
       write(out,'(a)') trim(COUPLE(ic))
       write(out,'(a,T70,i5)') trim(CONFIG(jc)),jc-ncfg1 
       write(out,'(a)') trim(COUPLE(jc))
       write(out,'(80("-"))')

       Do k = 1,nk
        AS = CONFIG(ic);  i = 2 + (ik(k)-1)*8; EL1=AS(i:i+2)
        AS = CONFIG(jc);  j = 2 + (jk(k)-1)*8; EL2=AS(j:j+2)
        if(ca(k).ne.0.d0) &
        write(out,'(a,i1,1x,a,a,a,a,a,f10.5)') &
                   'd',kpol,'(',EL1,',',EL2,')=',ca(k)        
        if(cb(k).ne.0.d0) &
        write(out,'(a,i1,1x,a,a,a,a,a,f10.5)') &
                   'm',kpol,'(',EL1,',',EL2,')=',cb(k)        
       End do
       write(out,*)

      End do; End do   ! over ic

      END ! Program ...


!======================================================================
      Subroutine Decode_cn(CONFIG,COUPLE,no,nn,ln,iq,kn,LS)
!======================================================================
!     decode the config. from c-file format to ZOI format
!----------------------------------------------------------------------
      Implicit none
      Character(*), intent(in) :: CONFIG,COUPLE
      Integer :: no,nn(*),ln(*),iq(*),kn(*),LS(5,*)
      Integer :: ii, k,i,j 
      Integer, external :: LA

      no=0; ii=LEN_TRIM(CONFIG); ii=ii/8;  k=1; j=2
      Do i=1,ii
       if(CONFIG(k+4:k+4).ne.'(') Exit
       no=no+1
       Call EL4_nlk(CONFIG(k:k+3),nn(i),ln(i),kn(i))
       read(CONFIG(k+5:k+6),'(i2)') iq(i)
       k=k+8
       read(COUPLE(j:j),'(i1)') LS(3,i)
       LS(2,i)=2*LA(COUPLE(j+1:j+1))+1
       read(COUPLE(j+2:j+2),'(i1)') LS(1,i)
       j=j+4
      End do

      LS(4,1)=LS(2,1)
      LS(5,1)=LS(3,1)
      Do i=2,no
       read(COUPLE(j:j),'(i1)') LS(5,i)
       LS(4,i)=2*LA(COUPLE(j+1:j+1))+1
       j=j+4
      End do

      End Subroutine Decode_cn

!======================================================================
      Integer Function Idef_ncfg(nu)
!======================================================================
!     gives the number of configuration in c-file (unit nu)
!----------------------------------------------------------------------
      Implicit none
      Integer, intent(in) :: nu
      Integer :: ncfg
      Character(5) :: AS

      rewind(nu)
      ncfg=0
    1 read(nu,'(a)',end=2) AS
      if(AS(1:1).eq.'*') go to 2
      if(AS(5:5).ne.'(') go to 1
      read(nu,'(a)') AS
      ncfg=ncfg+1
      go to 1
    2 rewind(nu)
      Idef_ncfg=ncfg

      End Function Idef_ncfg


!======================================================================
      Subroutine Read_aarg(name,avalue)
!======================================================================
!     read characer argument
!----------------------------------------------------------------------
      Implicit None

      Character(*) :: name, avalue
      Integer :: iarg,i,i1,i2,iname
      Character(80) :: AS

      iarg = Command_argument_count(); if(iarg.eq.0) Return 
      iname=LEN_TRIM(name)
      Do i=1,iarg
       Call get_command_argument(i,AS)
       i1=INDEX(AS,'=')+1; i2=LEN_TRIM(AS)
       if(AS(1:i1-2).ne.name(1:iname)) Cycle
       read(AS(i1:i2),'(a)') avalue; Exit
      End do

      End Subroutine Read_aarg


!======================================================================
      Subroutine Read_iarg(name,ivalue)
!======================================================================
!     read integer argument as name=... from the command line 
!----------------------------------------------------------------------
      Implicit none
      Character(*) :: name
      Integer :: ivalue
      Integer :: iarg,i,i1,i2,iname
      Character(80) :: AS
      Integer, external :: IARGC

      iarg = Command_argument_count(); if(iarg.eq.0) Return 
      iname=LEN_TRIM(name)
      Do i=1,iarg
       Call GETARG(i,AS)
       i1=INDEX(AS,'=')+1; i2=LEN_TRIM(AS)
       if(AS(1:i1-2).ne.name(1:iname)) Cycle
       read(AS(i1:i2),*) ivalue; Exit
      End do

      End Subroutine Read_iarg


!======================================================================
      Subroutine Check_file(AF)
!======================================================================

      Character(*), Intent(in) :: AF
      Logical :: EX

      Inquire(file=AF,exist=EX)
      if(.not.EX) then
       write(*,*) ' can not find file  ',AF;  Stop
      end if

      End Subroutine Check_file


!====================================================================
      Integer FUNCTION LA(a)
!====================================================================
!     gives the value of L from spetroscopic symbol "a"
!--------------------------------------------------------------------
      Implicit none  
      Character, Intent(in) :: a
      Character(21) :: AS, AB
      Integer :: i

      DATA AS/'spdfghiklmnoqrtuvwxyz'/
      DATA AB/'SPDFGHIKLMNOQRTUVWXYZ'/

      i = INDEX (AS,a)
      if(i.eq.0) i = INDEX (AB,a)
      if(i.eq.0) i = ICHAR(a)-101
      LA = i-1

      End FUNCTION LA

!====================================================================
      Subroutine EL4_NLK(EL,n,l,k)
!====================================================================
!     decodes the A4 specroscopic notation for orbital (n,l,k)
!
!     It is allowed following notations: 1s, 2s3, 2p30, 20p3,
!     1sh, 20sh, kp, kp1, kp11, ns, ns3, ns33, ... .
!
!     Call:  LA, ICHAR
!--------------------------------------------------------------------
      Implicit none
      Character(4), intent(in) :: EL
      Integer, intent(out) :: n,l,k    
      Integer :: i,j,ic, k1,k2  
      Integer, external :: LA

      Character(61) :: ASET = &
       '123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

      n=0; l=-1; k=0; i=1; j=1
    1 if(EL(i:i).eq.' ') then
       i=i+1
       if(i.le.4) go to 1
      end if
      if(i.eq.4.and.j.eq.1) j=2
      if(i.gt.4) Return

      ic=ICHAR(EL(i:i))-ICHAR('1')+1

      if(j.eq.1) then                      !  n -> ?
       if(n.eq.0.and.ic.le.9) then
        n=ic; j=1
       elseif(n.eq.0.and.ic.gt.9) then
        n=ic; j=2
       elseif(ic.gt.9) then
        l=LA(EL(i:i)); j=3
       else
        n=n*10+ic
       end if

      elseif(j.eq.2) then                   !  l -> ?
       l=LA(EL(i:i)); j=3

      elseif(j.eq.3) then                   !  k -> ?
       if(i.eq.3) then
        k1 = INDEX(ASET,EL(i:i)); k2 = INDEX(ASET,EL(i+1:i+1))
        if(k2.gt.0) k = k1*61+k2
        if(k2.eq.0) k = k1
       else
        k = INDEX(ASET,EL(i:i))
       end if
       j=4
      end if

      i=i+1
      if(i.le.4.and.j.le.3) go to 1
      if(n.ge.100.or.l.lt.0) then
       write(*,*) 'EL4_nlk is fail to decode: ',EL 
       Stop ' '
      end if

      End Subroutine EL4_NLK