@fits_info
@writestis
@stisextract
@plotorders
@stis_setup
PRO stisdriver, rootname, NOGAUSS=nogauss, $
            SUMMED=summed_yes, ASCII=ascii_yes, SKIP=skip_yes
;+
; ----------------------------------------------------------------------
;   STISDRIVER --   
;      
;   *Program Description:
;       This program is designed to drive the spectral extraction of
;       a STIS dataset including accurate background subtraction.
;       The primary routine for doing the extraction is STISEXTRACT.
;   
;      The outputs of this routine are a set of IDL save files
;       rootname.###.save, where ### is the spectral order in that
;       save file.  By setting the keyword /ascii in the calling the
;       procedure, ascii files named rootname.###.dat will be produced
;       instead.  A postscript file containing plots of flux versus
;       wavelength for every spectral order is also output in the file
;       ROOTNAME.ps (where ROOTNAME is the rootname of the observation
;       in all caps).
;
;   *Calling sequence:
;      STISDRIVER, rootname, /summed, /skip, /ascii, /nogauss
;
;   *Inputs:
;      rootname -- The STScI rootname of the observation 
;                   (e.g., 'o4qx04040').
;   
;   *Optional Keywords:
;       /summed -- extracts the data from an _sx2 file rather
;                   than _x2d file.
;       /ascii  -- write output to ascii files rather than IDL
;                   save files.
;       /skip   -- skips the first order in the file.  Useful
;                   if order is corrupt (e.g., falls off the edge
;                   of the detector).   However, the problem for
;                   which this is designed should be taken care
;                   of within STISEXTRACT.   
;      /nogauss  -- Do not use Gaussian fit to derive center of
;                   spectral trace and interloping orders in 2D
;                   spectral images.  **This option is faster but
;                   is less robust to problems in STIS reference 
;                   files.**   
;   
;   *External Routines Called:
;       FITS_OPEN,  WRITESTIS, STISEXTRACT, PLOTORDERS
;
;   *HISTORY:
;       7/99 -- Howk -- Created and added comments
;       8/99 -- Howk -- Added ability to skip first order if corrupt.
;      12/99 -- Howk -- Added \ascii keyword.
;       1/00 -- Howk -- Modified FITS input.  Now uses FITS_OPEN to
;                       access data and calls modified STISEXTRACT
;                       with appropriate control block structure.
;                         -- Modification adopted from suggestion by 
;                              W. Landsman (GSFC)   
;         3/01 -- Howk -- Added  BGFIT1D_GAUSS compliance.    
;   
; ----------------------------------------------------------------------   
;-   
   
   IF N_PARAMS() EQ 0 THEN BEGIN 
      print, ''
      print, 'STISDRIVER, rootname, /summed, /skip, /ascii, /nogauss'
      print, ''
      print, '  *Inputs:'
      print, '     rootname -- STIS _x2d or _sx2 rootname.'
      print, ''
      print, '  '
      print, '  *Keywords:'
      print, '    /summed   -- Use _sx2 FITS file.'
      print, '    /ascii    -- Output ascii files rather than IDL save files.'
      print, '    /skip     -- Skip the first order of the observation.'
      print, '    /nogauss  -- Do not use Gaussian to identify spectral trace.'
      print, ''
      
      retall
   ENDIF 

  ;; Make sure the correct system variables are defined.
  stis_setup   
  
  ;; Determine if summed or singular exposures are to be used.
  IF KEYWORD_SET(summed_yes) THEN suffix = '_sx2.fits' $
  ELSE suffix = '_x2d.fits' 
  
  ;; Access FITS file and store control block info in fcb variable.
  ;;   Thanks to W. Landsman for the suggestion.     
  fits_open,rootname+suffix,fcb
  num_extens = fcb.nextend      ;Store the number of FITS extensions.
  
  IF NOT keyword_set(nogauss) THEN BEGIN 
     ;;
     IF keyword_set(skip_yes) THEN BEGIN 
        FOR iii=1, (num_extens/3.)-1. DO BEGIN 
           exnum = iii*3.+1.    ; Three extensions (SCI,ERR,DQ) per order. 
           stisextract, fcb, exnum, w, g, f, bg, err, sporder, /smoothbg
           IF keyword_set(ascii_yes) THEN $
            writestis, rootname, sporder, w, g, f, err, bg $
           ELSE writestis, rootname, sporder, w, g, f, err, bg, /savefile
        ENDFOR   
     ENDIF ELSE BEGIN 
        FOR iii=0, (num_extens/3.)-1. DO BEGIN 
           exnum = iii*3.+1.    ; Three extensions (SCI,ERR,DQ) per order. 
           stisextract, fcb, exnum, w, g, f, bg, err, sporder, /smoothbg
           
           IF keyword_set(ascii_yes) THEN $
            writestis, rootname, sporder, w, g, f, err, bg $
           ELSE writestis, rootname, sporder, w, g, f, err, bg, /savefile
           
        ENDFOR 
     ENDELSE     
     ;;
  ENDIF ELSE BEGIN  ;; NO GAUSSIAN FIT TO SPECTRAL TRACE
     ;;
      IF keyword_set(skip_yes) THEN BEGIN 
        FOR iii=1, (num_extens/3.)-1. DO BEGIN 
           exnum = iii*3.+1.    ; Three extensions (SCI,ERR,DQ) per order. 
           stisextract, fcb, exnum, w, g, f, bg, err, sporder, $
            /smoothbg, /nogauss
           IF keyword_set(ascii_yes) THEN $
            writestis, rootname, sporder, w, g, f, err, bg $
           ELSE writestis, rootname, sporder, w, g, f, err, bg, /savefile
        ENDFOR   
     ENDIF ELSE BEGIN 
        FOR iii=0, (num_extens/3.)-1. DO BEGIN 
           exnum = iii*3.+1.    ; Three extensions (SCI,ERR,DQ) per order. 
           stisextract, fcb, exnum, w, g, f, bg, err, sporder, $
            /smoothbg, /nogauss
           
           IF keyword_set(ascii_yes) THEN $
            writestis, rootname, sporder, w, g, f, err, bg $
           ELSE writestis, rootname, sporder, w, g, f, err, bg, /savefile
           
        ENDFOR 
     ENDELSE     
     ;;   
  ENDELSE      
     
  fits_close, fcb  
  
  
  
  ;; NOTE: For now, the extracted background spectra are always
  ;; smoothed with a Lee filter.
  
  
  ;;Output postscript file showing the order-by-order extracted
  ;; spectrum.
  
  in = mrdfits(rootname+suffix, 0, head, /silent)
  objname = strtrim(fxpar(head, 'TARGNAME'), 2)
  IF NOT keyword_set(ascii_yes) THEN plotorders, rootname, objname
    
END 

;;rootname = '
;;in = mrdfits(rootname+suffix, 0, head, /silent)
;;objname = strtrim(fxpar(head, 'TARGNAME'), 2)
;;plotorders, rootname, objname
