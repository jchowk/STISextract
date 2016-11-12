PRO stis_setup
;+
; ----------------------------------------------------------------------
;  STIS_SETUP -- 
;
;  *Program description:   
;    This routine defines system variables used with the 
;       FITS readers included as part of the STISEXTRACT
;       support package.  This routine is based on the 
;       start-up variables used with the GHRS IDT software.   
;   
;  *Calling sequence:
;     STIS_SETUP
;
;   *HISTORY:
;        12/99 -- Howk -- Created and documented
;                         
; ----------------------------------------------------------------------
;-   
   
   ;;------------------------------------------------------------
   ;;
   ;; System variables required for running support software
   ;;
   ;;------------------------------------------------------------
   
   
   defsysv,'!plotunit', exists=i 
   IF (i eq 0) THEN defsysv,'!plotunit',0 ; Redirect plot output
   
   defsysv,'!textout', exists=i
   IF (i eq 0) THEN defsysv,'!textout',1 ; Redirect text output
   
   defsysv,'!textunit', exists=i 
   IF (i eq 0) THEN defsysv,'!textunit',0 ; ...works with !textout
   
   defsysv,'!noprint', exists=i 
   IF (i eq 0) THEN defsysv,'!noprint',0 ; Suppress text output
   
   defsysv,'!noplot', exists=i 
   IF (i eq 0) THEN defsysv,'!noplot',0 ; Suppress graphics output
   
   defsysv,'!dump', exists=i 
   IF (i eq 0) THEN defsysv,'!dump',1 ; Level of output display mode
   
END 
