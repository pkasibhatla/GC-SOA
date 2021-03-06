!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !MODULE: jv_cmn_mod
!
! !DESCRIPTION: Module jv\_cmn\_mod contains global variables (formerly in
!  common blocks) for the FAST-J code (cf. Wild/Prather 7/99).
!\\
!\\
! !INTERFACE: 
!
      MODULE JV_CMN_MOD
!
! !USES:
!
      USE CMN_SIZE_MOD, ONLY : NDUST, NAER, NRH
      USE CMN_FJ_MOD,   ONLY : JPMAX, LPAR, IPAR, JPAR

      IMPLICIT NONE
      PUBLIC
!
! !DEFINED PARAMETERS
!
      ! NB  Number of levels in CTM plus one for above model top
      ! NC  Number of levels in the fundamental Fast-J grid
      ! NS  Maximum number of species which require J-values calculating 
      ! NW  Maximum number of wavelength bins that can be used
      ! NP  Maximum number of aerosol/cloud types that can be used
      ! MX  Number of aerosol/cloud types supplied from CTM
      INTEGER, PARAMETER :: NB      = LPAR+1
      INTEGER, PARAMETER :: NC      = 2*NB
      INTEGER, PARAMETER :: NS      = 51
      INTEGER, PARAMETER :: NW      = 15
      INTEGER, PARAMETER :: NP      = 56
      INTEGER, PARAMETER :: MX      = 35

      REAL*8,  PARAMETER :: RAD     = 6375.d5   
      REAL*8,  PARAMETER :: ZZHT    = 5.d5      
      REAL*8,  PARAMETER :: dtaumax = 1.d0
      REAL*8,  PARAMETER :: dtausub = 1.d0
      REAL*8,  PARAMETER :: dsubdiv = 10.d0
      REAL*8,  PARAMETER :: szamax  = 98.0d0
!
! !PUBLIC DATA MEMBERS:
!
      ! Character variables
      CHARACTER*20 TITLEA(NP)
      CHARACTER*78 TITLE0
      CHARACTER*7  TITLEJ(3,NS), jlabel(JPMAX)

      !-----------------------------------------------------------------------
      ! These common blocks MUST NOT be held local (bmy, 5/2/00)

      REAL*8  :: WBIN(NW+1),WL(NW),FL(NW),QO2(NW,3),QO3(NW,3)       
      REAL*8  :: Q1D(NW,3),QQQ(NW,2,NS-3),QRAYL(NW),TQQ(3,NS)       
      REAL*8  :: WAA(4,NP),QAA(4,NP)                                 
      REAL*8  :: PAA(8,4,NP),RAA(4,NP),SSA(4,NP),QBC(NW)
            
      INTEGER :: NJVAL,NW1,NW2,NAA,NLBATM                                 

      REAL*8  :: WAA_AOD(NP),QAA_AOD(NP),PAA_AOD(8,NP)             
      REAL*8  :: RAA_AOD(NP),SSA_AOD(NP)

      REAL*8  :: TREF(51,18,12),OREF(51,18,12),BREF(51)           
      REAL*8  :: ODMDUST(IPAR,JPAR,LPAR,NDUST)
      REAL*8  :: ODAER(IPAR,JPAR,LPAR,NAER*NRH)

      REAL*8  :: jfacta(JPMAX),zpdep(NW,7)
      INTEGER :: npdep,jpdep(NS),jind(JPMAX)

      INTEGER :: MIEDX(MX)

      !-----------------------------------------------------------------------
      ! Split off GLYX-chemistry specific arrays into separate common blocks
      ! (ccarouge, bmy, 8/20/09)
      INTEGER :: PDEPF(7)

      REAL*8  :: MGLYPDEP(NW, 3)

      !-----------------------------------------------------------------------
      ! These common blocks MUST be held local for the parallelization 
      ! (bmy, 5/2/00)
      REAL*8   :: TJ(NB),PJ(NB+1),DM(NB),DO3(NB),DBC(NB),Z(NB)    
      REAL*8   :: AER(MX,NB),AMF(NB,NB),RFLECT,SZA,U0,TANHT
      REAL*8   :: zj(LPAR,JPMAX)
      REAL*8   :: FFF(NW,lpar),VALJ(NS)
      INTEGER  :: jadsub(NC)

!$OMP THREADPRIVATE( TJ, PJ, DM, DO3, DBC, Z)           
!$OMP THREADPRIVATE( AER, AMF, RFLECT, SZA, U0, TANHT)
!$OMP THREADPRIVATE( zj )
!$OMP THREADPRIVATE( FFF, VALJ )
!$OMP THREADPRIVATE( jadsub )

! !REMARKS:
!  NOTES for CTM Interface (bmy, 10/27/99, 3/23/03)
!  =====================================================================
!  (1) Change JPNL and JPPJ from parameters to variables, which are 
!      set in "inphot.f".  This allows the user to switch the number 
!      of levels at run-time via the CTM inputs. 
!                                                                             .
!  (2) Now make RAD, ZZHT, DTAUMAX, DTAUSUB, DSUBDIV, SZAMAX into
!      parameters instead of holding them in common blocks.  
!                                                                             .
!  (3) Create new common blocks /WLLOC/ and /JVLOC/ to hold certain
!      quantities -Xlocal for parallel code (ppm, 4/98, bmy, 9/21/99)
!                                                                             .
!  (4) The common blocks that must be held -Xlocal are:
!         /ATMOS/, /JVSUB/, /WLLOC/, /JVLOC/ 
!                                                                             .
!  (4a) Declare the above commons THREADPRIVATE for the Compaq
!       Alpha platform (bmy, 7/10/01)
!                                                                             .
!  (5) Break MIEDX off from the WLLOC common block, since it must
!      not be declared LOCAL for the parallelization. (bmy, 5/2/00)
!                                                                             .
!  (6) For including aerosol optical depths: (rvm, bmy, 9/30/00)
!      (a) Increase MX from 3 to 10 .  
!      (c) Add ODMDUST(IPAR,JPAR,LPAR,NDUST) to common block /CLIM/
!                                                                             .
!  (7) Move NDUST to CMN_SIZE to avoid conflicts (bmy, 11/15/01)
!                                                                             .
!  (8) For updating aerosol optical depths again (rvm, bmy, 2/27/02):
!      (a) Change NP from 21 to 56
!      (b) Change MX from 10 to 35
!      (c) Add ODAER(IPAR,JPAR,LPAR,NAER*NRH) to common block /CLIM/
!                                                                             .
!  (9) Changed RCS ID tag comment character from "C" to "!" to allow freeform
!       compilation.  Also added & continuation characters in column 73
!       to allow header files to be included in F90 freeform files.
!       Also changed comment character from "C" to "!" to allow this
!       file to be inlined into freeform source code. (bmy, 6/25/02)
!                                                                             .
!  (10) Renamed cpp switch from DEC_COMPAQ to COMPAQ.  Also declare common
!        blocks ATMOS, JVLOC, WLLOC, JVSUB as !$OMP THREADPRIVATE for
!        all platforms. (bmy, 3/23/03)
!                                                                             .
!  (11) Added new pressure denpendencies algorithm parameters 
!         for MGLY. (tmf, 1/7/09)
!                                                                             .
!  (12) Added 'pdepf' as pressure dependancy function selector. (tmf, 1/31/06)
!                                                                             .
!  (13) Split off PDEPF and MGLYPDEP into separate common blocks to avoid
!        warnings on IFORT 9 (ccarouge, bmy, 8/20/09)
!                                                                             .
!  (14) Add new optical variables for AOD calculation (clh, 05/06/10)
!
! !REVISION HISTORY:
!  23 Aug 2011 - M. Long   - Converted to Module from Header file
!EOP
!------------------------------------------------------------------------------
!BOC
      END MODULE JV_CMN_MOD
!EOC
