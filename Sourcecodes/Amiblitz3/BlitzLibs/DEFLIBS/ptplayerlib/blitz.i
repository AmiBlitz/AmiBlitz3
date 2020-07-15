*** Blitz.i ****************************************************************************
*                                                                                      *
* Written by Olivier Laviale (lotan9@aol.com)                                          *
*                                                                                      *
*** Start of the library ***************************************************************
*                                                                                      *
* Do not touch / move / remove the label _BlitzLibStart, or you  will  no  longer  be  *
* able to use ALibJsr Macro, and all BlitzSystem functions...                          *
*                                                                                      *
_BlitzLibStart
*                                                                                      *
* Note that Blitz.i must always be included first, because of this label, as it  must  *
* be the first of the source.                                                          *
*                                                                                      *
****************************************************************************************

*** Macros to build a library for BlitzBasic *******************************************

libheader   Macro
            MOVEQ   #0,d0
            RTS

            Dc.w    \1
            Dc.l    0,0,0,0,\2
            Dc.w    \3
            Dc.l    \4,0,0,0,\5
            EndM

astatement  Macro
            Dc.w    1,0,0
            EndM

acommand    Macro
            Dc.b    \1,3
            Dc.w    0,0
            EndM

afunction   Macro
            Dc.b    \1,2
            Dc.w    0,0
            EndM

args        Macro
            Dc.w    NARG
                REPT    NARG
                Dc.b    \+
                ENDR
            Even
            EndM

repa        Macro
            Dc.w        (\+ << 12) | (\+ << 8) | (NARG-2)
                REPT  NARG-2
                Dc.b  \+
                ENDR
            Even
            EndM

libs        Macro
                REPT    NARG
                Dc.w    \+
                ENDR
            EndM

subs        Macro
            Dc.l    0
            Dc.w    \2
            Dc.l    \1,\3
            EndM

name        Macro
            Dc.w    $FFFF,0,0,0
            Dc.b    \1,0,\2,0
            Even
            EndM

libfin      Macro
            Dc.w    $FFFF,0,0
            EndM

nullsub     Macro
            Dc.w    0,0,0
CARG    SET 4
                REPT    NARG-3
                Dc.w    \+
                ENDR
            Dc.w    0
            Dc.l \2,\1,\3
            EndM

*** Supported Types ********************************************************************

byte        EQU 1
word        EQU 2
long        EQU 3
quick       EQU 4
float       EQU 5
string      EQU 7

usesize     equ 0
unknown     equ 8
arrayend    equ 16
array       equ 32
push        equ 64
varptr      equ 128

*** BlitzLibraries constants ***********************************************************

; These constants are for passing data directly to a register from a library

ld0 equ    0
ld1 equ $100
ld2 equ $200
ld3 equ $300
ld4 equ $400
ld5 equ $500
ld6 equ $600
ld7 equ $700

la0 equ $1000
la1 equ $1100
la2 equ $1200
la3 equ $1300
la6 equ $1600

; This one means you want it pushed on the stack

lpush equ $ff00

; Asking for a USED type data puts the currently used struct of a max type lib into
; the appropriate reg

_used equ 2

ud0 equ ld0|_used
ud1 equ ld1|_used
ud2 equ ld2|_used
ud3 equ ld3|_used
ud4 equ ld4|_used
ud5 equ ld5|_used
ud6 equ ld6|_used
ud7 equ ld7|_used

ua0 equ la0|_used
ua1 equ la1|_used
ua2 equ la2|_used
ua3 equ la3|_used
ua6 equ la6|_used

** Amiga Libraries *********************************************************************

intuitionlib            equ 255
graphicslib             equ 254
execlib                 equ 253
doslib                  equ 252
diskfontlib             equ 251
graphicslib2            equ 250
doslib2                 equ 249
amigaguidelib           equ 248
asllib                  equ 247
battclocklib            equ 246
batmemlib               equ 245
bulletlib               equ 244
cardreslib              equ 243
ciaalib                 equ 242
ciablib                 equ 241
commoditieslib          equ 240
datatypeslib            equ 239
disklib                 equ 238
expansionlib            equ 237
gadtoolslib             equ 236
iconlib                 equ 235
iffparselib             equ 234
keymaplib               equ 233
layerslib               equ 232
localelib               equ 231
mathffplib              equ 230
mathieeedoubbaslib      equ 229
mathieeedoubtranslib    equ 228
mathieeesingbaslib      equ 227
mathieeesingtranslib    equ 226
mathtranslib            equ 225
misclib                 equ 224
potgolib                equ 223
rexxsyslib              equ 222
utilitylib              equ 221
wblib                   equ 220

*** Blitz System ***********************************************************************

ALibJsr     Macro
            JSR   _BlitzLibStart-($80000000-\1)
            ENDM

BLibJsr     MACRO
            JSR   _BlitzLibStart-( ($4000-\2) << 16 + (0 - \1) << 16 >> 16)
            ENDM

Blitz_AllocMem    equ   $0000C002
Blitz_FreeMem     equ   $0000C003
Blitz_AllocStr    equ   $0000CF01
Blitz_FreeStr     equ   $0000CF02

BAllocMem   Macro
      MOVE.L      \1,d0                   ; Size
      MOVE.L      \2,d1                   ; Type
      ALibJsr     Blitz_AllocMem
            IFEQ  NARG-3
      MOVE.L      d0,\3                   ; Var holding result
            EndC

            EndM

BFreeMem    Macro
      MOVEA.L     \1,a1                   ; Addr
      MOVE.L      \2,d0                   ; Size
      ALibJsr     Blitz_FreeMem
            EndM

BAllocStr   Macro
      MOVE.L      \1,d1                   ; Size
      ALibJsr     Blitz_AllocStr
            IFEQ  NARG-2
      MOVE.L      d0,\2                   ; Var holding result
            EndC
            EndM

BFreeStr    Macro
      MOVE.L      \1,d0                   ; Addr
      ALibJsr     Blitz_FreeStr
            EndM
