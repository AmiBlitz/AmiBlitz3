; IRA V2.09 (06.03.18) (c)1993-1995 Tim Ruehsen
; (c)2009-2015 Frank Wille, (c)2014-2017 Nicolas Bastien

ABSEXECBASE	EQU	$4
EXT_0001	EQU	$DFF005




	SECTION S_0,CODE

SECSTRT_0:
	MOVEQ	#0,D0			;000: 7000
	RTS				;002: 4e75
	DC.W	$fff0			;004
	ORI.B	#$00,D0			;006: 00000000
	ORI.B	#$00,D0			;00a: 00000000
	ABCD	D0,D0			;00e: c100
	ABCD	-(A0),-(A0)		;010: c108
	ORI.B	#$00,D0			;012: 00000000
	DC.L	LAB_0001		;016: 000000d4
	ORI.B	#$00,D0			;01a: 00000000
	ORI.B	#$00,D0			;01e: 00000000
	ORI.B	#$00,D0			;022: 00000000
	ORI.B	#$00,D0			;026: 00000000
	ORI.B	#$00,D0			;02a: 00000000
	ORI.B	#$00,D0			;02e: 00000000
	ORI.B	#$00,D0			;032: 00000000
	ORI.B	#$00,D0			;036: 00000000
	DC.W	$0000			;03a
	DC.L	LAB_001E		;03c: 00000288
	ORI.B	#$00,D0			;040: 00000000
	ORI.B	#$00,D0			;044: 00000000
	ORI.B	#$00,D0			;048: 00000000
	ORI.B	#$00,D0			;04c: 00000000
	DC.L	LAB_0022		;050: 00000314
	ORI.B	#$00,D0			;054: 00000000
	ORI.B	#$00,D0			;058: 00000000
	ORI.B	#$00,D0			;05c: 00000000
	ORI.B	#$00,D0			;060: 00000000
	DC.L	LAB_001B		;064: 00000266
	ORI.B	#$00,D0			;068: 00000000
	ORI.B	#$00,D0			;06c: 00000000
	ORI.B	#$00,D0			;070: 00000000
	ORI.B	#$00,D0			;074: 00000000
	DC.L	LAB_001C		;078: 0000026c
	ORI.B	#$00,D0			;07c: 00000000
	ORI.B	#$00,D0			;080: 00000000
	ORI.B	#$fe,D0			;084: 000000fe
	ADDQ.B	#3,D0			;088: 5600
	ORI.B	#$00,D0			;08a: 00000000
	DC.W	$0000			;08e
	DC.L	LAB_0008		;090: 0000017c
	ORI.B	#$00,D0			;094: 00000000
	ORI.B	#$00,D0			;098: 00000000
	ORI.B	#$00,D0			;09c: 00000000
	ORI.B	#$00,D0			;0a0: 00000000
	DC.L	LAB_000E		;0a4: 000001c6
	ORI.B	#$00,D0			;0a8: 00000000
	ORI.B	#$00,D0			;0ac: 00000000
	ORI.B	#$00,D0			;0b0: 00000000
	ORI.B	#$00,D0			;0b4: 00000000
	DC.L	LAB_0028		;0b8: 0000038a
	ORI.B	#$00,D0			;0bc: 00000000
	ORI.B	#$00,D0			;0c0: 00000000
	ORI.B	#$00,D0			;0c4: 00000000
	ORI.B	#$00,D0			;0c8: 00000000
	DC.L	LAB_002A		;0cc: 000003ac
	ORI.B	#$00,D0			;0d0: 00000000
LAB_0001:
	ORI.B	#$00,D0			;0d4: 00000000
	ORI.B	#$00,D0			;0d8: 00000000
	ORI.B	#$00,D0			;0dc: 00000000
	DC.L	LAB_000C		;0e0: 000001ac
	ORI.B	#$00,D0			;0e4: 00000000
	DC.W	$ffff			;0e8
	ORI.B	#$00,D0			;0ea: 00000000
LAB_0002:
	ORI.B	#$00,D0			;0ee: 00000000
LAB_0004:
	ORI.B	#$00,D0			;0f2: 00000000
	ORI.B	#$00,D0			;0f6: 00000000
	ORI.B	#$00,D0			;0fa: 00000000
	ORI.B	#$00,D0			;0fe: 00000000
	ORI.B	#$00,D0			;102: 00000000
	ORI.B	#$00,D0			;106: 00000000
	ORI.B	#$00,D0			;10a: 00000000
	ORI.B	#$00,D0			;10e: 00000000
	ORI.B	#$00,D0			;112: 00000000
	ORI.B	#$00,D0			;116: 00000000
	ORI.B	#$00,D0			;11a: 00000000
	ORI.B	#$00,D0			;11e: 00000000
	ORI.B	#$00,D0			;122: 00000000
	ORI.B	#$00,D0			;126: 00000000
	ORI.B	#$00,D0			;12a: 00000000
	ORI.B	#$00,D0			;12e: 00000000
LAB_0005:
	ORI.B	#$00,D0			;132: 00000000
	ORI.B	#$00,D0			;136: 00000000
	ORI.B	#$00,D0			;13a: 00000000
	ORI.B	#$00,D0			;13e: 00000000
	ORI.B	#$00,D0			;142: 00000000
	ORI.B	#$00,D0			;146: 00000000
	ORI.B	#$00,D0			;14a: 00000000
	ORI.B	#$00,D0			;14e: 00000000
	ORI.B	#$00,D0			;152: 00000000
	ORI.B	#$00,D0			;156: 00000000
	ORI.B	#$00,D0			;15a: 00000000
	ORI.B	#$00,D0			;15e: 00000000
	ORI.B	#$00,D0			;162: 00000000
	ORI.B	#$00,D0			;166: 00000000
	ORI.B	#$00,D0			;16a: 00000000
	ORI.B	#$00,D0			;16e: 00000000
LAB_0006:
	ORI.B	#$00,D0			;172: 00000000
LAB_0007:
	ORI.B	#$00,D0			;176: 00000000
	DC.W	$0000			;17a
LAB_0008:
	DC.W	$a001			;17c
	DC.L	LAB_000A		;17e: 0000018e
	MOVE.W	D0,D2			;182: 3400
LAB_0009:
	JSR	-270(A6)		;184: 4eaefef2
	DBF	D2,LAB_0009		;188: 51cafffa
	RTS				;18c: 4e75
LAB_000A:
	BTST	#0,EXT_0001		;18e: 0839000000dff005
	BEQ.W	LAB_000A		;196: 6700fff6
LAB_000B:
	BTST	#0,EXT_0001		;19a: 0839000000dff005
	BNE.W	LAB_000B		;1a2: 6600fff6
	DBF	D0,LAB_000A		;1a6: 51c8ffe6
	RTS				;1aa: 4e75
LAB_000C:
	CLR.W	LAB_0007+2		;1ac: 427900000178
	LEA	LAB_0004+2(PC),A0	;1b2: 41faff40
	MOVEQ	#31,D0			;1b6: 701f
LAB_000D:
	CLR.L	(A0)+			;1b8: 4298
	DBF	D0,LAB_000D		;1ba: 51c8fffc
	MOVE.L	A5,LAB_0002+2		;1be: 23cd000000f0
	RTS				;1c4: 4e75
LAB_000E:
	LEA	LAB_0004+2(PC),A2	;1c6: 45faff2c
	BSR.W	LAB_0017		;1ca: 6100006c
	TST.W	LAB_0007+2		;1ce: 4a7900000178
	BEQ.W	LAB_000F		;1d4: 6700000a
	LEA	LAB_0005+2(PC),A2	;1d8: 45faff5a
	BSR.W	LAB_0017		;1dc: 6100005a
LAB_000F:
	LEA	LAB_0004+2(PC),A2	;1e0: 45faff12
	MOVEQ	#31,D2			;1e4: 741f
LAB_0010:
	MOVE.L	(A2)+,D0		;1e6: 201a
	BEQ.W	LAB_0012		;1e8: 6700001a
	CLR.L	-4(A2)			;1ec: 42aafffc
LAB_0011:
	MOVEA.L	D0,A3			;1f0: 2640
	MOVE.L	(A3),-(A7)		;1f2: 2f13
	MOVEA.L	A3,A1			;1f4: 224b
	MOVEQ	#28,D0			;1f6: 701c
	DC.W	$4eb9			;1f8
	DC.L	SECSTRT_0-2147434493	;1fa: 8000c003
	MOVE.L	(A7)+,D0		;1fe: 201f
	BNE.W	LAB_0011		;200: 6600ffee
LAB_0012:
	DBF	D2,LAB_0010		;204: 51caffe0
	RTS				;208: 4e75
LAB_0013:
	MOVEA.L	ABSEXECBASE,A6		;20a: 2c7900000004
	MOVEQ	#15,D2			;210: 740f
LAB_0014:
	MOVE.L	(A2)+,D0		;212: 201a
	BEQ.W	LAB_0016		;214: 6700001c
LAB_0015:
	MOVEA.L	D0,A3			;218: 2640
	LEA	6(A3),A1		;21a: 43eb0006
	MOVE.W	4(A3),D0		;21e: 302b0004
	AND.L	#$0000000f,D0		;222: c0bc0000000f
	JSR	-168(A6)		;228: 4eaeff58
	MOVE.L	(A3),D0			;22c: 2013
	BNE.W	LAB_0015		;22e: 6600ffe8
LAB_0016:
	DBF	D2,LAB_0014		;232: 51caffde
	RTS				;236: 4e75
LAB_0017:
	MOVEA.L	ABSEXECBASE,A6		;238: 2c7900000004
	MOVEQ	#15,D2			;23e: 740f
LAB_0018:
	MOVE.L	(A2)+,D0		;240: 201a
	BEQ.W	LAB_001A		;242: 6700001c
LAB_0019:
	MOVEA.L	D0,A3			;246: 2640
	LEA	6(A3),A1		;248: 43eb0006
	MOVE.W	4(A3),D0		;24c: 302b0004
	AND.L	#$0000000f,D0		;250: c0bc0000000f
	JSR	-174(A6)		;256: 4eaeff52
	MOVE.L	(A3),D0			;25a: 2013
	BNE.W	LAB_0019		;25c: 6600ffe8
LAB_001A:
	DBF	D2,LAB_0018		;260: 51caffde
	RTS				;264: 4e75
LAB_001B:
	MOVEA.L	LAB_0002+2(PC),A5	;266: 2a7afe88
	RTS				;26a: 4e75
LAB_001C:
	RTS				;26c: 4e75
LAB_001D:
	MOVE.L	#LAB_0005+2,LAB_0006+2	;26e: 23fc0000013400000174
	TST.W	LAB_0007+2		;278: 4a7900000178
	SEQ	LAB_0002		;27e: 57f9000000ee
	BRA.W	LAB_001F		;284: 60000018
LAB_001E:
	DC.W	$a001			;288
	DC.L	LAB_001D		;28a: 0000026e
	MOVE.L	#LAB_0004+2,LAB_0006+2	;28e: 23fc000000f400000174
	CLR.W	LAB_0002		;298: 4279000000ee
LAB_001F:
	MOVEM.L	D2/A0-A1/A6,-(A7)	;29e: 48e720c2
	MOVEM.L	D0-D1,-(A7)		;2a2: 48e7c000
	MOVEQ	#28,D0			;2a6: 701c
	MOVE.L	#$00010001,D1		;2a8: 223c00010001
	JSR	SECSTRT_0-2147434494	;2ae: 4eb98000c002
	MOVEA.L	D0,A1			;2b4: 2240
	MOVEM.L	(A7)+,D0-D1		;2b6: 4cdf0003
	MOVEA.L	LAB_0006+2(PC),A0	;2ba: 207afeb8
	MOVE.W	D0,D2			;2be: 3400
	AND.W	#$000f,D2		;2c0: c47c000f
	LSL.W	#2,D2			;2c4: e54a
	ADDA.W	D2,A0			;2c6: d0c2
	MOVE.L	(A0),(A1)		;2c8: 2290
	MOVE.L	A1,(A0)			;2ca: 2089
	ADDQ.W	#4,A1			;2cc: 5849
	MOVE.W	D0,(A1)+		;2ce: 32c0
	MOVE.L	D1,18(A1)		;2d0: 23410012
	MOVE.B	#$02,8(A1)		;2d4: 137c00020008
	TST.W	LAB_0002		;2da: 4a79000000ee
	BNE.W	LAB_0020		;2e0: 66000012
	MOVEA.L	ABSEXECBASE,A6		;2e4: 2c7900000004
	AND.L	#$0000000f,D0		;2ea: c0bc0000000f
	JSR	-168(A6)		;2f0: 4eaeff58
LAB_0020:
	MOVEM.L	(A7)+,D2/A0-A1/A6	;2f4: 4cdf4304
	RTS				;2f8: 4e75
LAB_0021:
	MOVE.L	#LAB_0005+2,LAB_0006+2	;2fa: 23fc0000013400000174
	TST.W	LAB_0007+2		;304: 4a7900000178
	SEQ	LAB_0002		;30a: 57f9000000ee
	BRA.W	LAB_0023		;310: 60000018
LAB_0022:
	DC.W	$a001			;314
	DC.L	LAB_0021		;316: 000002fa
	MOVE.L	#LAB_0004+2,LAB_0006+2	;31a: 23fc000000f400000174
	CLR.W	LAB_0002		;324: 4279000000ee
LAB_0023:
	MOVEM.L	D1-D2/A0-A3/A6,-(A7)	;32a: 48e760f2
	MOVE.W	D0,D2			;32e: 3400
	AND.W	#$000f,D0		;330: c07c000f
	LSL.W	#2,D0			;334: e548
	MOVEA.L	LAB_0006+2(PC),A2	;336: 247afe3c
	LEA	0(A2,D0.W),A3		;33a: 47f20000
LAB_0024:
	MOVE.L	(A3),D1			;33e: 2213
	BEQ.W	LAB_0027		;340: 67000042
	MOVEA.L	D1,A2			;344: 2441
	CMP.W	4(A2),D2		;346: b46a0004
	BEQ.W	LAB_0025		;34a: 67000008
	MOVEA.L	A2,A3			;34e: 264a
	BRA.W	LAB_0024		;350: 6000ffec
LAB_0025:
	TST.W	LAB_0002		;354: 4a79000000ee
	BNE.W	LAB_0026		;35a: 66000018
	LEA	6(A2),A1		;35e: 43ea0006
	MOVE.W	D2,D0			;362: 3002
	AND.L	#$0000000f,D0		;364: c0bc0000000f
	MOVEA.L	ABSEXECBASE,A6		;36a: 2c7900000004
	JSR	-174(A6)		;370: 4eaeff52
LAB_0026:
	MOVEA.L	A2,A1			;374: 224a
	MOVE.L	(A2),(A3)		;376: 2692
	MOVEQ	#28,D0			;378: 701c
	DC.W	$4eb9			;37a
	DC.L	SECSTRT_0-2147434493	;37c: 8000c003
	BRA.W	LAB_0024		;380: 6000ffbc
LAB_0027:
	MOVEM.L	(A7)+,D1-D2/A0-A3/A6	;384: 4cdf4f06
	RTS				;388: 4e75
LAB_0028:
	TST.W	LAB_0007+2		;38a: 4a7900000178
	BNE.W	LAB_0029		;390: 66000018
	ST	LAB_0007+2		;394: 50f900000178
	MOVEM.L	D0-D2/A0-A3/A6,-(A7)	;39a: 48e7e0f2
	LEA	LAB_0005+2(PC),A2	;39e: 45fafd94
	BSR.W	LAB_0013		;3a2: 6100fe66
	MOVEM.L	(A7)+,D0-D2/A0-A3/A6	;3a6: 4cdf4f07
LAB_0029:
	RTS				;3aa: 4e75
LAB_002A:
	TST.W	LAB_0007+2		;3ac: 4a7900000178
	BEQ.W	LAB_002B		;3b2: 67000018
	SF	LAB_0007+2		;3b6: 51f900000178
	MOVEM.L	D0-D2/A0-A3/A6,-(A7)	;3bc: 48e7e0f2
	LEA	LAB_0005+2(PC),A2	;3c0: 45fafd72
	BSR.W	LAB_0017		;3c4: 6100fe72
	MOVEM.L	(A7)+,D0-D2/A0-A3/A6	;3c8: 4cdf4f07
LAB_002B:
	RTS				;3cc: 4e75
	MOVEQ	#0,D0			;3ce: 7000
	RTS				;3d0: 4e75
	DC.W	$010d			;3d2
	END