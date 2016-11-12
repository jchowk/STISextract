pro fdecomp,filename,disk,dir,name,qual,version
;+
; NAME:
;    FDECOMP
; PURPOSE:
;    Routine to decompose file name
; CALLING SEQENCE:
;	fdecomp,filename,disk,dir,name,qual,version
; INPUT:
;	filename - string file name
; OUTPUTS:
;	disk - disk name, always null on a Unix machine
;	dir - directory name
;	name - file name
;	qual - qualifier
;	version - version number, always null on a Unix machine
; ROUTINES CALLED:
;       GETTOK
; NOTES:
;	1) Does not handle unix  ../ syntax.
;	2) Does not handle non-standard unix names (i.e. this.is.non.standard)
;	3) Does not handle unix network names (i.e. node:/disk1/data)
; RESULTS:
;	All tokens are removed between:
;		1) name and qual	(i.e. period is removed)
;		2) qual and ver		(i.e. semicolon is removed)
;
; HISTORY
;	version 1  D. Lindler  Oct 1986
;	converted to SUN IDL.  M. Greason, STX, 30 July 1990.
;       Revised by N. Collins, STX, Nov., 1990
;          (combined VAX and SUN versions of FDECOMP into one routine)
;	22-may-1993	JKF/ACC		- added support for IDL for Windows.
;	9-dec-1996	JKF/ACC		- IDL for Windows (4.0 or higher)-Win32
;          
;-
;--------------------------------------------------------
;
npar = n_params(0)
if (npar lt 6) then ver=''
if (npar lt 5) then qual=''
if (npar lt 4) then name=''
if (npar lt 3) then dir=''
if (npar lt 2) then begin
  print,$
     'CALLING SEQUENCE: fdecomp,filename,disk,[dir,name,qual,ver]'
  return
endif
;
;   find out what machine you're on, and take appropriate action.
;
os = strupcase(!version.os)
case  1 of
	os eq "VMS": begin
    		st=filename

		; get disk
    		if strpos(st,':') ge 0 then disk=gettok(st,':')+':' else disk=''
		; get dir

    		if strpos(st,']') ge 0 then dir=gettok(st,']')+']' else dir=''

		; get name
    		name=gettok(st,'.')
		
		; get qualifier
    		qual=gettok(st,';')
		
		; get version
    		version=st
		;
  		end
	
	(os eq "WINDOWS") or (os eq "DOS") or (os eq 'WIN32'): begin
		st=filename
		lpos = -1	; directory position path (i.e. \dos\idl\)
    		pos = -1
		pos = strpos( st, ':')		; DOS diskdrive (i.e. c:)
		if (pos gt 0) then disk = gettok(st,':') + ':' else disk=''
		;
    		;  Search the path name (i.e. \dos\idl\) and locate all backslashes
		;
		lpos = -1
    		pos = -1
    		repeat begin
	    		pos = strpos(st, '\',pos+1)
	    		if (pos ge 0) then lpos = pos
    		endrep until pos lt 0
		;
		;  Parse off the directory path 
		;
    		if lpos ge 0 then begin
	    		dir = strmid(st, 0, lpos+1)
	    		len = strlen(st)
	    		if lpos eq (len-1) then $
				st = '' else st = strmid(st,lpos+1,len-lpos-1)
    		endif else dir=''
		;
		; get DOS name and qual(extension)...qual is optional
		;
    		pos=-1
    		lpos=-1
    		repeat begin				
             		pos = strpos(st,'.',pos+1)
             		if (pos ge 0) then lpos = pos
    		endrep until pos lt 0
		;
		; Parse name and qual (if a qual was found )
		;
    		if lpos ge 0 then begin
             		len = strlen(st)
             		name = strmid(st,0,lpos)
			if lpos gt 8 then $
				message,/cont," DOS FILENAME should not " + $
					"exceed 8 chars...name: "+name
             		qual = strmid(st,lpos+1,len-lpos-1)
			if strlen(qual) gt 3 then $
				message,/cont," DOS QUALIFIER should not exceed 3 chars."
     		endif else begin
         		name = st
         		qual = '' 
     		endelse
    		version = ''		; no version numbers in dos 	
		end

	else : begin			; ( all unix platforms )		
    		st=filename
    		disk = ''	; disk (n/a in unix)
    		lpos = -1	; directory position path (i.e. /disk/idl/)
    		pos = -1
		;
    		;  Search the path name (i.e. /disk/idl/) and locate all slashes
		;
    		repeat begin
	    		pos = strpos(st, '/', pos+1)
	    		if (pos ge 0) then lpos = pos
    		endrep until pos lt 0
		;
		;  Parse off the directory path 
		;
    		if lpos ge 0 then begin
	    		dir = strmid(st, 0, lpos+1)
	    		len = strlen(st)
	    		if lpos eq (len-1) then $
				st = '' else st = strmid(st,lpos+1,len-lpos-1)
    		endif else dir=''
		;
		; get name and qual(extension)
		;
    		pos=-1
    		lpos=-1
    		repeat begin
             		pos = strpos(st,'.',pos+1)
             		if (pos ge 0) then lpos = pos
    		endrep until pos lt 0
		;
		; Unix does not require a qualifier. If no . is found, assume
		; remaining string is the name of the file (i.e. myfile).
		;
    		if lpos ge 0 then begin
             		len = strlen(st)
             		name = strmid(st,0,lpos)
             		qual = strmid(st,lpos+1,len-lpos-1)
     		endif else begin
         		name = st
         		qual = '' 
     		endelse
    		version = ''		; no version numbers in unix
	end

endcase
return
end
