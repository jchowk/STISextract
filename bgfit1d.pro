PRO bgfit1d, header, datain, bg_out, spec_out, yspec, xgood, $
             HIRES=hires_yes
;+
; ----------------------------------------------------------------------
;  BGFIT1D -- 
;
;  *Program description:   
;    This routine is used to determine the appropriate 
;    background for 2D-rectified STIS images.  It fits
;    a cubic spline to the cross-dispersion background
;    for each column.  The result is a 2D background 
;    image that can be directly subtracted from the STIS
;    science image.
; 
;    **** BGFIT1D_GAUSS is to be preferred. ****
;   
;
;  *Calling sequence:
;     BGFIT1D, header, stis_image, bg_out, spec_out, xgood, /HIRES
;
;  *Inputs:
;     header     -- Standard STIS image header.
;     stis_image -- The 2D science data array extracted
;                    from a STIS '_x2d' or '_sx2' file.
;        
;
;  *Outputs:
;     bg_out     -- The 2D background image.
;     spec_out   -- The 2D background-subtracted spectral image.
;     yspec      -- The average y-position of the spectral trace in
;                     the image.
;     (xgood     -- Optional array containing points used for bg fit.)   
;
;  *Optional Keywords:
;       /HIRES   -- High-resolution (non-binned) datasets.
;
;  *External Routines Called:  
;     POLY_FIT, POL_FIT_WEIGHTED, FXPAR, CONVOL, PSF_GAUSSIAN, POLY
;
;   *HISTORY:
;         7/99 -- Howk -- Created and added comments.
;        12/99 -- Howk -- Added HIRES compatability
;        12/00 -- Howk -- Changed polyfitw to poly_fit_weighted
;                          for use with IDL v5.4   
;   
; ----------------------------------------------------------------------
;-   
   IF N_PARAMS() EQ 0 THEN BEGIN 
      print, 'BGFIT1D, header, stis_image, bg_out, spec_out, yspec, xgood'
      print, '  *Inputs:'
      print, '    header     -- STIS science header'
      print, '    stis_image -- The 2D science data array extracted'
      print, '                  from a STIS _x2d or _sx2 file.'
      print, ''
      print, '  *Outputs:'
      print, '    bg_out     -- The 2D background image.'
      print, '    spec_out   -- The 2D background-subtracted spectral image.'
      print, '    yspec      -- Position of the spectral trace in the y-dimen.'
      print, '    xgood      -- Points used for fitting background.'
      print, ''
      print, '  *Keywords:'
      print, '    \hires     -- For images at full resolution (not rebinned).'
      print, ''
      
      retall 
  ENDIF 
                                   
   sz = size(datain)
   width  = sz(2)
   length = sz(1)
   
   crpix   = fxpar(header, 'CRPIX*')
   
   ;; Determine a fiducial spacing unit.
   offset  = round(width / 4.5) 
   
   ;; ------------------------------------------------------------
   ;; Compact spectrum along dispersion axis and derive cross-disp.
   ;;  profile of spectrum.
   ;; ------------------------------------------------------------

   squash = total(datain[*, *], 1)
          ;;; Find maximum of trace and store in yspec
   dummy = max(squash, yspec)
   
   ;; If trace max is too far from ideal trace, adopt the crpix2 value
   ;; from the header.  This can happen if there are several saturated
   ;; lines or if the order includes Ly Alpha.
   
   IF (abs(yspec-crpix[1]) GT offset) THEN $
    yspec = crpix[1]
   
   ;; ----Fit background to compacted spectrum----
   ;; Fix range of fit.
   xfit1 = findgen(width/2.-offset)
   xfit2 = findgen(width/2.-offset)
   xfit2 = round(yspec+offset + xfit2)
   
   xgood = [xfit1, xfit2]
   ygood = squash(xgood)
   
   ;; Do fit and calculate background 
   fit_coeff = poly_fit(xgood,ygood,4) 
   
   yfit = findgen(width) &  xfit = findgen(width)
   yfit = poly(xfit, fit_coeff)
   
   ;; Subtract bg fit and normalize bg spectrum to max=1. 
   squashed = (squash-yfit)/max(squash-yfit)
   
   ;; ------------------------------------------------------------
   ;; Find points where flux < 0.035 max(flux).  These points will be
   ;; used for fitting the *real* bg.
   ;; ------------------------------------------------------------

   xgood = where(squashed LE 0.035) 
   ygood = squash(xgood)
   
   
   ;; There will be some nastiness if the order happens to contain
   ;; Ly alpha.  This is because the order is usually black, and the
   ;; maximum can be far from the central pixels...thus bg is fit over
   ;; the spectral trace.  As a crude way of flagging this, occurences
   ;; where the program has decided to include the central position of
   ;; the trace in the bg fit are corrected, and we use a cruder bg
   ;; region.
   
   lyalpha_flag = where(xgood EQ yspec)
   IF (lyalpha_flag[0] NE -1) THEN xgood = [xfit1, xfit2]
   
   xfit = findgen(width) & yfit=datain*0.
   
   
   
   ;; ------------------------------------------------------------
   ;; Now do the real background subtraction:
   ;; ------------------------------------------------------------
   
   
       ;;; Do a little smoothing!  Best: fwhm=[0.5,2.5]
                                ; Have to change kernel size depending
                                ; on image size:
   smooth_fwhm = [1.0, 2.5]
   
   IF keyword_set(hires_yes) THEN smooth_fwhm = smooth_fwhm*2.
   
   IF (n_elements(xgood) GT 15) THEN $
    kern = psf_gaussian(npix=13, fwhm=smooth_fwhm, /normalize) $
   ELSE IF (n_elements(xgood) GT 9) THEN $
    kern = psf_gaussian(npix=7, fwhm=smooth_fwhm, /normalize) $
   ELSE kern = psf_gaussian(npix=5, fwhm=smooth_fwhm, /normalize)
   
   
      ;;; In a few cases, we still have troubles with the 
      ;;; kernel size.  If there is little or no light in 
      ;;; an order, this IF statement will keep the program
      ;;; from bombing.
   
   IF (n_elements(xgood) LE 5) THEN smdatain =  datain ELSE $
   smdatain = convol(datain(*, xgood), kern, /edge_truncate)
   
   
      ;;; If the data are hires and sampled at twice that
      ;;; of normal data, scale the cross-dispersion weighting
      ;;; appropriately in the fit.
   
   IF keyword_set(hires_yes) THEN weight_scale = 2. $
    ELSE  weight_scale = 1.
   
   ;; Loop through the lines of the spectrum, fitting a polynomial to
   ;; the cross-dispersion direction.  This fit is weighted towards
   ;; points closer to the trace.
      
   FOR i=0,length-1 do BEGIN 
      ygood = findgen(n_elements(xgood))
      ygood(*)      =  smdatain(i,*)
      
      coeff = poly_fit_weighted(xgood, ygood,$
        sqrt(1.*weight_scale/abs(xgood-yspec)), 7)
      
      yfit(i, *) = poly(xfit, coeff)
   ENDFOR
   
   bg_out = yfit
   
      ;;; Return the background-subtracted spectrum in spec_out.
   spec_out = datain - bg_out
     
   return 
END 
