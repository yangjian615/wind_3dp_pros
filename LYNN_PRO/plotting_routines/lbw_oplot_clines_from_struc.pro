;+
;*****************************************************************************************
;
;  PROCEDURE:   lbw_oplot_clines_from_struc.pro
;  PURPOSE  :   This routine takes an input IDL structure containing the outputs from
;                 the CONTOUR.PRO keywords PATH_INFO and PATH_XY and then plots the
;                 contour lines to the current device.  The input structure should have
;                 the following tags:
;                   INFO  :  returned result from PATH_INFO keyword
;                   XY    :  returned result from PATH_XY
;                 This routine is useful if the user wishes to replot the contours
;                 created by CONTOUR.PRO without having to re-call CONTOUR, e.g., in
;                 the event that creating the contour lines took a lot of computing time.
;
;  CALLED BY:   
;               NA
;
;  CALLS:
;               is_a_number.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               CPATH   :  Scalar [structure] defining the coordinates, levels, etc. of
;                            the desired output contour lines.  It must contain the
;                            structure tags:
;                              INFO  :  output from PATH_INFO keyword
;                              XY    :  output from PATH_XY keyword
;                            [see NOTES below for more details]
;
;  EXAMPLES:    
;               lbw_oplot_clines_from_struc,cpath,C_COLORS=c_colors
;
;  KEYWORDS:    
;               C_COLORS  :  [N]-Element [long] array defining the color indices for the
;                              contours on output
;                              [Default = evenly spaced values from 30 - 250]
;               _EXTRA    :  Any keywords accepted by PLOTS.PRO
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [07/21/2015   v1.0.0]
;             2)  Moved to ~/wind_3dp_pros/LYNN_PRO/plotting_routines/ and updated
;                   Man. page
;                                                                   [08/12/2015   v1.1.0]
;
;   NOTES:      
;               1)  This routine takes a structure containing the outputs from the
;                     PATH_XY and PATH_INFO keywords returned by calling the
;                     CONTOUR.PRO procedure.  The CPATH input should be an IDL structure
;                     with the tags INFO and XY corresponding to the output from
;                     PATH_INFO and PATH_XY, respectively.
;
;  REFERENCES:  
;               NA
;
;   CREATED:  07/19/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  08/12/2015   v1.1.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO lbw_oplot_clines_from_struc,cpath,C_COLORS=c_colors,_EXTRA=ex_str

;;  Let IDL know that the following are functions
FORWARD_FUNCTION is_a_number
;;----------------------------------------------------------------------------------------
;;  Define some constants, dummy variables, and defaults
;;----------------------------------------------------------------------------------------
;;  Dummy variables
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN

def_tags       = ['INFO','XY']
;;  Dummy error messages
noinpt_msg     = 'User must supply an IDL structure containing results returned by PATH_* keywords from CONTOUR.PRO'
badfor_msg     = "User supplied IDL structure must have the following tags:  'INFO' and 'XY'"
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() LT 1) OR (SIZE(cpath,/TYPE) NE 8)
IF (test) THEN BEGIN
  MESSAGE,noinpt_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;;  Check structure format
;;----------------------------------------------------------------------------------------
cpath_out      = cpath[0]
c_tags         = STRUPCASE(TAG_NAMES(cpath_out))
test0          = (TOTAL(c_tags EQ def_tags[0]) LE 0)
test1          = (TOTAL(c_tags EQ def_tags[1]) LE 0)
test           = test0[0] OR test1[0]
IF (test) THEN BEGIN
  MESSAGE,badfor_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define parameters
;;----------------------------------------------------------------------------------------
xy_cpaths      = REFORM(cpath_out.XY)          ;;  [2,N]-Element array
c_info         = cpath_out.INFO
nconts         = N_ELEMENTS(c_info)            ;;  # of contours
;;  Define level info
lev_nums       = c_info.LEVEL
unq            = UNIQ(lev_nums,SORT(lev_nums))
n_lev          = N_ELEMENTS(unq)               ;;  # of unique levels to be plotted (may differ from # of contours)
lev_n_ind      = c_info.N
lev_ind_off    = c_info.OFFSET[0]
;;  Define default colors
mnmx_col       = [30L,250L]
ccol_fac       = (mnmx_col[1] - mnmx_col[0])/(n_lev[0] - 1L)
def_c_cols     = LINDGEN(n_lev[0])*ccol_fac[0] + mnmx_col[0]
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check C_COLORS
test           = (is_a_number(c_colors,/NOMSSG) EQ 0) OR (N_ELEMENTS(c_colors) NE n_lev[0])
IF (test) THEN ccols = def_c_cols ELSE ccols = c_colors
;;----------------------------------------------------------------------------------------
;;  Overplot contours
;;----------------------------------------------------------------------------------------
FOR j=0L, nconts[0] - 1L DO BEGIN
  ;;  Define the level # and associated indices for path construction
  lev_nj = lev_nums[j]
  inds_j = [LINDGEN(lev_n_ind[j]),0L]
  ;;  Define index offset
  i0_j   = lev_ind_off[j]
  PLOTS,xy_cpaths[*, (inds_j + i0_j[0]) ],COLOR=ccols[lev_nj[0]],_EXTRA=ex_str
ENDFOR
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END
