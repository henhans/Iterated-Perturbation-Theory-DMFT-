program hmipt_matsuara
  USE DMFT_IPT
  USE IOTOOLS
  USE ERROR
  implicit none
  logical                :: converged,check
  real(8)                :: n,z
  integer                :: i,iloop
  complex(8)             :: zeta
  !type(matsubara_gf)     :: fg
  complex(8),allocatable :: fg(:),fg0(:),sigma(:),GFold(:)
  real(8),allocatable    :: wm(:),sigt(:)

  call read_input("inputIPT.in")

  !allocate functions:
  allocate(fg(L))
  allocate(sigma(L))
  allocate(fg0(L))
  allocate(GFold(L))
  allocate(sigt(0:L))

  !build freq. array
  allocate(wm(L))
  wm(:)  = pi/beta*real(2*arange(1,L)-1,8)

  !get or read first sigma 
  call  get_inital_sigma(Sigma,"Sigma.restart")

  !dmft loop:
  D=2.d0*ts ;  iloop=0 ; converged=.false.
  do while(.not.converged.AND.iloop<nloop)
     iloop=iloop+1
     write(*,"(A,i5)",advance="no")"DMFT-loop",iloop
     !SELF-CONSISTENCY:
     do i=1,L
        zeta = xi*wm(i) - sigma(i)
        fg(i) = gfbethe(wm(i),zeta,D)
     enddo
     n   = get_local_density(fg,beta)
     GFold=fg0
     fg0 = one/(one/fg + sigma)
     if(iloop>1)fg0 = weight*fg0 + (1.d0-weight)*GFold
     !
     !IMPURITY SOLVER
     sigma= solve_ipt_matsubara(fg0)
     converged=check_convergence(fg0,dmft_error,nsuccess,nloop)
     !GET OBSERVABLES
     z=1.d0 - dimag(sigma(1))/wm(1);z=1.d0/z
     call splot("observables_all.ipt",dble(iloop),u,z,beta,append=.true.)
  enddo
  call splot("G_iw.ipt",wm,fg)
  call splot("G0_iw.ipt",wm,fg0)
  call splot("Sigma_iw.ipt",wm,sigma)
  call splot("observables.ipt",u,beta,n,z)
  call fftgf_iw2tau(sigma,sigt(0:),beta,notail=.true.)
  open(100,file="fft_sigma_iw.ipt")
  do i=0,L
     write(100,*)i*beta/dble(L),sigt(i)
  enddo
  close(100)

contains

  subroutine get_inital_sigma(self,file)
    complex(8),dimension(:) :: self
    real(8),dimension(size(self)) :: wm
    character(len=*)        :: file
    logical                 :: check
    inquire(file=file,exist=check)
    if(check)then
       print*,'Reading sigma'
       call sread(file,wm,self)
    else
       print*,"Using Hartree-Fock self-energy"
       print*,"===================================="
       self=zero !U*(n-1/2)
    endif
  end subroutine get_inital_sigma

end program hmipt_matsuara
