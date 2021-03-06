!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !ROUTINE: chemdr
!
! !DESCRIPTION: Subroutine CHEMDR is the driver subroutine for full chemistry 
!  with SMVGEAR or KPP.
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE CHEMDR
!
! !USES:
!
      USE AEROSOL_MOD,          ONLY : AEROSOL_CONC, RDAER, SOILDUST
      USE COMODE_MOD,           ONLY : ABSHUM, CSPEC, ERADIUS, TAREA
      USE COMODE_MOD,           ONLY : JLOP,   JLOP_PREVIOUS
      USE DAO_MOD,              ONLY : AD,       AIRVOL,    ALBD, AVGW
!------------------------------------------------------------------------------
! Prior to 11/5/11:
!      USE DAO_MOD,              ONLY : BXHEIGHT, MAKE_AVGW, OPTD, SUNCOS  
!------------------------------------------------------------------------------
      USE DAO_MOD,              ONLY : BXHEIGHT, MAKE_AVGW, OPTD  
      USE DAO_MOD,              ONLY : T,        SUNCOS_MID
      USE DIAG_OH_MOD,          ONLY : DO_DIAG_OH
      USE DIAG_PL_MOD,          ONLY : DO_DIAG_PL
      USE DUST_MOD,             ONLY : RDUST_ONLINE, RDUST_OFFLINE
      USE ERROR_MOD,            ONLY : DEBUG_MSG,    ERROR_STOP
      USE FUTURE_EMISSIONS_MOD, ONLY : GET_FUTURE_YEAR
      USE LOGICAL_MOD,          ONLY : LCARB,        LDUST
      USE LOGICAL_MOD,          ONLY : LPRT,         LSSALT,    LSULF  
      USE LOGICAL_MOD,          ONLY : LSOA,         LVARTROP,  LFUTURE
      USE PLANEFLIGHT_MOD,      ONLY : SETUP_PLANEFLIGHT
      USE TIME_MOD,             ONLY : GET_MONTH,    GET_YEAR
      USE TIME_MOD,             ONLY : ITS_A_NEW_DAY
      USE TRACER_MOD,           ONLY : STT,          N_TRACERS, XNUMOL
      USE TRACERID_MOD,         ONLY : IDTNOX,       IDTOX,     SETTRACE
      USE TROPOPAUSE_MOD,       ONLY : SAVE_FULL_TROP
      USE UVALBEDO_MOD,         ONLY : UVALBEDO
      USE RESTART_MOD,          ONLY : READ_CSPEC_FILE 
      USE TIME_MOD,             ONLY : GET_NYMD,     GET_NHMS
      USE LOGICAL_MOD,          ONLY : LSVCSPEC,     LLINOZ

      USE CMN_SIZE_MOD               ! Size parameters
      USE COMODE_LOOP_MOD            ! SMVGEAR variables
      USE CMN_O3_MOD                 ! EMISRRN, EMISRR
      USE CMN_DIAG_MOD               ! ND40
      USE CMN_NOX_MOD                ! SLBASE
      USE CMN_DEP_MOD                ! FRCLND

      IMPLICIT NONE
#     include "define.h"

!
! !REMARKS:
!  Important input variables from "dao_mod.f" and "uvalbedo_mod.f":
!  ============================================================================
!  ALBD        : DAO visible albedo                         [unitless]
!  AVGW        : Mixing ratio of water vapor                [v/v] 
!  BXHEIGHT    : Grid box heights                           [m]
!  OPTD        : DAO grid-box optical depths (for FAST-J)   [unitless]
!  SUNCOS      : Cosine of solar zenith angle               [unitless]
!  SUNCOSB     : Cosine of solar zenith angle 1 hr from now [unitless]
!  UVALBEDO    : TOMS UV albedo 340-380 nm (for FAST-J)     [unitless]
!                                                                             .
!  Important input variables from "comode.h" or "comode_mod.f":
!  ============================================================================
!  NPTS        : Number of points (grid-boxes) to calculate
!  REMIS       : Emission rates                             [molec/cm3/s-1]
!  RAERSOL     : Frequency of gas-aerosol collisions        [s-1]
!  PRESS       : Pressure                                   [Pa]
!  TMPK        : Temperature                                [K]
!  ABSHUM      : Absolute humidity                          [molec/cm3]
!  CSPEC       : Initial species concentrations             [molec/cm3]
!                                                                             .
!  Important output variables in "comode.h" etc.
!  ============================================================================
!  NAMESPEC    : Character array of species names
!  NNSPEC      : # of ACTIVE + INACTIVE (not DEAD) species
!  CSPEC       : Final species concentrations               [molec/cm3]
!                                                                             .
!  Other Important Variables
!  ============================================================================
!  MAXPTS      : Maximum number of points or grid-boxes (in "comsol.h")
!                (NPTS must be <= MAXPTS, for SLOW-J only)
!  MAXDEP      : Maximum number of deposition species (note # of
!                depositing species listed in tracer.dat must be <= MAXDEP)
!  IGAS        : Maximum number of gases, ACTIVE + INACTIVE
!  IO93        : I/O unit for output for "ctm.chem" file
!                                                                             .
!  Input files for SMVGEAR II:
!  ============================================================================
!   mglob.dat  : control switches                       (read in "reader.f")
!  tracer.dat  : list of tracers, emitting species      (read in "reader.f")
!                and depositing species
! globchem.dat : species list, reaction list,           (read in "chemset.f")
!                photolysis reaction list
!                                                                             .
!  Input files for FAST-J photolysis:
!  ============================================================================
!     ratj.d   : Lists photo species, branching ratios  (read in "rd_js.f")
! jv_atms.dat  : Climatology of T and O3                (read in "rd_prof.f")
! jv_spec.dat  : Cross-sections for each species        (read in "RD_TJPL.f")
!
! !REVISION HISTORY:
!  15 Nov 2001 - Adapted from original code by lwh, jyl, gmg, djj. 
!  (1 ) Cleaned up a lot of stuff.  SUNCOS, OPTD, ALBD, and AVGW are now 
!        referenced from dao_mod.f.  IREF and JREF are obsolete.  Also 
!        updated comments. (bmy, 9/27/01)
!  (2 ) Do not declare LPRT or set LPRT = .FALSE. in "chemdr.f".  LPRT is 
!        included via "CMN" and is defined in "main.f". (bmy, 10/9/01)
!  (3 ) Removed obsolete data from 9/01 (bmy, 10/23/01)
!  (4 ) ERADIUS(JLOOP) is now ERADIUS(JLOOP,1) and TAREA(JLOOP) is now
!        TAREA(JLOOP,1) for sulfate aerosol.  Updated comments. (bmy, 11/15/01)
!  (5 ) Renamed routine PAFTOP to DEBUG_MSG.  Also deleted obsolete code
!        from 11/01.  Enhanced debug output via DEBUG_MSG.  Also reference
!        the UVALBEDO array directly from "uvalbedo_mod.f".  Remove UVALBEDO
!        from the argument list.  Removed obsolete comments. (bmy, 1/15/02)
!  (6 ) Now pass LPAUSE to "initgas.f" via the arg list (bmy, 2/14/02)
!  (7 ) Now call "rdaer.f" instead of RDAEROSOL to read the aerosol and dust 
!        fields from disk.  Also, ignore hygroscopic growth for dust.  Now
!        pass SAVEHO2 and FRACNO2 arrays in the arg list to "ohsave.f"; these 
!        return HO2 conc.'s and NO2 fraction.  Delete NTRACE from call
!        to "ohsave.f", it's obsolete.  Delete reference to DARSFCA from
!        "comode_mod.f", it's obsolete. (rvm, bmy, 2/27/02)
!  (8 ) Removed obsolete code from 2/02. (bmy, 4/15/02)
!  (9 ) Replaced all instances of IM with IIPAR and JM with JJPAR, in order
!        to prevent namespace confusion for the new TPCORE (bmy, 6/25/02)
!  (10) Now reference IU_CTMCHEM from "file_mod.f".  Assign the value of
!        IU_CTMCHEM (which =93) to IO93 for SMVGEAR routines.  Also open 
!        "ctm.chem" file on the first call as file unit # IO93.  Add
!        references to "F77_CMN_DIAG" and "planeflight_mod.f".  Call routine
!        SETUP_PLANEFLIGHT to initialize the plane track diagnostic
!        after reading the "chem.dat" file.  (bmy, 7/2/02)
!  (11) Now reference AD, T and BXHEIGHT from "dao_mod.f".  Also removed 
!        obsolete commented out code in various sections below.  Now also
!        references "tracerid_mod.f".  Also remove reference to BIOTRCE, since
!        this is now obsolete.  Now make FIRSTCHEM a local SAVED variable
!        instead of an argument.  Now calls MAKE_AVGW, which was formerly
!        called in "main.f". (bmy, 11/15/02)
!  (12) Now reference "AIRVOL" from "dao_mod.f".  Now declare local array
!        SO4_NH4_NIT, which will contain lumped SO4, NH3, NIT aerosol.  Now
!        pass SO4_NH4_NIT to "rdaer.f" via the arg list if sulfate chemistry
!        is turned on.  Now also references F77_CMN_SETUP. (rjp, bmy, 3/23/03)
!  (13) Removed ITAU from the arg list.  Removed reference to IHOUR.  Now use
!        functions GET_MONTH, GET_YEAR from "time_mod.f" (bmy, 3/27/03)
!  (14) Remove KYEAR and TWO_PI, these are now obsolete for SMVGEAR II.  Now 
!        open unit #93 and call READER in the same FIRSTCHEM if-block.  Now
!        Replace call to CHEMSET with call to READCHEM.  JPARSE is now called 
!        from w/in READCHEM.  Replace call to INITGAS w/ call to GASCONC.
!        Removed reference to "file_mod.f".  Remove call to SETPL, we now must
!        call this in "readchem.f" before the call to JSPARSE. 
!        (bdf, ljm, bmy, 5/8/03)
!  (15) Now reference routine GET_GLOBAL_CH4 from "global_ch4_mod.f".  Also
!        added CH4_YEAR as a SAVEd variable. (bnd, bmy, 7/1/03)
!  (16) Remove references to MONTHP, IMIN, ISEC; they are obsolete and not 
!        defined anywhere. (bmy, 7/16/03)
!  (17) Now reference SUNCOSB from "dao_mod.f".  Now pass SUNCOSB to "chem.f". 
!        Also remove LSAMERAD from call to CHEM, since it's obsolete. 
!        (gcc, bmy, 7/30/03)
!  (18) Added BCPO, BCPI, OCPO, OCPI, and SOILDUST arrays.  Now pass SOILDUST
!       to RDUST_ONLINE (in "dust_mod.f").  Now pass PIEC, POEC, PIOC, POOC to
!       "rdaer.f".  Now references "dust_mod.f". (rjp, tdf, bmy, 4/1/04)
!  (19) Added SALA and SALC arrays for passing seasalt to rdaer.f.  Now
!        rearranged the DO loop for computational efficiency. (bmy, 4/20/04)
!  (20) Added OCF parameter to account for the other chemical components that
!        are attached to OC.  Also now handle hydrophilic OC differently for
!        online & offline SOA. (rjp, bmy, 7/15/04)
!  (21) Now reference "logical_mod.f".  Now reference STT and N_TRACERS from
!        "tracer_mod.f".  Now references DO_DIAG_PL from "diag_pl_mod.f".
!        Now references DO_DIAG_OH from "diag_oh_mod.f".  Now references
!        AEROSOL_CONC, RDAER, & SOILDUST from "aerosol_mod.f" (bmy, 7/20/04)
!  (22) Now references ITS_A_NEW_DAY from "time_mod.f".  Now calls routine
!        SETUP_PLANEFLIGHT at the start of each new day. (bmy, 3/24/05)
!  (23) FAST-J is now the default, so we don't need the LFASTJ C-preprocessor 
!        switch any more (bmy, 6/23/05)
!  (24) Now remove LPAUSE from the arg list to "ruralbox.f" and "gasconc.f".
!        (bmy, 8/22/05)
!  (25) Now make sure all USE statements are USE, ONLY (bmy, 10/3/05)
!  (26) Now references XNUMOL & XNUMOLAIR from "tracer_mod.f" (bmy, 10/25/05)
!  (27) Remove more obsolete SLOW-J code references.  Also now move function
!        calls from subroutine "chem.f" into "chemdr.f".  Remove obsolete
!        arguments from call to RURALBOX. (bmy, 4/10/06) 
!  (28) Remove reference to "global_ch4_mod.f".  Add error check for LISOPOH
!        when using the online SOA tracers. (dkh, bmy, 6/1/06)
!  (29) Now support variable tropopause (bdf, phs, bmy, 10/3/06)
!  (30) Now get CH4 concentrations for FUTURE_YEAR when using the future
!        emissions scale factors (swu, havala, bmy, 1/28/04)
!  (31) Now call "save_full_trop" at the end to account for "do_diag_pl" 
!        resetting some of CSPEC elements (phs, 6/3/08)
!  (32) Reading the CSPEC_FULL restart file if asked.(dkh, hotp, ccc 2/26/09)
!  (33) Added optional call to gckpp_driver (phs,ks,dhk, 09/15/09)
!  (34) CSPEC_FOR_KPP not used anymore (use CSPEC instead) (ccc, 12/3/09)
!  (35) Move the KPP interface in physproc.f to save memory (ccc, 12/3/09)
!  (36) Now remove obsolete embedded chemistry stuff.  Modify arg list to
!        RURALBOX accordingly.   Removed obsolete LEMBED switch. (bmy, 2/26/10)
!  (37) Remove obsolete SUNCOSB (bmy, 4/28/10)
!  26 Aug 2010 - R. Yantosca - Added ProTeX headers
!  05 Oct 2011 - R. Yantosca - Now use SUNCOS30 (cosine of SZA at 30m after
!                              the GMT hour) instead of SUNCOS.  This fixes
!                              the photolysis issue.
!  07 Oct 2011 - R. Yantosca - Rename SUNCOS30 to SUNCOS_MID, which is the
!                              cos(SZA) at the midpt of the chemistry timestep
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      LOGICAL, SAVE            :: FIRSTCHEM = .TRUE.
      INTEGER, SAVE            :: CH4_YEAR  = -1
      INTEGER                  :: I, J, JLOOP, L, NPTS, N, MONTH, YEAR
      INTEGER                  :: WAVELENGTH
      INTEGER                  :: DATE                         
      INTEGER, SAVE            :: DATE_PREV = -1

      ! To use CSPEC_FULL restart (dkh, 02/12/09) 
      LOGICAL                  :: IT_EXISTS 

      !=================================================================
      ! CHEMDR begins here!
      !=================================================================

      ! Set some size variables
      NLAT   = JJPAR
      NLONG  = IIPAR
      NVERT  = IVERT 
      NPVERT = NVERT
      NPVERT = NVERT + IPLUME

      ! Get month and year
      MONTH  = GET_MONTH()
      YEAR   = GET_YEAR()

      !=================================================================
      ! Compute AVGW, the mixing ratio of water vapor
      !=================================================================
      CALL MAKE_AVGW

      !=================================================================
      ! Open "smv2.log" output file and read chem mechanism switches
      !=================================================================
      IF ( FIRSTCHEM ) THEN
         
         ! Read from data file mglob.dat
         CALL READER( FIRSTCHEM )
         IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after READER' )

         ! Set NCS for urban chemistry only (since that is where we
         ! have defined the GEOS-CHEM mechanism) (bdf, bmy, 4/21/03)
         NCS = NCSURBAN
      ENDIF

      !=================================================================      
      ! Call RURALBOX, which defines tropospheric boxes to be sent to
      ! the SMVGEAR solver, as well as setting up some SMVGEAR arrays.
      !=================================================================      

      ! Redefine NTLOOP since READER defines it initially (bmy, 9/28/04)
      NLOOP  = NLAT  * NLONG
      NTLOOP = NLOOP * NVERT

      !vartrop fix (dkh, 05/08/11)
      !Save a copy of JLOP from the previous time step before re-ordering
      !the grid mappings.
      JLOP_PREVIOUS(:,:,:) = JLOP(:,:,:)

!-----------------------------------------------------------------------------
! Prior to 10/5/11:
! SUNCOS is no longer used in RURALBOX, we can remove it (bmy, 10/5/11)
!     CALL RURALBOX( AD, T, AVGW, ALBD, SUNCOS )
!-----------------------------------------------------------------------------
      CALL RURALBOX( AD, T, AVGW, ALBD )

      !vartrop fix (dkh, 05/08/11)
      !Use JLOP from this timestep the first time through
      IF ( FIRSTCHEM ) THEN
	JLOP_PREVIOUS(:,:,:)= JLOP(:,:,:)
      ENDIF

      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after RURALBOX' ) 

      ! Reset NTTLOOP, the # of tropospheric grid boxes
      NTTLOOP = NTLOOP

      !=================================================================
      ! Call SETMODEL which defines number of grid-blocks in calculation,
      ! and copies meteorological parameters into local variables 
      !=================================================================
      CALL SETMODEL

      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after SETMODEL' )

      !=================================================================
      ! Do the following only on the first call ...
      !=================================================================
      IF ( FIRSTCHEM ) THEN

         !---------------------------------
         ! Initialize chemistry mechanism
         !---------------------------------

         ! Read "globchem.dat" chemistry mechanism
         CALL READCHEM

         ! Set NCS=NCSURBAN here since we have defined our tropospheric
         ! chemistry mechanism in the urban slot of SMVGEAR II (bmy, 4/21/03)
         NCS = NCSURBAN

         !### Debug
         IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after READCHEM' )

         !---------------------------------
         ! Check for LISOPOH for SOA
         !---------------------------------
         IF ( LSOA .and. ILISOPOH == 0 ) THEN
            CALL ERROR_STOP( 'LISOPOH needs to be defined for SOA!',
     &                       'chemdr.f' )
         ENDIF

         !---------------------------------
         ! Set global concentration of CH4
         !---------------------------------
         IF ( ICH4 > 0 .and. ( CH4_YEAR /= GET_YEAR() ) ) THEN

            ! If CH4 is a SMVGEAR II species, then call GET_GLOBAL_CH4
            ! to return the globally-varying CH4 conc. as a function of
            ! year and latitude bin.  (ICH4 is defined in READCHEM.)
            ! (bnd, bmy, 7/1/03)
            !
            ! If we are using the future emissions, then get the CH4
            ! concentrations for FUTURE_YEAR.  Otherwise get the CH4
            ! concentrations for the current met field year. 
            ! (swu, havala, bmy, 1/24/08)
            IF ( LFUTURE ) THEN
               CH4_YEAR = GET_FUTURE_YEAR()
            ELSE
               CH4_YEAR = GET_YEAR()
            ENDIF

            ! Get CH4 [ppbv] in 4 latitude bins for each year
            CALL GET_GLOBAL_CH4( CH4_YEAR, .TRUE., C3090S,
     &                           C0030S,   C0030N, C3090N )
         ENDIF

         !-------------------------------
         ! Initialize FAST-J photolysis
         !-------------------------------
         CALL INPHOT( LLTROP, NPHOT ) 
         
         !### Debug
         IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after INPHOT' )        

         !-------------------------------
         ! Flag certain chemical species
         !-------------------------------
         CALL SETTRACE

         !### Debug
         IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after SETTRACE' )

         !-------------------------------
         ! Flag emission & drydep rxns
         !-------------------------------
         CALL SETEMDEP( N_TRACERS )

         !### Debug
         IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after SETEMDEP' )

      ENDIF

      !=================================================================
      ! At the beginning of each new day, call SETUP_PLANEFLIGHT
      ! to see if there are any plane flight points to be processed
      !=================================================================
!-----------------------------------------------------------------------
! Prior to 9/27/11:
! Fix for centralizing chemistry timestep (bmy, mpayer, 9/27/11)
!      IF ( ND40 > 0 .and. ITS_A_NEW_DAY() ) THEN
!         CALL SETUP_PLANEFLIGHT
!      ENDIF
!-----------------------------------------------------------------------

      ! Get todays' date
      DATE = GET_NYMD()
    
      ! If this is the first chem timestep of a new day, then we need to 
      ! call SETUP_PLANEFLIGHT.  If chemistry is turned on, then we need
      ! to place this call here, so as to make sure that the chemical
      ! mechanism files (read by READER and READCHEM) have been loaded.
      IF ( ND40 .and. DATE /= DATE_PREV ) THEN
         print*, '### Called SETUP_PLANEFLIGHT'
         CALL SETUP_PLANEFLIGHT
         DATE_PREV = DATE
      ENDIF

      !================================================================
      ! Get concentrations of aerosols in [kg/m3] 
      ! for FAST-J and optical depth diagnostics
      !=================================================================
      IF ( LSULF .or. LCARB .or. LDUST .or. LSSALT ) THEN

         ! Skip this section if all these are turned off
         CALL AEROSOL_CONC

      ENDIF

      !=================================================================
      ! Call GASCONC which initializes gas concentrations and sets 
      ! miscellaneous parameters.  GASCONC also calls PARTITION, which
      ! splits up family tracers like NOx and Ox into individual
      ! chemical species for SMVGEAR.
      ! NOTE:
      ! (1) The call to GASCONC is modified to use CSPEC_FULL restart 
      !     file (dkh, hotp, ccc,2/26/09)
      !=================================================================
      IT_EXISTS = .FALSE.
      IF ( FIRSTCHEM .AND. LSVCSPEC ) THEN 

         CALL READ_CSPEC_FILE( GET_NYMD(), GET_NHMS(), IT_EXISTS ) 
   
         IF ( .not. IT_EXISTS ) THEN 
             
            ! Use default background values 
            WRITE(6,*) 
     &   '    - CHEMDR: CSPEC restart not found, use background values'
 
            CALL GASCONC( FIRSTCHEM,              N_TRACERS, 
     &                    STT(:,:,:,1:N_TRACERS), XNUMOL(1:N_TRACERS),    
     &                    FRCLND,                 IT_EXISTS )
         ELSE 

            ! Use restart values 
            WRITE(6,*) 
     &   '    - CHEMDR: using CSPEC values from restart file'                  

            ! Call GASCONC but don't reset CSPEC values
            CALL GASCONC( .FALSE.,                 N_TRACERS, 
     &                     STT(:,:,:,1:N_TRACERS), XNUMOL(1:N_TRACERS),    
     &                     FRCLND,                 IT_EXISTS )

         ENDIF 

      ELSE 

         CALL GASCONC(  FIRSTCHEM,              N_TRACERS, 
     &                  STT(:,:,:,1:N_TRACERS), XNUMOL(1:N_TRACERS),  
     &                  FRCLND,                 IT_EXISTS )

      ENDIF 
      IT_EXISTS = .FALSE.

      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after GASCONC' )

      !=================================================================  
      ! Call SETEMIS which sets emission rates REMIS 
      !=================================================================
      CALL SETEMIS( EMISRR, EMISRRN )
      
      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after SETEMIS' )

      !=================================================================
      ! Call RDAER -- computes aerosol optical depths
      !=================================================================

      ! Call RDAER to compute AOD for FAST-J (skim, 02/03/11)
      WAVELENGTH = 0

      CALL RDAER( MONTH, YEAR, WAVELENGTH )

      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after RDAER' )

      !=================================================================
      ! If LDUST is turned on, then we have online dust aerosol in
      ! GEOS-CHEM...so just pass SOILDUST to RDUST_ONLINE in order to
      ! compute aerosol optical depth for FAST-J, etc.
      !
      ! If LDUST is turned off, then we do not have online dust aerosol
      ! in GEOS-CHEM...so read monthly-mean dust files from disk.
      ! (rjp, tdf, bmy, 4/1/04)
      !=================================================================
      IF ( LDUST ) THEN
         CALL RDUST_ONLINE( SOILDUST, WAVELENGTH )
      ELSE
         CALL RDUST_OFFLINE( MONTH, YEAR, WAVELENGTH )
      ENDIF

      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after RDUST' )

      NPTS = NTTLOOP

      ! At present, we are only doing tropospheric chemistry, which 
      ! for the moment we are storing in SMVGEAR II's "urban" slot
      NCS = NCSURBAN

      !=================================================================
      ! Call photolysis routine to compute J-Values
      !=================================================================
!------------------------------------------------------------------------------
! Prior to 10/7/11:
!      CALL FAST_J( SUNCOS, OPTD, UVALBEDO )              
!------------------------------------------------------------------------------
      CALL FAST_J( SUNCOS_MID, OPTD, UVALBEDO )              

      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after FAST-J' )

      !================================================================
      ! Call chemistry routines
      !================================================================

      ! PHYSPROC calls both CALCRATE, which computes rxn rates 
      ! and SMVGEAR (if we do not use the solver coded by kpp), which
      ! is the chemistry solver
!------------------------------------------------------------------------------
! Prior to 10/5/11:
!      CALL PHYSPROC( SUNCOS )
!------------------------------------------------------------------------------
      CALL PHYSPROC( SUNCOS_MID )

      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after PHYSPROC' )

      ! SCHEM applies a simplified strat chemistry in order
      ! to prevent stuff from building up in the stratosphere
      !
      ! NOTE: SCHEM still needs to be called whether or not LINOZ is
      ! used.  LINOZ is just a replacement for SYNOZ. (bmy, 4/28/10)
      CALL SCHEM

      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after SCHEM' )

      !=================================================================
      ! Call LUMP which lumps the species together after chemistry
      !=================================================================
      CALL LUMP( N_TRACERS, 
     &           XNUMOL(1:N_TRACERS),
     &           STT(:,:,:,1:N_TRACERS) )

      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after LUMP' )

      !=================================================================
      ! Call OHSAVE which saves info on OZONE, OH, AND NO concentrations 
      !=================================================================
      IF ( IDTNOX /= 0 .AND. IDTOX /= 0 ) THEN
         CALL OHSAVE( N_TRACERS,              XNUMOL(1:N_TRACERS),
     &                STT(:,:,:,1:N_TRACERS), FRACO3, 
     &                FRACNO,                 FRACNO2, 
     &                SAVEOH,                 SAVEHO2, 
     &                SAVENO,                 SAVENO2, 
     &                SAVENO3 )

         !### Debug
         IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after OHSAVE' )
      ENDIF

      !=================================================================
      ! Save quantities for computing mean OH lifetime
      !=================================================================
      CALL DO_DIAG_OH
      
      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after DO_DIAG_OH' )

      !=================================================================
      ! Save production and loss for chemical families.  Also save
      ! P(Ox) and L(Ox) for a future tagged Ox run (if necessary).
      !=================================================================
      IF ( LFAMILY ) THEN
         CALL DO_DIAG_PL

         !### Debug
         IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after DO_DIAG_PL' )
      ENDIF
      
      !=================================================================
      ! Copy the chemical species from CSPEC (actual troposphere) to
      ! CSPEC_FULL (potential troposphere) array.  We only need to do 
      ! this if the variable troposphere is turned on. 
      ! (bdf, phs, bmy, 10/3/06)
      !
      ! NOTE: 
      ! (1) This has to be placed at the end of CHEMDR, after the
      !     call to the ND65 diagnostic DO_DIAG_PL. (phs, 6/3/08)
      ! (2) We also copy CSPEC to CSPEC_FULL if we want to write a 
      !     CSPEC_FULL restart file. (ccc, 2/26/09) 
      !=================================================================
      IF ( LVARTROP .or. LSVCSPEC ) THEN
         CALL SAVE_FULL_TROP

         !### Debug
         IF ( LPRT ) CALL DEBUG_MSG( '### CHEMDR: after SAVE_FULL_TROP')
      ENDIF

      !=================================================================
      ! Set FIRSTCHEM = .FALSE. -- we have gone thru one chem step
      !=================================================================
      FIRSTCHEM = .FALSE.

      !### Debug
      IF ( LPRT ) CALL DEBUG_MSG( '### Now exiting CHEMDR!' )

      END SUBROUTINE CHEMDR
!EOC



