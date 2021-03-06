;+
;*****************************************************************************************
;
;  FUNCTION :   resample_2d_vec.pro
;  PURPOSE  :   This routine interpolates an [N,3]-element array of vectors to an
;                 [K]-element array of new time stamps using a linear, quadratic,
;                 least-squares quadratic, or cubic spline fit for the interpolation.
;
;  CALLED BY:   
;               NA
;
;  CALLS:
;               is_a_number.pro
;               format_2d_vec.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries
;
;  INPUT:
;               VEC_V           :  [N,3]-Element [long/float/double] array of vectors
;                                    at VEC_T to be interpolated to NEW_T
;                                    [e.g., Y_j = F(x_j)]
;               VEC_T           :  [N]-Element [long/float/double] array of abscissa
;                                    values for VEC_V [e.g., x_j in F(x_j)]
;               NEW_T           :  [K]-Element [long/float/double] array of new
;                                    abscissa values to interpolate VEC_V to
;                                    [e.g., x_k in F(x_k)]
;
;  EXAMPLES:    
;               ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;               ;;  Test example
;               ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;               IDL> x__in  = DINDGEN(30)*2d0*!DPI/29
;               IDL> y__in0 = COS(x__in)
;               IDL> y__in1 = SIN(x__in)
;               IDL> y__in2 = TAN(x__in)
;               IDL> y__in  = [[y__in0],[y__in1],[y__in2]]
;               IDL> x_out  = [3d1,45d0,6d1,75d0]*!DPI/18d1
;               IDL> y_out  = resample_2d_vec(y__in,x__in,x_out,/NO_EXTRAPOLATE)
;               IDL> FOR k=0L, 2L DO PRINT, ';; ', y_out[*,k]
;               ;;       0.86112444      0.70315133      0.49823808      0.25863711
;               ;;       0.49709123      0.70329162      0.86328705      0.96500764
;               ;;       0.58662050       1.0208745       1.7680486       4.2201012
;               ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;               ;;  Check results
;               ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;               IDL> PRINT, ';; ', ABS(COS(x_out) - y_out[*,0])/COS(x_out)
;               IDL> PRINT, ';; ', ABS(SIN(x_out) - y_out[*,1])/SIN(x_out)
;               IDL> PRINT, ';; ', ABS(TAN(x_out) - y_out[*,2])/TAN(x_out)
;               ;;     0.0056591468    0.0055938561    0.0035238372   0.00070293444
;               ;;     0.0058175355    0.0053954595    0.0031619829   0.00095058149
;               ;;      0.016056517     0.020874472     0.020783323      0.13077270
;
;  KEYWORDS:    
;               LSQUADRATIC     :  If set, routine will use a least squares quadratic
;                                    fit to the equation y = a + bx + cx^2, for each
;                                    4 point neighborhood
;                                    [Default = FALSE]
;               QUADRATIC       :  If set, routine will use a least squares quadratic
;                                    fit to the equation y = a + bx + cx^2, for each
;                                    3 point neighborhood
;                                    [Default = FALSE]
;               SPLINE          :  If set, routine will use a cubic spline for each
;                                    4 point neighborhood
;                                    [Default = FALSE]
;               NO_EXTRAPOLATE  :  If set, program will not extrapolate end points
;                                    [Default = FALSE]
;
;   CHANGED:  1)  Updated routine to ignore/remove NaNs on end points when the
;                   NO_EXTRAPOLATE is set and now calls FORWARD_FUNCTION.PRO and
;                   is_a_number.pro
;                                                                   [07/08/2015   v1.0.1]
;             2)  Cleaned up a little
;                                                                   [11/10/2015   v1.0.2]
;
;   NOTES:      
;               1)  Unless the data is roughly linear, or known to functionally vary as
;                     one of the interpolating functions, or smoothly varies, it is wise
;                     to set the keyword NO_EXTRAPOLATE
;               2)  The routine requires N > 3
;               3)  If the data contains NaNs, it would be wise to run the routine
;                     remove_nans.pro prior to calling this routine
;               4)  The update to version 1.0.1 should account for issues raised in
;                     Note # 3 above.
;               5)  The routine does not try to deal with data intervals with gaps, thus
;                     if either input has gaps it would be wise to use
;                     t_interval_find.pro and run this routine by interval, not over the
;                     entire data set to avoid mistakes arising with the NO_EXTRAPOLATE
;                     keyword
;
;  REFERENCES:  
;               SEE ALSO:  
;                          INTERPOL.PRO
;                          interp.pro
;                          remove_nans.pro
;
;   CREATED:  11/14/2013
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  11/10/2015   v1.0.2
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION resample_2d_vec,vec_v,vec_t,new_t,LSQUADRATIC=lsquadratic,QUADRATIC=quadratic,$
                                           SPLINE=spline,NO_EXTRAPOLATE=no_extrapolate

;;  Let IDL know that the following are functions
FORWARD_FUNCTION is_a_number, format_2d_vec
;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;  Error messages
noinput_mssg   = 'No or incorrect input was supplied...'
incorrd_mssg   = 'Incorrect number of elements:  VEC_V[*,0] must have same elements as VEC_T...'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS()        NE 3) OR (N_ELEMENTS(vec_v) EQ 0) OR $
                 (N_ELEMENTS(vec_t) EQ 0) OR (N_ELEMENTS(new_t) EQ 0) OR $
                 (is_a_number(vec_t,/NOMSSG) EQ 0) OR (is_a_number(vec_v,/NOMSSG) EQ 0) OR $
                 (is_a_number(new_t,/NOMSSG) EQ 0)
IF (test[0]) THEN BEGIN
  MESSAGE,noinput_mssg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
;;  Format vector
vv             = REFORM(vec_v)
vec2d          = format_2d_vec(vv)
test           = (N_ELEMENTS(vec2d) LE 9)
IF (test[0]) THEN RETURN,0         ;;  Error messages found in format_2d_vec.pro
;;  Check dimensions
test           = (N_ELEMENTS(vec2d[*,0]) NE N_ELEMENTS(vec_t))
IF (test[0]) THEN BEGIN
  MESSAGE,incorrd_mssg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0
ENDIF
;;----------------------------------------------------------------------------------------
;;  Redefine input and determine type of interpolation to use
;;----------------------------------------------------------------------------------------
x__in          = REFORM(vec_t)
y__in          = vec2d
x_out          = REFORM(new_t)

i_type         = [0L,KEYWORD_SET(lsquadratic),KEYWORD_SET(quadratic),KEYWORD_SET(spline)]
good_it        = WHERE(i_type,gdit)
IF (gdit GT 1) THEN BEGIN
  ;;  More than one option is set => Default to the one first set
  i_type = good_it[0]
ENDIF ELSE BEGIN
  ;;  One or fewer options are set
  IF (gdit GT 0) THEN BEGIN
    ;;  One option is set
    i_type = good_it[0]
  ENDIF ELSE BEGIN
    ;;  No options were set => Use linear interpolation
    i_type = 0
  ENDELSE
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Interpolate
;;----------------------------------------------------------------------------------------
nx             = N_ELEMENTS(x_out)
out_y          = REPLICATE(d,nx[0],3)
lsquad         = 0b & quad = 0b & ispl = 0b
CASE i_type[0] OF
  0L   :                ;;  Linearly interpolate
  1L   :  lsquad = 1b   ;;  Least-squares quadratic interpolation
  2L   :  quad   = 1b   ;;  Quadratic interpolation
  3L   :  ispl   = 1b   ;;  Cubic spline interpolation
  ELSE :  BEGIN
    ;;  Incorrect choice of interpolation type
    weird_mssg = 'I am not sure how this happened... Using linear interpolation'
    MESSAGE,weird_mssg[0],/INFORMATIONAL,/CONTINUE
  END
ENDCASE
int_str        = {LSQUADRATIC:lsquad,QUADRATIC:quad,SPLINE:ispl}
FOR k=0, 2 DO out_y[*,k] = INTERPOL(y__in[*,k],x__in,x_out,_EXTRA=int_str)
;;----------------------------------------------------------------------------------------
;;  Remove end points if they were extrapolated
;;----------------------------------------------------------------------------------------
test           = (N_ELEMENTS(no_extrapolate) NE 0) AND KEYWORD_SET(no_extrapolate)
IF (test) THEN BEGIN
  ;;  First, find Min/Max elements of input that were finite
  test  = FINITE(y__in[*,0]) AND FINITE(y__in[*,1]) AND FINITE(y__in[*,2])
  good  = WHERE(test,gd,COMPLEMENT=bad,NCOMPLEMENT=bd)
  IF (gd GT 0) THEN BEGIN
    ;;  Remove end points
    mnmx  = [MIN(x__in[good],/NAN),MAX(x__in[good],/NAN)]
    test  = (x_out LT mnmx[0]) OR (x_out GT mnmx[1])
    bad   = WHERE(test,bd)
  ENDIF
  IF (bd GT 0) THEN out_y[bad,*] = f
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,out_y
END

