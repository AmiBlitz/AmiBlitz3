; In_Go Reassembler nclipboard.obj: 24.04.2004 11:47:46
MaxIntSgnd EQU $7FFFFFFF
Optimize68020 EQU 0
 SECTION "Segment0",CODE
 cnop 0,4
SegmentBeginn0:
  moveq.l #$00,D0
 rtS 
 
  dc.b $00,$A3,$00,$00 ;....
  ds.l 5
  dc.l AL_0_11C
  ds.l 4
  dc.b $00,$01,$00,$00 ;....
  ds.w 1
  dc.b $00,$01,$07,$00 ;....
  dc.b $00,$FD,$16,$00 ;....
  ds.w 3
  dc.l AJL_0_136
  ds.l 1
  dc.b $FF,$FF,$00,$00 ;....
  ds.l 1
  dc.b "NSetClipText",0
  dc.b "(String$) - Change the clipboard text -",0,0
  dc.b 7
  dc.b $02,$00,$00 ;...
  ds.l 1
  dc.b $00,$FD,$16,$00 ;....
  ds.w 3
  dc.l AL_0_1FA
  ds.l 1
  dc.b $00,$01,$03,$00 ;....
  dc.b $00,$FD,$16,$00 ;....
  ds.w 3
  dc.l AJL_0_1F4
  ds.l 1
  dc.b $FF,$FF,$00,$00 ;....
  ds.l 1
  dc.b "NGetClipText",0
  dc.b "[(max size)];- Return clipboard mak sure stringbuffer is 2* larger max size",0,0
AL_0_11C:
  ds.l 3
  dc.l AL_0_2EE
  ds.l 1
  dc.b $FF,$FF,$00,$00 ;....
  ds.w 1
AJL_0_136:
  move.l D0,D2
  move.l -(A2),D3
  tst.l D3
   ble.w JL_0_1F2
   jsr -$29A(A6)
   beq.w JL_0_1F2
  movea.l D0,A2
  movea.l D0,A0
  moveq.l #$34,D0
   jsr -$28E(A6)
   beq.w JL_0_1EC
  movea.l D0,A3
  lea L_0_2F4(PC),A0
  clr.l D0
  movea.l A3,A1
  clr.l D1
   jsr -$1BC(A6)
   bne.w JL_0_1E6
  move.l D3,D5
  addi.l #$14,D5
  move.l D5,D0
  and.l #$1,D0
  tst.l D0
   beq.w JL_0_182
  addq.l #1,D5
JL_0_182:
  move.l D5,D0
  move.l #$10000,D1
   jsr -$C6(A6)
  move.l D0,D6
  movea.l D0,A0
  move.l #$464F524D,(A0)+
  move.l D5,(A0)
  subi.l #$8,(A0)+
  move.l #$46545854,(A0)+
  move.l #$43485253,(A0)+
  move.l D3,(A0)+
  movea.l D2,A1
JL_0_1B0:
  move.b (A1)+,(A0)+
  subq.l #1,D3
   bne.w JL_0_1B0
  move.w #$0003,$1C(A3)
  move.l D5,$24(A3)
  move.l D6,$28(A3)
  movea.l A3,A1
   jsr -$1C8(A6)
  move.w #$0004,$1C(A3)
  movea.l A3,A1
   jsr -$1C8(A6)
  movea.l D6,A1
  move.l D5,D0
   jsr -$D2(A6)
  movea.l A3,A1
   jsr -$1C2(A6)
JL_0_1E6:
  movea.l A3,A0
   jsr -$294(A6)
JL_0_1EC:
  movea.l A2,A0
   jsr -$2A0(A6)
JL_0_1F2:
 rtS 
 
AJL_0_1F4:
  move.l D0,AL_0_2F0
AL_0_1FA:
  move.l A3,D6
  clr.l D5
   jsr -$29A(A6)
   beq.w JL_0_2E8
  movea.l D0,A2
  movea.l D0,A0
  moveq.l #$34,D0
   jsr -$28E(A6)
   beq.w JL_0_2E2
  movea.l D0,A3
  lea L_0_2F4(PC),A0
  clr.l D0
  movea.l A3,A1
  clr.l D1
   jsr -$1BC(A6)
   bne.w JL_0_2DC
  move.w #$0002,$1C(A3)
  move.l AL_0_2F0,$24(A3)
  move.l D6,$28(A3)
  movea.l A3,A1
   jsr -$1CE(A6)
  move.l #$2710,$2C(A3)
  movea.l A3,A1
   jsr -$1CE(A6)
  moveq.l #$00,D5
  movea.l D6,A0
  movea.l D6,A1
  cmpi.l #$464F524D,(A0)+
   bne.w JL_0_2D6
  adda.w #$4,A0
  cmpi.l #$46545854,(A0)+
   bne.w JL_0_2D6
JL_0_26C:
  cmpi.l #$5354594C,(A0)
   beq.w JL_0_298
  cmpi.l #$48494748,(A0)
   beq.w JL_0_298
  cmpi.l #$434F4C53,(A0)
   beq.w JL_0_298
  cmpi.l #$43485253,(A0)
   beq.w JL_0_2A2
 bra.w JL_0_2D6
 
JL_0_298:
  addq.l #4,A0
  move.l (A0)+,D0
  adda.l D0,A0
 bra.w JL_0_26C
 
JL_0_2A2:
  cmpi.l #$43485253,(A0)+
   bne.w JL_0_2D6
  move.l (A0)+,D0
  tst.l D0
   beq.w JL_0_2D6
  add.l D0,D5
  cmp.l AL_0_2F0,D5
   bge.w JL_0_2D6
JL_0_2C0:
  move.b (A0)+,(A1)+
  subq.l #1,D0
   bne.w JL_0_2C0
  move.l A0,D0
  addq.l #1,D0
  bclr #$0,D0
  movea.l D0,A0
 bra.w JL_0_26C
 
JL_0_2D6:
  movea.l A3,A1
   jsr -$1C2(A6)
JL_0_2DC:
  movea.l A3,A0
   jsr -$294(A6)
JL_0_2E2:
  movea.l A2,A0
   jsr -$2A0(A6)
JL_0_2E8:
  move.l D5,D0
  movea.l D6,A3
  adda.l D5,A3
AL_0_2EE:
 rtS 
 
AL_0_2F0:
  dc.l $1000
L_0_2F4:
  dc.b "clipboard.device",0,0
  dc.b "p",0
  dc.b "Nu",0,0
 Ende
