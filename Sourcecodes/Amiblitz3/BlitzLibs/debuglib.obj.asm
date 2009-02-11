; In_Go Reassembler debuglib.obj: 06.12.2002 18:03:46
_SysBase EQU $4
MaxIntSgnd EQU $7FFFFFFF
Optimize68020 EQU 0
 SECTION "Segment0",CODE
 cnop 0,4
SegmentBeginn0:
  moveq.l #$00,D0
 rtS 
 
  dc.b $FA,$3C,$00,$00 ;.<..
  ds.w 1
JL_0_A:
  ds.l 1
  dc.b $D5,$00,$D5,$10 ;....
  ds.l 1
  dc.l AL_0_F8
  ds.w 1
  dc.l AL_0_10C
  ds.l 7
  dc.l AJL_0_CAE
  ds.l 4
  dc.l AJL_0_C04
  ds.l 4
  dc.l AJL_0_C64
  ds.l 4
  dc.l AJL_0_CB0
  ds.l 4
  dc.l AJL_0_C30
  ds.l 4
  dc.l AJL_0_C40
  ds.l 4
  dc.l AJL_0_C50
  ds.l 4
  dc.l AJL_0_CF6
  ds.l 4
  dc.l AJL_0_C5A
  ds.l 4
  dc.l AJL_0_BFC
  ds.l 1
AL_0_F8:
  ds.l 3
  dc.l AJL_0_B0C
  ds.l 1
AL_0_10C:
  ds.l 3
  dc.l AJL_0_BEC
  ds.l 1
  dc.b $FF,$FF,$00,$00 ;....
  ds.w 1
AL_0_126:
  ds.w 1
AL_0_128:
  ds.w 1
AL_0_12A:
  ds.l 1
AL_0_12E:
  ds.l 1
AL_0_132:
  ds.l 1
AL_0_136:
  ds.l 1
AL_0_13A:
  ds.l 1
AL_0_13E:
  ds.l 1
AL_0_142:
 dc.l AL_0_146
AL_0_146:
 dc.l AJL_0_4FC
AL_0_14A:
 dc.l AJL_0_500
AL_0_14E:
 dc.l AJL_0_504
AL_0_152:
 dc.l AJL_0_508
AL_0_156:
 dc.l AJL_0_50C
AL_0_15A:
 dc.l AJL_0_50C
AL_0_15E:
 dc.l AJL_0_50C
AL_0_162:
  ds.w 3
AL_0_168:
  ds.w 1
AL_0_16A:
 dc.l AL_0_168
AL_0_16E:
 dc.l AL_0_162
  ds.l 63
  ds.l 63
  ds.l 63
  ds.w 7
AL_0_474:
 dc.l AL_0_478
AL_0_478:
  ds.l 32
AL_0_4F8:
  ds.l 1
AJL_0_4FC:
  cmp.w D0,D0
 rtS 
 
AJL_0_500:
 bra.w AJL_0_C50
 
AJL_0_504:
 bra.w AJL_0_C50
 
AJL_0_508:
  cmp.w D0,D0
 rtS 
 
AJL_0_50C:
 rtS 
 
AJL_0_50E:
  movem.l A0-A1,-(A7)
  movea.l AL_0_4F8(PC),A0
  tst.w (A0)
   beq.b JL_0_52A
  movem.l D0-D7/A0-A6,-(A7)
  moveq.l #$00,D1
  movea.l AL_0_15E(PC),A0
L_0_524:
   jsr (A0)
  movem.l (A7)+,D0-D7/A0-A6
JL_0_52A:
  movea.l $A(A7),A0
  addq.l #8,$A(A7)
  movea.l AL_0_16A(PC),A1
  cmpa.l (A1),A0
   beq.w JL_0_54E
  addq.w #6,A1
  move.l A1,AL_0_16A
  move.l A0,(A1)+
  clr.w (A1)+
  movem.l (A7)+,A0-A1
 rte 
 
JL_0_54E:
  addq.w #1,$4(A1)
  movem.l (A7)+,A0-A1
 rte 
 
AJL_0_558:
  move.l A0,-(A7)
  movea.l AL_0_4F8(PC),A0
  tst.w (A0)
   beq.b JL_0_572
  movem.l D0-D7/A0-A6,-(A7)
  moveq.l #-$01,D1
  movea.l AL_0_15E(PC),A0
L_0_56C:
   jsr (A0)
  movem.l (A7)+,D0-D7/A0-A6
JL_0_572:
  movea.l AL_0_16A(PC),A0
  subq.w #1,$4(A0)
   bpl.w JL_0_586
  subq.l #6,A0
  move.l A0,AL_0_16A
JL_0_586:
  movea.l (A7)+,A0
 rte 
 
AL_0_58A:
  dc.b "No currently used object!",0
AL_0_5A4:
  dc.b "Offset out of range",0
AL_0_5B8:
  dc.b "End of Program",0,0
AJL_0_5C8:
  movea.l $2(A7),A0
  tst.w $4(A0)
   bmi.w JL_0_5DC
  move.w AL_0_126(PC),D0
   beq.w JL_0_5E2
JL_0_5DC:
  move.l (A0),$2(A7)
 rte 
 
JL_0_5E2:
  move.l #AJL_0_5EC,$2(A7)
 rte 
 
AJL_0_5EC:
  movea.l AL_0_474(PC),A1
  move.l A7,(A1)+
  move.l A0,(A1)+
  move.l A1,AL_0_474
  addq.w #6,A0
L_0_5FC:
 jmp (A0)
 
AJL_0_5FE:
  subq.l #8,AL_0_474
 rte 
 
AJL_0_606:
  btst #$5,(A7)
   bne.w JL_0_646
  move.l $2(A7),AL_0_7DE
  move.w (A7),AL_0_7E2
  movem.l D0-D7/A0-A6,AL_0_79E
  move.l usp,A0
  move.l A0,AL_0_7DA
  lea AL_0_79E(PC),A0
  movea.l AL_0_146(PC),A1
L_0_634:
   jsr (A1)
   bne.b JL_0_64C
  tst.b AL_0_12A
   bne.b JL_0_64C
  movem.l L_0_7BE(PC),A0-A1
JL_0_646:
  addq.l #8,$2(A7)
 rte 
 
JL_0_64C:
  move.l #AJL_0_656,$2(A7)
 rte 
 
AJL_0_656:
   bsr.w JL_0_738
JL_0_65A:
  bclr #$7,AL_0_12A
   beq.w JL_0_670
  movea.l L_0_7D2(PC),A5
   jsr $9025BF60
JL_0_670:
  bclr #$6,AL_0_12A
   beq.w JL_0_686
  movea.l AL_0_132(PC),A0
  movea.l AL_0_14A(PC),A1
L_0_684:
   jsr (A1)
JL_0_686:
  bclr #$5,AL_0_12A
   beq.w JL_0_69C
  movea.l AL_0_136(PC),A0
  movea.l AL_0_14E(PC),A1
L_0_69A:
   jsr (A1)
JL_0_69C:
  bclr #$4,AL_0_12A
   beq.w JL_0_6BC
  movem.l L_0_7CE(PC),A4-A5
  movea.l AL_0_13A(PC),A0
   bsr.w JL_0_984
  movea.l AL_0_156(PC),A1
L_0_6BA:
   jsr (A1)
JL_0_6BC:
  bclr #$3,AL_0_12A
   beq.w JL_0_6E2
  movem.l L_0_7CE(PC),A4-A5
  movea.l AL_0_13E(PC),A0
   bsr.w JL_0_99E
  tst.b (A0)
   beq.w JL_0_6E2
  movea.l AL_0_156(PC),A1
L_0_6E0:
   jsr (A1)
JL_0_6E2:
  bclr #$2,AL_0_12A
   beq.w JL_0_70A
  movea.l AL_0_7DE(PC),A0
  move.w $6(A0),D0
   beq.w JL_0_70A
  adda.w D0,A0
  lea -$A(A0),A0
  move.l A0,AL_0_7DE
 bra.w JL_0_720
 
JL_0_70A:
  movea.l AL_0_152(PC),A0
L_0_70E:
   jsr (A0)
  move.w D0,AL_0_79C
  tst.b AL_0_12A
   bne.w JL_0_65A
JL_0_720:
   bsr.w JL_0_74C
  movem.l AL_0_79E(PC),D0-D7/A0-A7
  move.l AL_0_7DE(PC),-(A7)
  move.w AL_0_7E2(PC),-(A7)
  addq.l #8,$2(A7)
 rtr 
 
JL_0_738:
  St AL_0_126
   jsr $9025B961
  move.w D0,AL_0_128
 rtS 
 
JL_0_74C:
  move.w AL_0_79C(PC),D0
   bne.w JL_0_778
  move.w AL_0_128(PC),D0
   beq.w JL_0_770
   bmi.w JL_0_76A
   jsr $9025B962
 bra.w JL_0_770
 
JL_0_76A:
   jsr $9025B960
JL_0_770:
  Sf AL_0_126
 rtS 
 
JL_0_778:
  move.w AL_0_128(PC),D0
   beq.w JL_0_794
   bmi.w JL_0_78E
   jsr $9025B967
 bra.w JL_0_794
 
JL_0_78E:
   jsr $9025B966
JL_0_794:
  Sf AL_0_126
 rtS 
 
AL_0_79C:
  ds.w 1
AL_0_79E:
  ds.l 8
L_0_7BE:
  ds.l 4
L_0_7CE:
  ds.l 1
L_0_7D2:
  ds.l 2
AL_0_7DA:
  ds.l 1
AL_0_7DE:
  ds.l 1
AL_0_7E2:
  ds.w 1
AJL_0_7E4:
  cmpi.l #$1,D0
   bne.w JL_0_7F4
  move.l #AL_0_58A,D0
JL_0_7F4:
  cmpi.l #$2,D0
   bne.w JL_0_804
  move.l #AL_0_5A4,D0
JL_0_804:
  cmpi.l #$3,D0
   bne.w JL_0_814
  move.l #AL_0_5B8,D0
JL_0_814:
  btst #$5,(A7)
   bne.w JL_0_838
  move.l D0,AL_0_136
  bset #$5,AL_0_12A
  tst.w AL_0_97E
   beq.w JL_0_64C
 bra.w JL_0_A58
 
JL_0_838:
  move.l D0,AL_0_132
  bset #$6,AL_0_12A
  move.l #AJL_0_850,$2(A7)
 rte 
 
AJL_0_850:
  movea.l AL_0_474(PC),A1
  movea.l -(A1),A0
  St $4(A0)
  movea.l -(A1),A7
  move.l A1,AL_0_474
  movea.l (A0),A0
L_0_864:
 jmp (A0)
 
AL_0_866:
   ds.l 63
   ds.l 5
L_0_976:
   dc.b "Print ",0,0
AL_0_97E:
   ds.w 1
AL_0_980:
   ds.l 1
JL_0_984:
  lea L_0_976(PC),A1
  lea AL_0_866(PC),A2
JL_0_98C:
  move.b (A1)+,(A2)+
   bne.w JL_0_98C
  subq.w #1,A2
  move.l #AJL_0_A6C,D0
 bra.w JL_0_9A4
 
JL_0_99E:
  lea AL_0_866(PC),A2
  moveq.l #$00,D0
JL_0_9A4:
  move.b (A0)+,(A2)+
   bne.w JL_0_9A4
  tst.l D0
   beq.w JL_0_9BE
  movea.l D0,A0
   jsr $90254964
  move.l D0,AL_0_980
JL_0_9BE:
  clr.w AL_0_A62
  movea.l AL_0_16A(PC),A0
  movea.l (A0),A0
  move.l (A0)+,AL_0_9FA
  move.l (A0),AL_0_9FE
  clr.l AL_0_A02
  move.w AL_0_128(PC),D0
  Smi D0
  ext.w D0
  move.w D0,AL_0_A06
   bsr.w JL_0_74C
  St AL_0_97E
 trap #$F
 
  dc.l AL_0_866
AL_0_9FA:
  ds.l 1
AL_0_9FE:
  ds.l 1
AL_0_A02:
  ds.l 1
AL_0_A06:
  ds.w 1
AJL_0_A08:
  Sf AL_0_97E
   bsr.w JL_0_738
  move.l AL_0_A02(PC),D0
   beq.w JL_0_A34
  movea.l D0,A0
  lea AL_0_866(PC),A1
  move.w #$FFFF,AL_0_A62
JL_0_A28:
  addq.w #1,AL_0_A62
  move.b (A0)+,(A1)+
   bne.w JL_0_A28
JL_0_A34:
  move.l AL_0_980(PC),D0
   beq.w JL_0_A4A
  clr.l AL_0_980
  movea.l D0,A0
   jsr $90254964
JL_0_A4A:
  lea AL_0_866(PC),A0
  move.w AL_0_A62(PC),D0
  clr.b $0(A0,D0.W)
 rtS 
 
JL_0_A58:
  move.l #AJL_0_A08,$2(A7)
 rte 
 
AL_0_A62:
  ds.w 1
  dc.b "`",0,0
  dc.b "^`",0,0
  dc.b $2A
AJL_0_A6C:
  cmpi.w #$100,AL_0_A62
   bcc.w JL_0_A92
  movem.l D0-D1/A0-A1,-(A7)
  lea AL_0_866(PC),A1
  move.w AL_0_A62(PC),D1
  move.b D0,$0(A1,D1.W)
  addq.w #1,AL_0_A62
  movem.l (A7)+,D0-D1/A0-A1
JL_0_A92:
 rtS 
 
JL_0_A94:
  tst.w D0
   beq.w JL_0_AC2
  movem.l D0-D1/A0-A1,-(A7)
  lea AL_0_866(PC),A1
  move.w AL_0_A62(PC),D1
JL_0_AA6:
  cmpi.w #$100,D1
   bcc.w JL_0_AB8
  move.b (A0)+,$0(A1,D1.W)
  addq.w #1,D1
 bra.w JL_0_AA6
 
JL_0_AB8:
  move.w D1,AL_0_A62
  movem.l (A7)+,D0-D1/A0-A1
JL_0_AC2:
 rtS 
 
JL_0_AC4:
  movem.l D0-D1/A0-A1,-(A7)
  lea AL_0_866(PC),A1
  move.w AL_0_A62(PC),D1
JL_0_AD0:
  cmpi.w #$100,D1
   bcc.w JL_0_AE4
  addq.w #1,D1
  move.b (A0)+,-$1(A1,D1.W)
   bne.w JL_0_AD0
  subq.w #1,D1
JL_0_AE4:
  move.w D1,AL_0_A62
  movem.l (A7)+,D0-D1/A0-A1
 rtS 
 
AL_0_AF0:
  dc.b "Interrupted - program start",0
AJL_0_B0C:
  clr.w AL_0_97E
  clr.l AL_0_980
  clr.w AL_0_126
  clr.w AL_0_128
  clr.l AL_0_12A
  tst.b D0
   bne.w JL_0_B42
  move.l #AL_0_AF0,AL_0_136
  bset #$5,AL_0_12A
JL_0_B42:
  move.l #AL_0_478,AL_0_474
  move.l #AL_0_16E,AL_0_16A
  move.l #AJL_0_4FC,AL_0_146
  move.l #AJL_0_500,AL_0_14A
  move.l #AJL_0_504,AL_0_14E
  move.l #AJL_0_508,AL_0_152
  move.l #AJL_0_50C,AL_0_156
   jsr $9025BA7D
  move.l $84(A0),AL_0_12E
  move.l #AJL_0_7E4,$80(A0)
  move.l #AJL_0_606,$84(A0)
  move.l #AJL_0_5C8,$88(A0)
  move.l #AJL_0_5FE,$8C(A0)
  move.l #AJL_0_50E,$90(A0)
  move.l #AJL_0_558,$94(A0)
  movea.l _SysBase,A6
  suba.l A1,A1
FindTask SET -$126
   jsr FindTask(A6)
  move.l D0,AL_0_BE6
  moveq.l #-$01,D0
AllocSignal SET -$14A
   jsr AllocSignal(A6)
  move.w D0,AL_0_BEA
 rtS 
 
AL_0_BE6:
  ds.l 1
AL_0_BEA:
  ds.w 1
AJL_0_BEC:
  movea.l _SysBase,A6
  move.w AL_0_BEA(PC),D0
FreeSignal SET -$150
   jsr FreeSignal(A6)
 rtS 
 
AJL_0_BFC:
  movea.l AL_0_15A(PC),A1
L_0_C00:
   jsr (A1)
 rtS 
 
AJL_0_C04:
  move.l #AL_0_C18,AL_0_136
  bset #$5,AL_0_12A
 rtS 
 
AL_0_C18:
  dc.b "***** Interupted *****",0,0
AJL_0_C30:
  move.l A0,AL_0_13A
  bset #$4,AL_0_12A
 rtS 
 
AJL_0_C40:
  move.l A0,AL_0_13E
  bset #$3,AL_0_12A
 rtS 
 
AJL_0_C50:
  bset #$7,AL_0_12A
 rtS 
 
AJL_0_C5A:
  bset #$2,AL_0_12A
 rtS 
 
AJL_0_C64:
  move.l D0,AL_0_4F8
  move.l AL_0_142(PC),D0
  move.l A0,AL_0_142
  movem.l D0-D5,-(A7)
  movem.l (A0)+,D0-D4
  movem.l D0-D4,AL_0_146
  addq.l #4,A0
  move.l (A0)+,AL_0_15A
  move.l (A0)+,AL_0_15E
  movem.l (A7)+,D0-D5
  lea AL_0_79E(PC),A0
  lea AL_0_128(PC),A1
  movea.l AL_0_12E,A2
  movea.l AL_0_BE6(PC),A3
  move.w AL_0_BEA(PC),D0
 rtS 
 
AJL_0_CAE:
 rtS 
 
AJL_0_CB0:
  move.b (A0)+,(A1)+
   beq.w JL_0_CEE
   bpl.w AJL_0_CB0
  move.b -(A1),D0
  lsl.w #8,D0
  move.b (A0)+,D0
  lea AL_0_12E(PC),A2
  bclr #$F,D0
JL_0_CC8:
  move.l (A2),D1
   beq.w JL_0_CE6
  movea.l D1,A2
  cmp.w $4(A2),D0
   bne.w JL_0_CC8
  addq.w #6,A2
JL_0_CDA:
  move.b (A2)+,(A1)+
   bne.w JL_0_CDA
  subq.w #1,A1
 bra.w AJL_0_CB0
 
JL_0_CE6:
  lea L_0_CF0(PC),A2
 bra.w JL_0_CDA
 
JL_0_CEE:
 rtS 
 
L_0_CF0:
  dc.b "?????",0
AJL_0_CF6:
  moveq.l #$00,D1
  tst.w D0
JL_0_CFA:
   beq.w JL_0_D4A
  tst.b (A0)+
   beq.w JL_0_D4A
   bmi.w JL_0_D10
  addq.w #1,D1
  subq.w #1,D0
 bra.w JL_0_CFA
 
JL_0_D10:
  subq.w #2,D0
  move.b -$1(A0),D2
  lsl.w #8,D2
  move.b (A0)+,D2
  lea AL_0_12E(PC),A2
  bclr #$F,D2
JL_0_D22:
  move.l (A2),D3
   beq.w JL_0_D42
  movea.l D3,A2
  cmp.w $4(A2),D2
   bne.w JL_0_D22
  addq.w #6,A2
JL_0_D34:
  addq.w #1,D1
  tst.b (A2)+
   bne.w JL_0_D34
  subq.w #1,D1
 bra.w JL_0_CFA
 
JL_0_D42:
  lea L_0_CF0(PC),A2
 bra.w JL_0_D34
 
JL_0_D4A:
  move.w D1,D0
 rtS 
 
  dc.b "N"
  dc.b $B9 ;.
  dc.l $902554E1
  dc.b "N"
  dc.b $B9 ;.
  dc.l $90255164
  dc.b "p",0
  dc.b "Nu"
  dc.b $0E,$18 ;..
 Ende
