! $Id: gasconc.f,v 1.2 2010/03/15 19:33:23 ccarouge Exp $
      SUBROUTINE GASCONC( FIRSTCHEM, NTRACER, STT, XNUMOL, FRCLND,
     &                    READ_CSPEC )
!
!******************************************************************************
!  Subroutine GASCONC initializes gas concentrations for SMVGEAR II.
!  (M. Jacobson 1997; bdf, bmy, 4/18/03, 11/19/08)
!
!  NOTES:
!  (1 ) Now reference ABSHUM, AIRDENS, CSPEC, IXSAVE, IYSAVE, IZSAVE,  
!        PRESS3, T3 from "comode_mod.f".  Also now references tracer ID flags
!        from "tracerid_mod.f".  Also removed code that is not needed for
!        GEOS-CHEM.  Now also force double precision with "D" exponents.
!        (bdf, bmy, 4/18/03)
!  (2 ) Remove IRUN -- it's obsolete.  Remove obsolete variables from
!        documentation. (bmy, 7/16/03)
!  (3 ) Now dimension args XNUMOL, STT w/ NTRACER and not NNPAR (bmy, 7/20/04)
!  (4 ) Now remove LPAUSE from the arg list.  Now references ITS_IN_THE_TROP
!        from "tropopause_mod.f". (bmy, 8/22/05)
!  (5 ) Now make sure all USE statements are USE, ONLY.  Also remove 
!        reference to TRACERID_MOD, it's not needed. (bmy, 10/3/05)
!  (6 ) Now zero out the isoprene oxidation counter species (dkh, bmy, 6/1/06)
!  (7 ) Now take care of variable tropopause case.  Also set NCS=NCSURBAN
!        (=1) instead of hardwiring it. (bdf, phs, 10/16/06)
!  (8 ) Now use NUMDEP instead of NDRYDEP(NCS) for the loop limit over drydep 
!        species.  NDRYDEP is the # of rxns in "globchem.dat", and NUMDEP is 
!        the # of drydep species in GEOS-Chem.  The two values may not be the 
!        same. (dbm, phs, 11/19/08)
!  (9 ) Add READ_SPEC in argument list (hotp, 2/26/09)
!  (10) Now CSPEC_FULL is copied to CSPEC depending on 
!       the READ_CSPEC value. (hotp, 2/26/09)
!  (11) For SOA add check for LxRO2y species in globchem.dat and initialise. 
!       (dkh, 03/12/10)
!  18 Oct 2011 - M. Payer    - Do not overwrite CSPEC with CSPEC_FULL prior
!                              to partitioning (D. Henze)
!******************************************************************************
!
      ! References to F90 modules 
      USE COMODE_MOD,     ONLY : ABSHUM, AIRDENS, CSPEC,  IXSAVE
      USE COMODE_MOD,     ONLY : IYSAVE, IZSAVE,  PRESS3, T3
      USE COMODE_MOD,     ONLY : CSPEC_FULL, JLOP
      USE DRYDEP_MOD,     ONLY : NUMDEP
      USE TROPOPAUSE_MOD, ONLY : ITS_IN_THE_TROP, COPY_FULL_TROP
      USE TROPOPAUSE_MOD, ONLY : SAVE_FULL_TROP
      USE LOGICAL_MOD,    ONLY : LVARTROP
      USE DAO_MOD,        ONLY : T
      USE PRESSURE_MOD,   ONLY : GET_PCENTER
      USE ERROR_MOD,      ONLY : ERROR_STOP ! (dkh, 10/06/06)  
      USE LOGICAL_MOD,    ONLY : LSOA ! (dkh, 10/06/06)  
      
      USE CMN_SIZE_MOD       ! Size parameters
      USE COMODE_LOOP_MOD       ! SMVGEAR II arrays

      IMPLICIT NONE
#     include "define.h"

      ! Arguments
      LOGICAL, INTENT(IN)     :: FIRSTCHEM
      INTEGER, INTENT(IN)     :: NTRACER
      REAL*8,  INTENT(INOUT)  :: STT(IIPAR,JJPAR,LLPAR,NTRACER)
      REAL*8,  INTENT(IN)     :: XNUMOL(NTRACER)
      REAL*8,  INTENT(IN)     :: FRCLND(IIPAR,JJPAR)
      ! cspecrestart hotp 2/25/09
      LOGICAL, INTENT(IN)     :: READ_CSPEC
!
! *********************************************************************
! ************       WRITTEN BY MARK JACOBSON (1991-4)     ************
! ***            (C) COPYRIGHT, 1991-4 BY MARK Z. JACOBSON          *** 
! ***                          (650) 723-6836                       *** 
! *********************************************************************
!
!    GGGGGG      A       SSSSSS   CCCCCC   OOOOO   N     N   CCCCCC  
!   G           A A     S        C        O     O  N N   N  C  
!   G  GGGG    A   A    SSSSSSS  C        O     O  N  N  N  C   
!   G     G   AAAAAAA         S  C        O     O  N   N N  C    
!    GGGGGG  A       A  SSSSSS    CCCCCC   OOOOO   N     N   CCCCCC    
!
! *********************************************************************
! ******       INITIALIZE GAS CONCENTRATIONS IN THE MODEL        ******
! ***********       AND SET MISCELLANEOUS PARAMETERS         ********** 
! *********************************************************************
!
! *********************************************************************
! * SET THE CONCENTRATION  (# CM-3) OF ACTIVE AND INACTIVE GASES      *
! *********************************************************************
!
! NTLOOP    = NUMBER OF GRID-CELLS IN THE ENTIRE GRID-DOMAIN
! NTSPECGAS = NUMBER OF ACTIVE PLUS INACTIVE GASES
! NVERT     = NUMBER OF VERTICAL LAYERS.  
!
! QBKGAS    = INITIAL BACKGROUND CONCENTRATION (VOL MIXING RATIO) 
! RHO3      = G-AIR CM-3-AIR
! C(GAS)    = GAS CONCENTRATION IN A GIVEN GRID-CELL (# CM-3)
!
      ! Local variables
      INTEGER :: IX, IY, IZ, N, NK, JJ
      INTEGER :: JGAS,JLOOP,NGASMIX,JALTS,K,J,NM,L,JN,MLOOP,I
      INTEGER :: IPCOMPAR,JRUN,JNEW,JOLD,NGCOUNT,IAVG,KN,SUM,SUM1
      REAL*8  :: PMBCEN,PBELOW,PABOVE,ALNPRES,PS,ALNCONC,AVMIX,S1CON
      REAL*8  :: S2CON,GRCONC1,GRCONC2,GRCONC3,SUMRMS,SUMFRACS,QNEW
      REAL*8  :: QACC,FRACDIF,FRACABS,AVGERR,RMSCUR
      REAL*8  :: TK,CONSEXP,VPRESH2O,CONST

      !=================================================================
      ! GASCONC begins here!
      !=================================================================

      ! Set NCS=NCSURBAN here since we have defined our tropospheric
      ! chemistry mechanism in the urban slot of SMVGEAR II
      NCS = NCSURBAN

      !=================================================================
      ! First time through here, copy initial conditions from QBKCHEM
      ! to CSPEC() for each grid box.  QBKCHEM stores the default
      ! background concentrations for species in the file "chem.dat".
      !=================================================================
      IF ( FIRSTCHEM ) THEN

         ! Loop over species
         DO 28 JGAS = 1, NTSPEC(NCS)

            !===========================================================
            ! For methanol (MOH), now use different initial background
            ! concentrations for different regions of the atmosphere:
            !
            ! (a) 2.0 ppbv MOH -- continental boundary layer
            ! (b) 0.9 ppbv MOH -- marine boundary layer
            ! (c) 0.6 ppbv MOH -- free troposphere
            !
            ! The concentrations listed above are from Heikes et al,
            ! "Atmospheric methanol budget and ocean implication",
            ! _Global Biogeochem. Cycles_, submitted, 2002.  These
            ! represent the best estimates for the methanol conc.'s
            ! in the troposphere based on various measurements.
            !
            ! MOH is an inactive chemical species in GEOS-CHEM, so
            ! these initial concentrations will never change.  However,
            ! MOH acts as a sink for OH, and therefore will affect both
            ! the OH concentration and the methylchloroform lifetime.
            !
            ! We specify the MOH concentration as ppbv, but then we
            ! need to multiply by PRESS3(JLOOP) / ( T3(JLOOP) * BK )
            ! in order to convert to [molec/cm3].  (bdf, bmy, 2/22/02)
            !===========================================================
            IF ( NAMEGAS(JGAS) == 'MOH' ) THEN

               ! Loop over all potential tropospheric boxes
               DO IZ = 1, LLTROP
               DO IY = 1, JJPAR
               DO IX = 1, IIPAR

                  ! Conversion factor
                  CONST = GET_PCENTER(IX,IY,IZ)*1000D0/(T(IX,IY,IZ)*BK)
                
                  !------------------------------
                  ! Test for altitude
                  ! IZ < 9 is always in the trop.
                  !------------------------------
                  IF ( IZ <= 9 ) THEN

                     !---------------------------
                     ! Test for ocean/land boxes
                     !---------------------------
                     IF ( FRCLND(IX,IY) >= 0.5 ) THEN

                         ! Continental boundary layer: 2 ppbv MOH
                        CSPEC_FULL(IX,IY,IZ,JGAS) = 2.000d-9 * CONST

                        ! Make sure MOH conc. is not negative (SMAL2 = 1d-99)
                        CSPEC_FULL(IX,IY,IZ,JGAS) = 
     &                       MAX(CSPEC_FULL(IX,IY,IZ,JGAS),SMAL2)

                     ELSE

                        ! Marine boundary layer: 0.9 ppbv MOH
                        CSPEC_FULL(IX,IY,IZ,JGAS) = 0.900d-9 * CONST

                        ! Make sure MOH conc. is not negative (SMAL2 = 1d-99)
                        CSPEC_FULL(IX,IY,IZ,JGAS) = 
     &                       MAX(CSPEC_FULL(IX,IY,IZ,JGAS),SMAL2)
                     ENDIF

                  ELSE

                     !---------------------------
                     ! Test for troposphere
                     !---------------------------
                     IF ( ITS_IN_THE_TROP( IX, IY, IZ ) ) THEN
                      
                        ! Free troposphere: 0.6 ppbv MOH
                        CSPEC_FULL(IX,IY,IZ,JGAS) = 0.600d-9 * CONST

                        ! Make sure MOH conc. is not negative (SMAL2 = 1d-99)
                        CSPEC_FULL(IX,IY,IZ,JGAS) = 
     &                       MAX(CSPEC_FULL(IX,IY,IZ,JGAS),SMAL2)

                     ELSE

                        ! Stratosphere: set MOH conc. to SMAL2 = 1d-99
                        CSPEC_FULL(IX,IY,IZ,JGAS) = SMAL2
                     ENDIF
                  ENDIF
               ENDDO
               ENDDO
               ENDDO

            ELSE

               !========================================================
               ! Set default initial conc. for species other than
               ! Methanol (MOH) in mixing ratios units
               !========================================================

               DO IZ = 1, LLTROP         
               DO IY = 1, JJPAR
               DO IX = 1, IIPAR

                  ! Conversion factor
                  CONST = GET_PCENTER(IX,IY,IZ)*1000D0/(T(IX,IY,IZ)*BK)
                
                  ! Copy default background conc. from "globchem.dat" to CSPEC
                  CSPEC_FULL(IX,IY,IZ,JGAS) = QBKCHEM(JGAS,NCS)* CONST

                  ! Make sure concentration is not negative (SMAL2 = 1d-99)
                  CSPEC_FULL(IX,IY,IZ,JGAS) = 
     &                 MAX(CSPEC_FULL(IX,IY,IZ,JGAS),SMAL2)

                  ! For emission species, don't do unit conversion
                  IF (NAMEGAS(JGAS).EQ.'EMISSION') THEN
                     CSPEC_FULL(IX,IY,IZ,JGAS) = QBKCHEM(JGAS,NCS)
                  ENDIF
               ENDDO
               ENDDO
               ENDDO
            ENDIF
 28      CONTINUE
      ENDIF        !(FIRSTCHEM)
      
      ! If it's the first chemistry timestep then we need to copy the
      ! concentrations from CSPEC_FULL into CSPEC.  We also need to do
      ! this on subsequent chemistry timesteps if the variable tropopause
      ! is turned on. (bdf, phs, bmy, 10/3/06)
      ! NOTE : 
      ! (1 ) copy CSPEC_FULL to CSPEC depending on READ_CSPEC (hotp, 2/25/09)

!-----------------------------------------------------------------------
! Prior to 10/18/11:
! Do not overwrite CSPEC with CSPEC_FULL prior to partitioning 
! (dkh, mpayer, 10/18/11)
!      ! IF ( LVARTROP .or. FIRSTCHEM ) CALL COPY_FULL_TROP
!
!      IF ( LVARTROP .or. FIRSTCHEM .or. READ_CSPEC ) CALL COPY_FULL_TROP
!-----------------------------------------------------------------------
      IF ( FIRSTCHEM .or. READ_CSPEC ) CALL COPY_FULL_TROP

!  ********************************************************************
!  *            Update starting concentrations for plumes             *
!  ********************************************************************
!

! currently only partition species in full chemistry.
!   should be added as needed to other chemistries.
!      if (NCS .eq. 1) then
!  maybe??
      CALL PARTITION( NTRACER, STT, XNUMOL ) 
!      endif

! 
! *********************************************************************
! *              zero out dry deposition counter species              *
! *********************************************************************

      ! Set NCS=NCSURBAN here since we have defined our tropospheric
      ! chemistry mechanism in the urban slot of SMVGEAR II
      NCS = NCSURBAN

      DO 130 N = 1,NUMDEP
         NK = NTDEP(N)
         IF (NK.EQ.0) GOTO 130
         JJ = IRM(NPRODLO+1,NK,NCS)
         !write(6,*) 'value of drydep reactions in cspec= ',jj
         IF (JJ.LE.0) GOTO 130
         DO 135 JLOOP = 1,NTTLOOP
            CSPEC(JLOOP,JJ) = 0.0D0
 135     CONTINUE
 130  CONTINUE

!
! *********************************************************************
! *           INITIALIZE H2O (# CM-3) IF H2O IS INACTIVE              *
! *********************************************************************
! VPRESH2O = SATURATION VAPOR PRESSURE OVER H2O (# CM-3)
! ABSHUM   = ABSOLUTE HUMIDITY (molec cm^-3) [input] (ABSHUM)
! ABSHUM   = RELATIVE HUMIDITY (FRACTION)    [output]
! TK       = TEMPERATURE (K)
!
      IF (IH2O.GT.NGAS) THEN
         DO 33 JLOOP    = 1, NTTLOOP
            TK            = T3(JLOOP)
            CONSEXP       = 17.2693882D0 * (TK - 273.16D0) /
     1           (TK - 35.86D0)
            VPRESH2O      = CONSVAP * EXP(CONSEXP) / TK 
            CSPEC(JLOOP,IH2O) = ABSHUM(JLOOP)
!     then calculate R.H.
            ABSHUM(JLOOP) = CSPEC(JLOOP,IH2O) / VPRESH2O 
!            write(297,*) 'in initgas',jloop,abshum(jloop)
 33      CONTINUE
      ENDIF

! *********************************************************************
! *           INITIALIZE O2 (# CM-3) IF O2 IS INACTIVE                *
! *********************************************************************
! AIRDENS = AIR DENSITY (G CM-3)
! OXYCONS = (# G-1) CONVERSION OF O2 FROM G CM-3 TO # CM-3
!
      IF (IOXYGEN.GT.NGAS) THEN
         OXYCONS           = 0.2095d0
         DO 260 JLOOP      = 1, NTLOOP
 260        CSPEC(JLOOP,IOXYGEN) = AIRDENS(JLOOP) * OXYCONS
      ENDIF
 999  format(E10.3)

!
! *********************************************************************
! *           ZERO OUT ISOPRENE OXIDATION COUNTER SPECIES
! *                     (dkh, bmy, 6/1/06)  
! *********************************************************************
! LISOPOH  = Dummy variable for tracking loss of isoprene due to rxn w/ OH
! ILISOPOH = Location of LISOPOH in CSPEC 
!
      IF ( ILISOPOH > 0 ) THEN
         DO JLOOP = 1, NTLOOP
            CSPEC(JLOOP,ILISOPOH) = 0d0
         ENDDO
      ENDIF 
!
! *********************************************************************
! *           zero out aromatic oxidation counter species
! *            (dkh, 10/06/06)  
! *********************************************************************
! LBRO2H  Counter for oxidation of BRO2 by HO2
! LBRO2N  Counter for oxidation of BRO2 by NO
! LTRO2H  Counter for oxidation of TRO2 by HO2
! LTRO2N  Counter for oxidation of TRO2 by NO
! LXRO2H  Counter for oxidation of XRO2 by HO2
! LXRO2N  Counter for oxidation of XRO2 by NO
! ILBRO2H Location of LBRO2H in CSPEC
! ILBRO2N Location of LBRO2N in CSPEC
! ILTRO2H Location of LTRO2H in CSPEC
! ILTRO2N Location of LTRO2N in CSPEC
! ILXRO2H Location of LXRO2H in CSPEC
! ILXRO2N Location of LXRO2N in CSPEC
!

      ! Check if we have 2dy organic aerosols
      IF ( LSOA ) THEN

         ! Check to make sure that LxRO2y has been listed in globchem.dat
         IF ( ILBRO2H > 0 .and.
     &        ILBRO2N > 0 .and.
     &        ILTRO2H > 0 .and.
     &        ILTRO2N > 0 .and.
     &        ILXRO2H > 0 .and.
     &        ILXRO2N > 0  ) THEN

            ! Reset value of LISOPOH to zero 
            DO JLOOP      = 1, NTLOOP
               CSPEC(JLOOP,ILBRO2H) = 0d0
               CSPEC(JLOOP,ILBRO2N) = 0d0
               CSPEC(JLOOP,ILTRO2H) = 0d0
               CSPEC(JLOOP,ILTRO2N) = 0d0
               CSPEC(JLOOP,ILXRO2H) = 0d0
               CSPEC(JLOOP,ILXRO2N) = 0d0
            ENDDO

         ! Exit with an error message if it is not. 
         ELSE

            CALL ERROR_STOP( ' LRO2 not defined! ',
     &                       ' Stop in gasconc.f' )

         ENDIF

      ENDIF
!
! *********************************************************************
! *             SUM UP INITIAL GAS MASSES OVER ENTIRE GRID            *
! *********************************************************************
! GQSUMINI(JGAS)  = INITIAL # MOLECULES, OVER THE ENTIRE GRID
! QSUMINIT        = SUM OF ALL ME OR IM # OVER GRID
!                    SUM OF ALL MEVF OR IMVF CM3 OVER GRID
! GRIDVH          = VOLUME OF A GRID-CELL (CM**3)
!

!       DO 800 JGAS      = 1, NTSPECGAS
!        GQSUMINI(JGAS)  = 0. 
!        DO 800 JLOOP    = 1, NTLOOP
!         GQSUMINI(JGAS)=GQSUMINI(JGAS)+CSPEC(JLOOP,JGAS)*GRIDVH(JLOOP) 
! 800   CONTINUE
!
! *********************************************************************
! *                    IDENTIFY GASES FOR PRINTING                    *
! *********************************************************************
!
      NUMPRG            = 0 
      DO 290 JGAS       = 1, NTSPECGAS
       JST              = NAMEGAS(JGAS)
       IF (APGASA.EQ.JST) IFPRGAS(JGAS) = 2 
       IF (APGASB.EQ.JST) IFPRGAS(JGAS) = 2  
       IF (APGASC.EQ.JST) IFPRGAS(JGAS) = 2 
       IF (APGASD.EQ.JST) IFPRGAS(JGAS) = 2 
       IF (APGASE.EQ.JST) IFPRGAS(JGAS) = 2 
       IF (APGASF.EQ.JST) IFPRGAS(JGAS) = 2  
       IF (APGASG.EQ.JST) IFPRGAS(JGAS) = 2 
       IF (APGASH.EQ.JST) IFPRGAS(JGAS) = 2 
       IF (IFPRGAS(JGAS).GE.1) THEN
        NUMPRG                          = NUMPRG + 1
        LGNUM(NUMPRG)                   = JGAS 
       ENDIF
 290  CONTINUE
!
 370  FORMAT(25X,0PF6.4/) 
 380  FORMAT(A14,1X,1PE10.4,I5,I7)
!
! *********************************************************************
! ****          PRINT OUT INITIAL CONCENTRATION INFORMATION        ****
! *********************************************************************
!
      NCS         =  1
!
      IF (ITESTGEAR.EQ.2) THEN
       WRITE(KCPD,810) 0.,0.,(NAMENCS(INEWOLD(I,NCS),NCS),
     1        CSPEC(LLOOP,INEWOLD(I,NCS)), I = 1, ISCHANG(NCS))
       WRITE(KCPD,820)
      ENDIF
!
 810  FORMAT('CONC (# CM-3) AT TIME=',1PE10.2,' SECONDS. ',  
     l       'STEP=',E10.2,' . RUN =',I3/3(A13,'=',E11.4,1X))
 820  FORMAT('END')
!
! *********************************************************************
! ********** READ DATA FOR TESTING RESULTS FROM CHEMISTRY *************
! *********************************************************************
! CSPEC(), GEARCONC ARE # CM-3 FOR GASES
!
      IF (ITESTGEAR.EQ.1) THEN
       IPCOMPAR    = 0  
       JRUN        = 0 
       WRITE(6,*)
       WRITE(6,*)'GEAR-CODE CONCENTRATIONS TO TEST'
       READ(KCPD,450) HEADING
 470   READ(KCPD,460) RINP(1), GRCONC1, RINP(2), GRCONC2, 
     1              RINP(3), GRCONC3  
       IF (RINP(1).NE.'END') THEN
        DO 480 JNEW = 1, ISCHANG(NCS)
         JOLD       = INEWOLD(JNEW,NCS)
         JST        = NAMENCS(JOLD,NCS)
         IF (JST.EQ.RINP(1)) GEARCONC(JNEW,JRUN,NCS) = GRCONC1
         IF (JST.EQ.RINP(2)) GEARCONC(JNEW,JRUN,NCS) = GRCONC2
         IF (JST.EQ.RINP(3)) GEARCONC(JNEW,JRUN,NCS) = GRCONC3
 480    CONTINUE
        GOTO 470 
       ELSE
        IF (IPCOMPAR.EQ.1) THEN
         WRITE(6,450) HEADING
         WRITE(6,460)(NAMENCS(INEWOLD(JNEW,NCS),NCS),
     1                GEARCONC(JNEW,JRUN,NCS), JNEW = 1, ISCHANG(NCS)) 
        ENDIF
!
! COMPARE INITIAL CONDITIONS OF GEAR DATA TO chem.dat DATA
!
        IF (JRUN.EQ.0) THEN
         IF (IPCOMPAR.EQ.1) WRITE(6,475)
!
         SUMRMS      = 0.d0
         SUMFRACS    = 0.d0
         NGCOUNT     = 0
!
         DO 485 JNEW = 1, ISCHANG(NCS)
          JOLD       = INEWOLD(JNEW,NCS)
          QNEW       = QBKCHEM(JOLD,NCS) 
          QACC       = GEARCONC(JNEW,0,NCS) 
!
          IF (QACC.EQ.0.AND.QNEW.NE.0.) THEN
           WRITE(6,465) NAMEGAS(JOLD) 
           STOP 
          ENDIF 
!
          IF (QNEW.GT.1.0d-20) THEN
           FRACDIF   = (QNEW - QACC)/QACC
           FRACABS   = ABS(FRACDIF)
           SUMFRACS  = SUMFRACS + FRACABS 
           SUMRMS    = SUMRMS   + FRACABS * FRACABS
           NGCOUNT   = NGCOUNT + 1
           IAVG      = 1
          ELSE
           FRACDIF   = 0.d0
           IAVG      = 0
          ENDIF
          IF (IPCOMPAR.EQ.1) 
     1    WRITE(6,495) NAMENCS(JOLD,NCS),QACC,QNEW,
     2                 FRACDIF*100, IAVG
 485     CONTINUE
!
         AVGERR      = 100.d0 * SUMFRACS     / NGCOUNT  
         RMSCUR      = 100.d0 * SQRT(SUMRMS  / NGCOUNT)
         WRITE(6,505) JRUN, AVGERR, NGCOUNT  
!
        ENDIF
!       ENDIF JRUN.EQ.0
!
        JRUN        = JRUN + 1
        IF (GRCONC1.EQ.0.) THEN 
         READ(KCPD,450) HEADING
         GOTO 470 
        ENDIF
        IF (JRUN.GT.MXHOLD) THEN
         WRITE(6,*)'JSPARSE: JRUN > MXHOLD'
         STOP
        ENDIF
       ENDIF
      ENDIF
!
 475  FORMAT(4X,'SPECIES',5X,'GEARCONC     chem.dat    % ERROR IFAVG')
 495  FORMAT(A14,2(1X,1PE11.4),2X,0PF8.2,'%',3X,I1)
 505  FORMAT(I3,37X,F8.2,'%   AVERAGE OF ',I5,' SPECIES')
 450  FORMAT(A76) 
 460  FORMAT(3(A13,1X,1PE11.4,1X))
 465  FORMAT('GASCONC: AN INITIAL CONCENTRATION FROM compare.dat '/
     1       'DOES NOT MATCH THAT FROM globchem.dat. CHECK WHETHER '/
     2       'THE CONDITIONS FOR THIS RUN (ITESTGEAR = 1) ARE THE '/
     3       'SAME FOR THE CONDITIONS FOR THE RUN WITH ITESTGEAR=2. '/
     4       'OTHERWISE, TURN ITESTGEAR = 0 OR 2. ',A14)   
!
! *********************************************************************
! ********************* END OF SUBROUTINE GASCONC *********************
! *********************************************************************
!
      RETURN
      END SUBROUTINE GASCONC

