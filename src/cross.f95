!#ifndef timeanalyt 
subroutine cross_stat(ijk,ia,ja,ka,r0,sp,sn)
  
  ! subroutine to compute time (sp,sn) when trajectory 
  ! crosses face of box (ia,ja,ka) 
  ! two crossings are considered for each direction:  
  ! east and west for longitudinal directions, etc.  
  ! 
  !  Input:
  !
  !  ijk      : considered direction (i=zonal, 2=meridional, 3=vertical)
  !  ia,ja,ka : original position in integers
  !  r0       : original non-dimensional position in the 
  !             ijk-direction of particle 
  !             (fractions of a grid box side in the 
  !              corresponding direction)
  !  intrpr       : time interpolation constant between 0 and 1 
  !
  !
  !  Output:
  !
  !    sp,sn   : crossing time to reach the grid box wall 
  !              (in units of s/m3)

USE mod_precdef   
USE mod_log, only: log_level 
USE mod_grid, only: undef, imt, jmt, nsm, nsp
USE mod_vel, only: uflux, vflux, wflux, ff
USE mod_active_particles, only: upr
USE mod_time, only: dtreg, intrpr, intrpg
IMPLICIT none

real(DP)                                     :: r0, ba, sp, sn, uu, um, vv, vm
real(DP)                                     :: frac1,frac2
integer                                      :: ijk, ia, ja, ka, ii, im

if(ijk.eq.1) then
 ii=ia
 im=ia-1
 if(im.eq.0) im=IMT
 uu=(intrpg*uflux(ia,ja,ka,nsp)+intrpr*uflux(ia,ja,ka,nsm))*ff
 um=(intrpg*uflux(im,ja,ka,nsp)+intrpr*uflux(im,ja,ka,nsm))*ff
 !frac1 = min( abs(upr(1,1)), abs(0.99*uu/upr(1,1)) )
 !frac2 = min( abs(upr(2,1)), abs(0.99*um/upr(2,1)) )
 !print*,'cross x',uu,um,upr(1,1),upr(2,1)
#ifdef turb   
 if(r0.ne.dble(ii)) then
  !if (uu /= 0.d0 .and. um /= 0.d0) then
   uu=uu+upr(1,2)!*frac1
  !end if
 else
  !if (uu /= 0.d0 .and. um /= 0.d0) then
   uu=uu+upr(1,1)!*frac1  ! add u' from previous iterative time step if on box wall
  !end if
 endif
 if(r0.ne.dble(im)) then
  !if (uu /= 0.d0 .and. um /= 0.d0) then
   um=um+upr(2,2)!*frac2
  !end if
 else
  !if (uu /= 0.d0 .and. um /= 0.d0) then
   um=um+upr(2,1)!*frac2  ! add u' from previous iterative time step if on box wall
  !end if
 endif
#endif
  
elseif(ijk.eq.2) then
 ii=ja
 uu=(intrpg*vflux(ia,ja  ,ka,nsp)+intrpr*vflux(ia,ja  ,ka,nsm))*ff
 um=(intrpg*vflux(ia,ja-1,ka,nsp)+intrpr*vflux(ia,ja-1,ka,nsm))*ff
 !frac1 = min( abs(upr(3,1)), abs(0.99*uu/upr(3,1)) )
 !frac2 = min( abs(upr(4,1)), abs(0.99*um/upr(4,1)) )
 !print*,'cross y',uu,um,upr(3,1),upr(4,1)
#ifdef turb    
 if(r0.ne.dble(ja  )) then
  !if (uu /= 0.d0 .and. um /= 0.d0) then
   uu=uu+upr(3,2)!*frac1
  !end if
 else 
  !if (uu /= 0.d0 .and. um /= 0.d0) then
   uu=uu+upr(3,1)!*frac1  ! add u' from previous iterative time step if on box wall
  !end if
 endif
 if(r0.ne.dble(ja-1)) then
  !if (uu /= 0.d0 .and. um /= 0.d0) then
   um=um+upr(4,2)!*frac2
  !end if
 else
  !if (uu /= 0.d0 .and. um /= 0.d0) then
   um=um+upr(4,1)!*frac2  ! add u' from previous iterative time step if on box wall
  !end if
 endif
#endif
 
elseif(ijk.eq.3) then
 ii=ka
#if defined  explicit_w || full_wflux
 uu=wflux(ia ,ja ,ka   ,nsm)!*ff
 um=wflux(ia ,ja ,ka-1 ,nsm)!*ff
#else
 uu=(intrpg*wflux(ka  ,nsp)+intrpr*wflux(ka  ,nsm))!*ff
 um=(intrpg*wflux(ka-1,nsp)+intrpr*wflux(ka-1,nsm))!*ff
#endif

#ifndef twodim   
#ifdef turb   
 if(r0.ne.dble(ka  )) then
  uu=uu+upr(5,2)  
 else
  uu=uu+upr(5,1)  ! add u' from previous iterative time step if on box wall
 endif
 if(r0.ne.dble(ka-1)) then
  uu=uu+upr(6,2)  
 else
  uu=uu+upr(6,1)  ! add u' from previous iterative time step if on box wall
 endif
#endif
#endif
 
endif

if (log_level >= 10) then
   print*,'cross: ijk,uu,um,ff: ',ijk,uu,um,ff
end if

! east, north or upward crossing
if(uu.gt.0.d0 .and. r0.ne.dble(ii)) then
   if (log_level >= 15) then
      print*,'positive crossing: uu, r0, ii:',uu,r0,ii
   end if 
   
   if(um.ne.uu) then
      ba=(r0+dble(-ii+1)) * (uu-um) + um
      if (log_level >= 20) then
         print*,'r0,-ii+1,(r0+(-ii+1)) * (uu-um),ba:',r0,-ii+1,(r0+dble(-ii+1)) * (uu-um),ba
      end if
      
      if(ba.gt.0.d0) then
!   sp=-1.d0/(um-uu)*( dlog(uu) - dlog(ba) )
         sp=( dlog(ba) - dlog(uu) )/(um-uu)
         if (log_level >= 20) then
            print*,' valid crossing ',ba
         end if
      else
         if (log_level >= 20) then
            print*,' invalid crossing ba < 0',ba
         end if
         sp=UNDEF
      endif
   else
      sp=(dble(ii)-r0)/uu
      if (log_level >= 20) then
         print*,'linear crossing',sp
      end if
   endif

else
   if (log_level >= 20) then
      print*,' invalid crossing uu < 0 or r0 = ii. uu, r0, ii: ',uu,r0,ii
   end if 
   sp=UNDEF
endif

if(sp.le.0.d0) sp=UNDEF

! west, south or downward crossing
if(um.lt.0.d0 .and. r0.ne.dble(ii-1)) then
   if (log_level >= 10) then
      print*,'negative crossing: uu, r0, ii:',um,r0,ii-1
   end if
   
   if(um.ne.uu)then
      ba=-((r0-dble(ii))*(uu-um)+uu) 
      if (log_level >= 20) then
         print*,'r0,ii,(r0-ii) * (uu-um),ba:',r0,ii,(r0+dble(ii)) * (uu-um),ba
      end if
      if(ba.gt.0.d0) then
      !   sn=-1.d0/(um-uu)*( dlog(-um) - dlog(ba)  )
         sn=( dlog(ba) - dlog(-um)  )/(um-uu)
         if (log_level >= 10) then
            print*,'valid crossing: ',ba,sn
         end if
      else
         sn=UNDEF
      endif
   
   else
      sn=(dble(ii-1)-r0)/uu
   endif

else
   if (log_level >= 20) then
      print*,' invalid crossing um > 0 or r0 = ii-1. um, r0, ii-1: ',um,r0,ii-1
   end if
   sn=UNDEF
endif

if(sn.le.0.d0) sn=UNDEF


return
end subroutine cross_stat
!#endif
