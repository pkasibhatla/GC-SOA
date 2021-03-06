!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !MODULE: CMN_SIZE
!
! !DESCRIPTION: CMN\_SIZE contains size parameters for GEOS-Chem arrays.
!\\
!\\
! !INTERFACE:
!
      MODULE CMN_SIZE_MOD
!
! !USES:
!
      IMPLICIT NONE
      PUBLIC

#     include "define.h"
!
! !DEFINED PARAMETERS:
!
      !=================================================================
      ! DISIZE = size (in degrees) of a longitude grid box
      ! DJSIZE = size (in degrees) of a latitude  grid box
      !=================================================================
#if   defined( GRID4x5 ) 
      REAL*8, PARAMETER :: DISIZE = 5.0d0
      REAL*8, PARAMETER :: DJSIZE = 4.0d0
#elif defined( GRID2x25 )
      REAL*8, PARAMETER :: DISIZE = 2.5d0 
      REAL*8, PARAMETER :: DJSIZE = 2.0d0
#elif defined( GRID1x125 )
      REAL*8, PARAMETER :: DISIZE = 1.25d0 
      REAL*8, PARAMETER :: DJSIZE = 1.0d0
#elif defined( GRID1x1 )
      REAL*8, PARAMETER :: DISIZE = 1.0d0 
      REAL*8, PARAMETER :: DJSIZE = 1.0d0
#elif defined( GRID05x0666 )
      REAL*8, PARAMETER :: DISIZE = 2d0/3d0
      REAL*8, PARAMETER :: DJSIZE = 0.5d0
#endif

      !=================================================================
      ! GRID PARAMETERS
      !
      ! IGLOB      = global longitude dimension
      ! JGLOB      = global latitude dimension
      ! LGLOB      = max number of sigma levels 
      ! IIPAR      = window longitude dimension
      ! JJPAR      = window latitude dimension
      ! LLPAR      = window vertical dimension
      ! LLTROP     = maximum number of tropospheric levels for variable
      !              tropopause
      ! LLTROP_FIX = number of tropospheric levels for offline simulations
      ! PTOP       = model top pressure (mb)
      !
      ! Most of the time, GEOS-CHEM is used for global simulations.
      ! In this case, then IIPAR=IGLOB, JJPAR=JGLOB, LLPAR=LGLOB.
      !
      ! For nested grids, then IIPAR<IGLOB, JJPAR<JGLOB, LLPAR<LGLOB.
      !=================================================================
#if   defined( GCAP ) && defined( GRID4x5 )

      !-----------------------------------------------------------------
      ! GCAP: 4 x 5
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: IGLOB      = 72
      INTEGER, PARAMETER :: JGLOB      = 45
      INTEGER, PARAMETER :: LGLOB      = 23
      INTEGER, PARAMETER :: IIPAR      = IGLOB
      INTEGER, PARAMETER :: JJPAR      = JGLOB
      INTEGER, PARAMETER :: LLPAR      = LGLOB
      INTEGER, PARAMETER :: LLTROP     = 12   
      INTEGER, PARAMETER :: LLTROP_FIX = LLTROP     
      REAL*8,  PARAMETER :: PTOP       = 0.002d0

#elif defined( GEOS_3 ) && defined( GRID4x5 )

      !-----------------------------------------------------------------
      ! GEOS-3: 4 x 5
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: IGLOB      = 72
      INTEGER, PARAMETER :: JGLOB      = 46
      INTEGER, PARAMETER :: LGLOB      = 48            
      INTEGER, PARAMETER :: IIPAR      = IGLOB
      INTEGER, PARAMETER :: JJPAR      = JGLOB
#if   defined( GRIDREDUCED )
      INTEGER, PARAMETER :: LLPAR      = 30        ! Reduced vertical grid
      INTEGER, PARAMETER :: LLTROP     = 24        !  -- 30 levels
#else
      INTEGER, PARAMETER :: LLPAR      = LGLOB     ! Full vertical grid
      INTEGER, PARAMETER :: LLTROP     = 25        !  -- 48 levels
#endif
      INTEGER, PARAMETER :: LLTROP_FIX = 20 
      REAL*8,  PARAMETER :: PTOP       = 0.01d0

#elif defined( GEOS_3 ) && defined( GRID2x25 )

      !-----------------------------------------------------------------
      ! GEOS-3: 2 x 2.5
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: IGLOB      = 144
      INTEGER, PARAMETER :: JGLOB      = 91
      INTEGER, PARAMETER :: LGLOB      = 48            
      INTEGER, PARAMETER :: IIPAR      = IGLOB
      INTEGER, PARAMETER :: JJPAR      = JGLOB
#if   defined( GRIDREDUCED )
      INTEGER, PARAMETER :: LLPAR      = 30        ! Reduced vertical grid
      INTEGER, PARAMETER :: LLTROP     = 24        !  -- 30 levels
#else
      INTEGER, PARAMETER :: LLPAR      = LGLOB     ! Full vertical grid
      INTEGER, PARAMETER :: LLTROP     = 25        !  -- 48 levels
#endif 
      INTEGER, PARAMETER :: LLTROP_FIX = 20
      REAL*8,  PARAMETER :: PTOP       = 0.01d0

#elif defined( GEOS_3 ) && defined( GRID1x1 )

      !-----------------------------------------------------------------
      ! GEOS-3: 1 x 1 
      !-----------------------------------------------------------------
#if   defined( NESTED_CH )
      INTEGER, PARAMETER :: IGLOB      = 81        ! CHINA NESTED 1x1
      INTEGER, PARAMETER :: JGLOB      = 67
      INTEGER, PARAMETER :: LGLOB      = 48           
#elif defined( NESTED_NA )
      INTEGER, PARAMETER :: IGLOB      = 101       ! N. AMERICA NESTED 1x1
      INTEGER, PARAMETER :: JGLOB      = 51    
      INTEGER, PARAMETER :: LGLOB      = 48    
#else
      INTEGER, PARAMETER :: IGLOB      = 360       ! GLOBAL GRID 1x1
      INTEGER, PARAMETER :: JGLOB      = 181
      INTEGER, PARAMETER :: LGLOB      = 48                 

#endif
      INTEGER, PARAMETER :: IIPAR      = IGLOB
      INTEGER, PARAMETER :: JJPAR      = JGLOB
#if   defined( GRIDREDUCED )
      INTEGER, PARAMETER :: LLPAR      = 30        ! Reduced vertical grid
      INTEGER, PARAMETER :: LLTROP     = 24        !  -- 30 levels  
#else
      INTEGER, PARAMETER :: LLPAR      = LGLOB     ! Full vertical grid
      INTEGER, PARAMETER :: LLTROP     = 25        !  -- 48 levels
#endif
      INTEGER, PARAMETER :: LLTROP_FIX = 20
      REAL*8,  PARAMETER :: PTOP       = 0.01d0

#elif defined( GEOS_4 ) && defined( GRID4x5 )

      !-----------------------------------------------------------------
      ! GEOS-4: 4 x 5
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: IGLOB      = 72
      INTEGER, PARAMETER :: JGLOB      = 46
      INTEGER, PARAMETER :: LGLOB      = 55           
      INTEGER, PARAMETER :: IIPAR      = IGLOB
      INTEGER, PARAMETER :: JJPAR      = JGLOB
#if   defined( GRIDREDUCED ) 
      INTEGER, PARAMETER :: LLPAR      = 30        ! Reduced vertical grid
      INTEGER, PARAMETER :: LLTROP     = 22        !  -- 30 levels
#else
      INTEGER, PARAMETER :: LLPAR      = LGLOB     ! Full vertical grid
      INTEGER, PARAMETER :: LLTROP     = 23        !  -- 55 levels
#endif
      INTEGER, PARAMETER :: LLTROP_FIX = 17
      REAL*8,  PARAMETER :: PTOP       = 0.01d0

#elif defined( GEOS_4 ) && defined( GRID2x25 )

      !-----------------------------------------------------------------
      ! GEOS-4: 2 x 2.5
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: IGLOB      = 144
      INTEGER, PARAMETER :: JGLOB      = 91
      INTEGER, PARAMETER :: LGLOB      = 55
      INTEGER, PARAMETER :: IIPAR      = IGLOB
      INTEGER, PARAMETER :: JJPAR      = JGLOB
#if   defined( GRIDREDUCED )
      INTEGER, PARAMETER :: LLPAR      = 30        ! Reduced vertical grid
      INTEGER, PARAMETER :: LLTROP     = 22        !  -- 30 levels
#else 
      INTEGER, PARAMETER :: LLPAR      = LGLOB     ! Full vertical grid
      INTEGER, PARAMETER :: LLTROP     = 23        !  -- 55 levels
#endif
      INTEGER, PARAMETER :: LLTROP_FIX = 17
      REAL*8,  PARAMETER :: PTOP       = 0.01d0

#elif defined( GEOS_4 ) && defined( GRID1x125 )

      !-----------------------------------------------------------------
      ! GEOS-4: 1 x 1.2.5
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: IGLOB      = 288
      INTEGER, PARAMETER :: JGLOB      = 181
      INTEGER, PARAMETER :: LGLOB      = 55
      INTEGER, PARAMETER :: IIPAR      = IGLOB
      INTEGER, PARAMETER :: JJPAR      = JGLOB
#if   defined( GRIDREDUCED )
      INTEGER, PARAMETER :: LLPAR      = 30        ! Reduced vertical grid
      INTEGER, PARAMETER :: LLTROP     = 22        !  -- 30 levels
#else 
      INTEGER, PARAMETER :: LLPAR      = LGLOB     ! Full vertical grid
      INTEGER, PARAMETER :: LLTROP     = 23        !  -- 55 levels
#endif
      INTEGER, PARAMETER :: LLTROP_FIX = 17
      REAL*8,  PARAMETER :: PTOP       = 0.01d0

#elif defined( GEOS_5 ) && defined( GRID4x5 )

      !-----------------------------------------------------------------
      ! GEOS-5: 4 x 5
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: IGLOB      = 72
      INTEGER, PARAMETER :: JGLOB      = 46
      INTEGER, PARAMETER :: LGLOB      = 72         
      INTEGER, PARAMETER :: IIPAR      = IGLOB
      INTEGER, PARAMETER :: JJPAR      = JGLOB
#if   defined( GRIDREDUCED ) 
      INTEGER, PARAMETER :: LLPAR      = 47        ! Reduced vertical grid
      INTEGER, PARAMETER :: LLTROP_FIX = 38        !  -- 47 levels
      INTEGER, PARAMETER :: LLTROP     = 38  
#else
      INTEGER, PARAMETER :: LLPAR      = LGLOB     ! Full vertical grid
      INTEGER, PARAMETER :: LLTROP_FIX = 40        !  -- 72 levels
      INTEGER, PARAMETER :: LLTROP     = 40  
#endif
      REAL*8,  PARAMETER :: PTOP       = 0.01d0

#elif defined( GEOS_5 ) && defined( GRID2x25 )

      !-----------------------------------------------------------------
      ! GEOS-5: 2 x 2.5
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: IGLOB      = 144
      INTEGER, PARAMETER :: JGLOB      = 91
      INTEGER, PARAMETER :: LGLOB      = 72
      INTEGER, PARAMETER :: IIPAR      = IGLOB
      INTEGER, PARAMETER :: JJPAR      = JGLOB
#if   defined( GRIDREDUCED )
      INTEGER, PARAMETER :: LLPAR      = 47        ! Reduced vertical grid
      INTEGER, PARAMETER :: LLTROP_FIX = 38        !  -- 47 levels
      INTEGER, PARAMETER :: LLTROP     = 38  
#else 
      INTEGER, PARAMETER :: LLPAR      = LGLOB     ! Full vertical grid
      INTEGER, PARAMETER :: LLTROP_FIX = 40        !  -- 72 levels
      INTEGER, PARAMETER :: LLTROP     = 40  
#endif
      REAL*8,  PARAMETER :: PTOP       = 0.01d0

#elif defined( GEOS_5 ) && defined( GRID1x125 )

      !-----------------------------------------------------------------
      ! GEOS-5: 1 x 1.25
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: IGLOB      = 288
      INTEGER, PARAMETER :: JGLOB      = 181
      INTEGER, PARAMETER :: LGLOB      = 72
      INTEGER, PARAMETER :: IIPAR      = IGLOB
      INTEGER, PARAMETER :: JJPAR      = JGLOB
#if   defined( GRIDREDUCED )
      INTEGER, PARAMETER :: LLPAR      = 47        ! Reduced vertical grid
      INTEGER, PARAMETER :: LLTROP_FIX = 38        !  -- 47 levels
      INTEGER, PARAMETER :: LLTROP     = 38
#else 
      INTEGER, PARAMETER :: LLPAR      = LGLOB     ! Full vertical grid
      INTEGER, PARAMETER :: LLTROP_FIX = 40        !  -- 72 levels    
      INTEGER, PARAMETER :: LLTROP     = 40
#endif
      REAL*8,  PARAMETER :: PTOP       = 0.01d0

#elif defined( GEOS_5 ) && defined( GRID05x0666 )

      !-----------------------------------------------------------------
      ! GEOS-5: 0.5 x 0.666
      !-----------------------------------------------------------------
#if   defined( NESTED_CH )
      INTEGER, PARAMETER :: IGLOB      = 121       ! NESTED CHINA   0.5x0.666
      INTEGER, PARAMETER :: JGLOB      = 133
      INTEGER, PARAMETER :: LGLOB      = 72
#elif defined( NESTED_NA )
      INTEGER, PARAMETER :: IGLOB      = 151       ! NESTED N.AMER. 0.5x0.666
      INTEGER, PARAMETER :: JGLOB      = 121
      INTEGER, PARAMETER :: LGLOB      = 72
#elif defined( NESTED_EU )
      INTEGER, PARAMETER :: IGLOB      = 121       ! NESTED EUROPE  0.5x0.666
      INTEGER, PARAMETER :: JGLOB      = 81
      INTEGER, PARAMETER :: LGLOB      = 72
#endif
      INTEGER, PARAMETER :: IIPAR      = IGLOB  
      INTEGER, PARAMETER :: JJPAR      = JGLOB
#if   defined( GRIDREDUCED )
      INTEGER, PARAMETER :: LLPAR      = 47        ! Reduced vertical grid
      INTEGER, PARAMETER :: LLTROP_FIX = 38        !  -- 47 levels
      INTEGER, PARAMETER :: LLTROP     = 38
#else
      INTEGER, PARAMETER :: LLPAR      = LGLOB     ! Full vertical grid
      INTEGER, PARAMETER :: LLTROP_FIX = 40        !  -- 72 levels
      INTEGER, PARAMETER :: LLTROP     = 40
#endif
      REAL*8,  PARAMETER :: PTOP       = 0.01d0

#elif defined( MERRA ) && defined( GRID4x5 )

      !-----------------------------------------------------------------
      ! MERRA: 4 x 5
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: IGLOB      = 72
      INTEGER, PARAMETER :: JGLOB      = 46
      INTEGER, PARAMETER :: LGLOB      = 72         
      INTEGER, PARAMETER :: IIPAR      = IGLOB
      INTEGER, PARAMETER :: JJPAR      = JGLOB
#if   defined( GRIDREDUCED ) 
      INTEGER, PARAMETER :: LLPAR      = 47        ! Reduced vertical grid
      INTEGER, PARAMETER :: LLTROP_FIX = 38        !  -- 47 levels
      INTEGER, PARAMETER :: LLTROP     = 38  
#else
      INTEGER, PARAMETER :: LLPAR      = LGLOB     ! Full vertical grid
      INTEGER, PARAMETER :: LLTROP_FIX = 40        !  -- 72 levels 
      INTEGER, PARAMETER :: LLTROP     = 40  
#endif
      REAL*8,  PARAMETER :: PTOP       = 0.01d0

#elif defined( MERRA ) && defined( GRID2x25 )

      !-----------------------------------------------------------------
      ! MERRA: 2 x 2.5
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: IGLOB      = 144
      INTEGER, PARAMETER :: JGLOB      = 91
      INTEGER, PARAMETER :: LGLOB      = 72
      INTEGER, PARAMETER :: IIPAR      = IGLOB
      INTEGER, PARAMETER :: JJPAR      = JGLOB
#if   defined( GRIDREDUCED )
      INTEGER, PARAMETER :: LLPAR      = 47        ! Reduced vertical grid
      INTEGER, PARAMETER :: LLTROP_FIX = 38        !  -- 47 levels
      INTEGER, PARAMETER :: LLTROP     = 38  
#else 
      INTEGER, PARAMETER :: LLPAR      = LGLOB     ! Full vertical grid
      INTEGER, PARAMETER :: LLTROP_FIX = 40        !  -- 72 levels
      INTEGER, PARAMETER :: LLTROP     = 40  
#endif
      REAL*8,  PARAMETER :: PTOP       = 0.01d0

#endif

      !-----------------------------------------------------------------
      ! For GEOS 1x1 files
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: I1x1       = 360
      INTEGER, PARAMETER :: J1x1       = 181

      !-----------------------------------------------------------------
      ! For GEOS 05x0666 files
      !-----------------------------------------------------------------
      INTEGER, PARAMETER :: I05x0666   = 540 
      INTEGER, PARAMETER :: J05x0666   = 361

      !=================================================================
      ! TRACER & EMISSION SPECIES PARAMETERS
      !
      ! NNPAR   = max number of tracers
      ! NEMPARA = max number of anthropogenic emission species
      ! NEMPARB = max number of biogenic      emission species
      !=================================================================
      ! increase NNPAR and NEMPARA an extra amount (hotp 7/31/09)
#if   defined( TOMAS )
      INTEGER, PARAMETER :: NNPAR   = 320   ! For TOMAS (win, bmy, 1/25/10)
#elif defined( APM )
      INTEGER, PARAMETER :: NNPAR   = 154   ! For APM (G. Luo, 3/8/11)
#else
      ! increase NNPAR to 100 (FP 8/2009)
      !INTEGER, PARAMETER :: NNPAR   = 75    ! For non-TOMAS simulations
      INTEGER, PARAMETER :: NNPAR   = 110
#endif

      ! Nempara increased to 26. (fp, 2/8/10)
      ! new emissions HNO3 and O3 (phs)
      !  Add non-biogenic emission species:
      !  BENZ, TOLU, XYLE, C2H2, C2H4, GLYX, MGLY, GLYC, HAC. (tmf, 1/7/09)
      !INTEGER, PARAMETER :: NEMPARA = 21 
      !  Add RCHO, HCOOH, ACTA
      !INTEGER, PARAMETER :: NEMPARA = 26 
      INTEGER, PARAMETER :: NEMPARA = 29

      ! Add biogenic emissions: MBO, MONX. (tmf, 1/7/09) 
!      INTEGER, PARAMETER :: NEMPARB = 3
      INTEGER, PARAMETER :: NEMPARB = 17

      !=================================================================
      ! OTHER PARAMETERS 
      !=================================================================

      ! NVEGTYPE - Maximum number of surface types: 74 olson
      ! NTYPE    - Maximum number of veg types in a CTM grid box
      ! NPOLY    - Number of coefficients for polynomial fits
      INTEGER, PARAMETER :: NVEGTYPE = 74
      INTEGER, PARAMETER :: NTYPE    = 15
      INTEGER, PARAMETER :: NPOLY    = 20

      ! NNSTA = max number of time series stations (in inptr.ctm)
      INTEGER, PARAMETER :: NNSTA = 800

      ! MAXIJ - Maximum number of 1st level grid boxes
      INTEGER, PARAMETER :: MAXIJ = IIPAR * JJPAR

      ! LLCONVM - Max number of layers for convection
      INTEGER, PARAMETER :: LLCONVM = LLPAR - 1

      ! NOXLEVELS = Number of levels of anthro NOx emission 
      !             (e.g. surface and 100m)
      ! NOXEXTENT = Highest sigma level that receives anthro NOx emission 
      INTEGER, PARAMETER :: NOXLEVELS = 2
      INTEGER, PARAMETER :: NOXEXTENT = 2 

      ! MAXFAM -- Max number of families for prod and loss output
      INTEGER, PARAMETER :: MAXFAM = 40

      ! MAXMEM is maximum number of families of prod and loss
      ! moved from input_mod and diag_pl_mod to here (hotp 7/31/09)
      ! MAXMEM also increased from 10 to 20 by FP
      INTEGER, PARAMETER :: MAXMEM = 20

      ! MAXPL increased from 100 to 500 and moved from diag_pl_mod
      ! to here by FP (hotp 7/31/09)
      INTEGER, PARAMETER :: MAXPL = 500


      ! NDUST -- Number of FAST-J aerosol size bins (rvm, bmy, 11/15/01)
      INTEGER, PARAMETER :: NDUST = 7

      ! NAER -- number of other aerosol categories (rvm, bmy, 2/27/02)
      INTEGER, PARAMETER :: NAER = 5

      ! NRH -- number of relative humidity bins (rvm, bmy, 2/27/02)
      INTEGER, PARAMETER :: NRH = 5

      !NBIOMAX -- biomass burning
      ! increase NBIOMAX to 20 (hotp 7/31/09)
      ! increase NBIOMAX to 24 for dicarbonyls (ccc, 2/02/10)
      INTEGER, PARAMETER :: NBIOMAX = 24

#if   defined( TOMAS )

      ! NDSTBIN -- redimensioned for TOMAS (dwest, bmy, 2/1/10)
      INTEGER, PARAMETER :: NDSTBIN   = 30

      ! Number of TOMAS bins 
      INTEGER, PARAMETER :: TOMASBIN  = 30
      INTEGER, PARAMETER :: TOMASSPEC = 8

#else

      ! NDSTBIN -- number of dust size bins for transport (tdf, bmy, 3/31/04)
      INTEGER, PARAMETER :: NDSTBIN   = 4

#endif
!
! !REMARKS:
!  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!  %%% NOTE: THIS WAS MADE INTO A MODULE IN ORDER TO REMOVE COMMON BLOCKS  %%%
!  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!
! !REVISION HISTORY:
!  (1 ) Now set LLTROP = 20 for GEOS-3 (bmy, 4/12/01)
!  (2 ) Eliminated obsolete commented-out code (bmy, 4/20/01)
!  (3 ) Now set MAXFAM = 12 for more P-L families (bmy, 6/28/01)  
!  (4 ) Comment out {IJL}GCMPAR -- these are obosolete (bmy, 9/24/01)
!  (5 ) Also set LLPAR = 30 for GEOS-3, will regrid online (bmy, 9/24/01) 
!  (6 ) Removed obsolete code from 9/01 (bmy, 10/23/01)
!  (7 ) Removed NAIR, LAIREMS, these are now defined 
!        in "aircraft_nox_mod.f" (bmy, 2/14/02)
!  (8 ) Eliminated commented-out code from 2/14/02.  Also added NAER 
!        and NRH parameters for aerosols. (rvm, bmy, 2/27/02)
!  (9 ) Removed IM, JM, IMX, JMX to avoid namespace pollution.  This
!        is needed to get the new TPCORE to work.  Also changed RCS
!        ID tag comment character from "C" to "!" to allow freeform
!        compilation. (bmy, 6/25/02)
!  (10) Removed obsolete code from 6/02 (bmy, 8/26/02)
!  (11) Added NUMDEP_SULF in a common block for sulfate dry deposition. 
!        Also set MAXDEP=31 and NNPAR=31 for coupled fullchem/sulfate
!        simulations. (rjp, bdf, bmy, 11/15/02)
!  (12) Removed I0, J0; these are now superseded by "grid_mod.f"
!        (bmy, 2/11/03)
!  (13) Added parameters for GEOS-4 (bmy, 6/18/03)
!  (14) Now defines both 55 level and 30 level GEOS-4 grids.  Also
!        define LLTROP=19 for GEOS-4 grids.  Also remove obsolete
!        GEOS-2 grid declarations. (bmy, 10/31/03)
!  (15) LLTROP should be 17 for GEOS-4...based on the ND55 diagnostic
!        when computed for 2003 met fields (bmy, 2/18/04)
!  (16) Increase NNPAR from 31 to 39 for carbon & dust tracers.  Also
!        declare NDSTBIN as # of dust bins. (rvm, tdf, bmy, 4/1/04)
!  (17) Increase NNPAR to 41 for seasalt tracers (rjp, bec, bmy, 4/20/04)
!  (18) Increase NNPAR to 50 for SOA tracers (rjp, bmy, 7/15/04)
!  (19) Now use NESTED_CH and NESTED_NA cpp switches to define 
!        parameters for 1x1 nested grids.  Also add parameters for
!        the 1 x 1.25 global grid. (bmy, 12/1/04)
!  (20) Now add parameters for GCAP and GEOS-5 grids.  Remove references
!        to obsolete LGEOSCO and FULLCHEM Cpp switches (bmy, 6/24/05)
!  (21) Now add I1x1 and J1x1 parameters for data on the 1x1 GEOS
!        grid. (bmy, 10/24/05)
!  (22) Increase NNPAR to 52 (bmy, 12/6/05)
!  (23) Increase NNPAR to 54 (dkh, bmy, 5/22/06)
!  (24) Remove support for GEOS-1 and GEOS-STRAT met fields (bmy, 8/4/06)
!  (25) Added variable tropopause case (bmy, phs, bdf, 8/21/06)
!  (26) Set LLTROP to level of first box entirely above 20km for GEOS-3 
!       and GEOS-4 (phS, 9/14/06)
!  (27) Bug fix: set LLTROP_FIX = LLPAR for GCAP (bmy, 11/29/06)
!  (28) Reset vertical coordinates for GEOS-5.  Also renamed GRID30LEV
!        to GRIDREDUCED (bmy, 4/3/07)
!  (29) New parameters for GEOS-5 nested grid (yxw, dan, bmy, 11/6/08)
!  (30) NEMPARA set to 12 to emit O3 and HNO3 (phs, 4/3/08)
!  (31) Add tracers to NNPAR = 73. (tmf, 1/7/09)
!  (32) NEMPARA set to 21 to emit new tracers for GLYX chemistry 
!       (tmf, ccc, 3/2/09)
!  (33) NEMPARB set to 3 to emit MBO, MONX (tmf, ccc, 3/2/09)
!  (34) Added EUROPE grid parameters (amv, 10/19/09)
!  18 Dec 2009 - Aaron van D - Added NESTED_EU grid parameters
!  18 Dec 2009 - R. Yantosca - Added ProTeX headers
!  25 Jan 2010 - R. Yantosca - Set NNPAR=320 for TOMAS simulations
!  25 Jan 2010 - R. Yantosca - Define TOMASBIN and TOMASSPEC for TOMAS sims
!  08 Feb 2010 - F. Paulot   - Increase NNPAR, NEMPARA and NEMPARB
!  08 Feb 2010 - F. Paulot   - Move MAXMEM and MAXPL from diag_pl_mod.
!  30 Nov 2010 - R. Yantosca - Increase LLTROP (from 38 to 40) for GEOS-5 and 
!                              MERRA for the full 72-layer grids (i.e. when
!                              the Cpp switch GRIDREDUCED is not set).
!  09 Mar 2011 - R. Yantosca - Updated NNPAR for APM (G. Luo)
!  23 Aug 2011 - M. Long   - Converted to Module from Header file
!EOP
!------------------------------------------------------------------------------
!BOC
      END MODULE CMN_SIZE_MOD
!EOC
