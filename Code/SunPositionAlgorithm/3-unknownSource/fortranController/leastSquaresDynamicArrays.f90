double precision function leastSquaresFortranDA(inputFileName, numRows, iterations, solutionRa, solutionDec, totalEstimatedError)
	implicit none

	!! NUM ROWS IS NOT USED FOR THIS VERSION, THIS IS THE DYNAMIC VERSION!!!! (A bit slower maybe? should test)

	!! Parameters
	double precision, parameter :: PI = datan(1.d0)*4.d0
	double precision, parameter :: COSINE_THRESHOLD = -0.1

	character(len=20), intent(in) :: inputFileName
	double precision :: rxyPearsonCoefficient
	integer, intent(in) :: numRows, iterations
	double precision :: solutionRa, solutionDec, totalEstimatedError

	call iterateLeastSquares()
	! print *, "_________________"
	! call leastSquares(1)

	rxyPearsonCoefficient = 23232
	return

	contains
		subroutine addToList(array, element)
			implicit none

			integer :: i, oldSize
			double precision, intent(in) :: element
			double precision, dimension(:), allocatable, intent(inout) :: array
			double precision, dimension(:), allocatable :: tmpArray

			if(allocated(array)) then
				oldSize = size(array)
				allocate(tmpArray(0:oldSize))

				! Copy the original content of the array
				tmpArray(0:oldSize) = array(0:oldSize)

				! "Append" the new row
				tmpArray(oldSize) = element

				deallocate(array)
				call move_alloc(tmpArray, array)
			else
				allocate(array(0:0))
				array(0) = element
			end if
		end subroutine addToList

		! Function made specifically for this case
		subroutine addRowToArray(array, element0, element1, element2, element3)
			implicit none

			integer :: i, oldSize
			double precision, intent(in) :: element0, element1, element2, element3
			double precision, dimension(:, :), allocatable, intent(inout) :: array
			double precision, dimension(:, :), allocatable :: tmpArray


			if(allocated(array)) then
				! Allocate one more row to the tmpArray
				oldSize = size(array,1)
				allocate(tmpArray(0:oldSize, 0:3)) 

				! Copy the original content of the array
				tmpArray(0:oldSize,0:3) = array(0:oldSize,0:3)

				! "Append" the new row
				tmpArray(oldSize,0) = element0
				tmpArray(oldSize,1) = element1
				tmpArray(oldSize,2) = element2
				tmpArray(oldSize,3) = element3

				! Free the previous array and store the new data in it
				deallocate(array)
				call move_alloc(tmpArray, array)
			else
				allocate(array(0:0, 0:3))
				array(0,0) = element0
				array(0,1) = element1
				array(0,2) = element2
				array(0,3) = element3
			end if
		end subroutine addRowToArray

		subroutine iterateLeastSquares()
			implicit none
			integer :: iteration
			double precision :: bestRa, bestDec, bestError
			
			bestError = 100

			do iteration = 0, iterations-1
				call leastSquares(iteration, solutionRa, solutionDec)
				if (totalEstimatedError <= bestError) then
					bestError = totalEstimatedError
					bestRa = solutionRa
					bestDec = solutionDec
				end if
				print *, "Iteration: ", iteration, " | Ra, Dec: ", solutionRa, solutionDec, " Error : ", totalEstimatedError
			end do

			! Return the best solution
			totalEstimatedError = bestError
			solutionRa = bestRa
			solutionDec = bestDec
			print *, "BEST | Ra, Dec: ", solutionRa, solutionDec, " Error : ", totalEstimatedError
		end subroutine iterateLeastSquares

		subroutine leastSquares(iteration, solutionRa, solutionDec)
			implicit none
			integer, intent(in) :: iteration
			double precision :: solutionRa, solutionDec
			double precision, dimension(:), allocatable :: matrixVTEC
			double precision, dimension (:,:), allocatable :: matrixIPP
			double precision, dimension (0:3) :: solution
			integer :: vtecSize, i

			call storeMatrixData(matrixVTEC, matrixIPP, iteration, solutionRa, solutionDec)
			call printMatrices(matrixVTEC, matrixIPP)

			call matrixComputations(solution, matrixIPP, matrixVTEC)
			deallocate(matrixVTEC)
			deallocate(matrixIPP)
			call obtainSourceLocation(solution, solutionRa, solutionDec)
		end subroutine leastSquares

		subroutine storeMatrixData(matrixVTEC, matrixIPP, iteration, solutionRa, solutionDec)
			implicit none
			integer, intent(in) :: iteration
			double precision, intent(in) :: solutionRa, solutionDec
			double precision, dimension(:), allocatable, intent(out) :: matrixVTEC
			double precision, dimension (:,:), allocatable, intent(out) :: matrixIPP
			double precision :: vtec, raIPP, decIPP
			double precision :: xIPP, yIPP, zIPP
			integer :: i, validSample, nUsedSamples

			nUsedSamples = 0

			call openFile(inputFileName)

			do i = 0, numRows
				read (1, *, end = 240) vtec, raIPP, decIPP
				validSample = 1

				if (iteration /= 0) then
					validSample = checkOutlier(solutionRa, solutionDec, raIPP, decIPP)
				end if

				if (validSample == 1) then
					nUsedSamples = nUsedSamples + 1
					call computeComponentsIPP(raIPP, decIPP, xIPP, yIPP, zIPP)
					call addToList(matrixVTEC, vtec)
					vtec = 1 ! To avoid declaring another var
					call addRowToArray(matrixIPP, xIPP, yIPP, zIPP, vtec)
				else
					vtec = 0
					xIPP = 0
					yIPP = 0
					zIPP = 0
				end if
				
				! matrixVTEC(i) = vtec
				! matrixIPP(i, 0) = xIPP
				! matrixIPP(i, 1) = yIPP
				! matrixIPP(i, 2) = zIPP
				! matrixIPP(i, 3) = 1
			end do
			240 continue
			! print *, "Number of used samples: ", nUsedSamples
			close(1)
		end subroutine storeMatrixData

		! subroutine matrixComputationsLapack(solution, A, Y)
		! 	implicit none
		! 	double precision, dimension (0:3), intent(out) :: solution
		! 	double precision, dimension (:), intent(in) :: Y
		! 	double precision, dimension (:, :) :: A
		! 	double precision, dimension (:,:) :: transposedA, innerMat
		! 	double precision, dimension (:,:) :: invMult
		! 	double precision, dimension(size(A,1)) :: work  ! work array for LAPACK
		! 	integer :: n, info

		! 	external DGELS

		! 	call DGELS('N', numRows, 4, 1, A, numRows, Y, numRows, work, numRows, info)

		! 	if (info /= 0) then
		! 		stop 'Matrix is numerically singular!'
		! 	end if
		! end subroutine matrixComputationsLapack

		subroutine matrixComputations(solution, A, Y)
			implicit none
			double precision, dimension (0:3), intent(out) :: solution
			double precision, dimension (:), intent(in) :: Y
			double precision, dimension (:,:), intent(in) :: A
			double precision, dimension (0:3,size(A,1)) :: transposedA
			double precision, dimension (0:3, 0:3) :: covMat

			transposedA = transpose(A)
			covMat = inv(matmul(transposedA, A))
			totalEstimatedError = sqrt(covMat(0,0)) + sqrt(covMat(1,1)) + sqrt(covMat(2,2))
			! print *, totalEstimatedError
			
			solution = matmul(matmul(covMat, transposedA), y) ! esto dejarlo mas bonito???
		end subroutine matrixComputations

		subroutine obtainSourceLocation(solution, solutionRa, solutionDec)
			double precision, dimension (0:3), intent(in) :: solution
			double precision, intent(out) :: solutionRa, solutionDec
			double precision :: a, b, g, mod, radianRa, radianDec
			double precision :: X, Y, Z

			a = solution(0)
			b = solution(1)
			g = solution(2)

			mod = sqrt(a*a + b*b + g*g)
			! print *, "Gradient: ", mod ! Pendiente

			X = a/mod
			Y = b/mod
			Z = g/mod

			radianRa = datan2(Y,X)
			radianDec = dasin(Z)

			if (radianRa < 0) then
				radianRa = radianRa + 2*PI
			end if

			solutionRa = toDegree(radianRa)
			solutionDec = toDegree(radianDec)
		end subroutine obtainSourceLocation

		integer function checkOutlier(solutionRa, solutionDec, raIPP, decIPP)
			implicit none
			double precision, intent(in) :: solutionRa, solutionDec, raIPP, decIPP
			double precision :: sourceZenithAngle
			integer :: validSample, returnValue

			sourceZenithAngle = computeSourceZenithAngle (solutionRa, solutionDec, raIPP, decIPP)
			if (sourceZenithAngle >= COSINE_THRESHOLD) then
				validSample = 1
			else
				validSample = 0
			end if
			returnValue = validSample
			return
		end function checkOutlier

		double precision function computeSourceZenithAngle (raSource, decSource, raIPP, decIPP)
			implicit none
			double precision, intent(in) :: raSource, decSource, raIPP, decIPP
			double precision :: sourceZenithAngle

			sourceZenithAngle = sin(decIPP)*sin(decSource) + cos(decIPP)*cos(decSource)*cos(raIPP - raSource)
			return
		end function computeSourceZenithAngle

		subroutine computeComponentsIPP(ra, dec, xIPP, yIPP, zIPP)
			implicit none
			double precision, intent(in) :: ra, dec
			double precision :: raRad, decRad
			double precision, intent(out) :: xIPP, yIPP, zIPP

			raRad = toRadian(ra)
			decRad = toRadian(dec)

			xIPP = cos(decRad)*cos(raRad)
			yIPP = cos(decRad)*sin(raRad)
			zIPP = sin(decRad)

			return
		end subroutine computeComponentsIPP

		double precision function toRadian(degree)
		  implicit none
		  double precision, intent(in) :: degree
		  double precision :: radians

		  radians = (degree*PI)/180
		  return
		end function toRadian

		double precision function toDegree(radians)
		  implicit none
		  double precision, intent(in) :: radians
		  double precision :: degree

		  degree = (radians*180/PI)
		  return
		end function toDegree

		! subroutine inverse(A, invA)
		! 	implicit none

		! 	external DGETRI

		! 	double precision, dimension (0:numRows, 0:3), intent(in) :: A
		! 	double precision, dimension (0:numRows, 0:3), intent(out) :: invA

		! 	call DGETRI(3, invA, 3, ipiv, work, n, info)


		! end subroutine

		! Returns the inverse of a matrix calculated by finding the LU
		! decomposition.  Depends on LAPACK.
		function inv(A) result(Ainv)
			double precision, dimension(:,:), intent(in) :: A
			double precision, dimension(size(A,1),size(A,2)) :: Ainv

			double precision, dimension(size(A,1)) :: work  ! work array for LAPACK
			integer, dimension(size(A,1)) :: ipiv   ! pivot indices
			integer :: n, info

			! External procedures defined in LAPACK
			external DGETRF
			external DGETRI

			! Store A in Ainv to prevent it from being overwritten by LAPACK
			Ainv = A
			n = size(A,1)

			! DGETRF computes an LU factorization of a general M-by-N matrix A
			! using partial pivoting with row interchanges.
			call DGETRF(n, n, Ainv, n, ipiv, info)

			if (info /= 0) then
				stop 'Matrix is numerically singular!'
			end if

			! DGETRI computes the inverse of a matrix using the LU factorization
			! computed by DGETRF.
			call DGETRI(n, Ainv, n, ipiv, work, n, info)

			if (info /= 0) then
				stop 'Matrix inversion failed!'
			end if
		end function inv

		subroutine openFile(inputFileName)
			implicit none
			character(len = 20), intent(in) :: inputFileName
			integer :: status ! I/O status: 0 for success

			open (unit = 1, file = inputFileName, status='old', action='read', iostat=status)

		   	if (status /= 0) then 
				write (*, 1040) status
				1040 format (1X, 'File open failed, status = ', I6)
			end if
		end subroutine openFile

		subroutine printMatrices(matrixVTEC, matrixIPP)
			implicit none
			double precision, dimension (:), intent(in) :: matrixVTEC
			double precision, dimension (:, :), intent(in) :: matrixIPP
			integer :: vtecSize, i

			vtecSize = size(matrixVTEC)
			! do i = 0, vtecSize-1
			! 	print *, "VTEC:", matrixVTEC(i), "|IPP:", matrixIPP(i,1), matrixIPP(i,2), matrixIPP(i,3), matrixIPP(i,4)
			! end do
			print *, "size: ", vtecSize
		end subroutine printMatrices
end function leastSquaresFortranDA

