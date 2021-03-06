SUBROUTINE setupgrid
  
  !USE mod_param, only:
  !USE mod_vel, only:
  
  !USE mod_time, only:
  USE mod_grid, only: imt, jmt, km, dyu, dxv, dxdy, kmt, mask, depth
  USE mod_name, only: indatadir
  !USE mod_vel, only:
  USE mod_getfile, only: get2DfieldNC, ncTpos, map2d, map3d
  USE mod_write, only: twritetype
  
  IMPLICIT none
  ! =============================================================
  !    ===  Set up the grid ===
  ! =============================================================
  ! Subroutine for defining the grid of the GCM. Run once
  ! before the loop starts.
  ! -------------------------------------------------------------
  ! The following arrays has to be populated:
  !
  !  dxdy - Area of horizontal cell-walls.
  !  dz   - Height of k-cells in 1 dim. |\
  !  dzt  - Height of k-cells i 3 dim.  |- Only one is needed
  !  kmt  - Number of k-cells from surface to seafloor.
  !
  ! The following might be needed to calculate
  ! dxdy, uflux, and vflux
  !
  !  dzu - Height of each u-gridcell.
  !  dzv - Height of each v-gridcell.
  !  dxu -
  !  dyu -
  ! -------------------------------------------------------------

  ! === Init local variables for the subroutine ===
  INTEGER                                    :: i ,j ,k ,kk

  allocate ( depth(imt,jmt) )
  !Order is   t  k  i  j 
  map2d    = [3, 4, 1, 2]
  map3d    = [2, 3, 4, 1]

  twritetype = 2

  ncTpos = 1
  print *,trim(inDataDir) // "scb_grid.nc" 
  dxv(:-2,:) = get2DfieldNC(trim(inDataDir) // "scb_grid.nc" , 'x_rho')
  dyu(:-2,:) = get2DfieldNC(trim(inDataDir) // "scb_grid.nc" , 'y_rho')

  dxv(1:imt-1,:) = dxv(2:imt,:)-dxv(1:imt-1,:)
  dyu(:,1:jmt-1) = dyu(:,2:jmt)-dyu(:,1:jmt-1)
  dxv(imt:imt+1,:) = dxv(imt-2:imt-1,:)
  dyu(:,jmt) = dyu(:,jmt-1)
  dxdy = dyu*dxv

  depth = get2DfieldNC(trim(inDataDir) // "scb_grid.nc" , 'h')
  mask = get2DfieldNC(trim(inDataDir) // "scb_grid.nc" , 'mask_rho')
  kmt = 40 
  where (mask(2:imt,:) == 1) 
     mask(1:imt-1,:) = 1
  end where
  where (mask(:, 2:jmt) == 1) 
     mask(:,1:jmt-1) = 1
  end where
  !where (mask(2:imt,:) == 0) 
  !   mask(1:imt-1,:) = 0
  !end where
  !where (mask(:, 2:jmt) == 0) 
  !   mask(:,1:jmt-1) = 0
  !end where


  where (mask==0) kmt=0  

end SUBROUTINE setupgrid
