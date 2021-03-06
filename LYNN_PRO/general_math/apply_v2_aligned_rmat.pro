;+
;*****************************************************************************************
;
;  FUNCTION :   apply_v2_aligned_rmat.pro
;  PURPOSE  :   This routine uses vectorized matrix multiplication to apply an array of
;                 3x3 matrices to an array of 3-vectors without using the # operator.
;
;  CALLED BY:   
;               rot_v1_2_v2_aligned_basis.pro
;
;  INCLUDES:
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
;               V1      :  [N,3]-Element [numeric] array of 3-vectors to rotate into
;                            the new orthonormal basis
;               RMATS   :  [N,3,3]-Element [numeric] array of 3x3 matrices that will
;                            rotate V1 into a new orthonormal basis
;
;  EXAMPLES:    
;               v1rot = apply_v2_aligned_rmat(v1,rmats)
;
;  KEYWORDS:    
;               NAN     :  If set, the rotated V1 on output will contain zeros instead of
;                            NaNs on account of the results returned by the TOTAL.PRO
;                            function when the NAN keyword is set.
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [09/27/2015   v1.0.0]
;             2)  Finished writing routine
;                                                                   [10/06/2015   v1.0.0]
;
;   NOTES:      
;               1)  This is meant to be used with the output from the routine
;                     create_v2_aligned_rmat.pro and should be called by the routine
;                     rot_v1_2_v2_aligned_basis.pro
;
;  REFERENCES:  
;               NA
;
;   CREATED:  09/26/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  10/06/2015   v1.0.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION apply_v2_aligned_rmat,v1,rmats,NAN=nan

;;  Let IDL know that the following are functions
FORWARD_FUNCTION is_a_number, format_2d_vec
;;----------------------------------------------------------------------------------------
;;  Constants
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
;;  Dummy error messages
no_inpt_msg    = 'User must supply an array of 3-vectors and an array of rotation matrices'
badvfor_msg    = 'Incorrect input format:  V1 must be an [N,3]-element [numeric] array of 3-vectors'
badrfor_msg    = 'Incorrect input format:  RMATS must be [N,3,3]-element [numeric] array of 3x3 rotation matrices'
baddim__msg    = 'V1 and RMATS must both have the same # of elements, N, in their first dimension'
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() LT 2) OR (is_a_number(v1,/NOMSSG) EQ 0) OR  $
                 (is_a_number(rmats,/NOMSSG) EQ 0)
IF (test[0]) THEN BEGIN
  MESSAGE,no_inpt_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Check vector format
v1_2d          = format_2d_vec(v1)    ;;  If a vector, routine will force to [N,3]-elements, even if N = 1
test           = ((N_ELEMENTS(v1_2d) LT 3) OR ((N_ELEMENTS(v1_2d) MOD 3) NE 0))
IF (test[0]) THEN BEGIN
  MESSAGE,badvfor_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Check rotation matrices format
szdv1          = SIZE(v1_2d,/DIMENSIONS)
szdrm          = SIZE(rmats,/DIMENSIONS)
test           = ((N_ELEMENTS(szdrm) LT 3) OR ((N_ELEMENTS(rmats) MOD 9) NE 0)) OR $
                  (TOTAL(szdrm EQ 3) LT 2)
IF (test[0]) THEN BEGIN
  MESSAGE,badrfor_msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;  Make sure both arrays have matching 1st dimensions
test           = (szdrm[0] NE szdv1[0])
IF (test[0]) THEN BEGIN
  MESSAGE,baddim__msg,/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;----------------------------------------------------------------------------------------
;;  Apply rotation
;;----------------------------------------------------------------------------------------
;;  Rebin the array of 3-vectors to an [N,3,3]-element array
;;   [Note:  REBIN stacks vectors across rows, not columns]
v1_2d_r        = REBIN(v1_2d,szdv1[0],szdv1[1],szdv1[1])
;;  Apply rotation
v1_rot         = TOTAL(v1_2d_r*rmats,2L,/DOUBLE,NAN=nan)
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,v1_rot
END
