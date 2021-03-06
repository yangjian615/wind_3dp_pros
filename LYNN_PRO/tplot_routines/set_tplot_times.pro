;+
;*****************************************************************************************
;
;  PROCEDURE:   set_tplot_times.pro
;  PURPOSE  :   This routine uses currently stored TPLOT handles to define the time
;                 ranges found in the TPLOT_COM common block.
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               tnames.pro
;               tplot_com.pro
;               str_element.pro
;               get_data.pro
;
;  REQUIRES:    
;               1)  UMN Modified Wind/3DP IDL Libraries or SPEDAS IDL Libraries
;
;  INPUT:
;               NA
;
;  EXAMPLES:    
;               [calling sequence]
;               set_tplot_times
;
;  KEYWORDS:    
;               NA
;
;   CHANGED:  1)  Changed TRANGE_FULL definition algorithm
;                                                                   [01/31/2013   v1.1.0]
;             2)  Routine can now handle TSHIFT structure tag for TPLOT structures
;                                                                   [04/21/2016   v1.2.0]
;
;   NOTES:      
;               1)  Be careful... may change "default" values [not thoroughly tested]
;
;  REFERENCES:  
;               NA
;
;   CREATED:  12/12/2012
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  04/21/2016   v1.2.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

PRO set_tplot_times

;;----------------------------------------------------------------------------------------
;;  Define some constants and dummy variables
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
no_tplot       = 'You must first load some data into TPLOT!'
no_plot        = 'You must first plot something in TPLOT!'
no_tran        = 'Not able to find any defined time ranges...'
;;----------------------------------------------------------------------------------------
;;  Make sure TPLOT variables exist
;;----------------------------------------------------------------------------------------
tpn_all        = tnames()
IF (tpn_all[0] EQ '') THEN BEGIN
  MESSAGE,no_tplot[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDIF
;;----------------------------------------------------------------------------------------
;;  Load common block
;;----------------------------------------------------------------------------------------
@tplot_com.pro
;;  Determine current settings
str_element,tplot_vars,'OPTIONS.TRANGE',trange
str_element,tplot_vars,'OPTIONS.TRANGE_FULL',trange_full
str_element,tplot_vars,'SETTINGS.TRANGE_OLD',trange_old
str_element,tplot_vars,'SETTINGS.TIME_SCALE',time_scale
str_element,tplot_vars,'SETTINGS.TIME_OFFSET',time_offset
;;----------------------------------------------------------------------------------------
;;  Make sure something is plotted
;;----------------------------------------------------------------------------------------
tpv_set_tags   = TAG_NAMES(tplot_vars.SETTINGS)
idx            = WHERE(tpv_set_tags EQ 'X',icnt)
IF (icnt GT 0) THEN BEGIN
  ;;  define current TPLOT time range
  tr = tplot_vars.SETTINGS.X.CRANGE*time_scale[0] + time_offset[0]
ENDIF ELSE BEGIN
  MESSAGE,no_plot[0],/INFORMATIONAL,/CONTINUE
  RETURN
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Check time ranges
;;----------------------------------------------------------------------------------------
test_tr0       = (trange[0] EQ trange[1])
test_tr1       = (tr[0] EQ tr[1])
test_trc       = (trange[0] NE tr[0])     OR (trange[1] NE tr[1])
test_trf       = (trange_full[0] EQ trange_full[1])
test_tro       = (trange_old[0] EQ trange_old[1])
IF (test_tr1) THEN BEGIN
  ;;  this shouldn't happen
  IF (test_tr0) THEN BEGIN
    IF (test_trf) THEN BEGIN
      IF (test_tro) THEN BEGIN
        ;;  None of the TRANGE values are set
        MESSAGE,no_tran[0],/INFORMATIONAL,/CONTINUE
        RETURN
      ENDIF ELSE BEGIN
        ;;  Use common block OLD TRANGE
        tr = trange_old
      ENDELSE
    ENDIF ELSE BEGIN
      ;;  Use common block FULL TRANGE
      tr = trange_full
    ENDELSE
  ENDIF ELSE BEGIN
    ;;  Use common block default
    tr = trange
  ENDELSE
ENDIF ELSE BEGIN
  ;;  Use current setting to define others
  tr = tr[SORT(tr)]
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Define other time ranges if necessary
;;----------------------------------------------------------------------------------------
IF (test_tr0) THEN str_element,tplot_vars,'OPTIONS.TRANGE',tr,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Define Full TRANGE
;;----------------------------------------------------------------------------------------
IF (test_trf) THEN BEGIN
  ntpn    = N_ELEMENTS(tpn_all)
  tr_f0   = [0d0,0d0]  ;; dummy FULL TRANGE
  ;;  need maximum time range
  test_dq = (SIZE(data_quants,/TYPE) EQ 8)
  IF (test_dq) THEN BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  DATA_QUANTS is defined
    ;;------------------------------------------------------------------------------------
    ndq      = N_ELEMENTS(data_quants) < 100L  ;; try to keep this small
    ;;  Initialize variable
    tr_f0    = [0d0,0d0]
    FOR j=0L, ntpn - 1L DO BEGIN
      ;;  Reset parameters
      test_name    = ''
      test_dh      = 0
      struc_dh     = 0
      test_x       = 0
      tr_00        = [0d0,0d0]
      ;;----------------------------------------------------------------------------------
      ;;  Loop through and redefine time range
      ;;----------------------------------------------------------------------------------
      str_element,data_quants[j],'NAME',test_name
      IF (test_name EQ '') THEN CONTINUE  ;; try next index
      str_element,data_quants[j],'DH',test_dh
      IF (SIZE(test_dh,/TYPE) NE 10) THEN BEGIN
        ;;  Check to see if variable is a structure [just in case]
        IF (SIZE(test_dh,/TYPE) NE 8) THEN struc_dh = 0 ELSE struc_dh = test_dh[0]
      ENDIF ELSE BEGIN
        ;;  value is a pointer
        struc_dh = *test_dh[0]
        ;;  Clean up pointer heap variables
        HEAP_FREE,test_dh,/PTR
      ENDELSE
      ;;  Check format of structure
      str_element,struc_dh[0],     'X',test_x
      str_element,struc_dh[0],'TSHIFT',test_tshift
      IF (SIZE(test_x,/TYPE)      EQ 0) THEN CONTINUE  ;; no time index
      IF (SIZE(test_tshift,/TYPE) EQ 0) THEN tshift = 0d0 ELSE tshift = test_tshift[0]
      ;;  Clean up pointer heap variables (if necessary)
      IF (SIZE(struc_dh,/TYPE) EQ 10) THEN HEAP_FREE,struc_dh,/PTR
      ;;----------------------------------------------------------------------------------
      ;;  Determine Min/Max range of timestamps current variable
      ;;----------------------------------------------------------------------------------
      testp    = (SIZE(test_x,/TYPE) EQ 10)
      testdf   = (SIZE(test_x,/TYPE) EQ 4) OR (SIZE(test_x,/TYPE) EQ 5)
      good_pdf = WHERE([testp,testdf],gdpdf)
      CASE good_pdf[0] OF
        0    :  BEGIN
          ;;  pointer
          tr_00    = [MIN(*test_x,/NAN),MAX(*test_x,/NAN)]
          IF (SIZE(tshift,/TYPE) EQ 10) THEN tr_00 += *tshift[0] ELSE tr_00 += tshift[0]
          ;;  Clean up pointer heap variables
          HEAP_FREE,test_x,/PTR
          IF (SIZE(tshift,/TYPE) EQ 10) THEN HEAP_FREE,tshift,/PTR
        END
        1    :  BEGIN
          ;;  float or double
          tr_00    = [MIN(test_x,/NAN),MAX(test_x,/NAN)]
          IF (SIZE(tshift,/TYPE) EQ 10) THEN tr_00 += *tshift[0] ELSE tr_00 += tshift[0]
          ;;  Clean up pointer heap variables
          IF (SIZE(tshift,/TYPE) EQ 10) THEN HEAP_FREE,tshift,/PTR
        END
        ELSE :  BEGIN  ;;  unusable format
          ;;  skip to end of loop and try next index
          GOTO,JUMP_SKIP_TRA
        END
      ENDCASE
      bad      = WHERE(FINITE(tr_00) EQ 0,bd)  ;; check for bad timestamps
      IF (bd GT 0) THEN BEGIN
        ;; skip to end of loop and try next index
        GOTO,JUMP_SKIP_TRA
      ENDIF
      ;;----------------------------------------------------------------------------------
      ;;  Adjust TRANGE_FULL
      ;;----------------------------------------------------------------------------------
      badf0    = WHERE(tr_f0 EQ 0,bdf0,COMPLEMENT=goodf0)  ;; check for bad timestamps
      test     = (j EQ 0) OR (tr_f0[0] EQ tr_f0[1])
      IF (test) THEN BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  Initialize TRANGE_FULL
        ;;--------------------------------------------------------------------------------
        tr_f0[0] = tr_f0[0] > tr_00[0]
        tr_f0[1] = tr_f0[1] > tr_00[1]
      ENDIF ELSE BEGIN
        ;;--------------------------------------------------------------------------------
        ;;  adjust
        ;;--------------------------------------------------------------------------------
        CASE bdf0[0] OF
          0    :  BEGIN
            ;;  no bad values
            tr_f0[0] = tr_f0[0] < tr_00[0]
            tr_f0[1] = tr_f0[1] > tr_00[1]
          END
          1    :  BEGIN
            ;;  1 bad value
            tr_f0[badf0] = tr_f0[badf0] > tr_00[badf0]
            CASE goodf0[0] OF
              0    :  tr_f0[0] = tr_f0[0] < tr_00[0]
              1    :  tr_f0[1] = tr_f0[1] > tr_00[1]
            ENDCASE
          END
          ELSE :  ;;  all bad values
        ENDCASE
      ENDELSE
      ;;==================================================================================
      JUMP_SKIP_TRA:
      ;;==================================================================================
    ENDFOR
  ENDIF ELSE BEGIN
    ;;------------------------------------------------------------------------------------
    ;;  DATA_QUANTS not defined => try TPLOT variable values
    ;;------------------------------------------------------------------------------------
    ntpn    = N_ELEMENTS(tpn_all) < 100L  ;; try to keep it small
    FOR j=0L, ntpn[0] - 1L DO BEGIN
      ;;  Clean up
      dumb        = TEMPORARY(time_x)
      IF (N_ELEMENTS(time_tshift) GT 0) THEN dumb = TEMPORARY(time_tshift)
      ;;  Get data
      test_t0     = (j EQ 0) OR (tr_f0[0] EQ tr_f0[1])
      get_data,tpn_all[j],DATA=temp
      IF (SIZE(temp,/TYPE) NE 8) THEN CONTINUE  ;;  move on to next iteration
;      IF (SIZE(temp,/TYPE) EQ 8) THEN BEGIN
      str_element,temp[0],     'X',time_x
      str_element,temp[0],'TSHIFT',time_tshift
      test_tag    = (N_ELEMENTS(test_x) GT 0)
      test_tshift = (N_ELEMENTS(time_tshift) EQ 1)
;      test_tag = TOTAL(STRLOWCASE(TAG_NAMES(temp)) EQ 'x') EQ 1
      IF (test_tag[0]) THEN BEGIN
        ;;  TPLOT handle has a time tag
        tr_00    = [MIN(time_x,/NAN),MAX(time_x,/NAN)]
        IF (test_tshift[0]) THEN tr_00 += time_tshift[0]  ;;  Offset by TSHIFT, if present
;        tr_00    = [MIN(temp.X,/NAN),MAX(temp.X,/NAN)]
        bad      = WHERE(FINITE(tr_00) EQ 0,bd)
        IF (bd GT 0) THEN BEGIN
          ;; remove NaNs
          tr_00[bad] = 0d0
        ENDIF
        IF (test_t0) THEN BEGIN
          ;; initialize
          tr_f0[0] = tr_f0[0] > tr_00[0]
          tr_f0[1] = tr_f0[1] > tr_00[1]
        ENDIF ELSE BEGIN
          ;;  Define start time reference
          test_sta = (tr_00[0] NE 0d0) AND (tr_f0[0] NE 0d0)
          IF (test_sta) THEN BEGIN
            ;; both > 0.0
            tr_f0[0] = tr_f0[0] < tr_00[0]
          ENDIF ELSE BEGIN
            ;; at least one of them = 0.0
            tr_f0[0] = tr_f0[0] > tr_00[0]
          ENDELSE
          ;;  Define end time reference
          tr_f0[1] = tr_f0[1] > tr_00[1]
        ENDELSE
      ENDIF
;      ENDIF
    ENDFOR
  ENDELSE
  ;;--------------------------------------------------------------------------------------
  ;;  Reset value in common block
  ;;--------------------------------------------------------------------------------------
  IF (tr_f0[0] NE tr_f0[1] AND TOTAL(tr_f0) NE 0) THEN BEGIN
    ;;  Only alter if something was actually found/done
    trange_full = tr_f0
    str_element,tplot_vars,'OPTIONS.TRANGE_FULL',trange_full,/ADD_REPLACE
  ENDIF
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define Old/Previous TRANGE
;;----------------------------------------------------------------------------------------
IF (test_tro) THEN str_element,tplot_vars,'SETTINGS.TRANGE_OLD',trange_full,/ADD_REPLACE
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END
