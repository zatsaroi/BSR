!======================================================================
!     PROGRAM       B S R _ P H O T                     version 3
!
!               C O P Y R I G H T -- 2013
!
!     Written by:   Oleg Zatsarinny
!                   email: oleg_zoi@yahoo.com
!
!======================================================================
!
!     Calculation of photoionization cross sections in the R-matrix
!     approach
!
!     INPUT FILES:
!
!     bsr_phot.inp  - input parameters 
!
!     h.nnn - the name of 'H.DAT' file, containing the description of
!             target states, scatering channels for given total LS,  
!             internal-region eigenvalues and surfice amplitudes.
!             This file has the same structure as H.DAT file in the
!             BELFAST R-matrix code. In the BSR package these files 
!             are generated by BSR_HD program with names 'h.nnn',
!             where nnn - number of partial wave.
!
!     d.nnn - the name for dipole-matrix file, containing the dipole
!             matrix elements between initial state and R-matrix 
!             eigenfunctions. In the BSR package these files 
!             are generated by BSR_HD program with names 'd.nnn',
!             where nnn - number of partial wave.
!
!     w.nnn - the name for file with expansion coefficients for 
!             internal region solutions. These data are used to
!             obtain the contibution of different closed channel
!             for given resonanes. In the BSR package these files 
!             are generated by BSR_HD program with names 'w.nnn',
!             where nnn - number of partial wave.
!
!
!     OUTPUT FILES:
!
!     bsr_phot.log  - running information   
!
!     photo.nnn - file with total cross sections and sum of eigenphases
!    
!     bsr_phot.nnn - file with detailed scattering information for
!                    given partial photionization
!           
!     Output files accumulate the results from different runs
!     
!=====================================================================
!
!     ELECTRON ENERGIES 
!
!     Elow,Estep,Ehigh - difine the range of electron energies (in Ry)
!                        relative to the first target state
!                        Can be up to 10 energy ranges in oune input
!
!     OTHER PARAMETERS
!
!     AWT  - atomic weight, used to define the Rydberg constant
!
!     ibug - level of debug printing (0,1,2,3)
!
!     AC, iauto, mfgi - the parameter for asymptotic package 'ASYMPT'
!                       by Creese, CPC, 1982, ...
!                       Interface module for call ASYMPT --> ZAFACE 
!     AC   - accuracy ( < 0.01)
!     iauto - 2 
!     mfgi  - number of points in external region
!
!=====================================================================
      USE bsr_phot

      Implicit real(8) (A-H,O-Z)
 
      Character(60) :: AFORM = '(f14.8,f14.7,f12.2,2f15.5,f12.6,f8.3,i5)'

      Call CPU_time(t1)
!----------------------------------------------------------------------
! ... define input parameters

      Call Check_file(AF_inp)
      Open(inp, file=AF_inp, status='OLD');      Call Read_arg(inp)

! ... input files:

      write(ALSP,'(i3.3)') klsp  

      i=INDEX(AF_h,'.'); AF = AF_h(1:i)//ALSP;   Call Check_file(AF)
      Open(nuh, file=AF, form='UNFORMATTED', status='OLD')

      i=INDEX(AF_d,'.'); AF = AF_d(1:i)//ALSP;   Call Check_file(AF)
      Open(nud, file=AF, form='UNFORMATTED', status='OLD')

      if(nwt.gt.0) then  
       i=INDEX(AF_w,'.'); AF = AF_w(1:i)//ALSP;  Call Check_file(AF)
       Open(nuw, file=AF, form='UNFORMATTED', status='OLD')
      end if

! ... output files:
  
      Open(pri, file=AF_log)

      i=INDEX(AF_out,'.'); AF = AF_out(1:i)//ALSP; AF_out=AF

      i=INDEX(AF_ph ,'.'); AF = AF_ph (1:i)//ALSP; AF_ph =AF

!----------------------------------------------------------------------
! ... read d.nnn:

      Call Read_Ddat(nud,pri)

! ... read h.nnn:
      
      Call Read_Hdat(nuh,pri)

      if(ndm.ne.nhm) Stop ' ndm <> nhm '      

! ... read w.nnn:

      if(nwt.gt.0) Call Read_Wdat(nuw)

! ... read pseudo-states energies:

      Call Read_bound

!----------------------------------------------------------------------
! ... convert factors from Hartree to cm-1 and eV:
      
      Z = 0.d0;  Call Conv_au (Z,AWT,au_cm,au_eV,pri)

      EION1 = (E1-EI)
      EION2 = (E1-EI)*2.d0
      EION3 = (E1-EI)*au_eV

      if(e_exp.ne.0.d0) then
       EION3 = e_exp
       EION1 = EION3 / au_eV
       EION2 = EION1 * 2.d0
      end if

      write(pri,'(a,f16.8,a)') ' Etarget(1)       : ',E1,   ' au'
      write(pri,'(a,f16.8,a)') ' ionization energy: ',EION1,' au'
      write(pri,'(a,f16.8,a)') ' ionization energy: ',EION2,' Ry'
      write(pri,'(a,f16.8,a)') ' ionization energy: ',EION3,' eV'
      EION = EION2
 
      write(pri,'(//)')
      Do J = 1,ntarg
        write(pri,'(i3,a,a,i2,a,i2,a,2f12.6)')   J,'. ',&
       '  L = ',Ltarg(J),'   2S+1 =',IStarg(J),'   E(Ry) =',etarg(J), &
       (etarg(J)+EION2)/2*au_eV
      End do

!----------------------------------------------------------------------
! ... allocatiopns:

      Allocate(RMAT(nch,nch), RMATI(nch,nch), KMAT(nch,nch), ECH(nch),&
               F(nch,nch), G(nch,nch), FP(nch,nch), GP(nch,nch),      &
               DLr(nch),DLi(nch),DVr(nch),DVi(nch), SL(nch),SV(nch),  &
               ui(nch), uk(nch,nch), FFF(nch,nch), FFP(nch,nch),      &
               AA(nch,nch),BB(nch,nch),FF(nch,nch),v(nch) )

      GI = ILI + ILI + 1           !  2L+1 
      if(ISI.eq.0) GI = ILI+1      !  2J+1

      PI = ACOS(-1.d0)

!-----------------------------------------------------------------------
! ... define energies:

      me = 0
      Do istep = 1,nrange
       if(Elow(istep).le.0.d0) Cycle
       if(Ehigh(istep).lt.Elow(istep)) Cycle
       EKK = Elow(istep)-Estep(istep)
      Do 
       EKK = EKK + Estep(istep)
       if(EKK.gt.Ehigh(istep)) Exit
       me = me + 1
      End do    ! over electron energies
      End do    ! over energy intervals
      write(pri,*) 'number of input energies = ',me
      if(me.eq.0) Stop 'nothing to do, based on input energies'

      OPEN(iph,file=AF_ph)
      ke = 0
      rewind(iph)
    1 read(iph,'(a)',end=2) AS 
      if(len_trim(AS).eq.0) go to 1
      read(AS,*,err=1) EKK
      ke = ke + 1                                                                             
      go to 1
    2 Continue
      write(pri,*) 'number of energies in photo.nnn file = ',ke

      Allocate(eee(ke))
      ke = 0
      rewind(iph)
    3 read(iph,'(a)',end=4) AS 
      if(len_trim(AS).eq.0) go to 1
      read(AS,*,err=3) EKK
      ke = ke + 1                                                         
      eee(ke) = EKK
      go to 3
    4 Close(iph)

      Allocate(ee(me))
      ne = 0
      Do istep = 1,nrange
       if(Elow(istep).le.0.d0) Cycle
       if(Ehigh(istep).lt.Elow(istep)) Cycle
       EKK = Elow(istep)-Estep(istep)
      Do 
       EKK = EKK + Estep(istep)
       if(EKK.gt.Ehigh(istep)) Exit
       if(minval(abs(eee - EKK)).le.5.d-8)  Cycle
       ne = ne + 1;  ee(ne) = EKK
      End do    ! over electron energies
      End do    ! over energy intervals

      write(pri,*) 'number of new energies to calculate = ',ne

      if(ne.eq.0) Stop 'nothing to do, ne = 0'

!======================================================================
!                Main loop other energies:
!======================================================================

      Do ie = 1,ne
       ekk = ee(ie)
       ekv = (ekk + eion) * au_eV / 2.d0

! ... check the proximity to thresshold       

       dab = 1000.d0 
       dbl = 1000.d0
       Do i=1,ntarg
        S = ekk - etarg(i)
        if(s.ge.0.d0.and.s.lt.dab) dab = s
        if(s.le.0.d0.and.abs(s).lt.dbl) dbl=abs(s)
       End do

       if(dab.le.athreshold) Cycle
       if(dbl.le.bthreshold) Cycle

! ... define open channels:
 
       Call ZOPEN (EKK, ntarg, etarg, NCONAT, nch, nopen, ECH)

       if(nopen.le.0) Cycle

! ... define asymptotic:

       Call ZAFACE(ibug,AC,ION,km,RA,DR,nch,nopen,LCH,ECH,CF, &
                   iauto,mfgi,info,F,G,FP,GP)                                  
       if(info.ne.0) Cycle

! ... define R-matrix:
 
       Call ZRMAT (EKK,RA,nch,nhm,RMAT,VALUE,WMAT)

! ... define K-matrix:
 
       Call ZKMAT(nch,nopen,RA,RB,RMAT,F,G,FP,GP,KMAT) 

! ... evaluate the symmetry of the K-matrix:
 
       Call Sym_mat1 (nopen,nch,KMAT,dmn,dmx,dav)
 
       if(ibug.gt.0) write(pri,'(/a,3f7.1/)') &
          ' asymmetry, LOG(Min/Max/Av): ',dmn,dmx,dav

! ... deternine eigenphases from K-matrix:

       Call ephase (nopen,nch,KMAT,uk,ui,us)

! ... photoionization data:
 
       Ephot = EION + EKK;   Call PHOT_SEC (EKK,Ephot,GI,nopen,method)

! ... weights:

       if(nwt.gt.0) Call AK_coef(nopen,EKK)

! ... --> partial sections:

       OPEN(ics,file=AF_out,position='APPEND')
       write(ics,'(2d15.8,4i5)') EKK,EKV,nopen,nwt,ikm
       write(ics,'(5d15.8)') SLP,SL(1:nopen)
       write(ics,'(5d15.8)') SVP,SV(1:nopen)
       write(ics,'(5d15.8)') us ,ui(1:nopen)

       Do i=1,nopen
        write(ics,'(4d15.8)') dlr(i),dli(i),dvr(i),dvi(i)
       End do
       if(nwt.gt.nopen) then
        write(ics,'(d15.8)') CC
        write(ics,'(5d15.8)') WTch(1:nwt)
        Do i=1,nopen
         write(ics,'(5d15.8)') AK(1:nwt,i)
        End do
       end if
       if(ikm.gt.0) &
        write(ics,'(6d13.6)') ((KMAT(i,j),i=1,j),j=1,nopen)
       Close(ics)


! ...  --> photo.out:
 
       OPEN(iph,file=AF_ph,position='APPEND')
       write(iph,'(f14.8,f14.7,f12.2,2f15.5,f12.6,f8.3,i5)') &
            EKK,EKV,CC,slp,svp,us,dav,method
       Close(iph)

       write(pri,AFORM) EKK,EKV,CC,slp,svp,us,dav,method

      End do    ! over electron energies

!----------------------------------------------------------------------

      OPEN(iph,file=AF_ph)
      Call Sort_photo(iph,AFORM)

      Call CPU_time(t2)
      write(pri,'(/a,f6.2,a)')  ' time = ',(t2-t1)/60,' min'
 
      End  ! program bsr_phot
