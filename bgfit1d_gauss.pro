PRO bgfit1d_gauss, header, datain, bg_out, spec_out, yspec, xgood, $
             HIRES=hires_yes
;+
; ----------------------------------------------------------------------
;  BGFIT1D_GAUSS -- 
;
;  *Program description:   
;    This routine is used to determine the appropriate 
;    background for 2D-rectified STIS images.  It fits
;    a cubic spline to the cross-dispersion background
;    for each column.  The result is a 2D background 
;    image that can be directly subtracted from the STIS
;    science image.  ** This routine differs from BGFIT1D
;    in that it uses a Gaussian fit to identify the spectral
;    trace; it also uses such fits to identify and mask out
;    other spectral orders that appear in the 2D images due
;    to non-optimal CALSTIS reference files.   
;   
;  *Calling sequence:
;     BGFIT1D_GAUSS, header, stis_image, bg_out, spec_outyspec, xgood, $
;             HIRES=hires_yes
;
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
;     POLY_FIT, POL_FIT_WEIGHTED, FXPAR, CONVOL, PSF_GAUSSIAN, POLY,
;         GAUSSFIT, GAUSSIAN
;    
;   *HISTORY:
;         7/99 -- Howk -- Created and added comments.
;        12/99 -- Howk -- Added HIRES compatability
;        12/00 -- Howk -- Changed polyfitw to poly_fit_weighted
;                          for use with IDL v5.4   
;         3/01 -- Howk -- Added gaussian fitting to identify spectral
;                          trace and multiple orders in the 2D spectrum.   
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
   width  = sz[2]
   length = sz[1]
   
   ;; Determine a fiducial spacing unit.
   offset  = round(width/ 4.5)    
   
   crpix   = fxpar(header, 'CRPIX*')
   cenwave = fxpar(header, 'CRVAL1')
   specorder = fxpar(header, 'SPORDER')
   
   ;; ------------------------------------------------------------
   ;; Compact spectrum along dispersion axis and derive cross-disp.
   ;;  profile of spectrum.
   ;; ------------------------------------------------------------

   squash = total(datain[*, *], 1)
   yyy = findgen(n_elements(squash))
   normsquash = squash/max(squash)
   
   ;       ;;; Find maximum of trace and store in yspec
   ;dummy = max(squash, yspec)
   
   ;; Find center of trace by fitting gaussian to squashed profile
   sqgood = where(abs(yyy-crpix[1]) LE 2.*offset)
   
   dummy = gaussfit(yyy[sqgood],normsquash[sqgood],aaa,nterms=4)
   yspec = round(aaa[1])
   
   dummy = gaussian(yyy, aaa)
   
   ydiff = normsquash-dummy
   ydiff_fit = gaussfit(yyy,ydiff,aa,nterms=4)
   ydiff_cen = aa[1] 
   ydiff_sig = aa[2]
   
   ;;Create a mask to mark those regions of the 2D spectrum not to be fit.
   datamask = 0.*datain+1.
   
   ;;Where extra gaussian components (other orders) exist, mask those
   ;; out.
                                ; Look only for regions that are
                                ; narrow enough to be another order.
   IF abs(ydiff_sig) LE 3. THEN BEGIN 
      ;;
      IF (ydiff_cen LE 0) OR (ydiff_cen LE 2.*abs(ydiff_sig)) THEN BEGIN 
         ybad = indgen(round(2.*abs(ydiff_sig)))
         datamask[*, ybad] = 0.
         numbad = n_elements(ybad)
      ENDIF ELSE IF (abs(width-ydiff_cen) LE 2.*abs(ydiff_sig)) $
       THEN BEGIN       
         ybad = width-indgen(round(2.*abs(ydiff_sig)))-1.
         datamask[*, ybad] = 0.
         numbad = n_elements(ybad)
      ENDIF ELSE BEGIN 
         ybad = -1.
         numbad = 0.
      ENDELSE 
      ;;
   ENDIF ELSE BEGIN 
      ;;
      ybad = -1
      numbad = 0.
      ;;
   ENDELSE  
   
   ;; Redetermine fiducial spacing unit given number of bad pts.
   offset  = round((width-numbad)/ 4.5) 
      
   ;; If trace max is too far from ideal trace, adopt the crpix2 value
   ;; from the header.  This can happen if there are several saturated
   ;; lines or if the order includes Ly Alpha.
   
   IF (abs(yspec-crpix[1]) GT offset) THEN BEGIN 
      yspec = crpix[1]
      print, 'WARNING: Assuming spectral trace is centered at CRPIX2 for '+$
       'order '+strtrim(specorder, 2)
   ENDIF 
   
   ;;  ------------------- OBSOLETE -------------------->>
   ;; ----Fit background to compacted spectrum----
   ;; Fix range of fit.
   ;;xfit1 = findgen(width/2.-offset)
   ;;xfit2 = round(yspec+offset + xfit1)
   ;;xfit2 = width-xfit1
   ;;st = sort(xfit2)
   
   ;;xgood = [xfit1, xfit2[st]]
   ;;xgood = xgood[where(datamask[crpix[0], xgood] NE 0.)]
   ;;ygood = squash(xgood)
   ;;  <<------------------- OBSOLETE --------------------
   
   
   ;; ----Fit background to compacted spectrum----
   ;; Fix range of fit.
   xgood = where(abs(yyy-yspec) GE offset/2.)
   xgood = xgood[where(datamask[crpix[0], xgood] NE 0.)]
   ygood = squash[xgood]   
   
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
   xgood = xgood[where(datamask[crpix[0], xgood] NE 0.)]
   ygood = squash(xgood)
   
   
   ;; There will be some nastiness if the order happens to contain
   ;; Ly alpha.  This is because the order is usually black, and the
   ;; maximum can be far from the central pixels...thus bg is fit over
   ;; the spectral trace.  As a crude way of flagging this, occurences
   ;; where the program has decided to include the central position of
   ;; the trace in the bg fit are corrected, and we use a cruder bg
   ;; region.
   
   lyalpha_flag = where(xgood EQ yspec)
   IF (lyalpha_flag[0] NE -1) THEN BEGIN 
      xgood = where(abs(yyy-yspec) GE offset/2.)
      xgood = xgood[where(datamask[crpix[0], xgood] NE 0.)]
   ENDIF 
   
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
   smdatain = convol(datain[*, xgood], kern, /edge_truncate)
   
   
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
      ygood[*] = smdatain[i,*]
      
      coeff = poly_fit_weighted(xgood, ygood,$
        sqrt(1.*weight_scale/abs(xgood-yspec)), 7)
      
      yfit[i, *] = poly(xfit, coeff)
   ENDFOR
   
   bg_out = yfit
   
      ;;; Return the background-subtracted spectrum in spec_out.
   spec_out = datain - bg_out
     
   return 
END 
