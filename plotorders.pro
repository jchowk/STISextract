@printroutines
PRO plotorders, rootname, objname, ASCII=ascii_yes
;+
; ----------------------------------------------------------------------
;   PLOTORDERS --   
;      
;   *Program Description:
;       This program will produce a postscript plot of the output
;        from the STISEXTRACT procedures.   
;
;   *Calling sequence:
;      PLOTORDERS, rootname, /ascii
;
;   *Inputs:
;      rootname -- The STScI rootname of the observation 
;                   (e.g., 'o4qx04040').
;   
;   *Optional Keywords:
;       /ascii  -- write output to ascii files rather than IDL
;                   save files.
;
;   *HISTORY:
;       8/99 -- Howk -- Created and documented.
;      12/99 -- Howk -- Added \ascii keyword.
; ----------------------------------------------------------------------   
;-    
   
   
   IF N_PARAMS() EQ 0 THEN BEGIN 
      print, ''
      print, 'PLOTORDERS, rootname, objname, /ascii'
      print, ''
      print, '  *Inputs:'
      print, '     rootname -- STIS rootname.'
      print, '     objname  -- Object name.'
      print, ''
      print, '  '
      print, '  *Keywords:'
      print, '    \ascii    -- Plot data from ascii files rather '
      print, '                  than save files.'
      print, ''
      
      retall
   ENDIF 
   
   IF n_params() LT 2 THEN objname = ''
   

   
   !p.thick = 1.8
   !p.charsize = 1.1
   !x.charsize = 1.1
   !y.charsize = 1.1
   !p.multi = [0, 1, 3]
   !x.style = 1
   
   xxxzero = [-1e6,1e6]
   yyyzero = [0,0]
   
   IF keyword_set(ascii_yes) THEN $
    names = findfile2(rootname+'.*.dat', /sort) $
   ELSE names = findfile2(rootname+'.*.save', /sort)
   
   psp, /long
   
   
   FOR i=0, n_elements(names)-1 DO BEGIN 
      
      ind = n_elements(names)-1 - i
      
      startpos = strpos(names[ind], '.')+1.
      ordernum = strmid(names[ind], startpos, 3)
      
      IF (strpos(ordernum, '.') NE -1) THEN $
       ordernum = strmid(ordernum, 0, 2)      
      orderstring = strtrim(ordernum, 2)
         
      IF keyword_set(ascii_yes) THEN $
       readcol, names[ind], wave, gross, flux, err, bg, /silent $
      ELSE restore, names[ind]
      
      sz = size(wave)
      
      titlestring = strupcase(rootname)+'; Order '+orderstring
            
      plot,wave[8:sz[1]-10],flux[8:sz[1]-10],xr=[wave[6],wave[sz[1]-8]], $
       charsize=1.75, psym=10
      oplot, wave[8:sz[1]-10],bg[8:sz[1]-10], linestyle=1, psym=10
      oplot,xxxzero, yyyzero, linestyle=1
      
      xpos = !x.crange[1]-0.015*(!x.crange[1]-!x.crange[0])
      ypos = !y.crange[1]+0.035*(!y.crange[1]-!y.crange[0])
      xyouts, xpos, ypos, titlestring, align=1.0
      
      xpos = !x.crange[0]+0.015*(!x.crange[1]-!x.crange[0])
      ypos = !y.crange[1]+0.035*(!y.crange[1]-!y.crange[0])
      xyouts, xpos, ypos, objname, align=0.      
      
   ENDFOR 
   
   lp
   
   spawn_text = 'mv idl.ps '+strupcase(rootname)+'.ps'
   spawn, spawn_text
      
   !p.multi = 0
END 
