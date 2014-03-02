
;- Blitz2/AmiBlitz macros for building libs in asm.

;- Note: all init/exit/statements/funcs MUST preserve A3-A6 !

;-- hrm.. several AlibJsrs to look at in EFMUI.
;-- 426,428,cf02
;-- need to check repargs macro..

TARG  SET   0
NFUNCS   SET   0



;-- return types

BYTE  EQU 1
WORD  EQU 2
LONG  EQU 3
QUICK EQU 4
FLOAT EQU 5
STRING  EQU 7
ARRAY	EQU $20	;-- i think !

;- Args for libs macro.. OR these together.
;-- oops, does this clash ?
A0 EQU   $1000
A1 EQU   $1100
A2 EQU   $1200
A3 EQU   $1300
A4 EQU   $1400
A5 EQU   $1500
A6 EQU   $1600

P0 EQU   $80
P1 EQU   $81
P2 EQU   $82
P3 EQU   $83
P4 EQU   $84
P5 EQU   $85

;---- Args for shared/fd converted libs.
SD0   EQU   0
SD1   EQU   1
SD2   EQU   2
SD3   EQU   3
SD4   EQU   4
SD5   EQU   5
SD6   EQU   6
SD7   EQU   7

SA0   EQU   $10
SA1   EQU   $11
SA2   EQU   $12
SA3   EQU   $13
SA4   EQU   $14
SA5   EQU   $15
SA6   EQU   $16
SA7   EQU   $17

;-----------------------------------------------------------------------------
   Macro pchk
      If (\1 -\2)
         Echo "Wrong number of macro parameters"
         Fail
      Endif
   EndM

;-----------------------------------------------------------------------------
   Macro chkfuncs
NFUNCS SET   (NFUNCS + 1)
      IFGE  (NFUNCS-128)
         ECHO  "This lib needs splitting !"
         FAIL
      ENDIF
   EndM
;-----------------------------------------------------------------------------
   Macro syslibheader
TARG  SET   NARG
START:      ; label needed for AlibJSR's etc !

         IFEQ (TARG - 8)
      MOVEQ #0,D0
      RTS
      dc.w  \1
      dc.l  0
      dc.w  0,\8,\2,\3
      dc.l  0,\4
      dc.w  \5
      dc.l  \6,0,0,0,\7
         ELSE
         ;-- if args !=8
      pchk  TARG,7
      MOVEQ #0,D0
      RTS
      dc.w  \1
      dc.l  0,0
      dc.w  \2,\3
      dc.l  0,\4
      dc.w  \5
      dc.l  \6,0,0,0,\7
          ENDIF

   EndM
;-----------------------------------------------------------------------------
;-- SharedLibHeader(library#,init,return,cleanup,runerrs)
;-- learned by decompilation..

   Macro sharedlibheader
      ;-- needs arg check for 5 args
TARG  SET   NARG
      pchk  TARG,5
      dc.l  0  ;-- instead of MOVEQ/RTS
      dc.w  \1
      dc.l  0,0,0,0
      dc.l  \2
      dc.w  \3
      dc.l  \4
      dc.l  0,0,0
      dc.l  \5
   EndM
;-----------------------------------------------------------------------------
;-- LibHeader(library#,init,return,cleanup,runerrs)
   Macro libheader
      ;-- needs arg check for 5 args
START:      ; label needed for AlibJSR's etc 
TARG  SET   NARG
      pchk  TARG,5
      MOVEQ #0,D0
      RTS
      dc.w  \1
      dc.l  0,0,0,0
      dc.l  \2
      dc.w  \3
      dc.l  \4
      dc.l  0,0,0
      dc.l  \5
   EndM
;-----------------------------------------------------------------------------
   Macro libfin
      ; hrm.. not quite!
      dc.w  -1
      IFEQ (NARG)
      	dc.l  0  ; only if no args! FIXME !!
      ELSE
	dc.l \1,\2,\3,\4,\5
	dc.w 0,\6,\7
      ENDIF
      Echo  \1
   EndM
;-----------------------------------------------------------------------------
   Macro afunction
TARG  SET   NARG
      chkfuncs    ; check for 128+ functions!
      pchk  TARG,1
      dc.w  (\1 <<8)+2
      dc.w  0,0
   EndM
;-----------------------------------------------------------------------------
   Macro acommand
TARG  SET   NARG
      chkfuncs    ; check for 128+ functions!
      pchk  TARG,1
      dc.w  (\1<<8)+3,0,0
   EndM
;-----------------------------------------------------------------------------
   Macro astatement
TARG  SET   NARG
      chkfuncs    ; check for 128+ functions!
      pchk  TARG,0
      dc.w  1,0,0
   EndM

;-----------------------------------------------------------------------------
   Macro slfunction
      chkfuncs    ; check for 128+ functions
      dc.w  6,0,0
      dc.w  \1 ; needed lib ? should always have it!
      dc.w  \2 ; LVO for this function
      ;-- now args..
CARG  SET   3
NARG  SET   NARG-2
      REPT  (NARG)
         dc.b  \+
      ENDR

      dc.b  -1
      ;-- even it out 
      CNOP 0,2
      dc.w  0,0,0    ;-- dunno always seems to be 0.

   EndM
;-----------------------------------------------------------------------------
   Macro slname
      dc.b  \1,0
      dc.b  \2,0
      CNOP 0,2
   EndM
;-----------------------------------------------------------------------------
   Macro name
      dc.w  -1
      dc.l  0
      dc.w  0
;-- eek, \3 can be used as a label here.
       IFEQ (NARG-3)
   IF (\3)
\3:
   ENDIF
       ENDIF
      dc.b  \1,0
      dc.b  \2,0
      CNOP 0,2
   EndM
;-----------------------------------------------------------------------------
   Macro subs
TARG  SET   NARG
      pchk  TARG,3
      dc.l  \2,\1,\3
      CNOP 0,2
   ENDM
;-----------------------------------------------------------------------------
   Macro libs
      REPT  (NARG/2)
         dc.w  \+,\+
      ENDR
      dc.w  0  
   ENDM

;-----------------------------------------------------------------------------
   Macro args
      dc.w  NARG
      REPT  NARG
         dc.b  \+
      ENDR
      
      CNOP 0,2
   EndM
;-----------------------------------------------------------------------------
   Macro nullsub
      dc.w  0,0,0
      ;-- now the libs .. (arg 4+) .. add support for more libs?
      libs \4,\5,\6,\7,\8,\9
      dc.l  \2,\1,\3
      
   EndM
;-----------------------------------------------------------------------------
   Macro dumtoke
      dc.w  8,0,0
      dc.l  0
      dc.w  0
;-- create token label.
   IFEQ (NARG-3)
\3:
   ENDIF
      dc.b  \1,0
      dc.b  \2,0
      CNOP 0,2
   EndM

;-----------------------------------------------------------------------------
    Macro repargs
	dc.w (\1 << 12)|(\2 << 8)|(NARG-2)
	;-- now do normal args..
NARG	SET	(NARG-2)
CARG	SET	3
	REPT	(NARG)
		dc.b	\+
	ENDR
	CNOP 0,2
    EndM
;-----------------------------------------------------------------------------
;-- Done this way to stop any possible optimising by phxass.
;-- ALibJSR $c002 for AllocMem
   Macro BlitzAllocMem
	dc.w	$4eb9
	dc.l	START-($80000000-$C002)
   EndM
;-----------------------------------------------------------------------------
   Macro BlitzFreeMem
	dc.w	$4eb9
	dc.l	START-($80000000-$C003)
   EndM
;-----------------------------------------------------------------------------
   Macro BlitzAllocStr
	dc.w	$4eb9
	dc.l	START-($80000000-$CF01)
   EndM

;-----------------------------------------------------------------------------
   Macro BlitzFreeStr
	dc.w	$4eb9
	dc.l	START-($80000000-$CF02)
   EndM
;-----------------------------------------------------------------------------
   Macro  AlibJSR
	dc.w	$4eb9
	dc.l	START-($80000000-\1)
   EndM

;-----------------------------------------------------------------------------
;-- Shared Library/Resource Init+Exit functions.
;-- Moved here so it can be changed without having to edit all the sources..

    Macro shared_init
InitFunc:
	IFD (Is_Resource)
		;-- Resource opener.
		movea.l	4.w,a6
		lea	name(pc),a1
		jmp	-498(a6)	; OpenResource()
		
		;-- resource has no close function..

    	Else
    		;-- Std. library opener
		movea.l	4.w,a6
		lea	name(pc),a1
		jmp	-408(a6)	; OldOpenLibrary() .. no need to set d0.

		;-- Std. library closer
ExitFunc:
		move.l	a1,d0		
		beq.s	Exit		; skip, if lib was never opened!
		movea.l	4.w,a6
		jmp	-414(a6)	; CloseLibrary()
Exit:
		rts
	Endif
    EndM
