;+
;*****************************************************************************************
;
;  FUNCTION :   read_gen_ascii.pro
;  PURPOSE  :   Reads in any generic ASCII file and returns every line as an array
;                 of strings.
;
;  CALLED BY:   
;               NA
;
;  CALLS:
;               NA
;
;  REQUIRES:    
;               NA
;
;  INPUT:
;               FILE         :  Scalar string for full path with file name
;
;  EXAMPLES:    
;               NA
;
;  KEYWORDS:    
;               REMOVE_NULL  :  If set, program removes null strings
;               FIRST_NL     :  Scalar defining the number of lines to read from the
;                                 file [used for reading headers only]
;               FIRST_NC     :  Scalar defining the max number of characters to read
;                                 for any given line
;
;   CHANGED:  1)  Fixed an issue when index > 32767                [01/19/2012   v1.0.1]
;             2)  Added keyword:  FIRST_NL                         [01/19/2012   v1.1.0]
;             3)  Added keyword:  FIRST_NC                         [04/05/2012   v1.2.0]
;
;   NOTES:      
;               1)  A return value of '' means there was an error
;               2)  To read in only the header, use the FIRST_NL keyword
;
;   CREATED:  03/11/2011
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  04/05/2012   v1.2.0
;    MODIFIED BY: Lynn B. Wilson III
;
;*****************************************************************************************
;-

FUNCTION read_gen_ascii,file,REMOVE_NULL=remove_null,FIRST_NL=first_nl,FIRST_NC=first_nc

;-----------------------------------------------------------------------------------------
; => Define dummy variables
;-----------------------------------------------------------------------------------------
badfile_mssg = 'FILE is not a valid file name and path!'
a            = ''   ; => dummy string
lines        = ''
j            = 0L   ; => dummy counter
ftest        = 1    ; => logic test for WHILE loop
;-----------------------------------------------------------------------------------------
; => Check input
;-----------------------------------------------------------------------------------------
test_file = FILE_TEST(file[0],/REGULAR) EQ 0
IF (test_file) THEN BEGIN
  MESSAGE,badfile_mssg,/INFORMATIONAL,/CONTINUE
  RETURN,''
ENDIF

IF KEYWORD_SET(first_nl) THEN jmax  = first_nl[0]
;  LBW III  04/05/2012   v1.2.0
IF KEYWORD_SET(first_nc) THEN BEGIN
  nchar = STRTRIM(STRING(first_nc[0],FORMAT='(I)'),2L)
  aform = '(a'+nchar[0]+')'
ENDIF ELSE BEGIN
  aform = '(a)'
ENDELSE
;-----------------------------------------------------------------------------------------
; => Open file
;-----------------------------------------------------------------------------------------
OPENR,gunit,file[0],ERROR=err,/GET_LUN
  IF (err NE 0) THEN BEGIN
    PRINTF, -2, !ERROR_STATE.MSG
    RETURN,''
  ENDIF
;-----------------------------------------------------------------------------------------
; => Read file
;-----------------------------------------------------------------------------------------
  WHILE (ftest) DO BEGIN
    READF,gunit,a,FORMAT=aform
;  LBW III  04/05/2012   v1.2.0
;    READF,gunit,a
    IF (j EQ 0) THEN lines = a[0] ELSE lines = [lines,a[0]]
    IF KEYWORD_SET(jmax) THEN BEGIN
      ; => User only wants the 1st JMAX-Lines of file
      ftest = (j LT jmax - 1L) AND (NOT EOF(gunit))
    ENDIF ELSE BEGIN
      ; => Read in entire file
      ftest = NOT EOF(gunit)
    ENDELSE
    IF (ftest) THEN j += 1L
  ENDWHILE
; => Close file
FREE_LUN,gunit
;-----------------------------------------------------------------------------------------
; => Check result
;-----------------------------------------------------------------------------------------
nl = N_ELEMENTS(lines)
IF (nl LE 1) THEN RETURN,''
; => Remove null lines
IF KEYWORD_SET(remove_null) THEN BEGIN
  good = WHERE(lines NE '',gd)
  IF (gd EQ 0) THEN RETURN,''
  lines = lines[good]
ENDIF

;-----------------------------------------------------------------------------------------
; => Return file lines
;-----------------------------------------------------------------------------------------
RETURN,lines
END
