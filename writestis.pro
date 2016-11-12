PRO writestis, rootname, order, wave, gross, flux, err, bg, SAVEFILE=save_yes
;+   
; ----------------------------------------------------------------------
;  WRITESTIS --
;
;    *Program description:
;       This procedure writes output files to store extracted STIS
;       data.  The outputs can be in IDL save files or ASCII files
;       (defaults to ASCII).  In an ASCII file five columns are output   
;       storing the input variables: wave, gross, flux, err, bg.
;       
;   
;   *Calling sequence:   
;       WRITESTIS, rootname, order, wave, gross, flux, err, bg, /savefile
;							
;   *Input:
;       rootname   -- Rootname for output.  The spectral order will
;                    be attached, as well as '.save' for save files
;                    or '.dat' for ASCII files (e.g., o4qx04040.454.save).
;       order      -- The spectral order of the observation.
;       wave       -- Wavelength vector.
;       gross,flux -- Gross and net flux vectors.
;       err        -- Error vector.
;       bg         -- Background vector.   
;
;   *Optional Keywords:
;       /savefile  -- Store output in an IDL save file rather than 
;                      an ASCII file.  The names of the variables
;                      saved are: wave,gross,flux,err,bg.
;								
;     7/99 -- Howk -- Created from writespecnorm.pro
;     4/00 -- Howk -- Changed file unit allocation to be more flexible.
;   
; ----------------------------------------------------------------------
;-  
   ;; Check to see if save file is preferred over ascii file.
   IF keyword_set(save_yes) THEN BEGIN 
                                ; Construct right output name.
      outname = rootname+'.'+strtrim(string(order), 2)+'.save'
                                ; Save output.
      save, filename=outname, order, wave, gross, flux, err, bg, rootname
      
   ENDIF ELSE BEGIN             ;ASCII file creation:
      
                                ; Construct right output name.
      outname = rootname+'.'+strtrim(string(order), 2)+'.dat'
                                ; Open file 'outname'.
      get_lun, filelun
      openw,filelun,outname
                                ; Loop through the variables.
      sz=size(wave)
      FOR i=0,sz(1)-1 DO $
       printf,filelun,'$(2x,f12.4,3x,e12.5,3x,e12.5,3x,e12.5,3x,e12.5)',$
       wave(i),gross(i), flux(i), err(i), bg(i)
      free_lun,filelun
      
   ENDELSE 
   
   return
END
