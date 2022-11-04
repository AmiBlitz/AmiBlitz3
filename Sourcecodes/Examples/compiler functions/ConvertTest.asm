;This shows what can convert from a .asm file to bb2 asm

wert EQU 3
;wert2 SET wert+1
                  ; macro
test3 dc.b "AllocMem"
AllocMem
 jsr AllocMem
.10
 bra .10
test macro
\@2
 bra \@2
  endm;docu

test2 MACRO
  move.l \1,d0 

 ENDM ;docu
   move.l $4.W,a0
   test d0
   test d1
   move.l #wert,d0
   ;move.l #wert2,d1
   dc.b "צהü"

