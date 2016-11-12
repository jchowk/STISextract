PRO stis_asciiconvert
;+
; ----------------------------------------------------------------------
;   STIS_ASCIICONVERT
;      
;   *Program Description: 
;   
;      This program will convert the IDL save files created by the
;       STISEXTRACT procedures into ascii files containing columns of
;       wavelength, gross and net fluxes, errors, and the derived
;       background (in that order).  The output files have the naming
;       convention rootname.###.dat, where rootname is the STScI
;       archival rootname of the observation and ### is the order
;       number.
;
;   *Calling sequence:
;      STIS_ASCIICONVERT
;   
;   *External Routines:
;      WRITESTIS   
;
;   *HISTORY:
;      12/99 -- Howk -- Created and documented.
; ----------------------------------------------------------------------   
;-    
   
   spawn, 'ls *.*.save > stisnames.txt'
   readcol, 'stisnames.txt', names, format='a'
   
   FOR i=0, n_elements(names)-1 DO BEGIN 
      restore, names[i]
      
      ordernum = fix(strtrim(strmid(names[i], 10, 3), 2))
      orderstring = strtrim(string(ordernum), 1)
      
      rootname = strmid(names[i], 0, 9)
      
      writestis, rootname, orderstring, wave, gross, $
       flux, err, bg
      close, /all
   ENDFOR 
   
END 
         
