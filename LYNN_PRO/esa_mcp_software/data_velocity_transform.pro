;+
;*****************************************************************************************
;
;  FUNCTION :   data_velocity_transform.pro
;  PURPOSE  :   Calculates an estimate of the reduced distribution function and adds
;                 the tags to a copy of the input data structure then returns to
;                 "add_df2d_to_ph.pro".  The data is transformed into the solar wind
;                 frame first and rotated into a coordinate system defined by a plane
;                 created between two vectors of interest [Default = (Vsw x B)].
;                 If the input structure is from the Pesa High instrument, the 
;                 "known" data glitches are removed (see "pesa_high_bad_bins.pro")
;                 before data is transformed or rotated.  The glitches are also
;                 removed to prevent an alteration of the energy bin values.  If the
;                 input structure is from the Eesa Low instrument, the spacecraft
;                 potential estimate is subtracted from the energies of the particles
;                 before transforming into the solar wind frame.
;
;  CALLED BY: 
;               add_df2d_to_ph.pro
;
;  CALLS:
;               dat_3dp_str_names.pro
;               dat_3dp_energy_bins.pro
;               pesa_high_bad_bins.pro
;               convert_ph_units.pro
;               conv_units.pro
;               cart_to_sphere.pro
;               cal_rot.pro
;               velocity.pro
;               str_element.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               DAT        :  3DP data structure either from get_ph.pro etc.
;
;  EXAMPLES:
;
;  KEYWORDS:  
;               VLIM       :  Limit for x-y velocity axes over which to plot data
;                               [Default = max vel. from energy bin values]
;               NGRID      :  # of isotropic velocity grids to use to triangulate the data
;                               [Default = 50L]
;               ROT_MAT    :  [3,3]-Element matrix used to rotate data into a new desired
;                               plane of projection [Default = plane defined by (Vsw x B)]
;               NSMOOTH    :  Scalar # of points over which to smooth the DF
;                               [Default = 3]
;               NOKILL_PH  :  If set, program will not call pesa_high_bad_bins.pro
;                               leaving "bad/contaminated" data bins alone
;               NO_REDF    :  If set, program will calculate cuts of the distribution,
;                               not quasi-reduced distributions
;                               [Default:  calculates quasi-reduced distributions]
;
;   CHANGED:  1)  Fixed syntax error                              [07/13/2009   v1.0.1]
;             2)  Fixed possible negative DF-Value issue          [07/18/2009   v1.0.2]
;             3)  Changed program my_3dp_energy_bins.pro to dat_3dp_energy_bins.pro
;                   and my_str_names.pro to dat_3dp_str_names.pro
;                                                                 [08/05/2009   v1.1.0]
;             4)  Added keyword:  NSMOOTH                    
;                   and my_pesa_high_bad_bins.pro to pesa_high_bad_bins.pro
;                   and altered spacing for TRIGRID.PRO           [08/27/2009   v1.2.0]
;             5)  Changed minor syntax issue                      [08/31/2009   v1.2.1]
;             6)  Updated 'man' page                              [10/05/2008   v1.2.2]
;             7)  Changed calculation of parallel/perp. cuts      [04/12/2010   v1.3.0]
;             8)  Added error handling for moments produced by the Mac OS X shared
;                   object library which produces anomalous data spikes
;                                                                 [02/18/2011   v1.4.0]
;             9)  Fixed typo in return tags:  DF2DZ, VX2DZ, and VY2DZ
;                                                                 [05/23/2011   v1.4.1]
;            10)  Changed normalization of para/perp cuts         [07/15/2011   v1.4.2]
;            11)  Fixed typo in man page                          [07/16/2011   v1.4.2]
;            12)  Changed calculation of X-Z Plane projection     [12/15/2011   v1.4.3]
;            13)  Added keyword:  NOKILL_PH                       [01/13/2012   v1.5.0]
;            14)  Added keyword:  NO_REDF                         [01/27/2012   v1.6.0]
;
;   NOTES:      
;               1)  This program is adapted from software by K. Meziane
;               2)  While the purpose section suggests that PESA High contains "glitches,"
;                     this is incorrect.  The "bad" data bins correspond to bins that
;                     are going through a double-sweep mode.  Meaning, these bins sweep
;                     through the top half of the energy range of the detector.  The
;                     fly-back bin contains NaNs or >10^8 counts, depending on the
;                     shared object library used to read the level zero files.  
;                     Regardless, one can use the NOKILL_PH to shut off the removal of
;                     these "bad" data bins.
;
;   CREATED:  06/24/2009
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  01/27/2012   v1.6.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION data_velocity_transform,dat,VLIM=vlim,NGRID=ngrid,ROT_MAT=rot_mat, $
                                 NSMOOTH=nsmooth,NOKILL_PH=nokill_ph,       $
                                 NO_REDF=no_redf

;-----------------------------------------------------------------------------------------
; -Determine default parameters
;-----------------------------------------------------------------------------------------
f      = !VALUES.F_NAN
d      = !VALUES.D_NAN
radf   = !PI/18e1                 ; => Conversion factor between radian and degrees
twph   = dat
IF NOT KEYWORD_SET(ngrid) THEN ngrid = 20L
IF NOT KEYWORD_SET(vlim) THEN BEGIN
  vlim = MAX(SQRT(2*dat.ENERGY/dat.MASS),/NAN)
ENDIF ELSE BEGIN
  vlim = FLOAT(vlim)
ENDELSE
xylim  = [-1*vlim,-1*vlim,vlim,vlim]
dgs    = vlim/5e1
;gs     = [vlim,vlim]/ngrid
gs     = [dgs,dgs]
;-----------------------------------------------------------------------------------------
; -Determine structure and rotation info
;-----------------------------------------------------------------------------------------
index  = twph.INDEX               ; => Integer associated with 3DP data structure
nbins  = twph.NBINS               ; => # of data bins
nener  = twph.NENERGY             ; => # of energy bins
strn   = dat_3dp_str_names(twph)
sname  = STRMID(strn.SN,0L,2L)
; => Define B-field and solar wind velocities
vsw    = twph.VSW
bgse   = twph.MAGF
; => Check to make sure Vsw is defined!
goodvsw = WHERE(FINITE(vsw) AND ABS(vsw) GT 0e0,gdvsw)
IF (gdvsw EQ 0) THEN vsw = [-1e0,0e0,0e0]
; => Check to make sure Magf is defined!
goodmag = WHERE(FINITE(bgse) AND ABS(bgse) GT 0e0,gdmag)
IF (gdmag EQ 0) THEN bgse = [1e0,1e0,0e0]/ SQRT(2e0)

IF NOT KEYWORD_SET(rot_mat) THEN BEGIN
  cart_to_sphere,bgse[0],bgse[1],bgse[2],rr,the,phi
  bb   = bgse/rr[0]
  MESSAGE,'Using default rotation defined by Vsw x B',/CONTINUE,/INFORMATIONAL
  mrot = cal_rot(bb,vsw)
ENDIF ELSE BEGIN
  mrot = REFORM(rot_mat)
ENDELSE
;-----------------------------------------------------------------------------------------
; -Determine energies and convert to df units
;-----------------------------------------------------------------------------------------
ddener = FLTARR(nener,nbins)
myens  = dat_3dp_energy_bins(twph)
myener = myens.ALL_ENERGIES
g_ener = myener # REPLICATE(1.,nbins)
CASE sname[0] OF
  'ph' : BEGIN
    ; => Remove data glitch if necessary in PH data
    IF NOT KEYWORD_SET(nokill_ph) THEN pesa_high_bad_bins,twph
    convert_ph_units,twph,'df'
    tener = myener
  END
  'el' : BEGIN
    twph  = conv_units(twph,'df')
    scpot = twph.SC_POT            ; => Consider contribution to SC Potential (eV)
    tener = myener - scpot[0]      ; => Shift energies accordingly
    bad = WHERE(twph.ENERGY LT scpot*1.3,nbad)
    ;-------------------------------------------------------------------------------------
    ; => Remove photo-electrons from data (**rough estimate**)
    ;-------------------------------------------------------------------------------------
    IF (nbad GT 0) THEN BEGIN
      bind = ARRAY_INDICES(twph.ENERGY,bad)
      twph.DATA[bind[0,*],bind[1,*]] = !VALUES.F_NAN
    ENDIF
    twph.ENERGY = tener # REPLICATE(1.,nbins)        ; => Redefine energy values (eV)
  END
  ELSE : BEGIN
    twph  = conv_units(twph,'df')
    tener = myener
  END
ENDCASE
;-----------------------------------------------------------------------------------------
; -Find the magnitude of the velocities (from energy bin values)
;-----------------------------------------------------------------------------------------
mvel  = DBLARR(nener,nbins,3L)
vmag  = velocity(tener,twph.MASS,/TRUE)   ; => Magnitude of velocities from energy (km/s)
vmag2 = vmag # REPLICATE(1.,nbins)        ; => [nbins,nener]-Element array (km/s)
coth  = COS(twph.THETA*radf)
sith  = SIN(twph.THETA*radf)
coph  = COS(twph.PHI*radf)
siph  = SIN(twph.PHI*radf)

mvel[*,*,0]  = vmag2*coth*coph            ; => Define X-Velocity per energy per data bin
mvel[*,*,1]  = vmag2*coth*siph            ; => Define Y-Velocity per energy per data bin
mvel[*,*,2]  = vmag2*sith                 ; => Define Z-Velocity per energy per data bin

mvel2        = REFORM(mvel,nener*nbins,3L)  ; -Resize the array
;-----------------------------------------------------------------------------------------
; -Subtract off the solar wind speed then rotate into desired plane
;-----------------------------------------------------------------------------------------
vd2      = DBLARR(nener*nbins,3L)
vd2[*,0] = REPLICATE(1.,nener*nbins) # REFORM(vsw[0])
vd2[*,1] = REPLICATE(1.,nener*nbins) # REFORM(vsw[1])
vd2[*,2] = REPLICATE(1.,nener*nbins) # REFORM(vsw[2])
mvel3    = mvel2 - vd2                   ; => Subtract off solar wind speed
mvmag3   = SQRT(TOTAL(mvel3^2,2,/NAN))   ; => New velocity magnitudes (km/s)
;-----------------------------------------------------------------------------------------
; => Rotate velocities into plane created by vec1 and vec2
;-----------------------------------------------------------------------------------------
mvel4    = mvel3 # mrot    ; => Rotated into new coordinate system
;-----------------------------------------------------------------------------------------
; -Triangulate data in this plane
;-----------------------------------------------------------------------------------------
ff0    = twph.DATA
ff2    = REFORM(ff0,nener*nbins)
vel2dx = REFORM(mvel4[*,0])
vel2dy = SQRT(TOTAL(mvel4[*,1:2]^2,2,/NAN))*REFORM(mvel4[*,1])/ ABS(REFORM(mvel4[*,1]))
vel2dz = SQRT(TOTAL(mvel4[*,1:2]^2,2,/NAN))*REFORM(mvel4[*,2])/ ABS(REFORM(mvel4[*,2]))
;-----------------------------------------------------------------------------------------
;                   |-------Resolve the triangulate problem-------|
;-----------------------------------------------------------------------------------------
;  => ONLY Finite data is allowed in TRIANGULATE.PRO and TRIGRID.PRO
;-----------------------------------------------------------------------------------------
indx   = WHERE(FINITE(ff2) EQ 1 AND ff2 GE 0.,cnt)
IF (cnt GT 0L) THEN BEGIN
  vel2dx = vel2dx[indx] 
  vel2dy = vel2dy[indx]
  vel2dz = vel2dz[indx]
  ff2    = ff2[indx]
ENDIF ELSE BEGIN
  MESSAGE,'No finite data',/CONTINUE,/INFORMATIONAL
  RETURN,dat
ENDELSE
;-----------------------------------------------------------------------------------------
; => X-Y Plane projection
;-----------------------------------------------------------------------------------------
TRIANGULATE, vel2dx, vel2dy, tr, bound
df2d = TRIGRID(vel2dx,vel2dy,ff2,tr,gs,xylim)
;-----------------------------------------------------------------------------------------
; => X-Z Plane projection
;-----------------------------------------------------------------------------------------
TRIANGULATE, vel2dx, vel2dz, tr
;df2dz = TRIGRID(vel2dx,vel2dz,ff2,tr)
;vx2dz = TRIGRID(vel2dx,vel2dz,vel2dx,tr)
;vy2dz = TRIGRID(vel2dx,vel2dz,vel2dx,tr)
; LBW III 12/15/2011
df2dz = TRIGRID(vel2dx,vel2dz,ff2,tr,gs,xylim)
vx2dz = TRIGRID(vel2dx,vel2dz,vel2dx,tr,gs,xylim)  ; LBW III 12/15/2011
vy2dz = TRIGRID(vel2dx,vel2dz,vel2dz,tr,gs,xylim)
;-----------------------------------------------------------------------------------------
; => Smooth the data
;-----------------------------------------------------------------------------------------
IF NOT KEYWORD_SET(nsmooth) THEN ns = 3 ELSE ns = LONG(nsmooth)

df2ds   = SMOOTH(df2d,ns,/EDGE_TRUNCATE,/NAN)
badsm   = WHERE(df2ds LE 0d0,bdsm)
IF (bdsm GT 0L) THEN BEGIN
  bind  = ARRAY_INDICES(df2ds,badsm)
  df2ds[bind[0,*],bind[1,*]] = d
ENDIF

; => LBW III 01/27/2012
IF KEYWORD_SET(no_redf) THEN BEGIN
  ndf     = (SIZE(df2d,/DIMENSIONS))[0]/2L + 1L
  ; => Calculate Cuts of DFs
  dfpar   = REFORM(df2d[*,ndf[0]])                                  ; => Para. Cut of DF
  dfper   = REFORM(df2d[ndf[0],*])                                  ; => Perp. Cut of DF
ENDIF ELSE BEGIN
  ; => Calculate Quasi-Reduced DFs
  ; => LBW III 06/15/2011
  dfpar   = TOTAL(df2d,2L,/NAN)/SQRT(TOTAL(FINITE(df2d),2L,/NAN))   ; => Para. Cut of DF
  dfper   = TOTAL(df2d,1L,/NAN)/SQRT(TOTAL(FINITE(df2d),1L,/NAN))   ; => Perp. Cut of DF
ENDELSE
;-----------------------------------------------------------------------------------------
; => Force regularly grided velocities (for contour plots)
;-----------------------------------------------------------------------------------------
vx2d = -1e0*vlim + gs[0]*FINDGEN(FIX((2e0*vlim)/gs[0]) + 1L)
vy2d = -1e0*vlim + gs[1]*FINDGEN(FIX((2e0*vlim)/gs[1]) + 1L)
;-----------------------------------------------------------------------------------------
; => Add new data to original structure
;-----------------------------------------------------------------------------------------
str_element,twph,'ROT_MAT',mrot,/ADD_REPLACE   ; => Rotation Matrix

str_element,twph,'DF2D',df2d,/ADD_REPLACE
str_element,twph,'VX2D',vx2d,/ADD_REPLACE
str_element,twph,'VY2D',vy2d,/ADD_REPLACE
str_element,twph,'VX_PTS',vel2dx,/ADD_REPLACE
str_element,twph,'VY_PTS',vel2dy,/ADD_REPLACE
str_element,twph,'VZ_PTS',vel2dz,/ADD_REPLACE  ; LBW III 12/15/2011

str_element,twph,'DF2DZ',df2dz,/ADD_REPLACE
str_element,twph,'VX2DZ',vx2dz,/ADD_REPLACE
str_element,twph,'VY2DZ',vy2dz,/ADD_REPLACE
; => Stuff for contour plots
str_element,twph,'DF_SMOOTH',df2ds,/ADD_REPLACE
str_element,twph,'DF_PARA',dfpar,/ADD_REPLACE
str_element,twph,'DF_PERP',dfper,/ADD_REPLACE
;-----------------------------------------------------------------------------------------
; => Return new/altered data structure
;-----------------------------------------------------------------------------------------

RETURN,twph
END