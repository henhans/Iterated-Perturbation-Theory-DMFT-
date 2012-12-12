!########################################################
!     Program  : HMIPT
!     PURPOSE  : Solve the Hubbard model using DMFT-IPT
!     AUTHORS  : Adriano Amaricci
!########################################################
program hmipt_zerot_2dsquare
  USE IPT_VARS_GLOBAL
  USE SQUARE_LATTICE
  implicit none

  integer,parameter      :: M=2048
  integer                :: i,Lk,ik
  logical                :: converged
  complex(8)             :: zeta,sqroot
  real(8)                :: sq,sig
  type(real_gf)          :: fg0,sigma
  complex(8),allocatable :: fg(:)
  real(8),allocatable    :: wr(:),wt(:),epsik(:),dos(:)

  call read_input("inputIPT.in")
  allocate(fg(2*L))
  call allocate_gf(fg0,L)
  call allocate_gf(sigma,L)

  !grids:
  allocate(wr(2*L))
  wr = linspace(-wmax,wmax,2*L,mesh=fmesh)
  dt = pi/wmax

  !
  !
  !build square lattice structure:
  Lk   = square_lattice_dimension(Nx)
  allocate(wt(Lk),epsik(Lk))
  wt   = square_lattice_structure(Lk,Nx)
  epsik= square_lattice_dispersion_array(Lk,ts)
  allocate(dos(M))  
  call get_free_dos(epsik,wt,dos,wmin=-wmax,wmax=wmax,eps=0.005d0)
  !
  !

  D=1.d0 ; sigma=zero ; iloop=0 ; converged=.false.
  do while (.not.converged)
     iloop=iloop+1
     write(*,"(A,i5,1x)",advance="no")"DMFT-loop",iloop
     fg=zero
     do i=1,2*L
        zeta = wr(i) - sigma%w(i)
        sq=real(zeta,8)
        sig=1.d0 ; if(wr(i)<0.d0)sig=-sig
        zeta=zeta+sig*xi*eps
        fg(i)=sum_overk_zeta(zeta,epsik,wt)
     enddo
     fg0%w = one/(one/fg + sigma%w)

     call fftgf_rw2rt(fg0%w,fg0%t,L) ; fg0%t=fmesh/pi2*fg0%t
     forall(i=-L:L)sigma%t(i)=(U**2)*(fg0%t(i)**2)*fg0%t(-i)
     call fftgf_rt2rw(sigma%t,sigma%w,L) ; sigma%w= dt*sigma%w

     fg = one/(one/fg0%w - sigma%w)
     converged= check_convergence(sigma%w,eps_error,nsuccess,nloop)
  enddo
  call splot("G_realw.ipt",wr,fg,append=printf)
  call splot("Sigma_realw.ipt",wr,sigma%w,append=printf)
  call splot("G0_realw.ipt",wr,fg0%w,append=printf)

end program hmipt_zerot_2dsquare

