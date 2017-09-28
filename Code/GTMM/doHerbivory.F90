!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: doHerbivory
!
! !DESCRIPTION: Subroutine doHerbivory calculate herbivory analog to 
!  McNaughton (Science, 1989) as fraction of foliage NPP.
!\\
!\\
! !INTERFACE:
!
SUBROUTINE doHerbivory
!
! !USES:
!
  USE defineConstants
  USE loadCASAinput
  USE defineArrays
  
  IMPLICIT NONE
!
! !REMARKS:
!  Herbivory analog to McNaughton is computed as:
!                                                                             .
!     log C = 2.04*(log NFP)-4.8   -->  C = NFP^2.04*10^(-4.8)
!                                                                             .
!  where C= consumption, NFP = Net foliage production (NPP
!  delivered to leaves)  units kJ/m2/yr
!
! !REVISION HISTORY:
!  09 July 2010 - C. Carouge  - Parallelization.
!EOP
!------------------------------------------------------------------------------
!BOC
! 
! !LOCAL VARIABLES:
!
  INTEGER :: i
  REAL*8  :: herb(n_veg, 1)
  character(len=f_len_output+4) :: filename3
  
  filename3(1:f_len_output)=outputpath
      
  !converting kJ/m2/yr to gC/m2/yr
  !
  !NPP(j/m2/yr)=NPP(gC/m2/yr)*energy content/carbon content
  !where energy content = 1.6*10^4
  !and carbon content = 0.45
  !
  !so 1 gC/m2/yr = 35.5 kJ/m2/yr
  !! 1/35.5 = 0.028
  !

  herb(:,1)=0.0d0
!$OMP PARALLEL DO     &
!$OMP DEFAULT(SHARED) &
!$OMP PRIVATE(i)
  DO i=1, n_veg
     herb(i,1)=0.028d0*(35.5d0*sum(NPP(i,1:12))/2d0)**2.04d0
     herb(i,1)=herb(i,1)*(10d0**(-4.8d0))
     grass_herbivory(i,1)=herb(i,1)
     herb(i,1)=0.0d0
     herb(i,1)=0.028d0*(35.5d0*sum(NPP(i,1:12))/3d0)**2.04d0
     herb(i,1)=herb(i,1)*(10.00d0**(-4.8d0))
     trees_herbivory(i,1)=herb(i,1)
  END DO
!$OMP END PARALLEL DO

  !Seasonality in herbivory is calculated as in Randerson et al
  !(GBC 1996) scaling linearly with npp (66%) with a non zero
  !intercept (33%) representing a minimum consumption limit
  !outside the growing season - scalar is equal for C3 and C4
  !NPP
  herb(1,:)=0.0d0
!$OMP PARALLEL DO     &
!$OMP DEFAULT(SHARED) &
!$OMP PRIVATE(i)
  DO i=1, n_veg
     IF (sum(NPP(i,1:12)) .eq. 0d0) THEN
        herb(i,1)=(0.08333333333d0)
     ELSE
        herb(i,1)=0.666667d0*(NPP(i,mo)/sum(NPP(i,1:12)))+ &
             0.33333d0*0.08333d0
     END IF
  END DO
!$OMP END PARALLEL DO
  herb_seasonality(:,mo)=herb(:,1)
  
  
  IF (yr .eq. NPPequilibriumYear .and. mo .eq. 12) THEN
     filename3(f_len_output+1:f_len_output+4)='fhsn'
     OPEN(UNIT=4, FILE=filename3, STATUS="NEW", &
          FORM="FORMATTED")
     WRITE(4, *) herb_seasonality
     CLOSE(4)
     
     filename3(f_len_output+1:f_len_output+4)='fgrh'
     OPEN(UNIT=4, FILE=filename3, STATUS="NEW", &
          FORM="FORMATTED")
     WRITE(4, *) grass_herbivory
     CLOSE(4)
     
     filename3(f_len_output+1:f_len_output+4)='ftrh'
     OPEN(UNIT=4, FILE=filename3, STATUS="NEW", &
          FORM="FORMATTED")
     WRITE(4, *) trees_herbivory
     CLOSE(4)
  ENDIF
END SUBROUTINE doHerbivory
!EOC
