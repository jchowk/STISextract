function OS_FAMILY
;+
; NAME:
;	OS_FAMILY
; PURPOSE:
;	Return the current operating system as in !VERSION.OS_FAMILY 
;
; CALLING SEQUENCE
;	result = OS_FAMILY()
; INPUTS: 
;	None
; OUTPUTS:
;	result - scalar string containing one of the four values
;		'Windows','MacOS','vms' or 'unix'
; NOTES:
;	OS_FAMILY is assumed to be 'unix' if !VERSION.OS is not 'windows',
;		'MacOS' or 'vms'
;
;	To make procedures from IDL V4.0 and later compatibile with earlier
;	versions of IDL, replace calls to !VERSION.OS_FAMILY with OS_FAMILY().	
;
; PROCEDURES CALLED
;	function TAG_EXISTS()
; REVISION HISTORY:
;	Written,  W. Landsman     
;	12/9/96	JKF/ACC		- IDL Version 4.0 and higher(Win32)
;-
 if tag_exist(!VERSION, 'OS_FAMILY') then return, !VERSION.OS_FAMILY

 case !VERSION.OS of

'windows': return, 'Windows'
  'Win32': return, 'Windows'
  'MacOS': return, 'MacOS'
    'vms': return, 'vms'
     else: return, 'unix'

 endcase

 end
