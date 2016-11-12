@bgfit1d
@bgfit1d_gauss
@extract_trace
@fxpar
PRO stisextract, fcb, exnum, wave, gross, flux, bg_out, $
   err_out, sporder,  SMOOTHBG=smooth_yes, NOGAUSS=nogauss
;+
; ----------------------------------------------------------------------
; STISEXTRACT --
; 
;   *Program description:
;      This routine will extract STIS spectra from the 2D rectified
;      images provided by the STScI CALSTIS routine, fit and remove
;      a background, extract and calibrate the flux and error vectors,
;      and return wavelength, flux, background, and error vectors.
;   
;   *Calling sequence:
;      STISEXTRACT, rootname, exnum, wave, flux, bg_out, err_out, sporder, 
;                 \SMOOTHBG
;
;   *Input:
;      fcb      -- File control block for FITS access.
;      exnum    -- Extension number of the SCI array.
;   
;   *Output:
;      wave     -- Wavelength array
;      flux     -- Flux array
;      bg_out   -- Background array
;      err_out  -- Error array
;  
;   *Keywords:
;      /smoothbg -- Smooth the derived background using bg_smooth.pro
;      /nogauss  -- Do not use Gaussian fit to derive center of
;                   spectral trace and interloping orders in 2D
;                   spectral images.  **This option is faster but
;                   is less robust to problems in STIS reference 
;                   files.**   
;   
;   *External Routines called:
;      BGFIT1D, BGFIT1D_GAUSS, EXTRACT_TRACE, FXPAR, FITS_READ, BG_SMOOTH
;
;   *HISTORY:
;         7/99 -- Howk -- Created and added comments.
;         8/99 -- Howk -- Added Lee filter smoothing option.   
;        12/99 -- Howk -- Added HIRES compatability
;        12/99 -- Howk -- Added automatic trimming for orders
;                           at the end of an image.   
;         1/00 -- Howk -- Fixed the fits_read call to read the
;                           observation level header in order to get
;                           the correct grating name.
;         1/00 -- Howk -- Adopted to use file control block to access
;                           FITS files.  -- Adopted from suggestion by
;                           W. Landsman (GSFC).   
;         3/01 -- Howk -- Added  BGFIT1D_GAUSS compliance.    
;   
; ----------------------------------------------------------------------
;-

   IF N_PARAMS() EQ 0 THEN BEGIN 
      print, ''
      print, 'STISEXTRACT,fcb,exnum,wave,gross,flux,bg_out,'+$
       'err_out,/summed,/smoothbg'
      print, '  *Inputs:'
      print, '     fcb      -- File control block returned by FITS_OPEN'
      print, '     exnum    -- Extension number of the SCI array.'
      print, ''
      print, '  *Output:'
      print, '     wave     -- Wavelength array'
      print, '     gross    -- Gross flux array'
      print, '     flux     -- Net flux array (background subtracted)'
      print, '     bg_out   -- Background array'
      print, '     err_out  -- Error array'
      print, '  '
      print, '  *Keywords:'
      print, '    /summed   -- Use _sx2 FITS file.'
      print, '    /smoothbg -- Smooth the background.'
      print, '    /nogauss  -- Do not use Gaussian to identify spectral trace.'
      print, ''
      
      retall
   ENDIF   
   
   ;; Make sure appropriate system variables are set.
   defsysv,'!plotunit', exists=i 
   IF (i eq 0) THEN stis_setup
   
    
        ;;; Read data from FITS file
               ;;;SCI extension:
   fits_read,fcb,data,head,exten_no=exnum
               ;;;ERR extension:
   fits_read,fcb,err_in,ehead,/no_pdu,exten_no=exnum+1
               ;;;DQ  extension:   
                                ;For now the DQ array is left alone. 
   ;;fits_read,fcb,dq,dqhead,/no_pdu,exten_no=exnum+2
   
      
   ;; --------------------------------------------------
   ;; Populate header values needed to calculate wavelengths and
   ;; fluxes for the data.  SPORDER contains the spectral order.
   ;; --------------------------------------------------
                                ; FXPAR is part of the IDL  
                                ; Astronomy Library.
   crpix   = fxpar(head, 'CRPIX*')
   cd1     = double(fxpar(head, 'CD1_1'))
   crval   = double(fxpar(head, 'CRVAL*'))
   diff2pt = fxpar(head, 'DIFF2PT')
   grating = fxpar(head, 'OPT_ELEM')
   sporder = fix(fxpar(head, 'SPORDER'))
   
   
   ;; --------------------------------------------------
   ;; Some datasets have the DIFF2PT keyword set to 0. 
   ;; This causes real troubles!  The following resets
   ;; diff2pt to 1.0 in these cases.
   ;; --------------------------------------------------
   
   IF (diff2pt EQ 0) THEN diff2pt = 1.
   
   
   ;; --------------------------------------------------
   ;; Trim off the junk that STScI puts on the ends.   
   ;; --------------------------------------------------
   sz   = size(data)
   
   good = where(data(*, crpix[1]) NE 0.) ;;; STScI tacks on zeroes.
   offset=min(good)+10.                   ;;; Find the starting point.
   
   
      ;;; Check for HIRES data...if present, trim accordingly
   
   IF (sz[1] GT 1300) THEN BEGIN 
      trimsize = 2047 
      hires = 1
   ENDIF ELSE BEGIN 
      trimsize = 1023
      hires = 0
   ENDELSE 
   
   IF (offset+trimsize GT sz[1]) THEN trimsize = sz[1]-offset-1.

   
   ;; Trim the data to an appropriate size.
   
   data=data[offset:(offset+trimsize),*]  
   err_in = err_in[offset:(offset+trimsize),*]
            
   crpix[0]=crpix[0]-offset     ; Correct crpix1 for offset.


   ;; --------------------------------------------------
   ;; Call background fitting routine.
   ;; --------------------------------------------------
   
   IF keyword_set(nogauss) THEN BEGIN 
      IF (hires EQ 0) THEN bgfit1d, head, data, bg_fit, spec, yspec $
      ELSE bgfit1d, head, data, bg_fit, spec, yspec, /hires
   ENDIF ELSE BEGIN 
      IF (hires EQ 0) THEN bgfit1d_gauss, head, data, bg_fit, spec, yspec $
      ELSE bgfit1d_gauss, head, data, bg_fit, spec, yspec, /hires
   ENDELSE 
   
   ;; --------------------------------------------------
   ;; Use header keywords to calculate wavelength and flux.
   ;; --------------------------------------------------
   
   sz   = size(spec)
   
         ;;; Calculate wavelength solution.
   wave = findgen(sz[1])+1.     ; The +1 is needed because the first 
                                ; pixel number is 1 rather than 0.   
                                
   wave = (wave-crpix[0]) * cd1 + crval[0]
   
   
   ;; --------------------------------------------------
   ;; Call extraction routine.  
   ;; --------------------------------------------------
                                ; No optimal extraction for now. 
   
   ;;diff2pt = diff2pt/0.89       ; Rough aperture correction
   
   IF (hires EQ 0) THEN BEGIN 
      extract_trace, grating, data, bg_fit, err_in, yspec,$
       diff2pt, gross, flux, bg_out, err_out
   ENDIF ELSE BEGIN 
      extract_trace, grating, data, bg_fit, err_in, yspec,$
       diff2pt, gross, flux, bg_out, err_out, /hires
   ENDELSE 
   
   ;;--------------------------------------------------
   ;; Apply a smoothing routine if requested.
   ;;--------------------------------------------------
   

   IF keyword_set(smooth_yes) THEN BEGIN 
      ;;Use a Lee filter for smoothing the background.
      ;; [See Lee 1986, Optical Engineering, 25(5), 636]
      
      scale = hires*8.
      
      smbg_out = LEEFILT(bg_out,8+scale)
      
      bg_out = smbg_out
      flux =  gross - smbg_out
   ENDIF 
   
   ;;Alternative smoothing options not implemented:
   ;;BG_SMOOTH, bg_out, smbg_out, 2, 8.         ;Polynomial
   ;;smbg_out = leefilt(median(bg_out, 5), 5)   ;Median

   ;; Tell the user we're finished.
  
   print, format='("Extracted Order ", i4)', sporder
   return
END 

;------------------------------ END MAIN ------------------------------


