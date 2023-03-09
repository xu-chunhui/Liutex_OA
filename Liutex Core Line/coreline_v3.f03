program main
!!!=================================================================================================
!!! Liutex Core Line generation program.
!!! 
!!! First compile module:  then compile together, i.e.:
!!! > gfortran -c liutex_mod.f03
!!! 
!!! Then compile this program:
!!! > gfortran -c coreline.f03
!!!
!!! Then compile the output files (.o) together:
!!! > gfortran liutex_mod.o coreline.o -o coreline.exe
!!! 
!!! By: Oscar Alvarez
!!!=================================================================================================
    use liutex_mod

    implicit none
    
    !! Parameter values
    real(8), parameter :: pi = 4.d0*atan(1.d0)

    !! File handling
    integer, parameter :: fin1 = 10, fin2 = 20, fout1 = 30
    character(100) :: inputfilename, gridfilename, funcfilename, outputfilename, pointfilename
    character(100) :: msg, ignore, datafileprefix
    character(6) :: chars
    integer :: ios, nvar
    integer :: f_start, f_end, skip
    integer :: istart, iend, jstart, jend, kstart, kend
    integer :: iii
    logical :: lexist

    !! Other stuff
    real(8), dimension(:,:,:,:), allocatable :: f, f2
    real(8), dimension(:,:,:,:), allocatable :: r, l_mag_gradient
    real(8), dimension(:,:,:), allocatable :: x, y, z
    real(8), dimension(:,:,:), allocatable :: l_mag, omega_l
    real(8), dimension(:,:,:), allocatable :: l_core_x, l_core_y, l_core_z
    real(8), dimension(3) :: lmg_vec, r_vec
    real(8), dimension(3) :: lmg_vec_x1, lmg_vec_x2, lmg_vec_x3, lmg_vec_x4, lmg_vec_x5, lmg_vec_x6, lmg_vec_x7, lmg_vec_x8
    real(8), dimension(3) :: lmg_vec_y1, lmg_vec_y2, lmg_vec_y3, lmg_vec_y4, lmg_vec_y5, lmg_vec_y6, lmg_vec_y7, lmg_vec_y8
    real(8), dimension(3) :: lmg_vec_z1, lmg_vec_z2, lmg_vec_z3, lmg_vec_z4, lmg_vec_z5, lmg_vec_z6, lmg_vec_z7, lmg_vec_z8
    real(8), dimension(3) :: lmg_avg_x
    real(8) :: lmg_norm, r_norm
    real(8) :: l_omega_tol, dot_tol, tol3
    logical :: dot1, dot2, dot3, dot4
    logical :: condition1, condition3, all_conditions
    logical :: x_condition, y_condition, z_condition, neighbor_conditions
    integer :: imax, jmax, kmax, nx
    integer :: i, j, k, s
    integer :: l_core_counter

    
    !! Program start
    inputfilename = 'input.txt'

    !! inquire whether the input file exists
    inquire(file=inputfilename, exist=lexist)
    if(.not. lexist) then
        write(*,*) 'ERROR: no file '//inputfilename
        stop
    end if

    !! read input file
    open(fin1, file=inputfilename, form='formatted', action='read')
    read(fin1, *) f_start
    read(fin1, *) f_end
    read(fin1, *) skip
    read(fin1, *) istart, iend
    read(fin1, *) jstart, jend
    read(fin1, *) kstart, kend
    read(fin1, *) ignore
    read(fin1, *) datafileprefix

    close(fin1)

    write(chars,"(I6)") f_start
    chars = trim(chars)
    
    gridfilename = 'data/'//trim(datafileprefix)//'_'//chars//'.xyz'

    !! check if the grid file exists
    inquire(file=trim(gridfilename), exist=lexist)
    if(.not. lexist) then
        write(*,*) 'ERROR: no grid file ', trim(gridfilename)
        stop
    end if

    write(*,*)
    write(*,*) 'reading ', trim(gridfilename)

    !! open grid file
    open(fin1, file=trim(gridfilename), form='unformatted', action='read', iostat=ios, iomsg=msg)
    if(ios /= 0) then
        write(*,*) 'ERROR: ', msg
        stop
    end if

    read(fin1, iostat=ios, iomsg=msg) imax, jmax, kmax
    if(ios /= 0) then
        write(*,*) 'ERROR: ', msg
        stop
    end if

    allocate(x(imax, jmax, kmax))
    allocate(y(imax, jmax, kmax))
    allocate(z(imax, jmax, kmax))

    write(*,*)
    write(*,*) 'imax = ', imax, ' jmax = ', jmax, ' kmax = ', kmax

    !! read coordinates
    read(fin1, iostat=ios, iomsg=msg) (((x(i, j, k), i=1,imax), j=1,jmax), k=1,kmax),  &
                                      (((y(i, j, k), i=1,imax), j=1,jmax), k=1,kmax),  &
                                      (((z(i, j, k), i=1,imax), j=1,jmax), k=1,kmax)

    close(fin1)

    print*, 'Grid File Read Complete !!'

    do iii = f_start, f_end, skip

        write(chars, "(I6)") iii

        funcfilename = 'data/'//trim(datafileprefix)//'_'//chars//'.fun'

        !! Check if the function file exists
        inquire(file=trim(funcfilename), exist=lexist)
        if(.not. lexist) then
            write(*,*) 'ERROR: no data file ', funcfilename
            stop
        end if

        write(*,*)
        write(*,*) 'reading ', funcfilename

        !! Open function file
        open(fin2, file=trim(funcfilename), form='unformatted', action='read', iostat=ios, iomsg=msg)
        if(ios /= 0) then
            write(*,*) 'ERROR: ', msg
            stop
        end if

        read(fin2, iostat=ios, iomsg=msg) imax, jmax, kmax, nvar
        if(ios /= 0) then
            write(*,*) 'ERROR: ', msg
            stop
        end if

        allocate(f(imax, jmax, kmax, nvar))

        ! Reading Data
        !---------------------------------------------------------------------------
        ! f(1): u velocity
        ! f(2): v velocity
        ! f(3): w velocity
        ! f(4): vorticity x
        ! f(5): vorticity y
        ! f(6): vorticity z
        ! f(7): Omega
        ! f(8): Liutex x
        ! f(9): Liutex y
        ! f(10): Liutex z
        ! f(11): Liutex magnitude
        ! f(12): Q Method
        ! f(13): isLocExtrOmg
        ! f(14): Liutex mag gradient x
        ! f(15): Liutex mag gradient y
        ! f(16): Liutex mag gradient z
        ! f(17): Modified-Omega-Liutex
        !---------------------------------------------------------------------------

        read(fin2, iostat=ios, iomsg=msg) ((((f(i, j, k, nx), i=1,imax), j=1,jmax), k=1,kmax), nx=1,nvar)
        if(ios /= 0) then
            write(*,*) 'ERROR: ', msg
            stop
        end if
        close(fin2)

        print*, "Function File Read Complete !!"

        allocate(r(imax,jmax,kmax,3))
        allocate(l_mag(imax,jmax,kmax))
        allocate(l_mag_gradient(imax,jmax,kmax,3))
        allocate(omega_l(imax,jmax,kmax))

        r(:,:,:,:) = f(:,:,:, 8:10)
        l_mag = f(:,:,:, 11)
        l_mag_gradient(:,:,:,:) = f(:,:,:, 14:16)
        omega_l = f(:,:,:, 17)
        
        allocate(l_core_x(imax,jmax,kmax))   !! New Liutex Core Vector
        allocate(l_core_y(imax,jmax,kmax))   !! New Liutex Core Vector
        allocate(l_core_z(imax,jmax,kmax))   !! New Liutex Core Vector
        
        write(*,*) 'Finding the Liutex Core Vector Field'
        
        pointfilename = 'data/corepoints_'//trim(datafileprefix)//'_'//chars//'.dat'
        open(fout1, file=trim(pointfilename), form='formatted', action='write')

        l_core_x = 0.d0
        l_core_y = 0.d0
        l_core_z = 0.d0

        !! Apply conditions for liutex core vector

        l_omega_tol = 0.51d0    !! tolerance for condition 1
        dot_tol = 1.d-6         !! tolerance for condition 2
        tol3 = 1.d-3            !! tolerance for condition 3

        l_core_counter = 0

        do k = 3, kmax - 2
            do j = 3, jmax - 2
                do i = 3, imax - 2

                    condition1 = (omega_l(i,j,k) >= l_omega_tol)
                    
                    if (condition1) then

                        lmg_vec = (/ l_mag_gradient(i,j,k,1), l_mag_gradient(i,j,k,2), l_mag_gradient(i,j,k,3) /)
                        r_vec = (/ r(i,j,k,1), r(i,j,k,2), r(i,j,k,3) /)

                        lmg_norm = norm2(lmg_vec)
                        r_norm = norm2(r_vec)

                        if (lmg_norm .ne. 0.d0) then
                            lmg_vec = lmg_vec / lmg_norm
                        end if

                        if (r_norm .ne. 0.d0) then
                            r_vec = r_vec / r_norm
                        end if

                        !! Taking average of neighboring vectors and comparing them to the original.
                        !! Condition: if the average is = or similar to original then it is a core point.
                        
                        !! X-DIRECTION
                        !! Get the neighboring gradient vectors (Going along the x-direction / i-direction).
                        lmg_vec_x1 = (/ l_mag_gradient(i,j-2,k,1), l_mag_gradient(i,j-2,k,2), l_mag_gradient(i,j-2,k,3) /)
                        lmg_vec_x2 = (/ l_mag_gradient(i,j-1,k,1), l_mag_gradient(i,j-1,k,2), l_mag_gradient(i,j-1,k,3) /)
                        lmg_vec_x3 = (/ l_mag_gradient(i,j+1,k,1), l_mag_gradient(i,j+1,k,2), l_mag_gradient(i,j+1,k,3) /)
                        lmg_vec_x4 = (/ l_mag_gradient(i,j+2,k,1), l_mag_gradient(i,j+2,k,2), l_mag_gradient(i,j+2,k,3) /)

                        lmg_vec_x5 = (/ l_mag_gradient(i,j,k-2,1), l_mag_gradient(i,j,k-2,2), l_mag_gradient(i,j,k-2,3) /)
                        lmg_vec_x6 = (/ l_mag_gradient(i,j,k-1,1), l_mag_gradient(i,j,k-1,2), l_mag_gradient(i,j,k-1,3) /)
                        lmg_vec_x7 = (/ l_mag_gradient(i,j,k+1,1), l_mag_gradient(i,j,k+1,2), l_mag_gradient(i,j,k+1,3) /)
                        lmg_vec_x8 = (/ l_mag_gradient(i,j,k+2,1), l_mag_gradient(i,j,k+2,2), l_mag_gradient(i,j,k+2,3) /)

                        !! Normalize the neighbors
                        if (norm2(lmg_vec_x1) .ne. 0.d0) then
                            lmg_vec_x1 = lmg_vec_x1 / norm2(lmg_vec_x1)
                        end if
                        
                        if (norm2(lmg_vec_x2) .ne. 0.d0) then
                            lmg_vec_x2 = lmg_vec_x2 / norm2(lmg_vec_x2)
                        end if
                        
                        if (norm2(lmg_vec_x3) .ne. 0.d0) then
                            lmg_vec_x3 = lmg_vec_x3 / norm2(lmg_vec_x3)
                        end if
                        
                        if (norm2(lmg_vec_x4) .ne. 0.d0) then
                            lmg_vec_x4 = lmg_vec_x4 / norm2(lmg_vec_x4)
                        end if

                        if (norm2(lmg_vec_x5) .ne. 0.d0) then
                            lmg_vec_x5 = lmg_vec_x5 / norm2(lmg_vec_x5)
                        end if
                        
                        if (norm2(lmg_vec_x6) .ne. 0.d0) then
                            lmg_vec_x6 = lmg_vec_x6 / norm2(lmg_vec_x6)
                        end if
                        
                        if (norm2(lmg_vec_x7) .ne. 0.d0) then
                            lmg_vec_x7 = lmg_vec_x7 / norm2(lmg_vec_x7)
                        end if
                        
                        if (norm2(lmg_vec_x8) .ne. 0.d0) then
                            lmg_vec_x8 = lmg_vec_x8 / norm2(lmg_vec_x8)
                        end if

                        do s = 1, 3
                            lmg_avg_x(s) = lmg_vec_x1(s) + lmg_vec_x2(s) + lmg_vec_x3(s) + lmg_vec_x4(s)    &
                                         + lmg_vec_x5(s) + lmg_vec_x6(s) + lmg_vec_x7(s) + lmg_vec_x8(s)
                            
                            lmg_avg_x(s) = lmg_avg_x(s) / 8.d0
                        end do

                        x_condition = (abs(dot_product(lmg_vec, lmg_avg_x)) <= dot_tol)
                        
                        
                        !! Y-DIRECTION
                        !! Get the neighboring gradient vectors (Going along the y-direction / j-direction).
                        lmg_vec_y1 = (/ l_mag_gradient(i-1,j,k,1), l_mag_gradient(i-1,j,k,2), l_mag_gradient(i-1,j,k,3) /)
                        lmg_vec_y2 = (/ l_mag_gradient(i+1,j,k,1), l_mag_gradient(i+1,j,k,2), l_mag_gradient(i+1,j,k,3) /)
                        lmg_vec_y3 = (/ l_mag_gradient(i,j,k-1,1), l_mag_gradient(i,j,k-1,2), l_mag_gradient(i,j,k-1,3) /)
                        lmg_vec_y4 = (/ l_mag_gradient(i,j,k+1,1), l_mag_gradient(i,j,k+1,2), l_mag_gradient(i,j,k+1,3) /)

                        !! Normalize the neighbors
                        if (norm2(lmg_vec_y1) .ne. 0.d0) then
                            lmg_vec_y1 = lmg_vec_y1 / norm2(lmg_vec_y1)
                        end if
                        
                        if (norm2(lmg_vec_y2) .ne. 0.d0) then
                            lmg_vec_y2 = lmg_vec_y2 / norm2(lmg_vec_y2)
                        end if
                        
                        if (norm2(lmg_vec_y3) .ne. 0.d0) then
                            lmg_vec_y3 = lmg_vec_y3 / norm2(lmg_vec_y3)
                        end if
                        
                        if (norm2(lmg_vec_y4) .ne. 0.d0) then
                            lmg_vec_y4 = lmg_vec_y4 / norm2(lmg_vec_y4)
                        end if

                        !! Use dot product to determine if the neighboring nodes are perpendicular
                        !! i.e. if v dot w = 0 then v and w are perpendicular.
                        dot1 = (dot_product(lmg_vec, lmg_vec_y1) <= dot_tol)
                        dot2 = (dot_product(lmg_vec, lmg_vec_y2) <= dot_tol)
                        dot3 = (dot_product(lmg_vec, lmg_vec_y3) <= dot_tol)
                        dot4 = (dot_product(lmg_vec, lmg_vec_y4) <= dot_tol)

                        y_condition = dot1 .and. dot2 .and. dot3 .and. dot4

                        !! Z-DIRECTION
                        !! Get the neighboring gradient vectors (Going along the z-direction / k-direction).
                        lmg_vec_z1 = (/ l_mag_gradient(i-1,j,k,1), l_mag_gradient(i-1,j,k,2), l_mag_gradient(i-1,j,k,3) /)
                        lmg_vec_z2 = (/ l_mag_gradient(i+1,j,k,1), l_mag_gradient(i+1,j,k,2), l_mag_gradient(i+1,j,k,3) /)
                        lmg_vec_z3 = (/ l_mag_gradient(i,j-1,k,1), l_mag_gradient(i,j-1,k,2), l_mag_gradient(i,j-1,k,3) /)
                        lmg_vec_z4 = (/ l_mag_gradient(i,j+1,k,1), l_mag_gradient(i,j+1,k,2), l_mag_gradient(i,j+1,k,3) /)

                        !! Normalize the neighbors
                        if (norm2(lmg_vec_z1) .ne. 0.d0) then
                            lmg_vec_z1 = lmg_vec_z1 / norm2(lmg_vec_z1)
                        end if
                        
                        if (norm2(lmg_vec_z2) .ne. 0.d0) then
                            lmg_vec_z2 = lmg_vec_z2 / norm2(lmg_vec_z2)
                        end if
                        
                        if (norm2(lmg_vec_z3) .ne. 0.d0) then
                            lmg_vec_z3 = lmg_vec_z3 / norm2(lmg_vec_z3)
                        end if
                        
                        if (norm2(lmg_vec_z4) .ne. 0.d0) then
                            lmg_vec_z4 = lmg_vec_z4 / norm2(lmg_vec_z4)
                        end if

                        !! Use dot product to determine if the neighboring nodes are perpendicular
                        !! i.e. if v dot w = 0 then v and w are perpendicular.
                        dot1 = (dot_product(lmg_vec, lmg_vec_z1) <= dot_tol)
                        dot2 = (dot_product(lmg_vec, lmg_vec_z2) <= dot_tol)
                        dot3 = (dot_product(lmg_vec, lmg_vec_z3) <= dot_tol)
                        dot4 = (dot_product(lmg_vec, lmg_vec_z4) <= dot_tol)

                        z_condition = dot1 .and. dot2 .and. dot3 .and. dot4

                        !! Checking all the conditions
                        neighbor_conditions = x_condition .or. y_condition .or. z_condition

                        condition3 = (norm2(cross_product_3d(r_vec, lmg_vec)) <= tol3)

                        all_conditions = neighbor_conditions .and. condition3

                        if (all_conditions) then

                            !! Liutex Core Line (l_core) vector components
                            l_core_x(i,j,k) = l_mag(i,j,k) * lmg_vec(1)
                            l_core_y(i,j,k) = l_mag(i,j,k) * lmg_vec(2)
                            l_core_z(i,j,k) = l_mag(i,j,k) * lmg_vec(3)

                            l_core_counter = l_core_counter + 1

                            !! Write liutex core points to file
                            write(fout1,*) x(i,j,k), y(i,j,k), z(i,j,k)

                        end if

                    end if
        
                end do
            end do
        end do

        close(fout1)

        !! Check if any liutex core lines were found.
        if (l_core_counter == 0) then
            !! This should ONLY happen if there there is no turbulence/vortices.
            write(*,*)
            write(*,*) 'NO LIUTEX CORE LINES FOUND FOR: ', funcfilename
            goto 1
        else 
            write(*,*)
            write(*,*) 'Liutex Core Lines Found: ', l_core_counter
        end if

        nvar = nvar + 3
        allocate(f2(imax,jmax,kmax,nvar))

        f2(:,:,:, 1:nvar-3) = f
        deallocate(f)
        
        f2(:,:,:, nvar-2)   = l_core_x
        f2(:,:,:, nvar-1)   = l_core_y
        f2(:,:,:, nvar)     = l_core_z
        
        write(*,*) 'Writing Function (.fun) file.'

        outputfilename = 'data/corelines_'//trim(datafileprefix)//'_'//chars//'.fun'

        open(fout1, file=trim(outputfilename), form='unformatted', action='write')
        write(fout1) imax, jmax, kmax, nvar
        write(fout1) ((((f2(i, j, k, nx), i=1,imax), j=1,jmax), k=1,kmax), nx=1,nvar)
        close(fout1)
        
        write(*,*)
        write(*,*) 'New function (.fun) file created: ', outputfilename

        1 continue

        deallocate(r)
        deallocate(l_mag)
        deallocate(l_mag_gradient)
        deallocate(omega_l)
        deallocate(l_core_x)
        deallocate(l_core_y)
        deallocate(l_core_z)
        
    end do

    write(*,*) 'Program complete.'
  
end program main