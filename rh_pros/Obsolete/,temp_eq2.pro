; => Eq 2.

;=========================================================================================
; => d/dphi 
;=========================================================================================
sth[0]*sph[0]*bf1[1] - sth[0]*sph[0]*bf2[1] - cph[0]*sth[0]*bf1[2] + cph[0]*sth[0]*bf2[2]


;=========================================================================================
; => d/dthe 
;=========================================================================================
sth[0]*bf1[0] - sth[0]*bf2[0] - cth[0]*cph[0]*bf1[1] + cth[0]*cph[0]*bf2[1] - cth[0]*sph[0]*bf1[2] + cth[0]*sph[0]*bf2[2]


;=========================================================================================
; => d/dVs 
;=========================================================================================
0


    ; => Bn equation [Eq. 2 from Koval and Szabo, 2008]
    term0           = sth[0]*sph[0]*bf1[1] - sth[0]*sph[0]*bf2[1]
    term1           = cph[0]*sth[0]*bf2[2] - cph[0]*sth[0]*bf1[2]
    df_dphi         = term0 + term1
    term0           = sth[0]*bf1[0] - sth[0]*bf2[0] - cth[0]*cph[0]*bf1[1]
    term1           = cth[0]*cph[0]*bf2[1] - cth[0]*sph[0]*bf1[2] + cth[0]*sph[0]*bf2[2]
    df_dthe         = term0 + term1
    df_dvsh         = 0d0






