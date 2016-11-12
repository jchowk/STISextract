PRO EXTRACT_TRACE, grating, spec, bg_fit, err_in, yspec, diff2pt, $
                   gross, flux, bg_out, err_out, OPTIMAL=opt_yes, $
                   HIRES=hires_yes
;+
; ----------------------------------------------------------------------
; EXTRACT_TRACE --
;
;   *Program description:
;      This procedure extracts the gross, background, and error
;       spectra from a series of 2-D images.  The center of the
;       spectra in the cross-dispersion direction is given by 
;       the input yspec.  The input diff2pt is the photometric   
;       calibration.    
;   
;   *Calling sequence:
;      EXTRACT_TRACE, grating, spec, bg_fit, err_in, yspec, diff2pt, 
;                   gross, flux, bg_out, err_out, /optimal
;
;   *Inputs:
;      grating -- Grating name.   
;      spec,bg_fit,err_in -- 2D arrays holding spectral, background,
;                            and error data.   
;      yspec   -- Y centroid of the spectral trace.
;      diff2pt -- Constant for conversion to STScI flux scale.
;
;   *Outputs: 
;      gross,flux,bg_out,err_out -- 1D output arrays containing
;                                   gross and net flux, background, 
;                                   and error vectors.
;   *Keywords:
;      \optimal -- Optimal extraction: NOT IMPLEMENTED
;      \hires   -- For images at full resolution (not rebinned).
;
;
;   *HISTORY:
;         7/99 -- Howk -- Created and added comments.   
;        12/99 -- Howk -- Added HIRES compatability
;
; ----------------------------------------------------------------------
;-   
   
   IF keyword_set(hires_yes) THEN BEGIN 
      ;; Hard-wire STScI extraction box size.
      IF strmid(grating,4,1) EQ 'H' THEN extract_box = 15. $
      ELSE extract_box = 23.
   ENDIF ELSE BEGIN 
      ;; Hard-wire STScI extraction box size.
      IF strmid(grating,4,1) EQ 'H' THEN extract_box = 7. $
      ELSE extract_box = 11.
   ENDELSE 
   
   IF keyword_set(opt_yes) THEN BEGIN 
   ;;; Optimal extraction routine:
      
      ;; CURRENTLY THE OPTIMAL EXTRACTION OPTION IS NOT
      ;;      IMPLEMENTED
      
   ENDIF ELSE BEGIN    
   ;;;Non-optimal extraction routine:      
      
      n = 0.5*(extract_box - 1.)
            
      ;; Sum gross spectrum and convert to correct flux units.
      gross = total(spec(*, yspec-n:yspec+n), 2)
      gross = gross*diff2pt
   
      ;; Sum spectrum and convert to correct flux units.
      flux = total(spec(*, yspec-n:yspec+n)-bg_fit(*, yspec-n:yspec+n), 2)
      flux=flux*diff2pt
   
      ;; Sum background and convert to correct flux units.
      bg_out = total(bg_fit(*, yspec-n:yspec+n), 2)
      bg_out=bg_out*diff2pt
      
      ;; Sum error in quadrature and convert to correct flux units.
      err_out = sqrt(total(err_in(*, yspec-n:yspec+n)^2., 2))
      err_out=err_out*diff2pt
      
   ENDELSE 
   
   return 
 END 
