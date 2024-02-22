; IRA V2.09 (06.03.18) (c)1993-1995 Tim Ruehsen
; (c)2009-2015 Frank Wille, (c)2014-2017 Nicolas Bastien

EXT_0000	EQU	$614A
CIAA_PRA	EQU	$BFE001
HARDBASE	EQU	$DFF000
DMACON		EQU	$DFF096
AUD0LCH		EQU	$DFF0A0
AUD0VOL		EQU	$DFF0A8
AUD1LCH		EQU	$DFF0B0
AUD1VOL		EQU	$DFF0B8
AUD2LCH		EQU	$DFF0C0
AUD2VOL		EQU	$DFF0C8
AUD3LCH		EQU	$DFF0D0
AUD3VOL		EQU	$DFF0D8

SECSTRT_0:
;libheader{libnum,init,return,finit,error}
;            1     2     3      4    5
!libheader{#trackerlib,LAB_0007+2,0,0,error_checking}
;	MOVEQ	#0,D0			;000: 7000
;	RTS				;002: 4e75
;	ORI.w	#$0000,-(A0)		;004: 00600000
;	ORI.b	#$00,D0			;008: 00000000
;	ORI.b	#$00,D0			;00c: 00000000
;	ORI.b	#$00,D0			;010: 00000000
;	ORI.b	#$00,D0			;014: 00000000
;	ORI.b	#$00,D0			;018: 00000000
;	Dc.l	LAB_0007+2		;01c: 0000010c
;	ORI.b	#$00,D0			;020: 00000000
;	ORI.b	#$00,D0			;024: 00000000
;	ORI.b	#$00,D0			;028: 00000000
;	Dc.l	error_checkling		;02c: 00000e52


	Dc.w	$0008			;030
	ORI.b	#$00,D0			;032: 00000000
	ORI.b	#$00,D0			;036: 00000000
	Dc.w	$0000			;03a
LAB_0001:
	Dc.b "Module",0
	Dc.b "A Sound or Noise tracker module",0
;	Dc.w	$4d6f			;03c
;	Dc.w	$6475			;03e
;	Dc.w	$6c65			;040
;	ORI.w	#$2053,D1		;042: 00412053
;	Dc.w	$6f75			;046
;	BGT.S	LAB_0003		;048: 6e64
;	MOVEA.l	29216(A7),A0		;04a: 206f7220
;	MOVE.l	USP,A7			;04e: 4e6f
;	Dc.w	$6973			;050
;	BCS.S	LAB_0002		;052: 6520
;	MOVEQ	#114,D2			;054: 7472
;	Dc.w	$6163			;056
;	Dc.w	$6b65			;058
;	MOVEQ	#32,D1			;05a: 7220
;	Dc.w	$6d6f			;05c
;	Dc.w	$6475			;05e
;	Dc.w	$6c65			;060

!afunction{#word}
!args{#word,#string}
!libs
!subs{LAB_0010+1,0,0}
!name{"LoadModule","Module#,Filename$"}

;	ORI.b	#$01,D2			;062: 00020001
;	ORI.b	#$00,D0			;066: 00000000
;	Dc.w	$0002			;06a
;	ANDI.b	#$60,D7			;06c: 02070060
;	MOVE.b	D0,-4(A1,D0.w)		;070: 138000fc
;LAB_0002:
;	MOVE.b	D0,D3			;074: 1600
;	ORI.b	#$00,D0			;076: 00000000
;	Dc.w	$0000			;07a
;	Dc.l	LAB_0010+1		;07c: 0000018d
;	ORI.b	#$00,D0			;080: 00000000
;	Dc.w	$ffff			;084
;	ORI.b	#$00,D0			;086: 00000000
;	Dc.w	$0000			;08a
;	Dc.w	$4c6f			;08c
;	BSR.S	LAB_0005		;08e: 6164
;	Dc.w	$4d6f			;090
;	Dc.w	$6475			;092
;	Dc.w	$6c65			;094
;	Dc.w	$004d			;096
;	BLE.S	LAB_0006		;098: 6f64
;	Dc.w	$756c			;09a
;	Dc.w	$6523			;09c
;	MOVEA.l	D6,A6			;09e: 2c46
;	BVS.S	LAB_0008		;0a0: 696c
;	BCS.S	LAB_0009		;0a2: 656e
;	Dc.w	$616d			;0a4
;	BCS.S	LAB_0004		;0a6: 6524
	Dc.w	$00f7			;0a8
	ORI.b	#$00,D1			;0aa: 00010000
;LAB_0003:
	ORI.b	#$01,D0			;0ae: 00000001
	Dc.w	$020f			;0b2
	ORI.w	#$1380,-(A0)		;0b4: 00601380
	Dc.w	$0000			;0b8
	Dc.l	LAB_006B		;0ba: 00000e8c
	Dc.l	LAB_0015		;0be: 0000022e
	ORI.b	#$00,D0			;0c2: 00000000
	Dc.w	$ffff			;0c6
	ORI.b	#$00,D0			;0c8: 00000000
;LAB_0004:
	Dc.w	$0000			;0cc
	ADDQ.w	#8,24953(A4)		;0ce: 506c6179
	Dc.w	$4d6f			;0d2
	Dc.w	$6475			;0d4
	Dc.w	$6c65			;0d6
	Dc.w	$004d			;0d8
	BLE.S	LAB_000C		;0da: 6f64
	Dc.w	$756c			;0dc
	Dc.w	$6523			;0de
	ORI.b	#$01,D0			;0e0: 00000001
	ORI.b	#$00,D0			;0e4: 00000000
	ORI.b	#$00,D0			;0e8: 00000000
	ORI.b	#$00,D0			;0ec: 00000000
	Dc.l	LAB_0018		;0f0: 00000264
;LAB_0005:
	ORI.b	#$00,D0			;0f4: 00000000
	Dc.w	$ffff			;0f8
	ORI.b	#$00,D0			;0fa: 00000000
;LAB_0006:
	Dc.w	$0000			;0fe
	Dc.w	$5374			;100
	BLE.S	LAB_000F+2		;102: 6f70
	Dc.w	$4d6f			;104
	Dc.w	$6475			;106
	Dc.w	$6c65			;108
LAB_0007:
	Dc.w	$0000
	Dc.w	$0000
;	ORI.b	#$00,D0			;10a: 00000000
LAB_0008:
	ORI.b	#$00,D0			;10e: 00000000
LAB_0009:
	ORI.b	#$00,D0			;112: 00000000
	Dc.w	$0000			;116
	Dc.l	LAB_0019		;118: 0000026a
	ORI.b	#$00,D0			;11c: 00000000
LAB_000A:
	ORI.b	#$00,D0			;120: 00000000
	ORI.b	#$00,D0			;124: 00000000
	ORI.b	#$00,D0			;128: 00000000
	ORI.b	#$00,D0			;12c: 00000000
	ORI.b	#$00,D0			;130: 00000000
LAB_000B:
	ORI.b	#$00,D0			;134: 00000000
	ORI.b	#$00,D0			;138: 00000000
	ORI.b	#$00,D0			;13c: 00000000
LAB_000C:
	ORI.b	#$00,D0			;140: 00000000
	ORI.b	#$00,D0			;144: 00000000
LAB_000D:
	ORI.b	#$00,D0			;148: 00000000
	ORI.b	#$00,D0			;14c: 00000000
	ORI.b	#$00,D0			;150: 00000000
	ORI.b	#$00,D0			;154: 00000000
	ORI.b	#$00,D0			;158: 00000000
LAB_000E:
	ORI.b	#$00,D0			;15c: 00000000
	ORI.b	#$00,D0			;160: 00000000
	ORI.b	#$00,D0			;164: 00000000
	Dc.l	LAB_001C		;168: 00000282
	ORI.b	#$00,D0			;16c: 00000000
	Dc.w	$ffff			;170
LAB_000F:
	Dc.l	LAB_0001		;172: 0000003c
	Dc.l	LAB_000A		;176: 00000120
	Dc.l	LAB_000B		;17a: 00000134
	Dc.l	LAB_000D		;17e: 00000148
	Dc.l	LAB_000E		;182: 0000015c
	ORI.b	#$05,D0			;186: 00000005
	Dc.w	$0003			;18a
LAB_0010:
	MOVE.l	D1,D7			;18c: 2e01
	BSR.w	LAB_001D		;18e: 610000f8
	MOVE.l	#$00000104,D0		;192: 203c00000104
	MOVEQ	#1,D1			;198: 7201
	JSR	SECSTRT_0-2147434494	;19a: 4eb98000c002
	MOVEA.l	D0,A2			;1a0: 2440
	MOVE.l	D7,D1			;1a2: 2207
	MOVEQ	#-2,D2			;1a4: 74fe
	JSR	-84(A6)			;1a6: 4eaeffac
	MOVE.l	D0,D6			;1aa: 2c00
	MOVE.l	D6,D1			;1ac: 2206
	MOVE.l	A2,D2			;1ae: 240a
	JSR	-102(A6)		;1b0: 4eaeff9a
	TST.l	D0			;1b4: 4a80
	BEQ.w	LAB_0066		;1b6: 67000c92
	TST.l	4(A2)			;1ba: 4aaa0004
	BGT.w	LAB_0066		;1be: 6e000c8a
	MOVE.l	124(A2),4(A3)		;1c2: 276a007c0004
	MOVE.l	D6,D1			;1c8: 2206
	JSR	-90(A6)			;1ca: 4eaeffa6
	MOVEA.l	A2,A1			;1ce: 224a
	MOVE.l	#$00000104,D0		;1d0: 203c00000104
	Dc.w	$4eb9			;1d6
	Dc.l	SECSTRT_0-2147434493	;1d8: 8000c003
	MOVE.l	4(A3),D0		;1dc: 202b0004
	MOVEQ	#2,D1			;1e0: 7202
	JSR	SECSTRT_0-2147434494	;1e2: 4eb98000c002
	MOVE.l	D0,(A3)			;1e8: 2680
	MOVE.l	D7,D1			;1ea: 2207
	MOVE.l	#$000003ed,D2		;1ec: 243c000003ed
	JSR	-30(A6)			;1f2: 4eaeffe2
	MOVE.l	D0,D6			;1f6: 2c00
	BEQ.w	LAB_0066		;1f8: 67000c50
	MOVE.l	D6,D1			;1fc: 2206
	MOVE.l	(A3),D2			;1fe: 2413
	MOVE.l	4(A3),D3		;200: 262b0004
	JSR	-42(A6)			;204: 4eaeffd6
	MOVE.l	D6,D1			;208: 2206
	JMP	-36(A6)			;20a: 4eeeffdc
LAB_0011:
	JSR	SECSTRT_0-2147434240	;20e: 4eb98000c100
	RTS				;214: 4e75
LAB_0012:
	Dc.w	$4eb9			;216
	Dc.l	SECSTRT_0-2147434239	;218: 8000c101
	RTS				;21c: 4e75
LAB_0013:
	JSR	SECSTRT_0-1073692416	;21e: 4eb9c000c100
	RTS				;224: 4e75
LAB_0014:
	Dc.w	$4eb9			;226
	Dc.l	SECSTRT_0-1073692415	;228: c000c101
	RTS				;22c: 4e75
LAB_0015:
	Dc.w	$a001			;22e
	Dc.l	LAB_0016		;230: 0000023c
	LEA	LAB_0011(PC),A2		;234: 45faffd8
	BRA.w	LAB_0017		;238: 60000006
LAB_0016:
	LEA	LAB_0013(PC),A2		;23c: 45faffe0
LAB_0017:
	MOVEM.l	A4-A6,-(A7)		;240: 48e7000e
	MOVE.l	(A3),LAB_0023		;244: 23d3000002c4
	MOVE.l	A2,-(A7)		;24a: 2f0a
	BSR.w	LAB_0024		;24c: 6100007a
	MOVEA.l	(A7)+,A2		;250: 245f
	MOVE.w	#$8025,D0		;252: 303c8025
	MOVE.l	#LAB_0022,D1		;256: 223c000002b6
	JSR	(A2)			;25c: 4e92
	MOVEM.l	(A7)+,A4-A6		;25e: 4cdf7000
	RTS				;262: 4e75
LAB_0018:
	Dc.w	$a001			;264
	Dc.l	LAB_001A		;266: 00000272
LAB_0019:
	LEA	LAB_0012(PC),A2		;26a: 45faffaa
	BRA.w	LAB_001B		;26e: 60000006
LAB_001A:
	LEA	LAB_0014(PC),A2		;272: 45faffb2
LAB_001B:
	MOVE.w	#$8025,D0		;276: 303c8025
	JSR	(A2)			;27a: 4e92
	BRA.w	LAB_0028		;27c: 600000d4
	RTS				;280: 4e75
LAB_001C:
	Dc.w	$a001			;282
	Dc.l	LAB_001E		;284: 00000290
LAB_001D:
	LEA	LAB_0012(PC),A2		;288: 45faff8c
	BRA.w	LAB_001F		;28c: 60000006
LAB_001E:
	LEA	LAB_0014(PC),A2		;290: 45faff94
LAB_001F:
	MOVE.l	(A3),D0			;294: 2013
	BEQ.w	LAB_0021		;296: 6700001c
	CMP.l	LAB_0023(PC),D0		;29a: b0ba0028
	BNE.w	LAB_0020		;29e: 66000006
	BSR.w	LAB_001B		;2a2: 6100ffd2
LAB_0020:
	MOVEA.l	(A3),A1			;2a6: 2253
	CLR.l	(A3)			;2a8: 4293
	MOVE.l	4(A3),D0		;2aa: 202b0004
	Dc.w	$4eb9			;2ae
	Dc.l	SECSTRT_0-2147434493	;2b0: 8000c003
LAB_0021:
	RTS				;2b4: 4e75
LAB_0022:
	MOVEM.l	D2-D7/A2-A4,-(A7)	;2b6: 48e73f38
	BSR.w	LAB_0029		;2ba: 610000b8
	MOVEM.l	(A7)+,D2-D7/A2-A4	;2be: 4cdf1cfc
	RTS				;2c2: 4e75
LAB_0023:
	ORI.b	#$00,D0			;2c4: 00000000
LAB_0024:
	MOVEA.l	LAB_0023(PC),A0		;2c8: 207afffa
	MOVEA.l	A0,A1			;2cc: 2248
	ADDA.l	#$000003b8,A1		;2ce: d3fc000003b8
	MOVEQ	#127,D0			;2d4: 707f
	MOVEQ	#0,D1			;2d6: 7200
LAB_0025:
	MOVE.l	D1,D2			;2d8: 2401
	SUBQ.w	#1,D0			;2da: 5340
LAB_0026:
	MOVE.b	(A1)+,D1		;2dc: 1219
	CMP.b	D2,D1			;2de: b202
	BGT.w	LAB_0025		;2e0: 6e00fff6
	DBF	D0,LAB_0026		;2e4: 51c8fff6
	ADDQ.b	#1,D2			;2e8: 5202
	LEA	LAB_0061(PC),A1		;2ea: 43fa0672
	ASL.l	#8,D2			;2ee: e182
	ASL.l	#2,D2			;2f0: e582
	ADDI.l	#$0000043c,D2		;2f2: 06820000043c
	ADD.l	A0,D2			;2f8: d488
	MOVEA.l	D2,A2			;2fa: 2442
	MOVEQ	#30,D0			;2fc: 701e
LAB_0027:
	CLR.l	(A2)			;2fe: 4292
	MOVE.l	A2,(A1)+		;300: 22ca
	MOVEQ	#0,D1			;302: 7200
	MOVE.w	42(A0),D1		;304: 3228002a
	ASL.l	#1,D1			;308: e381
	ADDA.l	D1,A2			;30a: d5c1
	ADDA.l	#$0000001e,A0		;30c: d1fc0000001e
	DBF	D0,LAB_0027		;312: 51c8ffea
	ORI.b	#$02,CIAA_PRA		;316: 0039000200bfe001
	MOVE.b	#$06,LAB_005B		;31e: 13fc000600000956
	CLR.w	AUD0VOL			;326: 427900dff0a8
	CLR.w	AUD1VOL			;32c: 427900dff0b8
	CLR.w	AUD2VOL			;332: 427900dff0c8
	CLR.w	AUD3VOL			;338: 427900dff0d8
	CLR.b	LAB_005B+1		;33e: 423900000957
	CLR.b	LAB_005E		;344: 42390000095a
	CLR.w	LAB_005B+2		;34a: 427900000958
	RTS				;350: 4e75
LAB_0028:
	CLR.w	AUD0VOL			;352: 427900dff0a8
	CLR.w	AUD1VOL			;358: 427900dff0b8
	CLR.w	AUD2VOL			;35e: 427900dff0c8
	CLR.w	AUD3VOL			;364: 427900dff0d8
	MOVE.w	#$000f,DMACON		;36a: 33fc000f00dff096
	RTS				;372: 4e75
LAB_0029:
	MOVEM.l	D0-D4/A0-A3/A5-A6,-(A7)	;374: 48e7f8f6
	MOVEA.l	LAB_0023(PC),A0		;378: 207aff4a
	ADDQ.b	#1,LAB_005E		;37c: 52390000095a
	MOVE.b	LAB_005E,D0		;382: 10390000095a
	CMP.b	LAB_005B,D0		;388: b03900000956
	BLT.w	LAB_002A		;38e: 6d00000c
	CLR.b	LAB_005E		;392: 42390000095a
	BRA.w	LAB_0031		;398: 600000a4
LAB_002A:
	LEA	LAB_0062(PC),A6		;39c: 4dfa063c
	LEA	AUD0LCH,A5		;3a0: 4bf900dff0a0
	BSR.w	LAB_0047		;3a6: 610003a2
	LEA	LAB_0063(PC),A6		;3aa: 4dfa064a
	LEA	AUD1LCH,A5		;3ae: 4bf900dff0b0
	BSR.w	LAB_0047		;3b4: 61000394
	LEA	LAB_0064(PC),A6		;3b8: 4dfa0658
	LEA	AUD2LCH,A5		;3bc: 4bf900dff0c0
	BSR.w	LAB_0047		;3c2: 61000386
	LEA	LAB_0065(PC),A6		;3c6: 4dfa0666
	LEA	AUD3LCH,A5		;3ca: 4bf900dff0d0
	BSR.w	LAB_0047		;3d0: 61000378
	BRA.w	LAB_003A		;3d4: 60000274
LAB_002B:
	MOVEQ	#0,D0			;3d8: 7000
	MOVE.b	LAB_005E,D0		;3da: 10390000095a
	DIVS	#$0003,D0		;3e0: 81fc0003
	SWAP	D0			;3e4: 4840
	CMPI.w	#$0000,D0		;3e6: 0c400000
	BEQ.w	LAB_002D		;3ea: 67000024
	CMPI.w	#$0002,D0		;3ee: 0c400002
	BEQ.w	LAB_002C		;3f2: 6700000e
	MOVEQ	#0,D0			;3f6: 7000
	MOVE.b	3(A6),D0		;3f8: 102e0003
	LSR.b	#4,D0			;3fc: e808
	BRA.w	LAB_002E		;3fe: 60000018
LAB_002C:
	MOVEQ	#0,D0			;402: 7000
	MOVE.b	3(A6),D0		;404: 102e0003
	AND.b	#$0f,D0			;408: c03c000f
	BRA.w	LAB_002E		;40c: 6000000a
LAB_002D:
	MOVE.w	16(A6),D2		;410: 342e0010
	BRA.w	LAB_0030		;414: 60000022
LAB_002E:
	ASL.w	#1,D0			;418: e340
	MOVEQ	#0,D1			;41a: 7200
	MOVE.w	16(A6),D1		;41c: 322e0010
	LEA	LAB_005A(PC),A0		;420: 41fa04e8
	MOVEQ	#36,D7			;424: 7e24
LAB_002F:
	MOVE.w	0(A0,D0.w),D2		;426: 34300000
	CMP.w	(A0),D1			;42a: b250
	BGE.w	LAB_0030		;42c: 6c00000a
	ADDQ.l	#2,A0			;430: 5488
	DBF	D7,LAB_002F		;432: 51cffff2
	RTS				;436: 4e75
LAB_0030:
	MOVE.w	D2,6(A5)		;438: 3b420006
	RTS				;43c: 4e75
LAB_0031:
	MOVEA.l	LAB_0023(PC),A0		;43e: 207afe84
	MOVEA.l	A0,A3			;442: 2648
	MOVEA.l	A0,A2			;444: 2448
	ADDA.l	#$0000000c,A3		;446: d7fc0000000c
	ADDA.l	#$000003b8,A2		;44c: d5fc000003b8
	ADDA.l	#$0000043c,A0		;452: d1fc0000043c
	MOVEQ	#0,D0			;458: 7000
	MOVE.l	D0,D1			;45a: 2200
	MOVE.b	LAB_005B+1,D0		;45c: 103900000957
	MOVE.b	0(A2,D0.w),D1		;462: 12320000
	ASL.l	#8,D1			;466: e181
	ASL.l	#2,D1			;468: e581
	ADD.w	LAB_005B+2,D1		;46a: d27900000958
	CLR.w	LAB_005E+2		;470: 42790000095c
	LEA	AUD0LCH,A5		;476: 4bf900dff0a0
	LEA	LAB_0062(PC),A6		;47c: 4dfa055c
	BSR.w	LAB_0032		;480: 61000030
	LEA	AUD1LCH,A5		;484: 4bf900dff0b0
	LEA	LAB_0063(PC),A6		;48a: 4dfa056a
	BSR.w	LAB_0032		;48e: 61000022
	LEA	AUD2LCH,A5		;492: 4bf900dff0c0
	LEA	LAB_0064(PC),A6		;498: 4dfa0578
	BSR.w	LAB_0032		;49c: 61000014
	LEA	AUD3LCH,A5		;4a0: 4bf900dff0d0
	LEA	LAB_0065(PC),A6		;4a6: 4dfa0586
	BSR.w	LAB_0032		;4aa: 61000006
	BRA.w	LAB_0036		;4ae: 600000ea
LAB_0032:
	MOVE.l	0(A0,D1.l),(A6)		;4b2: 2cb01800
	ADDQ.l	#4,D1			;4b6: 5881
	MOVEQ	#0,D2			;4b8: 7400
	MOVE.b	2(A6),D2		;4ba: 142e0002
	AND.b	#$f0,D2			;4be: c43c00f0
	LSR.b	#4,D2			;4c2: e80a
	MOVE.b	(A6),D0			;4c4: 1016
	AND.b	#$f0,D0			;4c6: c03c00f0
	OR.b	D0,D2			;4ca: 8400
	TST.b	D2			;4cc: 4a02
	BEQ.w	LAB_0034		;4ce: 6700006c
	MOVEQ	#0,D3			;4d2: 7600
	LEA	LAB_0061(PC),A1		;4d4: 43fa0488
	MOVE.l	D2,D4			;4d8: 2802
	SUBQ.l	#1,D2			;4da: 5382
	ASL.l	#2,D2			;4dc: e582
	MULU	#$001e,D4		;4de: c8fc001e
	MOVE.l	0(A1,D2.l),4(A6)	;4e2: 2d7128000004
	MOVE.w	0(A3,D4.l),8(A6)	;4e8: 3d7348000008
	MOVE.w	2(A3,D4.l),18(A6)	;4ee: 3d7348020012
	MOVE.w	4(A3,D4.l),D3		;4f4: 36334804
	TST.w	D3			;4f8: 4a43
	BEQ.w	LAB_0033		;4fa: 6700002a
	MOVE.l	4(A6),D2		;4fe: 242e0004
	ASL.w	#1,D3			;502: e343
	ADD.l	D3,D2			;504: d483
	MOVE.l	D2,10(A6)		;506: 2d42000a
	MOVE.w	4(A3,D4.l),D0		;50a: 30334804
	ADD.w	6(A3,D4.l),D0		;50e: d0734806
	MOVE.w	D0,8(A6)		;512: 3d400008
	MOVE.w	6(A3,D4.l),14(A6)	;516: 3d734806000e
	MOVE.w	18(A6),8(A5)		;51c: 3b6e00120008
	BRA.w	LAB_0034		;522: 60000018
LAB_0033:
	MOVE.l	4(A6),D2		;526: 242e0004
	ADD.l	D3,D2			;52a: d483
	MOVE.l	D2,10(A6)		;52c: 2d42000a
	MOVE.w	6(A3,D4.l),14(A6)	;530: 3d734806000e
	MOVE.w	18(A6),8(A5)		;536: 3b6e00120008
LAB_0034:
	MOVE.w	(A6),D0			;53c: 3016
	AND.w	#$0fff,D0		;53e: c07c0fff
	BEQ.w	LAB_0050		;542: 67000300
	MOVE.b	2(A6),D0		;546: 102e0002
	AND.b	#$0f,D0			;54a: c03c000f
	CMPI.b	#$03,D0			;54e: 0c000003
	BNE.w	LAB_0035		;552: 6600000a
	BSR.w	LAB_003B		;556: 61000102
	BRA.w	LAB_0050		;55a: 600002e8
LAB_0035:
	MOVE.w	(A6),16(A6)		;55e: 3d560010
	ANDI.w	#$0fff,16(A6)		;562: 026e0fff0010
	MOVE.w	20(A6),D0		;568: 302e0014
	MOVE.w	D0,DMACON		;56c: 33c000dff096
	CLR.b	27(A6)			;572: 422e001b
	MOVE.l	4(A6),(A5)		;576: 2aae0004
	MOVE.w	8(A6),4(A5)		;57a: 3b6e00080004
	MOVE.w	16(A6),D0		;580: 302e0010
	AND.w	#$0fff,D0		;584: c07c0fff
	MOVE.w	D0,6(A5)		;588: 3b400006
	MOVE.w	20(A6),D0		;58c: 302e0014
	OR.w	D0,LAB_005E+2		;590: 81790000095c
	BRA.w	LAB_0050		;596: 600002ac
LAB_0036:
	MOVE.w	#$012c,D0		;59a: 303c012c
LAB_0037:
	DBF	D0,LAB_0037		;59e: 51c8fffe
	MOVE.w	LAB_005E+2,D0		;5a2: 30390000095c
	ORI.w	#$8000,D0		;5a8: 00408000
	MOVE.w	D0,DMACON		;5ac: 33c000dff096
	MOVE.w	#$012c,D0		;5b2: 303c012c
LAB_0038:
	DBF	D0,LAB_0038		;5b6: 51c8fffe
	LEA	HARDBASE,A5		;5ba: 4bf900dff000
	LEA	LAB_0065(PC),A6		;5c0: 4dfa046c
	MOVE.l	10(A6),208(A5)		;5c4: 2b6e000a00d0
	MOVE.w	14(A6),212(A5)		;5ca: 3b6e000e00d4
	LEA	LAB_0064(PC),A6		;5d0: 4dfa0440
	MOVE.l	10(A6),192(A5)		;5d4: 2b6e000a00c0
	MOVE.w	14(A6),196(A5)		;5da: 3b6e000e00c4
	LEA	LAB_0063(PC),A6		;5e0: 4dfa0414
	MOVE.l	10(A6),176(A5)		;5e4: 2b6e000a00b0
	MOVE.w	14(A6),180(A5)		;5ea: 3b6e000e00b4
	LEA	LAB_0062(PC),A6		;5f0: 4dfa03e8
	MOVE.l	10(A6),160(A5)		;5f4: 2b6e000a00a0
	MOVE.w	14(A6),164(A5)		;5fa: 3b6e000e00a4
	ADDI.w	#$0010,LAB_005B+2	;600: 0679001000000958
	CMPI.w	#$0400,LAB_005B+2	;608: 0c79040000000958
	BNE.w	LAB_003A		;610: 66000038
	MOVEA.l	LAB_0023(PC),A0		;614: 207afcae
	ADDA.w	#$03b6,A0		;618: d0fc03b6
LAB_0039:
	CLR.w	LAB_005B+2		;61c: 427900000958
	CLR.b	LAB_005E+1		;622: 42390000095b
	ADDQ.b	#1,LAB_005B+1		;628: 523900000957
	ANDI.b	#$7f,LAB_005B+1		;62e: 0239007f00000957
	MOVE.b	LAB_005B+1,D1		;636: 123900000957
	CMP.b	(A0),D1			;63c: b210
	BNE.w	LAB_003A		;63e: 6600000a
	MOVE.b	1(A0),LAB_005B+1	;642: 13e8000100000957
LAB_003A:
	TST.b	LAB_005E+1		;64a: 4a390000095b
	BNE.w	LAB_0039		;650: 6600ffca
	MOVEM.l	(A7)+,D0-D4/A0-A3/A5-A6	;654: 4cdf6f1f
	RTS				;658: 4e75
LAB_003B:
	MOVE.w	(A6),D2			;65a: 3416
	AND.w	#$0fff,D2		;65c: c47c0fff
	MOVE.w	D2,24(A6)		;660: 3d420018
	MOVE.w	16(A6),D0		;664: 302e0010
	CLR.b	22(A6)			;668: 422e0016
	CMP.w	D0,D2			;66c: b440
	BEQ.w	LAB_003C		;66e: 6700000e
	BGE.w	LAB_003D		;672: 6c00000e
	MOVE.b	#$01,22(A6)		;676: 1d7c00010016
	RTS				;67c: 4e75
LAB_003C:
	CLR.w	24(A6)			;67e: 426e0018
LAB_003D:
	RTS				;682: 4e75
LAB_003E:
	MOVE.b	3(A6),D0		;684: 102e0003
	BEQ.w	LAB_003F		;688: 6700000a
	MOVE.b	D0,23(A6)		;68c: 1d400017
	CLR.b	3(A6)			;690: 422e0003
LAB_003F:
	TST.w	24(A6)			;694: 4a6e0018
	BEQ.w	LAB_003D		;698: 6700ffe8
	MOVEQ	#0,D0			;69c: 7000
	MOVE.b	23(A6),D0		;69e: 102e0017
	TST.b	22(A6)			;6a2: 4a2e0016
	BNE.w	LAB_0041		;6a6: 66000024
	ADD.w	D0,16(A6)		;6aa: d16e0010
	MOVE.w	24(A6),D0		;6ae: 302e0018
	CMP.w	16(A6),D0		;6b2: b06e0010
	BGT.w	LAB_0040		;6b6: 6e00000c
	MOVE.w	24(A6),16(A6)		;6ba: 3d6e00180010
	CLR.w	24(A6)			;6c0: 426e0018
LAB_0040:
	MOVE.w	16(A6),6(A5)		;6c4: 3b6e00100006
	RTS				;6ca: 4e75
LAB_0041:
	SUB.w	D0,16(A6)		;6cc: 916e0010
	MOVE.w	24(A6),D0		;6d0: 302e0018
	CMP.w	16(A6),D0		;6d4: b06e0010
	BLT.w	LAB_0040		;6d8: 6d00ffea
	MOVE.w	24(A6),16(A6)		;6dc: 3d6e00180010
	CLR.w	24(A6)			;6e2: 426e0018
	MOVE.w	16(A6),6(A5)		;6e6: 3b6e00100006
	RTS				;6ec: 4e75
LAB_0042:
	MOVE.b	3(A6),D0		;6ee: 102e0003
	BEQ.w	LAB_0043		;6f2: 67000006
	MOVE.b	D0,26(A6)		;6f6: 1d40001a
LAB_0043:
	MOVE.b	27(A6),D0		;6fa: 102e001b
	LEA	LAB_0059(PC),A4		;6fe: 49fa01ea
	LSR.w	#2,D0			;702: e448
	AND.w	#$001f,D0		;704: c07c001f
	MOVEQ	#0,D2			;708: 7400
	MOVE.b	0(A4,D0.w),D2		;70a: 14340000
	MOVE.b	26(A6),D0		;70e: 102e001a
	AND.w	#$000f,D0		;712: c07c000f
	MULU	D0,D2			;716: c4c0
	LSR.w	#6,D2			;718: ec4a
	MOVE.w	16(A6),D0		;71a: 302e0010
	TST.b	27(A6)			;71e: 4a2e001b
	BMI.w	LAB_0044		;722: 6b000008
	ADD.w	D2,D0			;726: d042
	BRA.w	LAB_0045		;728: 60000004
LAB_0044:
	SUB.w	D2,D0			;72c: 9042
LAB_0045:
	MOVE.w	D0,6(A5)		;72e: 3b400006
	MOVE.b	26(A6),D0		;732: 102e001a
	LSR.w	#2,D0			;736: e448
	AND.w	#$003c,D0		;738: c07c003c
	ADD.b	D0,27(A6)		;73c: d12e001b
	RTS				;740: 4e75
LAB_0046:
	MOVE.w	16(A6),6(A5)		;742: 3b6e00100006
	RTS				;748: 4e75
LAB_0047:
	MOVE.w	2(A6),D0		;74a: 302e0002
	AND.w	#$0fff,D0		;74e: c07c0fff
	BEQ.w	LAB_0046		;752: 6700ffee
	MOVE.b	2(A6),D0		;756: 102e0002
	AND.b	#$0f,D0			;75a: c03c000f
	TST.b	D0			;75e: 4a00
	BEQ.w	LAB_002B		;760: 6700fc76
	CMPI.b	#$01,D0			;764: 0c000001
	BEQ.w	LAB_004C		;768: 67000072
	CMPI.b	#$02,D0			;76c: 0c000002
	BEQ.w	LAB_004E		;770: 6700009e
	CMPI.b	#$03,D0			;774: 0c000003
	BEQ.w	LAB_003E		;778: 6700ff0a
	CMPI.b	#$04,D0			;77c: 0c000004
	BEQ.w	LAB_0042		;780: 6700ff6c
	MOVE.w	16(A6),6(A5)		;784: 3b6e00100006
	CMPI.b	#$0a,D0			;78a: 0c00000a
	BEQ.w	LAB_0048		;78e: 67000004
	RTS				;792: 4e75
LAB_0048:
	MOVEQ	#0,D0			;794: 7000
	MOVE.b	3(A6),D0		;796: 102e0003
	LSR.b	#4,D0			;79a: e808
	TST.b	D0			;79c: 4a00
	BEQ.w	LAB_004A		;79e: 6700001e
	ADD.w	D0,18(A6)		;7a2: d16e0012
	CMPI.w	#$0040,18(A6)		;7a6: 0c6e00400012
	BMI.w	LAB_0049		;7ac: 6b000008
	MOVE.w	#$0040,18(A6)		;7b0: 3d7c00400012
LAB_0049:
	MOVE.w	18(A6),8(A5)		;7b6: 3b6e00120008
	RTS				;7bc: 4e75
LAB_004A:
	MOVEQ	#0,D0			;7be: 7000
	MOVE.b	3(A6),D0		;7c0: 102e0003
	AND.b	#$0f,D0			;7c4: c03c000f
	SUB.w	D0,18(A6)		;7c8: 916e0012
	BPL.w	LAB_004B		;7cc: 6a000006
	CLR.w	18(A6)			;7d0: 426e0012
LAB_004B:
	MOVE.w	18(A6),8(A5)		;7d4: 3b6e00120008
	RTS				;7da: 4e75
LAB_004C:
	MOVEQ	#0,D0			;7dc: 7000
	MOVE.b	3(A6),D0		;7de: 102e0003
	SUB.w	D0,16(A6)		;7e2: 916e0010
	MOVE.w	16(A6),D0		;7e6: 302e0010
	AND.w	#$0fff,D0		;7ea: c07c0fff
	CMPI.w	#$0071,D0		;7ee: 0c400071
	BPL.w	LAB_004D		;7f2: 6a00000e
	ANDI.w	#$f000,16(A6)		;7f6: 026ef0000010
	ORI.w	#$0071,16(A6)		;7fc: 006e00710010
LAB_004D:
	MOVE.w	16(A6),D0		;802: 302e0010
	AND.w	#$0fff,D0		;806: c07c0fff
	MOVE.w	D0,6(A5)		;80a: 3b400006
	RTS				;80e: 4e75
LAB_004E:
	CLR.w	D0			;810: 4240
	MOVE.b	3(A6),D0		;812: 102e0003
	ADD.w	D0,16(A6)		;816: d16e0010
	MOVE.w	16(A6),D0		;81a: 302e0010
	AND.w	#$0fff,D0		;81e: c07c0fff
	CMPI.w	#$0358,D0		;822: 0c400358
	BMI.w	LAB_004F		;826: 6b00000e
	ANDI.w	#$f000,16(A6)		;82a: 026ef0000010
	ORI.w	#$0358,16(A6)		;830: 006e03580010
LAB_004F:
	MOVE.w	16(A6),D0		;836: 302e0010
	AND.w	#$0fff,D0		;83a: c07c0fff
	MOVE.w	D0,6(A5)		;83e: 3b400006
	RTS				;842: 4e75
LAB_0050:
	MOVE.b	2(A6),D0		;844: 102e0002
	AND.b	#$0f,D0			;848: c03c000f
	CMPI.b	#$0e,D0			;84c: 0c00000e
	BEQ.w	LAB_0051		;850: 67000024
	CMPI.b	#$0d,D0			;854: 0c00000d
	BEQ.w	LAB_0052		;858: 67000036
	CMPI.b	#$0b,D0			;85c: 0c00000b
	BEQ.w	LAB_0053		;860: 67000036
	CMPI.b	#$0c,D0			;864: 0c00000c
	BEQ.w	LAB_0054		;868: 67000042
	CMPI.b	#$0f,D0			;86c: 0c00000f
	BEQ.w	LAB_0056		;870: 67000052
	RTS				;874: 4e75
LAB_0051:
	MOVE.b	3(A6),D0		;876: 102e0003
	AND.b	#$01,D0			;87a: c03c0001
	ASL.b	#1,D0			;87e: e300
	ANDI.b	#$fd,CIAA_PRA		;880: 023900fd00bfe001
	OR.b	D0,CIAA_PRA		;888: 813900bfe001
	RTS				;88e: 4e75
LAB_0052:
	NOT.b	LAB_005E+1		;890: 46390000095b
	RTS				;896: 4e75
LAB_0053:
	MOVE.b	3(A6),D0		;898: 102e0003
	SUBQ.b	#1,D0			;89c: 5300
	MOVE.b	D0,LAB_005B+1		;89e: 13c000000957
	NOT.b	LAB_005E+1		;8a4: 46390000095b
	RTS				;8aa: 4e75
LAB_0054:
	CMPI.b	#$40,3(A6)		;8ac: 0c2e00400003
	BLE.w	LAB_0055		;8b2: 6f000008
	MOVE.b	#$40,3(A6)		;8b6: 1d7c00400003
LAB_0055:
	MOVE.b	3(A6),8(A5)		;8bc: 1b6e00030008
	RTS				;8c2: 4e75
LAB_0056:
	CMPI.b	#$1f,3(A6)		;8c4: 0c2e001f0003
	BLE.w	LAB_0057		;8ca: 6f000008
	MOVE.b	#$1f,3(A6)		;8ce: 1d7c001f0003
LAB_0057:
	MOVE.b	3(A6),D0		;8d4: 102e0003
	BEQ.w	LAB_0058		;8d8: 6700000e
	MOVE.b	D0,LAB_005B		;8dc: 13c000000956
	CLR.b	LAB_005E		;8e2: 42390000095a
LAB_0058:
	RTS				;8e8: 4e75
LAB_0059:
	Dc.w	$0018			;8ea
	MOVE.w	A2,24952(A0)		;8ec: 314a6178
	OR.l	D6,-(A1)		;8f0: 8da1
	CMPA.w	D5,A2			;8f2: b4c5
	ADDA.w	-(A0),A2		;8f4: d4e0
	Dc.w	$ebf4			;8f6
	Dc.w	$fafd			;8f8
	Dc.w	$fffd			;8fa
	Dc.w	$faf4			;8fc
	Dc.w	$ebe0			;8fe
	ADDA.w	D5,A2			;900: d4c5
	CMP.l	-(A1),D2		;902: b4a1
	OR.w	D6,EXT_0000.w		;904: 8d78614a
	MOVE.w	(A0)+,-(A0)		;908: 3118
LAB_005A:
	BCHG	D1,(A0)+		;90a: 0358
	BTST	D1,762(A0)		;90c: 032802fa
	Dc.w	$02d0			;910
	ANDI.l	#$0280025c,-(A6)	;912: 02a60280025c
	Dc.w	$023a			;918
	Dc.w	$021a			;91a
	Dc.w	$01fc			;91c
	BSET	D0,-(A0)		;91e: 01e0
	BSET	D0,D5			;920: 01c5
	BCLR	D0,404(A4)		;922: 01ac0194
	Dc.w	$017d			;926
	BCHG	D0,339(A0)		;928: 01680153
	BCHG	D0,D0			;92c: 0140
	BTST	D0,285(A6)		;92e: 012e011d
	MOVEP.w	254(A5),D0		;932: 010d00fe
	Dc.w	$00f0			;936
	Dc.w	$00e2			;938
	Dc.w	$00d6			;93a
	Dc.w	$00ca			;93c
	Dc.w	$00be			;93e
	ORI.l	#$00aa00a0,-105(A4,D0.w) ;940: 00b400aa00a00097
	Dc.w	$008f			;948
	ORI.l	#$007f0078,D7		;94a: 0087007f0078
	ORI.w	#$0000,0(A1,D0.w)	;950: 007100000000
LAB_005B:
	ADDI.b	#$00,D0			;956: 06000000
LAB_005E:
	ORI.b	#$00,D0			;95a: 00000000
LAB_0061:
	ORI.b	#$00,D0			;95e: 00000000
	ORI.b	#$00,D0			;962: 00000000
	ORI.b	#$00,D0			;966: 00000000
	ORI.b	#$00,D0			;96a: 00000000
	ORI.b	#$00,D0			;96e: 00000000
	ORI.b	#$00,D0			;972: 00000000
	ORI.b	#$00,D0			;976: 00000000
	ORI.b	#$00,D0			;97a: 00000000
	ORI.b	#$00,D0			;97e: 00000000
	ORI.b	#$00,D0			;982: 00000000
	ORI.b	#$00,D0			;986: 00000000
	ORI.b	#$00,D0			;98a: 00000000
	ORI.b	#$00,D0			;98e: 00000000
	ORI.b	#$00,D0			;992: 00000000
	ORI.b	#$00,D0			;996: 00000000
	ORI.b	#$00,D0			;99a: 00000000
	ORI.b	#$00,D0			;99e: 00000000
	ORI.b	#$00,D0			;9a2: 00000000
	ORI.b	#$00,D0			;9a6: 00000000
	ORI.b	#$00,D0			;9aa: 00000000
	ORI.b	#$00,D0			;9ae: 00000000
	ORI.b	#$00,D0			;9b2: 00000000
	ORI.b	#$00,D0			;9b6: 00000000
	ORI.b	#$00,D0			;9ba: 00000000
	ORI.b	#$00,D0			;9be: 00000000
	ORI.b	#$00,D0			;9c2: 00000000
	ORI.b	#$00,D0			;9c6: 00000000
	ORI.b	#$00,D0			;9ca: 00000000
	ORI.b	#$00,D0			;9ce: 00000000
	ORI.b	#$00,D0			;9d2: 00000000
	ORI.b	#$00,D0			;9d6: 00000000
LAB_0062:
	ORI.b	#$00,D0			;9da: 00000000
	ORI.b	#$00,D0			;9de: 00000000
	ORI.b	#$00,D0			;9e2: 00000000
	ORI.b	#$00,D0			;9e6: 00000000
	ORI.b	#$00,D0			;9ea: 00000000
	ORI.b	#$00,D1			;9ee: 00010000
	ORI.b	#$00,D0			;9f2: 00000000
LAB_0063:
	ORI.b	#$00,D0			;9f6: 00000000
	ORI.b	#$00,D0			;9fa: 00000000
	ORI.b	#$00,D0			;9fe: 00000000
	ORI.b	#$00,D0			;a02: 00000000
	ORI.b	#$00,D0			;a06: 00000000
	ORI.b	#$00,D2			;a0a: 00020000
	ORI.b	#$00,D0			;a0e: 00000000
LAB_0064:
	ORI.b	#$00,D0			;a12: 00000000
	ORI.b	#$00,D0			;a16: 00000000
	ORI.b	#$00,D0			;a1a: 00000000
	ORI.b	#$00,D0			;a1e: 00000000
	ORI.b	#$00,D0			;a22: 00000000
	ORI.b	#$00,D4			;a26: 00040000
	ORI.b	#$00,D0			;a2a: 00000000
LAB_0065:
	ORI.b	#$00,D0			;a2e: 00000000
	ORI.b	#$00,D0			;a32: 00000000
	ORI.b	#$00,D0			;a36: 00000000
	ORI.b	#$00,D0			;a3a: 00000000
	ORI.b	#$00,D0			;a3e: 00000000
	Dc.w	$0008			;a42
	ORI.b	#$00,D0			;a44: 00000000
	Dc.w	$0000			;a48
	Dc.w	$f000			;a4a
	Dc.w	$fff0			;a4c
	Dc.w	$0000			;a4e
	Dc.w	$fff0			;a50
	Dc.w	$0fff			;a52
	Dc.w	$000f			;a54
	Dc.w	$ffff			;a56
	Dc.w	$000f			;a58
	Dc.w	$f000			;a5a
	Dc.w	$fff0			;a5c
	Dc.w	$0000			;a5e
	Dc.w	$fff0			;a60
	Dc.w	$0fff			;a62
	Dc.w	$000f			;a64
	Dc.w	$ffff			;a66
	Dc.w	$000f			;a68
	MOVE.l	D0,D0			;a6a: 2000
	Dc.w	$ffff			;a6c
	Dc.w	$f000			;a6e
	Dc.w	$ffff			;a70
	Dc.w	$ffff			;a72
	Dc.w	$0000			;a74
	Dc.w	$0fff			;a76
	Dc.w	$0000			;a78
	MOVE.w	D0,D0			;a7a: 3000
	Dc.w	$ffff			;a7c
	Dc.w	$f000			;a7e
	Dc.w	$ffff			;a80
	Dc.w	$cfff			;a82
	Dc.w	$0000			;a84
	Dc.w	$0fff			;a86
	Dc.w	$0000			;a88
	Dc.w	$f000			;a8a
	Dc.w	$ffff			;a8c
	Dc.w	$f000			;a8e
	Dc.w	$ffff			;a90
	Dc.w	$0fff			;a92
	Dc.w	$0000			;a94
	Dc.w	$0fff			;a96
	Dc.w	$0000			;a98
	Dc.w	$f000			;a9a
	Dc.w	$ffff			;a9c
	Dc.w	$f000			;a9e
	Dc.w	$ffff			;aa0
	Dc.w	$0fff			;aa2
	Dc.w	$0000			;aa4
	Dc.w	$0fff			;aa6
	Dc.w	$0000			;aa8
	Dc.w	$f000			;aaa
	Dc.w	$ffff			;aac
	Dc.w	$0000			;aae
	Dc.w	$fff0			;ab0
	Dc.w	$0fff			;ab2
	Dc.w	$0000			;ab4
	Dc.w	$ffff			;ab6
	Dc.w	$000f			;ab8
	Dc.w	$f000			;aba
	Dc.w	$ffff			;abc
	Dc.w	$0000			;abe
	Dc.w	$fff0			;ac0
	Dc.w	$0fff			;ac2
	Dc.w	$0000			;ac4
	Dc.w	$ffff			;ac6
	Dc.w	$000f			;ac8
	Dc.w	$f000			;aca
	Dc.w	$fff0			;acc
	Dc.w	$0000			;ace
	Dc.w	$fff0			;ad0
	Dc.w	$0fff			;ad2
	Dc.w	$000f			;ad4
	Dc.w	$ffff			;ad6
	Dc.w	$000f			;ad8
	Dc.w	$f000			;ada
	Dc.w	$fff0			;adc
	Dc.w	$0000			;ade
	Dc.w	$fff0			;ae0
	Dc.w	$0fff			;ae2
	Dc.w	$000f			;ae4
	Dc.w	$ffff			;ae6
	Dc.w	$000f			;ae8
	Dc.w	$0000			;aea
	Dc.w	$ffff			;aec
	Dc.w	$f000			;aee
	Dc.w	$ffff			;af0
	Dc.w	$dfff			;af2
	Dc.w	$0000			;af4
	Dc.w	$0fff			;af6
	Dc.w	$0000			;af8
	MOVE.l	D0,D0			;afa: 2000
	Dc.w	$ffff			;afc
	Dc.w	$f000			;afe
	Dc.w	$ffff			;b00
	Dc.w	$9fff			;b02
	Dc.w	$0000			;b04
	Dc.w	$0fff			;b06
	Dc.w	$0000			;b08
	Dc.w	$f000			;b0a
	Dc.w	$ffff			;b0c
	Dc.w	$f000			;b0e
	Dc.w	$ffff			;b10
	Dc.w	$0fff			;b12
	Dc.w	$0000			;b14
	Dc.w	$0fff			;b16
	Dc.w	$0000			;b18
	Dc.w	$f000			;b1a
	Dc.w	$ffff			;b1c
	Dc.w	$f000			;b1e
	Dc.w	$ffff			;b20
	Dc.w	$0fff			;b22
	Dc.w	$0000			;b24
	Dc.w	$0fff			;b26
	Dc.w	$0000			;b28
	Dc.w	$f000			;b2a
	Dc.w	$ffff			;b2c
	Dc.w	$0000			;b2e
	Dc.w	$fff0			;b30
	Dc.w	$0fff			;b32
	Dc.w	$0000			;b34
	Dc.w	$ffff			;b36
	Dc.w	$000f			;b38
	Dc.w	$f000			;b3a
	Dc.w	$ffff			;b3c
	Dc.w	$0000			;b3e
	Dc.w	$fff0			;b40
	Dc.w	$0fff			;b42
	Dc.w	$0000			;b44
	Dc.w	$ffff			;b46
	Dc.w	$000f			;b48
	Dc.w	$f000			;b4a
	Dc.w	$fff0			;b4c
	Dc.w	$0000			;b4e
	Dc.w	$fff0			;b50
	Dc.w	$0fff			;b52
	Dc.w	$000f			;b54
	Dc.w	$ffff			;b56
	Dc.w	$000f			;b58
	Dc.w	$f000			;b5a
	Dc.w	$fff0			;b5c
	Dc.w	$0000			;b5e
	Dc.w	$fff0			;b60
	Dc.w	$0fff			;b62
	Dc.w	$000f			;b64
	Dc.w	$ffff			;b66
	Dc.w	$000f			;b68
	Dc.w	$000d			;b6a
	Dc.w	$fff0			;b6c
	Dc.w	$000d			;b6e
	Dc.w	$fff0			;b70
	Dc.w	$fff1			;b72
	Dc.w	$000f			;b74
	Dc.w	$fff0			;b76
	Dc.w	$000f			;b78
	Dc.w	$000e			;b7a
	Dc.w	$fff0			;b7c
	Dc.w	$000e			;b7e
	Dc.w	$fff0			;b80
	Dc.w	$fff1			;b82
	Dc.w	$000f			;b84
	Dc.w	$fff1			;b86
	Dc.w	$000f			;b88
	Dc.w	$0000			;b8a
	Dc.w	$fffc			;b8c
	Dc.w	$0000			;b8e
	Dc.w	$fffc			;b90
	Dc.w	$ffff			;b92
	Dc.w	$000b			;b94
	Dc.w	$ffff			;b96
	Dc.w	$000b			;b98
	Dc.w	$0000			;b9a
	Dc.w	$fff6			;b9c
	Dc.w	$0000			;b9e
	Dc.w	$fff6			;ba0
	Dc.w	$ffff			;ba2
	Dc.w	$0009			;ba4
	Dc.w	$ffff			;ba6
	Dc.w	$0009			;ba8
	Dc.w	$f000			;baa
	Dc.w	$fff4			;bac
	Dc.w	$0000			;bae
	Dc.w	$ffff			;bb0
	Dc.w	$0fff			;bb2
	Dc.w	$000b			;bb4
	Dc.w	$ffff			;bb6
	Dc.w	$0000			;bb8
	Dc.w	$f000			;bba
	Dc.w	$fff6			;bbc
	Dc.w	$0000			;bbe
	Dc.w	$ffff			;bc0
	Dc.w	$0fff			;bc2
	Dc.w	$0009			;bc4
	Dc.w	$ffff			;bc6
	ORI.b	#$00,D0			;bc8: 00000000
	Dc.w	$efff			;bcc
	BTST	D7,D0			;bce: 0f00
	Dc.w	$efff			;bd0
	Dc.w	$ffff			;bd2
	MOVE.b	D0,D0			;bd4: 1000
	Dc.w	$f0ff			;bd6
	MOVE.b	D0,D0			;bd8: 1000
	Dc.w	$0000			;bda
	Dc.w	$effe			;bdc
	BTST	D7,D0			;bde: 0f00
	Dc.w	$efff			;be0
	Dc.w	$ffff			;be2
	MOVE.b	D0,D0			;be4: 1000
	Dc.w	$f0ff			;be6
	MOVE.b	D0,D0			;be8: 1000
	Dc.w	$0006			;bea
	Dc.w	$fff0			;bec
	Dc.w	$0006			;bee
	Dc.w	$fff0			;bf0
	Dc.w	$fff3			;bf2
	Dc.w	$000f			;bf4
	Dc.w	$fff3			;bf6
	Dc.w	$100f			;bf8
	Dc.w	$0007			;bfa
	Dc.w	$fff0			;bfc
	Dc.w	$0007			;bfe
	Dc.w	$fff0			;c00
	Dc.w	$fff9			;c02
	Dc.w	$000f			;c04
	Dc.w	$fff8			;c06
	Dc.w	$000f			;c08
	Dc.w	$0000			;c0a
	Dc.w	$fff6			;c0c
	Dc.w	$0000			;c0e
	Dc.w	$fff6			;c10
	Dc.w	$ffff			;c12
	Dc.w	$000b			;c14
	Dc.w	$ffff			;c16
	Dc.w	$000b			;c18
	Dc.w	$0000			;c1a
	Dc.w	$fff4			;c1c
	Dc.w	$0000			;c1e
	Dc.w	$fff4			;c20
	Dc.w	$ffff			;c22
	Dc.w	$0009			;c24
	Dc.w	$ffff			;c26
	Dc.w	$0009			;c28
	Dc.w	$f000			;c2a
	Dc.w	$fff6			;c2c
	Dc.w	$0000			;c2e
	Dc.w	$ffff			;c30
	Dc.w	$0fff			;c32
	Dc.w	$000b			;c34
	Dc.w	$ffff			;c36
	Dc.w	$0000			;c38
	Dc.w	$f000			;c3a
	Dc.w	$fff0			;c3c
	Dc.w	$0000			;c3e
	Dc.w	$ffff			;c40
	Dc.w	$0fff			;c42
	Dc.w	$0009			;c44
	Dc.w	$ffff			;c46
	ORI.b	#$00,D0			;c48: 00000000
	Dc.w	$efff			;c4c
	BTST	D7,D0			;c4e: 0f00
	Dc.w	$efff			;c50
	Dc.w	$ffff			;c52
	MOVE.b	D1,D0			;c54: 1001
	Dc.w	$f0ff			;c56
	MOVE.b	D0,D0			;c58: 1000
	Dc.w	$0000			;c5a
	Dc.w	$eff7			;c5c
	BTST	D7,D0			;c5e: 0f00
	Dc.w	$efff			;c60
	Dc.w	$ffff			;c62
	Dc.w	$1008			;c64
	Dc.w	$f0ff			;c66
	MOVE.b	D0,D0			;c68: 1000
	Dc.w	$000f			;c6a
	Dc.w	$fff0			;c6c
	Dc.w	$000f			;c6e
	Dc.w	$fff0			;c70
	Dc.w	$fff1			;c72
	Dc.w	$000f			;c74
	Dc.w	$fff0			;c76
	Dc.w	$000f			;c78
	Dc.w	$000d			;c7a
	Dc.w	$fff0			;c7c
	Dc.w	$000d			;c7e
	Dc.w	$fff0			;c80
	Dc.w	$fff3			;c82
	Dc.w	$000f			;c84
	Dc.w	$fff2			;c86
	Dc.w	$000f			;c88
	Dc.w	$0000			;c8a
	Dc.w	$fff2			;c8c
	Dc.w	$0000			;c8e
	Dc.w	$fff6			;c90
	Dc.w	$ffff			;c92
	Dc.w	$0001			;c94
	Dc.w	$ffff			;c96
	ORI.b	#$00,D1			;c98: 00010000
	Dc.w	$fff8			;c9c
	Dc.w	$0000			;c9e
	Dc.w	$fff8			;ca0
	Dc.w	$ffff			;ca2
	Dc.w	$000b			;ca4
	Dc.w	$ffff			;ca6
	Dc.w	$000b			;ca8
	Dc.w	$f000			;caa
	Dc.w	$fff2			;cac
	Dc.w	$0000			;cae
	Dc.w	$ffff			;cb0
	Dc.w	$0fff			;cb2
	Dc.w	$0005			;cb4
	Dc.w	$ffff			;cb6
	Dc.w	$0000			;cb8
	Dc.w	$f000			;cba
	Dc.w	$fff8			;cbc
	Dc.w	$0000			;cbe
	Dc.w	$ffff			;cc0
	Dc.w	$0fff			;cc2
	Dc.w	$000b			;cc4
	Dc.w	$ffff			;cc6
	ORI.b	#$00,D0			;cc8: 00000000
	Dc.w	$efff			;ccc
	BTST	D7,D0			;cce: 0f00
	Dc.w	$efff			;cd0
	Dc.w	$ffff			;cd2
	MOVE.b	D0,D0			;cd4: 1000
	Dc.w	$f0ff			;cd6
	MOVE.b	D0,D0			;cd8: 1000
	Dc.w	$0000			;cda
	Dc.w	$efff			;cdc
	BTST	D7,D0			;cde: 0f00
	Dc.w	$efff			;ce0
	Dc.w	$ffff			;ce2
	MOVE.b	D0,D0			;ce4: 1000
	Dc.w	$f0ff			;ce6
	MOVE.b	D0,D0			;ce8: 1000
	Dc.w	$0007			;cea
	Dc.w	$fff0			;cec
	Dc.w	$0007			;cee
	Dc.w	$bff0			;cf0
	Dc.w	$fff6			;cf2
	Dc.w	$000f			;cf4
	Dc.w	$fff6			;cf6
	Dc.w	$400f			;cf8
	Dc.w	$000d			;cfa
	Dc.w	$fff0			;cfc
	Dc.w	$000d			;cfe
	Dc.w	$fff0			;d00
	Dc.w	$fff4			;d02
	Dc.w	$000e			;d04
	Dc.w	$fff4			;d06
	Dc.w	$000e			;d08
	Dc.w	$0000			;d0a
	Dc.w	$fff6			;d0c
	Dc.w	$0000			;d0e
	Dc.w	$fff6			;d10
	Dc.w	$ffff			;d12
	Dc.w	$000e			;d14
	Dc.w	$ffff			;d16
	Dc.w	$000e			;d18
	Dc.w	$0000			;d1a
	Dc.w	$fffd			;d1c
	Dc.w	$0000			;d1e
	Dc.w	$fffd			;d20
	Dc.w	$fffe			;d22
	Dc.w	$000e			;d24
	Dc.w	$fffe			;d26
	Dc.w	$000c			;d28
	Dc.w	$f000			;d2a
	Dc.w	$fff6			;d2c
	Dc.w	$0000			;d2e
	Dc.w	$ffff			;d30
	Dc.w	$0fff			;d32
	Dc.w	$000e			;d34
	Dc.w	$ffff			;d36
	Dc.w	$0000			;d38
	Dc.w	$f000			;d3a
	Dc.w	$fff8			;d3c
	Dc.w	$0000			;d3e
	Dc.w	$ffff			;d40
	Dc.w	$0ffe			;d42
	Dc.w	$000e			;d44
	Dc.w	$fffe			;d46
	ORI.b	#$00,D0			;d48: 00000000
	Dc.w	$efff			;d4c
	BTST	D7,D0			;d4e: 0f00
	Dc.w	$efff			;d50
	Dc.w	$ffff			;d52
	MOVE.b	D0,D0			;d54: 1000
	Dc.w	$f0ff			;d56
	MOVE.b	D0,D0			;d58: 1000
	Dc.w	$0000			;d5a
	Dc.w	$efff			;d5c
	BTST	D7,D0			;d5e: 0f00
	Dc.w	$efff			;d60
	Dc.w	$ffff			;d62
	MOVE.b	D0,D0			;d64: 1000
	Dc.w	$f0ff			;d66
	MOVE.b	D0,D0			;d68: 1000
	MOVE.l	D0,D0			;d6a: 2000
	Dc.w	$ffff			;d6c
	Dc.w	$f000			;d6e
	Dc.w	$ffff			;d70
	Dc.w	$dfff			;d72
	Dc.w	$0000			;d74
	Dc.w	$0fff			;d76
	Dc.w	$0000			;d78
	MOVE.w	D0,D0			;d7a: 3000
	Dc.w	$ffff			;d7c
	Dc.w	$f000			;d7e
	Dc.w	$ffff			;d80
	Dc.w	$dfff			;d82
	Dc.w	$0000			;d84
	Dc.w	$0fff			;d86
	Dc.w	$0000			;d88
	Dc.w	$f000			;d8a
	Dc.w	$ffff			;d8c
	Dc.w	$f000			;d8e
	Dc.w	$ffff			;d90
	Dc.w	$0fff			;d92
	Dc.w	$0000			;d94
	Dc.w	$0fff			;d96
	Dc.w	$0000			;d98
	Dc.w	$f000			;d9a
	Dc.w	$ffff			;d9c
	Dc.w	$f000			;d9e
	Dc.w	$ffff			;da0
	Dc.w	$0fff			;da2
	Dc.w	$0000			;da4
	Dc.w	$0fff			;da6
	Dc.w	$0000			;da8
	Dc.w	$f000			;daa
	Dc.w	$ffff			;dac
	Dc.w	$0000			;dae
	Dc.w	$fff0			;db0
	Dc.w	$0fff			;db2
	Dc.w	$0000			;db4
	Dc.w	$ffff			;db6
	Dc.w	$000f			;db8
	Dc.w	$f000			;dba
	Dc.w	$ffff			;dbc
	Dc.w	$0000			;dbe
	Dc.w	$fff0			;dc0
	Dc.w	$0fff			;dc2
	Dc.w	$0000			;dc4
	Dc.w	$ffff			;dc6
	Dc.w	$000f			;dc8
	Dc.w	$f000			;dca
	Dc.w	$fff0			;dcc
	Dc.w	$0000			;dce
	Dc.w	$fff0			;dd0
	Dc.w	$0fff			;dd2
	Dc.w	$000f			;dd4
	Dc.w	$ffff			;dd6
	Dc.w	$000f			;dd8
	Dc.w	$f000			;dda
	Dc.w	$fff0			;ddc
	Dc.w	$0000			;dde
	Dc.w	$fff0			;de0
	Dc.w	$0fff			;de2
	Dc.w	$000f			;de4
	Dc.w	$ffff			;de6
	Dc.w	$000f			;de8
	MOVE.l	D0,D0			;dea: 2000
	Dc.w	$ffff			;dec
	Dc.w	$f000			;dee
	Dc.w	$ffff			;df0
	Dc.w	$dfff			;df2
	Dc.w	$0000			;df4
	Dc.w	$0fff			;df6
	Dc.w	$0000			;df8
	MOVE.l	D0,D0			;dfa: 2000
	Dc.w	$ffff			;dfc
	Dc.w	$f000			;dfe
	Dc.w	$ffff			;e00
	Dc.w	$cfff			;e02
	Dc.w	$0000			;e04
	Dc.w	$0fff			;e06
	Dc.w	$0000			;e08
	Dc.w	$f000			;e0a
	Dc.w	$ffff			;e0c
	Dc.w	$f000			;e0e
	Dc.w	$ffff			;e10
	Dc.w	$0fff			;e12
	Dc.w	$0000			;e14
	Dc.w	$0fff			;e16
	Dc.w	$0000			;e18
	Dc.w	$f000			;e1a
	Dc.w	$ffff			;e1c
	Dc.w	$f000			;e1e
	Dc.w	$ffff			;e20
	Dc.w	$0fff			;e22
	Dc.w	$0000			;e24
	Dc.w	$0fff			;e26
	Dc.w	$0000			;e28
	Dc.w	$f000			;e2a
	Dc.w	$ffff			;e2c
	Dc.w	$0000			;e2e
	Dc.w	$fff0			;e30
	Dc.w	$0fff			;e32
	Dc.w	$0000			;e34
	Dc.w	$ffff			;e36
	Dc.w	$000f			;e38
	Dc.w	$f000			;e3a
	Dc.w	$ffff			;e3c
	Dc.w	$0000			;e3e
	Dc.w	$fff0			;e40
	Dc.w	$0fff			;e42
	Dc.w	$0000			;e44
	Dc.w	$ffff			;e46
	Dc.w	$000f			;e48
LAB_0066:
	MOVE.l	#LAB_0068,D0		;e4a: 203c00000e5a
	TRAP	#0			;e50: 4e40
error_checkling:
	MOVE.l	#LAB_0069,D0		;e52: 203c00000e76
	TRAP	#0			;e58: 4e40
LAB_0068:
	Dc.w	$4572			;e5a
	MOVEQ	#111,D1			;e5c: 726f
	MOVEQ	#32,D1			;e5e: 7220
	Dc.w	$4163			;e60
	Dc.w	$6365			;e62
	Dc.w	$7373			;e64
	Dc.w	$696e			;e66
	BEQ.S	LAB_006A		;e68: 6720
	Dc.w	$4d6f			;e6a
	Dc.w	$6475			;e6c
	Dc.w	$6c65			;e6e
	MOVEA.l	D6,A0			;e70: 2046
	Dc.w	$696c			;e72
	Dc.w	$6500			;e74
LAB_0069:
	SUBQ.w	#2,26990(A6)		;e76: 556e696e
	Dc.w	$6974			;e7a
	Dc.w	$6961			;e7c
	Dc.w	$6c69			;e7e
	MOVEQ	#101,D5			;e80: 7a65
	Dc.w	$6420			;e82
	Dc.w	$4d6f			;e84
	Dc.w	$6475			;e86
	Dc.w	$6c65			;e88
LAB_006A:
	Dc.w	$0000			;e8a
LAB_006B:
	TST.l	(A3)			;e8c: 4a93
	BEQ.w	error_checkling		;e8e: 6700ffc2
	RTS				;e92: 4e75
	MOVEQ	#0,D0			;e94: 7000
	RTS				;e96: 4e75
	END
