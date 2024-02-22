;**************************************************
;*    ----- Protracker V2.3B Playroutine -----	  *
;**************************************************
;
; Version 5.3
; Written by Frank Wille in 2013, 2016, 2017, 2018, 2019.
;
; I, the copyright holder of this work, hereby release it into the
; public domain. This applies worldwide.
;
; The default version (single section, local base register) should
; work with most assemblers. Tested are: Devpac, vasm, PhxAss,
; Barfly-Asm, SNMA, AsmOne, AsmPro.
;
; The small data model can be enabled by defining the symbol SDATA. In
; this case all functions expect a4 to be initialised with the small
; data base register. Interrupt functions restore a4 from _LinkerDB.
; Small data may work with vasm and PhxAss only.
;
; Exported functions and variables:
; (CUSTOM is the custom-chip register set base address $dff000.)
;
; _mt_install_cia(a6=CUSTOM, a0=VectorBase, d0=PALflag.b)
;   Install a CIA-B interrupt for calling _mt_music or mt_sfxonly.
;   The music module is replayed via _mt_music when _mt_Enable is non-zero.
;   Otherwise the interrupt handler calls mt_sfxonly to play sound
;   effects only. VectorBase is 0 for 68000, otherwise set it to the CPU's
;   VBR register. A non-zero PALflag selects PAL-clock for the CIA timers
;   (NTSC otherwise).
;
; _mt_remove_cia(a6=CUSTOM)
;   Remove the CIA-B music interrupt, restore the previous handler and
;   reset the CIA timer registers to their original values.
;
; _mt_init(a6=CUSTOM, a0=TrackerModule, a1=Samples|NULL, d0=InitialSongPos.b)
;   Initialize a new module.
;   Reset speed to 6, tempo to 125 and start at the given song position.
;   Master volume is at 64 (maximum).
;   When a1 is NULL the samples are assumed to be stored after the patterns.
;
; _mt_end(a6=CUSTOM)
;   Stop playing current module.
;
; _mt_soundfx(a6=CUSTOM, a0=SamplePointer,
;             d0=SampleLength.w, d1=SamplePeriod.w, d2=SampleVolume.w)
;   Request playing of an external sound effect on the most unused channel.
;   This function is for compatibility with the old API only!
;   You should call _mt_playfx instead.
;
; _mt_playfx(a6=CUSTOM, a0=SfxStructurePointer)
;   Request playing of a prioritized external sound effect, either on a
;   fixed channel or on the most unused one.
;   Structure layout of SfxStructure:
;     void *sfx_ptr (pointer to sample start in Chip RAM, even address)
;     WORD sfx_len  (sample length in words)
;     WORD sfx_per  (hardware replay period for sample)
;     WORD sfx_vol  (volume 0..64, is unaffected by the song's master volume)
;     BYTE sfx_cha  (0..3 selected replay channel, -1 selects best channel)
;     BYTE sfx_pri  (unsigned priority, must be non-zero)
;   When multiple samples are assigned to the same channel the lower
;   priority sample will be replaced. When priorities are the same, then
;   the older sample is replaced.
;   The chosen channel is blocked for music until the effect has
;   completely been replayed.
;
; _mt_musicmask(a6=CUSTOM, d0=ChannelMask.b)
;   Bits set in the mask define which specific channels are reserved
;   for music only. Set bit 0 for channel 0, ..., bit 3 for channel 3.
;   When calling _mt_soundfx or _mt_playfx with automatic channel selection
;   (sfx_cha=-1) then these masked channels will never be picked.
;   The mask defaults to 0.
;
; _mt_mastervol(a6=CUSTOM, d0=MasterVolume.w)
;   Set a master volume from 0 to 64 for all music channels.
;   Note that the master volume does not affect the volume of external
;   sound effects (which is desired).
;
; _mt_music(a6=CUSTOM)
;   The replayer routine. Is called automatically after _mt_install_cia.
;
; Byte Variables:
;
; _mt_Enable
;   Set this byte to non-zero to play music, zero to pause playing.
;   Note that you can still play sound effects, while music is stopped.
;   It is set to 0 by _mt_install_cia.
;
; _mt_SongEnd
;   Set to -1 ($ff) if you want the song to stop automatically when
;   the last position has been played (clears _mt_Enable). Otherwise, the
;   song is restarted and _mt_SongEnd is incremented to count the restarts.
;   It is reset to 0 after _mt_init.
;
; _mt_E8Trigger
;   This byte reflects the value of the last E8 command.
;   It is reset to 0 after _mt_init.
;
; _mt_MusicChannels
;   This byte defines the number of channels which should be dedicated
;   for playing music. So sound effects will never use more
;   than 4 - _mt_MusicChannels channels at once. Defaults to 0.
;

  include "blitz.i"
	include	"custom.i"
	include	"cia.i"

audiolib equ 116
banklib  equ 76

  ; BB2 library header (library number = 196)
	libheader 195,0,0,blitz_finit,0

  ; Declare BB2 library statements and functions
  astatement
    args	word,byte ; Bank#, startpos
    libs	banklib,$1080
    subs	_MTInitBank,0,0
    args long,long,byte ; module addr, instr addr, startpos
    libs
    subs	_MTInit,0,0
  name "MTInit","Bank#, startpos | module addr, instr addr, startpos ; Inserts module into player."

  astatement
    args	byte
    libs
    subs	_MTInstall,0,0
  name "MTInstall","PAL=true/NTSC=false ; Install CIA player routine. PAL=true, NTSC=false"

  astatement
    args	byte
    libs
    subs	_MTPlay,0,0
  name "MTPlay","On/Off ; On=Play, Off=Pause"

  astatement
    args
    libs
    subs	_mt_remove_cia,0,0
  name "MTRemove","; Remove the player from the system."

  astatement
    args
    libs
    subs	_MTEnd,0,0
  name "MTEnd","; Stop playing the current module."

  astatement
    args	long,word,word,word ; sample_addr.l, length.w, period.w, volume.w
    libs
    subs	_MTSoundFX,0,0
    args	word,word ; "Sound#, volume (0..64)
    libs	audiolib,$1080
    subs	_MTSoundFXObject,0,0
  name "MTSoundFX","Sound#, volume (0..64)| sample_addr.l, length.w, period.w, volume.w"

  astatement
    args	word
    libs
    subs	_mt_mastervol,0,0
  name	"MTMasterVolume","volume ; Master volume (0..64) for all music channels."

  astatement
    args	byte
    libs
    subs	_mt_musicmask,0,0
  name	"MTMusicMask","mask ; Set bits 0-3 to reserve channels for music only."

  astatement
    args	byte
    libs
    subs	_MTMusicChannels,0,0
  name	"MTMusicChannels","channels ; Number of channels dedicated to music."

  afunction	byte
    args
    libs
    subs	_MTE8Trigger,0,0
  name	"MTE8Trigger","; Returns the value of the last E8 command (byte)."

  astatement
    args	long
    libs
    subs	_MTPlayFX,0,0
  name "MTPlayFX","sfxStructAddress.l"

blitz_finit:
	nullsub _blitz_ahx_lib_finit,0,0
	libfin

_blitz_ahx_lib_finit:
 	rts
  ; --------------------------------------------------

; Audio channel registers
AUDLC	 equ	0
AUDLEN equ	4
AUDPER equ	6
AUDVOL equ	8


; Sound effects structure, passed into _mt_playfx
		rsreset
sfx_ptr		rs.l	1
sfx_len		rs.w	1
sfx_per		rs.w	1
sfx_vol		rs.w	1
sfx_cha		rs.b	1
sfx_pri		rs.b	1
sfx_sizeof	rs.b	0


; Channel Status
		rsreset
n_note		rs.w	1
n_cmd		rs.b	1
n_cmdlo 	rs.b	1
n_start 	rs.l	1
n_loopstart	rs.l	1
n_length	rs.w	1
n_replen	rs.w	1
n_period	rs.w	1
n_volume	rs.w	1
n_pertab	rs.l	1
n_dmabit	rs.w	1
n_noteoff	rs.w	1
n_toneportspeed rs.w	1
n_wantedperiod	rs.w	1
n_pattpos	rs.w	1
n_funk		rs.w	1
n_wavestart	rs.l	1
n_reallength	rs.w	1
n_intbit	rs.w	1
n_audreg	rs.w	1
n_sfxlen	rs.w	1
n_sfxptr	rs.l	1
n_sfxper	rs.w	1
n_sfxvol	rs.w	1
n_looped	rs.b	1
n_minusft	rs.b	1
n_vibratoamp	rs.b	1
n_vibratospd	rs.b	1
n_vibratopos	rs.b	1
n_vibratoctrl	rs.b	1
n_tremoloamp	rs.b	1
n_tremolospd	rs.b	1
n_tremolopos	rs.b	1
n_tremoloctrl	rs.b	1
n_gliss		rs.b	1
n_sampleoffset	rs.b	1
n_loopcount	rs.b	1
n_funkoffset	rs.b	1
n_retrigcount	rs.b	1
n_sfxpri	rs.b	1
n_freecnt	rs.b	1
n_musiconly	rs.b	1
n_sizeof	rs.b	0


	ifd	SDATA
	xref	_LinkerDB		; small data base from linker
	near	a4
	code
	endc

; Blitz Basic stubs
_MTInstall
  movem.l a3-a6,-(sp) ; Save registers for Blitz 2
  ; _mt_install_cia(a6=CUSTOM, a0=AutoVecBase, d0=PALflag.b)
  lea CUSTOM,a6
  move.l #0,a0
  bra _mt_install_cia

_MTInitBank
  movem.l a3-a6,-(sp) ; Save registers for Blitz 2
  move.l	#0,a1       ; Set sample pointer to NULL
  move.b	d1,d0       ; Set starting position
  move.l	(a0),a0     ; Set module address
  bra	_MTInitBranch
_MTInit
  movem.l a3-a6,-(sp) ; Save registers for Blitz 2
  ; _mt_init(a6=CUSTOM, a0=TrackerModule, a1=Samples|NULL, d0=InitialSongPos.b)
  move.l d0,a0 ; Set module address
  move.l d1,a1 ; Set samples address
  move.l d2,d0 ; Start at position
_MTInitBranch
  lea CUSTOM,a6
  bra _mt_init

_MTPlay
  ;movem.l a3-a6,-(sp) ; Save registers for Blitz 2
  ;move.b d0,_mt_Enable ; Play / pause
  lea	mt_data+mt_Enable(pc),a0
	move.b d0,(a0)
  ;movem.l (sp)+,a3-a6	; Restore registers for Blitz
	rts

_MTEnd
  movem.l a3-a6,-(sp) ; Save registers for Blitz 2
  lea	CUSTOM,a6
  bra _mt_end

_MTMusicChannels:
	lea	mt_data+mt_MusicChannels(pc),a0
	move.b	d0,(a0)
	rts

_MTE8Trigger:
	lea	mt_data+mt_MusicChannels(pc),a0
	move.b	(a0),d0
	rts

;---------------------------------------------------------------------------
	xdef	_mt_install_cia
_mt_install_cia:
; Install a CIA-B interrupt for calling _mt_music.
; a6 = CUSTOM
; a0 = VectorBase
; d0 = PALflag.b (0 is NTSC)

	ifnd	SDATA
	move.l	a4,-(sp)
	lea	mt_data(pc),a4
	endc

	clr.b	mt_Enable(a4)

	lea	mt_Lev6Int(pc),a1
	lea	$78(a0),a0		; Level 6 interrupt vector
	move.l	a0,(a1)

	move.w	#$2000,d1
	and.w	INTENAR(a6),d1
	or.w	#$8000,d1
	move.w	d1,mt_Lev6Ena(a4)	; remember level 6 interrupt enable

	; disable level 6 EXTER interrupts, set player interrupt vector
	move.w	#$2000,INTENA(a6)
	move.l	(a0),mt_oldLev6(a4)
	lea	mt_TimerAInt(pc),a1
	move.l	a1,(a0)

	; disable CIA-B interrupts, stop and save all timers
	lea	CIAB,a0
	move.b	#$7f,CIAICR(a0)
	move.b	#$10,CIACRA(a0)
	move.b	#$10,CIACRB(a0)
	lea	mt_oldtimers(a4),a1
	move.b	CIATALO(a0),(a1)+
	move.b	CIATAHI(a0),(a1)+
	move.b	CIATBLO(a0),(a1)+
	move.b	CIATBHI(a0),(a1)

	; determine if 02 clock for timers is based on PAL or NTSC
	tst.b	d0
	bne	.1
	move.l	#1789773,d0		; NTSC
	bra	.2
.1:	move.l	#1773447,d0		; PAL
.2:	move.l	d0,mt_timerval(a4)

	; load TimerA in continuous mode for the default tempo of 125
	divu	#125,d0
	move.b	d0,CIATALO(a0)
	lsr.w	#8,d0
	move.b	d0,CIATAHI(a0)
	move.b	#$11,CIACRA(a0)		; load timer, start continuous

	; load TimerB with 496 ticks for setting DMA and repeat
	move.b	#496&255,CIATBLO(a0)
	move.b	#496>>8,CIATBHI(a0)

	; TimerA and TimerB interrupt enable
	move.b	#$83,CIAICR(a0)

	; enable level 6 interrupts
	move.w	#$a000,INTENA(a6)

	bra	mt_reset

mt_Lev6Int:
	dc.l	0


;---------------------------------------------------------------------------
	xdef	_mt_remove_cia
_mt_remove_cia:
; Remove CIA-B music interrupt and restore the old vector.
; a6 = CUSTOM

  movem.l a3-a6,-(sp) ; Save registers for Blitz 2
  lea CUSTOM,a6

	ifnd	SDATA
	move.l	a4,-(sp)
	lea	mt_data(pc),a4
	endc

	; disable level 6 and CIA-B interrupts
	lea	CIAB,a0
	move.b	#$7f,CIAICR(a0)
	move.w	#$2000,INTENA(a6)

	; restore old timer values
	lea	mt_oldtimers(a4),a1
	move.b	(a1)+,CIATALO(a0)
	move.b	(a1)+,CIATAHI(a0)
	move.b	(a1)+,CIATBLO(a0)
	move.b	(a1),CIATBHI(a0)
	move.b	#$10,CIACRA(a0)
	move.b	#$10,CIACRB(a0)

	; restore original level 6 interrupt vector
	move.l	mt_Lev6Int(pc),a1
	move.l	mt_oldLev6(a4),(a1)

	; reenable CIA-B ALRM interrupt, which was set by AmigaOS
	move.b	#$84,CIAICR(a0)

	; reenable previous level 6 interrupt
	move.w	mt_Lev6Ena(a4),INTENA(a6)

	ifnd	SDATA
	move.l	(sp)+,a4
	endc

  movem.l (sp)+,a3-a6	; Restore registers for Blitz
	rts


;---------------------------------------------------------------------------
mt_TimerAInt:
; TimerA interrupt calls _mt_music at a selectable tempo (Fxx command),
; which defaults to 50 times per second.

	movem.l	d0-d7/a0-a6,-(sp)
	lea	CUSTOM,a6
	ifd	SDATA
	lea	_LinkerDB,a4
	else
	lea	mt_data(pc),a4
	endc

	; clear EXTER interrupt flag
	move.w	#$2000,INTREQ(a6)

	; check and clear CIAB interrupt flags
	btst	#0,CIAB+CIAICR
	beq	.2

	; it was a TA interrupt, do music when enabled
	tst.b	mt_Enable(a4)
	beq	.1

	bsr	_mt_music		; music with sfx inserted
	movem.l	(sp)+,d0-d7/a0-a6
	nop
	rte

.1:	bsr	mt_sfxonly		; no music, only sfx
.2:	movem.l	(sp)+,d0-d7/a0-a6
	nop
	rte


;---------------------------------------------------------------------------
mt_TimerBdmaon:
; One-shot TimerB interrupt to enable audio DMA after 496 ticks.

	; clear EXTER interrupt flag
	move.w	#$2000,CUSTOM+INTREQ

	; check and clear CIAB interrupt flags
	btst	#1,CIAB+CIAICR
	beq	.1

	; it was a TB interrupt, restart timer to set repeat, enable DMA
	move.b	#$19,CIAB+CIACRB
	move.w	mt_dmaon(pc),CUSTOM+DMACON

	; set level 6 interrupt to mt_TimerBsetrep
	move.l	a0,-(sp)
	pea	mt_TimerBsetrep(pc)
	move.l	mt_Lev6Int(pc),a0
	move.l	(sp)+,(a0)
	move.l	(sp)+,a0
.1:	nop
	rte

mt_dmaon:
	dc.w	$8000


;---------------------------------------------------------------------------
mt_TimerBsetrep:
; One-shot TimerB interrupt to set repeat samples after another 496 ticks.

	move.l	a6,-(sp)
	lea	CUSTOM+INTREQ,a6

	; check and clear CIAB interrupt flags
	btst	#1,CIAB+CIAICR
	beq	.1

	; clear EXTER and possible audio interrupt flags
	move.l	a4,-(sp)
	move.l	d0,a4
	moveq	#$2000>>7,d0		; EXTER-flag
	or.b	mt_dmaon+1(pc),d0
	lsl.w	#7,d0
	move.w	d0,(a6)
	move.l	a4,d0

	; it was a TB interrupt, set repeat sample pointers and lengths
	ifd	SDATA
	lea	_LinkerDB,a4
	else
	lea	mt_data(pc),a4
	endc
	move.l	mt_chan1+n_loopstart(a4),AUD0LC-INTREQ(a6)
	move.w	mt_chan1+n_replen(a4),AUD0LEN-INTREQ(a6)
	move.l	mt_chan2+n_loopstart(a4),AUD1LC-INTREQ(a6)
	move.w	mt_chan2+n_replen(a4),AUD1LEN-INTREQ(a6)
	move.l	mt_chan3+n_loopstart(a4),AUD2LC-INTREQ(a6)
	move.w	mt_chan3+n_replen(a4),AUD2LEN-INTREQ(a6)
	move.l	mt_chan4+n_loopstart(a4),AUD3LC-INTREQ(a6)
	move.w	mt_chan4+n_replen(a4),AUD3LEN-INTREQ(a6)

	; restore TimerA music interrupt vector
	move.l	mt_Lev6Int(pc),a4
	lea	mt_TimerAInt(pc),a6
	move.l	a6,(a4)

	move.l	(sp)+,a4
	move.l	(sp)+,a6
	nop
	rte

	; just clear EXTER interrupt flag and return
.1:	move.w	#$2000,(a6)
	move.w	#$2000,(a6)

	move.l	(sp)+,a6
	nop
	rte


;---------------------------------------------------------------------------
	xdef	_mt_init
_mt_init:
; Initialize new module.
; Reset speed to 6, tempo to 125 and start at given song position.
; Master volume is at 64 (maximum).
; a6 = CUSTOM
; a0 = module pointer
; a1 = sample pointer (NULL means samples are stored within the module)
; d0 = initial song position

	ifnd	SDATA
	move.l	a4,-(sp)
	lea	mt_data(pc),a4
	endc

	move.l	a0,mt_mod(a4)
	movem.l	d2/a2,-(sp)

	; set initial song position
	cmp.b	950(a0),d0
	blo	.1
	moveq	#0,d0
.1:	move.b	d0,mt_SongPos(a4)

	move.l	a1,d0		; sample data location is given?
	bne	.4

	; get number of highest pattern
	lea	952(a0),a1	; song arrangement list
	moveq	#127,d0
	moveq	#0,d2
.2:	move.b	(a1)+,d1
	cmp.b	d2,d1
	bls	.3
	move.b	d1,d2
.3:	dbf	d0,.2
	addq.b	#1,d2		; number of patterns

	; now we can calculate the base address of the sample data
	moveq	#10,d0
	asl.l	d0,d2
	lea	(a0,d2.l),a1
	add.w	#1084,a1

	; save start address of each sample and do some fixes for broken mods
.4:	lea	mt_SampleStarts(a4),a2
	moveq	#1,d2
	moveq	#31-1,d0
.5:	move.l	a1,(a2)+
	moveq	#0,d1
	move.w	42(a0),d1
	cmp.w	d2,d1		; length 0 and 1 define unused samples
	bls	.6
	add.l	d1,d1
	add.l	d1,a1
	bra	.7
.6:	clr.w	42(a0)		; length 1 means zero -> no sample
.7:	lea	30(a0),a0
	dbf	d0,.5

	movem.l	(sp)+,d2/a2

	; reset CIA timer A to default (125)
	move.l	mt_timerval(a4),d0
	divu	#125,d0
	move.b	d0,CIAB+CIATALO
	lsr.w	#8,d0
	move.b	d0,CIAB+CIATAHI

mt_reset:
; a4 must be initialised with base register

	; reset speed and counters
	move.b	#6,mt_Speed(a4)
	clr.b	mt_Counter(a4)
	clr.w	mt_PatternPos(a4)

	; disable the filter
	or.b	#2,CIAA+CIAPRA

	; set master volume to 64
	lea	MasterVolTab64(pc),a0
	move.l	a0,mt_MasterVolTab(a4)

	; initialise channel DMA, interrupt bits and audio register base
	move.w	#$0001,mt_chan1+n_dmabit(a4)
	move.w	#$0002,mt_chan2+n_dmabit(a4)
	move.w	#$0004,mt_chan3+n_dmabit(a4)
	move.w	#$0008,mt_chan4+n_dmabit(a4)
	move.w	#$0080,mt_chan1+n_intbit(a4)
	move.w	#$0100,mt_chan2+n_intbit(a4)
	move.w	#$0200,mt_chan3+n_intbit(a4)
	move.w	#$0400,mt_chan4+n_intbit(a4)
	move.w	#AUD0LC,mt_chan1+n_audreg(a4)
	move.w	#AUD1LC,mt_chan2+n_audreg(a4)
	move.w	#AUD2LC,mt_chan3+n_audreg(a4)
	move.w	#AUD3LC,mt_chan4+n_audreg(a4)

	; make sure n_period doesn't start as 0
	move.w	#320,d0
	move.w	d0,mt_chan1+n_period(a4)
	move.w	d0,mt_chan2+n_period(a4)
	move.w	d0,mt_chan3+n_period(a4)
	move.w	d0,mt_chan4+n_period(a4)

	; disable sound effects
	clr.w	mt_chan1+n_sfxlen(a4)
	clr.w	mt_chan2+n_sfxlen(a4)
	clr.w	mt_chan3+n_sfxlen(a4)
	clr.w	mt_chan4+n_sfxlen(a4)

	clr.b	mt_SilCntValid(a4)
	clr.b	mt_E8Trigger(a4)
	clr.b	mt_SongEnd(a4)

	ifnd	SDATA
	move.l	(sp)+,a4
	endc


;---------------------------------------------------------------------------
	xdef	_mt_end
_mt_end:
; Stop playing current module.
; a6 = CUSTOM

	ifd	SDATA
	clr.b	mt_Enable(a4)
	else
	lea	mt_data+mt_Enable(pc),a0
	clr.b	(a0)
	endc

	moveq	#0,d0
	move.w	d0,AUD0VOL(a6)
	move.w	d0,AUD1VOL(a6)
	move.w	d0,AUD2VOL(a6)
	move.w	d0,AUD3VOL(a6)
	move.w	#$000f,DMACON(a6)

  movem.l (sp)+,a3-a6	; Restore registers for Blitz

	rts


;---------------------------------------------------------------------------
	xdef	_mt_soundfx

_MTSoundFXObject
	movem.l	a3-a6,-(sp) ; Save registers for Blitz 2
	lea	CUSTOM,a6
	move.w	d1,d2       ; volume
	move.w	4(a0),d1    ; period
	move.w	6(a0),d0    ; length
	move.l	(a0),a0     ; sample data
	bra	_mt_soundfx
_MTSoundFX
  ;--- Blitz 2 call stub -----
  movem.l	a3-a6,-(sp)
  lea	CUSTOM,a6
  move.l	d0,a0
  move.w	d1,d0
  move.w	d2,d1
  move.w	d3,d2
  ;---------------------------

_mt_soundfx:
; Request playing of an external sound effect on the most unused channel.
; This function is for compatibility with the old API only!
; You should call _mt_playfx instead!
; a6 = CUSTOM
; a0 = sample pointer
; d0.w = sample length in words
; d1.w = sample period
; d2.w = sample volume

	lea	-sfx_sizeof(sp),sp
	move.l	a0,sfx_ptr(sp)
	movem.w	d0-d2,sfx_len(sp)
	move.w	#$ff01,sfx_cha(sp)	; any channel, priority=1
	move.l	sp,a0
	bsr	_mt_playfx
	lea	sfx_sizeof(sp),sp

  movem.l	(sp)+,a3-a6  ; Restore registers for Blitz
	rts

_MTPlayFX
  movem.l a3-a6,-(sp) ; Save registers for Blitz 2
  lea	CUSTOM,a6
  move.l d0,a0 ; Copy structure pointer as parameter to a0
  bsr	_mt_playfx
  movem.l	(sp)+,a3-a6  ; Restore registers for Blitz
	rts

;---------------------------------------------------------------------------
	xdef	_mt_playfx
_mt_playfx:
; Request playing of a prioritized external sound effect, either on a
; fixed channel or on the most unused one.
; A negative channel specification means to use the best one.
; The priority is unsigned and should be greater than zero.
; This channel will be blocked for music until the effect has finished.
; a6 = CUSTOM
; a0 = sfx-structure pointer with the following layout:
;      0: ptr, 4: len.w, 6: period.w, 8: vol.w, 10: channel.b, 11: priority.b

	ifd	SDATA
	movem.l	d2-d7/a0-a3/a5,-(sp)
	else
	movem.l	d2-d7/a0-a5,-(sp)
	lea	mt_data(pc),a4
	endc

	moveq	#0,d0
	move.b	sfx_cha(a0),d0
	bpl	channelsfx		; use fixed channel for effect

	; Did we already calculate the n_freecnt values for all channels?
	tst.b	mt_SilCntValid(a4)
	bne	freecnt_valid

	; Look at the next 8 pattern steps to find the longest sequence
	; of silence (no new note or instrument).
	moveq	#8,d2
	move.l	#$fffff000,d3		; mask to ignore effects

	; remember which channels are not available for sound effects
	move.b	mt_chan1+n_musiconly(a4),d4
	move.b	mt_chan2+n_musiconly(a4),d5
	move.b	mt_chan3+n_musiconly(a4),d6
	move.b	mt_chan4+n_musiconly(a4),d7

	; reset freecnts for all channels
	moveq	#0,d0
	move.b	d0,mt_chan1+n_freecnt(a4)
	move.b	d0,mt_chan2+n_freecnt(a4)
	move.b	d0,mt_chan3+n_freecnt(a4)
	move.b	d0,mt_chan4+n_freecnt(a4)

	; get pattern pointer
	move.l	mt_mod(a4),a3		; a3 mod pointer
	lea	952(a3),a5		; a5 song arrangement list
	move.w	mt_PatternPos(a4),d1
	move.b	mt_SongPos(a4),d0
.1:	move.b	(a5,d0.w),d0
	swap	d0
	lea	1084(a3),a1
	lsr.l	#6,d0
	add.l	d0,a1
	lea	1024(a1),a2		; a2 end of pattern
	add.w	d1,a1			; a1 current pattern pos

.2:	moveq	#4,d0

	move.l	(a1)+,d1
	tst.b	d4
	bne	.3
	addq.b	#1,mt_chan1+n_freecnt(a4)
	and.l	d3,d1
	sne	d4
.3:	add.b	d4,d0

	move.l	(a1)+,d1
	tst.b	d5
	bne	.4
	addq.b	#1,mt_chan2+n_freecnt(a4)
	and.l	d3,d1
	sne	d5
.4:	add.b	d5,d0

	move.l	(a1)+,d1
	tst.b	d6
	bne	.5
	addq.b	#1,mt_chan3+n_freecnt(a4)
	and.l	d3,d1
	sne	d6
.5:	add.b	d6,d0

	move.l	(a1)+,d1
	tst.b	d7
	bne	.6
	addq.b	#1,mt_chan4+n_freecnt(a4)
	and.l	d3,d1
	sne	d7
.6:	add.b	d7,d0

	; break the loop when no channel has any more free pattern steps
	beq	.7

	; otherwise break after 8 pattern steps
	subq.w	#1,d2
	beq	.7

	; End of pattern reached? Then load next pattern pointer.
	cmp.l	a2,a1
	blo	.2
	moveq	#0,d1
	moveq	#1,d0
	add.b	mt_SongPos(a4),d0
	and.w	#$007f,d0
	cmp.b	950(a3),d0		; end of song reached?
	blo	.1
	moveq	#0,d0
	bra	.1

.7:	st	mt_SilCntValid(a4)

freecnt_valid:
	move.w	#$4000,INTENA(a6)

	sub.l	a2,a2
	move.b	sfx_pri(a0),d2

	; Determine which channels are already allocated for sound
	; effects and check if the limit was reached. In this case only
	; replace sound effect channels by higher priority.
	moveq	#3,d0
	sub.b	mt_MusicChannels(a4),d0
	move.b	mt_chan1+n_sfxpri(a4),d4
	sne	d1
	add.b	d1,d0
	move.b	mt_chan2+n_sfxpri(a4),d5
	sne	d1
	add.b	d1,d0
	move.b	mt_chan3+n_sfxpri(a4),d6
	sne	d1
	add.b	d1,d0
	move.b	mt_chan4+n_sfxpri(a4),d7
	sne	d1
	add.b	d1,d0
	bmi	.overwrite

	; We will prefer a music channel which had an audio interrupt,
	; because that means the last instrument sample has been played
	; completely, and the channel is now in an idle loop.
	; Also exclude channels which have set a repeat loop.
	; Try not to break them!
	moveq	#0,d3
	tst.b	mt_chan1+n_looped(a4)
	bne	.1
	or.w	#$0080,d3
.1:	tst.b	mt_chan2+n_looped(a4)
	bne	.2
	or.w	#$0100,d3
.2:	tst.b	mt_chan3+n_looped(a4)
	bne	.3
	or.w	#$0200,d3
.3:	tst.b	mt_chan4+n_looped(a4)
	bne	.4
	or.w	#$0400,d3
.4:	move.w	INTREQR(a6),d1
	and.w	d3,d1
	bne	.6

	; All channels are busy. Then break the non-looped ones first...
	move.w	d3,d1
	bne	.6

	; ..except there are none. Then it doesn't matter. :|
	move.w	#$0780,d1

	; first look for the best unused channel
.6:	moveq	#0,d3
	btst	#7,d1
	seq	d0
	or.b	d4,d0
	bne	.7
	lea	mt_chan1+n_freecnt(a4),a1
	cmp.b	(a1),d3
	bhi	.7
	move.l	a1,a2
	move.b	(a1),d3
.7:	btst	#8,d1
	seq	d0
	or.b	d5,d0
	bne	.8
	lea	mt_chan2+n_freecnt(a4),a1
	cmp.b	(a1),d3
	bhi	.8
	move.l	a1,a2
	move.b	(a1),d3
.8:	btst	#9,d1
	seq	d0
	or.b	d6,d0
	bne	.9
	lea	mt_chan3+n_freecnt(a4),a1
	cmp.b	(a1),d3
	bhi	.9
	move.l	a1,a2
	move.b	(a1),d3
.9:	btst	#10,d1
	seq	d0
	or.b	d7,d0
	bne	.10
	lea	mt_chan4+n_freecnt(a4),a1
	cmp.b	(a1),d3
	bhi	.10
	move.l	a1,a2
	bra	found_sfx_ch

.10:	move.l	a2,d3
	bne	found_sfx_ch

.overwrite:
	; finally try to overwrite a sound effect with lower/equal priority
	moveq	#0,d3
	tst.b	d4
	beq	.11
	cmp.b	d4,d2
	blo	.11
	lea	mt_chan1+n_freecnt(a4),a1
	cmp.b	(a1),d3
	bhi	.11
	move.l	a1,a2
	move.b	(a1),d3
.11:	tst.b	d5
	beq	.12
	cmp.b	d5,d2
	blo	.12
	lea	mt_chan2+n_freecnt(a4),a1
	cmp.b	(a1),d3
	bhi	.12
	move.l	a1,a2
	move.b	(a1),d3
.12:	tst.b	d6
	beq	.13
	cmp.b	d6,d2
	blo	.13
	lea	mt_chan3+n_freecnt(a4),a1
	cmp.b	(a1),d3
	bhi	.13
	move.l	a1,a2
	move.b	(a1),d3
.13:	tst.b	d7
	beq	.14
	cmp.b	d7,d2
	blo	.14
	lea	mt_chan4+n_freecnt(a4),a1
	cmp.b	(a1),d3
	bhi	.14
	move.l	a1,a2

.14:	move.l	a2,d3
	beq	exit_playfx		; ignore new sfx due to low priority

found_sfx_ch:
	lea	-n_freecnt(a2),a2
	bra	set_sfx

channel_offsets:
	dc.w	0*n_sizeof,1*n_sizeof,2*n_sizeof,3*n_sizeof

channelsfx:
; a0 = sfx structure
; d0 = fixed channel for new sound effect
	add.w	d0,d0
	lea	mt_chan1(a4),a2
	add.w	channel_offsets(pc,d0.w),a2

	; priority high enough to replace a present effect on this channel?
	move.w	#$4000,INTENA(a6)
	move.b	sfx_pri(a0),d2
	cmp.b	n_sfxpri(a2),d2
	blo	exit_playfx

set_sfx:
; activate the sound effect on this channel
; a0 = sfx structure
; d2 = sfx priority
; a2 = channel status
	move.l	(a0)+,n_sfxptr(a2)	; sfx_ptr
	move.w	(a0)+,n_sfxlen(a2)	; sfx_len
	move.w	(a0)+,n_sfxper(a2)	; sfx_per
	move.w	(a0),n_sfxvol(a2)	; sfx_vol
	move.b	d2,n_sfxpri(a2)

exit_playfx:
	move.w	#$c000,INTENA(a6)

	ifd	SDATA
	movem.l	(sp)+,d2-d7/a0-a3/a5
	else
	movem.l	(sp)+,d2-d7/a0-a5
	endc
	rts


;---------------------------------------------------------------------------
	xdef	_mt_musicmask
_mt_musicmask:
; Set bits in the mask define which specific channels are reserved
; for music only.
; a6 = CUSTOM
; d0.b = channel-mask (bit 0 for channel 0, ..., bit 3 for channel 3)

  move.l	a6,-(sp)   ; Save A6 for Blitz
  lea	CUSTOM,a6  ; Prepare A6 for player

	ifnd	SDATA
	move.l	a4,-(sp)
	lea	mt_data(pc),a4
	endc

	move.w	#$4000,INTENA(a6)

	lsl.b	#5,d0
	scs	mt_chan4+n_musiconly(a4)
	add.b	d0,d0
	scs	mt_chan3+n_musiconly(a4)
	add.b	d0,d0
	scs	mt_chan2+n_musiconly(a4)
	add.b	d0,d0
	scs	mt_chan1+n_musiconly(a4)

	move.w	#$c000,INTENA(a6)

	ifnd	SDATA
	move.l	(sp)+,a4
	endc

  move.l	(sp)+,a6  ; Restore A6 for Blitz
	rts


;---------------------------------------------------------------------------
	xdef	_mt_mastervol
_mt_mastervol:
; Set a master volume from 0 to 64 for all music channels.
; Note that the master volume does not affect the volume of external
; sound effects (which is desired).
; a6 = CUSTOM
; d0.w = master volume

  move.l	a6,-(sp) ; Save A6 for Blitz
  lea	CUSTOM,a6   ; Prepare A6 for player

	; stingray, since each volume table has a size of 65 bytes
	; we simply multiply (optimised of course) by 65 to get the
	; offset to the correct table
	lea	MasterVolTab0(pc),a0
	add.w	d0,a0
	lsl.w	#6,d0
	add.w	d0,a0

	move.w	#$4000,INTENA(a6)
	ifd	SDATA
	move.l	a0,mt_MasterVolTab(a4)
	else
	lea	mt_data+mt_MasterVolTab(pc),a1
	move.l	a0,(a1)
	endc
	move.w	#$c000,INTENA(a6)

  move.l	(sp)+,a6  ; Restore A6 for Blitz

	rts


;---------------------------------------------------------------------------
	xdef	_mt_music
_mt_music:
; Called from interrupt.
; Play next position when Counter equals Speed.
; Effects are always handled.
; a6 = CUSTOM

	moveq	#0,d7			; d7 is always zero

	lea	mt_dmaon+1(pc),a0
	move.b	d7,(a0)

	addq.b	#1,mt_Counter(a4)

	move.b	mt_Counter(a4),d0
	cmp.b	mt_Speed(a4),d0
	blo	no_new_note

	; handle a new note
	move.b	d7,mt_Counter(a4)
	tst.b	mt_PattDelTime2(a4)
	beq	get_new_note

	; we have a pattern delay, check effects then step
	lea	AUD0LC(a6),a5
	lea	mt_chan1(a4),a2
	bsr	mt_checkfx
	lea	AUD1LC(a6),a5
	lea	mt_chan2(a4),a2
	bsr	mt_checkfx
	lea	AUD2LC(a6),a5
	lea	mt_chan3(a4),a2
	bsr	mt_checkfx
	lea	AUD3LC(a6),a5
	lea	mt_chan4(a4),a2
	bsr	mt_checkfx
	bra	settb_step

no_new_note:
	; no new note, just check effects, don't step to next position
	lea	AUD0LC(a6),a5
	lea	mt_chan1(a4),a2
	bsr	mt_checkfx
	lea	AUD1LC(a6),a5
	lea	mt_chan2(a4),a2
	bsr	mt_checkfx
	lea	AUD2LC(a6),a5
	lea	mt_chan3(a4),a2
	bsr	mt_checkfx
	lea	AUD3LC(a6),a5
	lea	mt_chan4(a4),a2
	bsr	mt_checkfx

	; set one-shot TimerB interrupt for enabling DMA, when needed
	move.b	mt_dmaon+1(pc),d0
	beq	same_pattern

	move.l	mt_Lev6Int(pc),a0
	lea	mt_TimerBdmaon(pc),a1
	move.l	a1,(a0)
	move.b	#$19,CIAB+CIACRB	; load/start timer B, one-shot
	bra	same_pattern

get_new_note:
	; determine pointer to current pattern line
	move.l	mt_mod(a4),a0
	lea	12(a0),a3		; sample info table
	lea	1084(a0),a1		; pattern data
	lea	952(a0),a0
	moveq	#0,d0
	move.b	mt_SongPos(a4),d0
	move.b	(a0,d0.w),d0		; current pattern number
	swap	d0
	lsr.l	#6,d0
	add.l	d0,a1			; pattern base
	add.w	mt_PatternPos(a4),a1	; a1 pattern line

	; play new note for each channel, apply some effects
	lea	AUD0LC(a6),a5
	lea	mt_chan1(a4),a2
	bsr	mt_playvoice
	lea	AUD1LC(a6),a5
	lea	mt_chan2(a4),a2
	bsr	mt_playvoice
	lea	AUD2LC(a6),a5
	lea	mt_chan3(a4),a2
	bsr	mt_playvoice
	lea	AUD3LC(a6),a5
	lea	mt_chan4(a4),a2
	bsr	mt_playvoice

settb_step:
	; set one-shot TimerB interrupt for enabling DMA, when needed
	move.b	mt_dmaon+1(pc),d0
	beq	pattern_step

	move.l	mt_Lev6Int(pc),a0
	lea	mt_TimerBdmaon(pc),a1
	move.l	a1,(a0)
	move.b	#$19,CIAB+CIACRB	; load/start timer B, one-shot

pattern_step:
	; next pattern line, handle delay and break
	clr.b	mt_SilCntValid(a4)	; recalculate silence counters
	moveq	#16,d2			; offset to next pattern line

	move.b	mt_PattDelTime2(a4),d1
	move.b	mt_PattDelTime(a4),d0
	beq	.1
	move.b	d0,d1
	move.b	d7,mt_PattDelTime(a4)
.1:	tst.b	d1
	beq	.3
	subq.b	#1,d1
	beq	.2
	moveq	#0,d2			; do not advance to next line
.2:	move.b	d1,mt_PattDelTime2(a4)

.3:	add.w	mt_PatternPos(a4),d2	; d2 PatternPos

	; check for break
	bclr	#0,mt_PBreakFlag(a4)
	beq	.4
	move.w	mt_PBreakPos(a4),d2
	move.w	d7,mt_PBreakPos(a4)

	; check whether end of pattern is reached
.4:	move.w	d2,mt_PatternPos(a4)
	cmp.w	#1024,d2
	blo	same_pattern

song_step:
	move.w	mt_PBreakPos(a4),mt_PatternPos(a4)
	move.w	d7,mt_PBreakPos(a4)
	move.b	d7,mt_PosJumpFlag(a4)

	; next position in song
	moveq	#1,d0
	add.b	mt_SongPos(a4),d0
	and.w	#$007f,d0
	move.l	mt_mod(a4),a0
	cmp.b	950(a0),d0		; end of song reached?
	blo	.1
	moveq	#0,d0			; restart the song from the beginning
	addq.b	#1,mt_SongEnd(a4)
	bne	.2
	clr.b	mt_Enable(a4)		; stop the song when mt_SongEnd was -1
.2:	and.b	#$7f,mt_SongEnd(a4)
.1:	move.b	d0,mt_SongPos(a4)

same_pattern:
	tst.b	mt_PosJumpFlag(a4)
	bne	song_step

	rts


;---------------------------------------------------------------------------
mt_sfxonly:
; Called from interrupt.
; Plays sound effects on free channels.
; a6 = CUSTOM

	moveq	#0,d7			; d7 is always zero

	lea	mt_dmaon+1(pc),a0
	move.b	d7,(a0)

	lea	AUD0LC(a6),a5
	lea	mt_chan1(a4),a2
	bsr	chan_sfx_only
	lea	AUD1LC(a6),a5
	lea	mt_chan2(a4),a2
	bsr	chan_sfx_only
	lea	AUD2LC(a6),a5
	lea	mt_chan3(a4),a2
	bsr	chan_sfx_only
	lea	AUD3LC(a6),a5
	lea	mt_chan4(a4),a2
	bsr	chan_sfx_only

	move.b	mt_dmaon+1(pc),d0
	beq	.1

	move.l	mt_Lev6Int(pc),a0
	lea	mt_TimerBdmaon(pc),a1
	move.l	a1,(a0)
	move.b	#$19,CIAB+CIACRB	; load/start timer B, one-shot

.1:	rts


chan_sfx_only:
; Check for new sound samples. Check if previous ones are finished.
; a2 = channel data
; a5 = audio registers

	tst.b	n_sfxpri(a2)
	beq	.1

	move.w	n_sfxlen(a2),d0
	bne	start_sfx

	move.w	n_intbit(a2),d0
	and.w	INTREQR(a6),d0
	beq	.1
	move.w	n_dmabit(a2),d0
	and.w	mt_dmaon(pc),d0
	bne	.1

	; last sound effect sample has played, so unblock this channel again
	move.b	d7,n_sfxpri(a2)

.1:	rts


;---------------------------------------------------------------------------
start_sfx:
; d0 = sfx_len in words
; a2 = channel data
; a5 = audio registers

	; play new sound effect on this channel
	move.w	n_dmabit(a2),d1
	move.w	d1,DMACON(a6)

	move.l	n_sfxptr(a2),a0
	move.l	a0,AUDLC(a5)
	move.w	d0,AUDLEN(a5)
	move.w	n_sfxper(a2),d0
	move.w	d0,AUDPER(a5)
	move.w	n_sfxvol(a2),AUDVOL(a5)

	; save repeat and period for TimerB interrupt
	move.l	a0,n_loopstart(a2)
	move.w	#1,n_replen(a2)
	move.w	d0,n_period(a2)

	move.b	d7,n_looped(a2)
	move.w	d7,n_sfxlen(a2)

	lea	mt_dmaon(pc),a0
	or.w	d1,(a0)
	rts


;---------------------------------------------------------------------------
mt_checkfx:
; a2 = channel data
; a5 = audio registers

	tst.b	n_sfxpri(a2)
	beq	.3

	move.w	n_sfxlen(a2),d0
	beq	.2
	bsr	start_sfx

	; channel is blocked, only check some E-commands
.1:	move.w	#$0fff,d4
	and.w	n_cmd(a2),d4
	move.w	d4,d0
	clr.b	d0
	cmp.w	#$0e00,d0
	bne	mt_nop
	and.w	#$00ff,d4
	bra	blocked_e_cmds

.2:	move.w	n_intbit(a2),d0
	and.w	INTREQR(a6),d0
	beq	.1
	move.w	n_dmabit(a2),d0
	and.w	mt_dmaon(pc),d0
	bne	.1

	; sound effect sample has played, so unblock this channel again
	move.b	d7,n_sfxpri(a2)

	; do channel effects between notes
.3:	move.w	n_funk(a2),d0
	beq	.4
	bsr	mt_updatefunk

.4:	move.w	#$0fff,d4
	and.w	n_cmd(a2),d4
	beq	mt_pernop
	and.w	#$00ff,d4

	moveq	#$0f,d0
	and.b	n_cmd(a2),d0
	add.w	d0,d0
	move.w	fx_tab(pc,d0.w),d0
	jmp	fx_tab(pc,d0.w)

fx_tab:
	dc.w	mt_arpeggio-fx_tab	; $0
	dc.w	mt_portaup-fx_tab
	dc.w	mt_portadown-fx_tab
	dc.w	mt_toneporta-fx_tab
	dc.w	mt_vibrato-fx_tab	; $4
	dc.w	mt_tonevolslide-fx_tab
	dc.w	mt_vibrvolslide-fx_tab
	dc.w	mt_tremolo-fx_tab
	dc.w	mt_nop-fx_tab		; $8
	dc.w	mt_nop-fx_tab
	dc.w	mt_volumeslide-fx_tab
	dc.w	mt_nop-fx_tab
	dc.w	mt_nop-fx_tab		; $C
	dc.w	mt_nop-fx_tab
	dc.w	mt_e_cmds-fx_tab
	dc.w	mt_nop-fx_tab


mt_pernop:
; just set the current period

	move.w	n_period(a2),AUDPER(a5)
mt_nop:
	rts


;---------------------------------------------------------------------------
mt_playvoice:
; a1 = pattern ptr
; a2 = channel data
; a3 = sample info table
; a5 = audio registers

	move.l	(a1)+,d6		; d6 current note/cmd words

	; channel blocked by external sound effect?
	tst.b	n_sfxpri(a2)
	beq	.2

	move.w	n_sfxlen(a2),d0
	beq	.1
	bsr	start_sfx
	bra	moreblockedfx

	; do only some limited commands, while sound effect is in progress
.1:	move.w	n_intbit(a2),d0
	and.w	INTREQR(a6),d0
	beq	moreblockedfx
	move.w	n_dmabit(a2),d0
	and.w	mt_dmaon(pc),d0
	bne	moreblockedfx

	; sound effect sample has played, so unblock this channel again
	move.b	d7,n_sfxpri(a2)

.2:	tst.l	(a2)			; n_note/cmd: any note or cmd set?
	bne	.3
	move.w	n_period(a2),AUDPER(a5)
.3:	move.l	d6,(a2)

	moveq	#15,d5
	and.b	n_cmd(a2),d5
	add.w	d5,d5			; d5 cmd*2

	moveq	#0,d4
	move.b	d6,d4			; d4 cmd argument (in MSW)
	swap	d4
	move.w	#$0ff0,d4
	and.w	d6,d4			; d4 for checking E-cmd (in LSW)

	swap	d6
	move.l	d6,d0			; S...S...
	clr.b	d0
	rol.w	#4,d0
	rol.l	#4,d0			; ....00SS

	and.w	#$0fff,d6		; d6 note

	; get sample start address
	add.w	d0,d0			; sample number * 2
	beq	set_regs
	move.w	mult30tab(pc,d0.w),d1	; d1 sample info table offset
	lea	mt_SampleStarts(a4),a0
	add.w	d0,d0
	move.l	-4(a0,d0.w),d2

	; read length, volume and repeat from sample info table
	lea	(a3,d1.w),a0
	move.w	(a0)+,d0		; length
	bne	.4

	; use the first two bytes from the first sample for empty samples
	move.l	mt_SampleStarts(a4),d2
	addq.w	#1,d0

.4:	move.l	d2,n_start(a2)
	move.w	d0,n_reallength(a2)

	; determine period table from fine-tune parameter
	moveq	#0,d3
	move.b	(a0)+,d3
	add.w	d3,d3
	move.l	a0,d1
	lea	mt_PerFineTune(pc),a0
	add.w	(a0,d3.w),a0
	move.l	a0,n_pertab(a2)
	move.l	d1,a0
	cmp.w	#2*8,d3
	shs	n_minusft(a2)

	moveq	#0,d1
	move.b	(a0)+,d1		; volume
	move.w	d1,n_volume(a2)
	move.w	(a0)+,d3		; repeat offset
	beq	no_offset

	; set repeat
	add.l	d3,d2
	add.l	d3,d2
	move.w	(a0),d0
;	beq	idle_looping		; @@@ shouldn't happen, d0=n_length!?
	move.w	d0,n_replen(a2)
	exg	d0,d3			; n_replen to d3
	add.w	d3,d0
	bra	set_len_start

mult30tab:
	dc.w	0*30,1*30,2*30,3*30,4*30,5*30,6*30,7*30
	dc.w	8*30,9*30,10*30,11*30,12*30,13*30,14*30,15*30
	dc.w	16*30,17*30,18*30,19*30,20*30,21*30,22*30,23*30
	dc.w	24*30,25*30,26*30,27*30,28*30,29*30,30*30,31*30

no_offset:
	move.w	(a0),d3
	bne	set_replen
idle_looping:
	; repeat length zero means idle-looping
	moveq	#0,d2			; FIXME: expect two zero bytes at $0
	addq.w	#1,d3
set_replen:
	move.w	d3,n_replen(a2)
set_len_start:
	move.w	d0,n_length(a2)
	move.l	d2,n_loopstart(a2)
	move.l	d2,n_wavestart(a2)

	move.l	mt_MasterVolTab(a4),a0
	move.b	(a0,d1.w),d1
	move.w	d1,AUDVOL(a5)

	; remember if sample is looped
	; @@@ FIXME: also need to check if n_loopstart equals n_start
	subq.w	#1,d3
	sne	n_looped(a2)

set_regs:
; d4 = cmd argument | masked E-cmd
; d5 = cmd*2
; d6 = cmd.w | note.w

	move.w	d4,d3			; d3 masked E-cmd
	swap	d4			; d4 cmd argument into LSW

	tst.w	d6
	beq	checkmorefx		; no new note

	cmp.w	#$0e50,d3
	beq	set_finetune

	move.w	prefx_tab(pc,d5.w),d0
	jmp	prefx_tab(pc,d0.w)

prefx_tab:
	dc.w	set_period-prefx_tab,set_period-prefx_tab,set_period-prefx_tab
	dc.w	set_toneporta-prefx_tab			; $3
	dc.w	set_period-prefx_tab
	dc.w	set_toneporta-prefx_tab			; $5
	dc.w	set_period-prefx_tab,set_period-prefx_tab,set_period-prefx_tab
	dc.w	set_sampleoffset-prefx_tab		; $9
	dc.w	set_period-prefx_tab,set_period-prefx_tab,set_period-prefx_tab
	dc.w	set_period-prefx_tab,set_period-prefx_tab,set_period-prefx_tab

set_toneporta:
	move.l	n_pertab(a2),a0		; tuned period table

	; find first period which is less or equal the note in d6
	moveq	#36-1,d0
	moveq	#-2,d1
.1:	addq.w	#2,d1
	cmp.w	(a0)+,d6
	dbhs	d0,.1

	tst.b	n_minusft(a2)		; negative fine tune?
	beq	.2
	tst.w	d1
	beq	.2
	subq.l	#2,a0			; then take previous period
	subq.w	#2,d1

.2:	move.w	d1,n_noteoff(a2)	; note offset in period table
	move.w	n_period(a2),d2
	move.w	-(a0),d1
	cmp.w	d1,d2
	bne	.3
	moveq	#0,d1
.3:	move.w	d1,n_wantedperiod(a2)

	move.w	n_funk(a2),d0
	beq	.4
	bsr	mt_updatefunk

.4:	move.w	d2,AUDPER(a5)
	rts

set_sampleoffset:
; cmd 9 x y (xy = offset in 256 bytes)
; d4 = xy
	moveq	#0,d0
	move.b	d4,d0
	bne	.1
	move.b	n_sampleoffset(a2),d0
	bra	.2
.1:	move.b	d0,n_sampleoffset(a2)

.2:	lsl.w	#7,d0
	cmp.w	n_length(a2),d0
	bhs	.3
	sub.w	d0,n_length(a2)
	add.w	d0,d0
	add.l	d0,n_start(a2)
	bra	set_period

.3:	move.w	#1,n_length(a2)
	bra	set_period

set_finetune:
	lea	mt_PerFineTune(pc),a0
	moveq	#$0f,d0
	and.b	n_cmdlo(a2),d0
	add.w	d0,d0
	add.w	(a0,d0.w),a0
	move.l	a0,n_pertab(a2)
	cmp.w	#2*8,d0
	shs	n_minusft(a2)

set_period:
; find nearest period for a note value, then apply finetuning
; d3 = masked E-cmd
; d4 = cmd argument
; d5 = cmd*2
; d6 = note.w

	lea	mt_PeriodTable(pc),a0
	moveq	#36-1,d0
	moveq	#-2,d1
.1:	addq.w	#2,d1			; table offset
	cmp.w	(a0)+,d6
	dbhs	d0,.1

	; apply finetuning, set period and note-offset
	move.l	n_pertab(a2),a0
	move.w	(a0,d1.w),d2
	move.w	d2,n_period(a2)
	move.w	d1,n_noteoff(a2)

	; check for notedelay
	cmp.w	#$0ed0,d3		; notedelay
	beq	checkmorefx

	; disable DMA
	move.w	n_dmabit(a2),d0
	move.w	d0,DMACON(a6)

	btst	#2,n_vibratoctrl(a2)
	bne	.2
	move.b	d7,n_vibratopos(a2)

.2:	btst	#2,n_tremoloctrl(a2)
	bne	.3
	move.b	d7,n_tremolopos(a2)

.3:	move.l	n_start(a2),AUDLC(a5)
	move.w	n_length(a2),AUDLEN(a5)
	move.w	d2,AUDPER(a5)
	lea	mt_dmaon(pc),a0
	or.w	d0,(a0)

checkmorefx:
; d4 = cmd argument
; d5 = cmd*2
; d6 = note.w

	move.w	n_funk(a2),d0
	beq	.1
	bsr	mt_updatefunk

.1:	move.w	morefx_tab(pc,d5.w),d0
	jmp	morefx_tab(pc,d0.w)

morefx_tab:
	dc.w	mt_pernop-morefx_tab,mt_pernop-morefx_tab,mt_pernop-morefx_tab
	dc.w	mt_pernop-morefx_tab,mt_pernop-morefx_tab,mt_pernop-morefx_tab
	dc.w	mt_pernop-morefx_tab,mt_pernop-morefx_tab,mt_pernop-morefx_tab
	dc.w	mt_pernop-morefx_tab			; $9
	dc.w	mt_pernop-morefx_tab
	dc.w	mt_posjump-morefx_tab			; $B
	dc.w	mt_volchange-morefx_tab
	dc.w	mt_patternbrk-morefx_tab		; $D
	dc.w	mt_e_cmds-morefx_tab
	dc.w	mt_setspeed-morefx_tab


moreblockedfx:
; d6 = note.w | cmd.w

	moveq	#0,d4
	move.b	d6,d4			; cmd argument
	and.w	#$0f00,d6
	lsr.w	#7,d6
	move.w	blmorefx_tab(pc,d6.w),d0
	jmp	blmorefx_tab(pc,d0.w)

blmorefx_tab:
	dc.w	mt_nop-blmorefx_tab,mt_nop-blmorefx_tab
	dc.w	mt_nop-blmorefx_tab,mt_nop-blmorefx_tab
	dc.w	mt_nop-blmorefx_tab,mt_nop-blmorefx_tab
	dc.w	mt_nop-blmorefx_tab,mt_nop-blmorefx_tab
	dc.w	mt_nop-blmorefx_tab,mt_nop-blmorefx_tab
	dc.w	mt_nop-blmorefx_tab
	dc.w	mt_posjump-blmorefx_tab			; $B
	dc.w	mt_nop-blmorefx_tab
	dc.w	mt_patternbrk-blmorefx_tab		; $D
	dc.w	blocked_e_cmds-blmorefx_tab
	dc.w	mt_setspeed-blmorefx_tab		; $F


mt_arpeggio:
; cmd 0 x y (x = first arpeggio offset, y = second arpeggio offset)
; d4 = xy

	moveq	#0,d0
	move.b	mt_Counter(a4),d0
	move.b	arptab(pc,d0.w),d0
	beq	mt_pernop		; step 0, just use normal period
	bmi	.1

	; step 1, arpeggio by left nibble
	lsr.b	#4,d4
	bra	.2

	; step 2, arpeggio by right nibble
.1:	and.w	#$000f,d4

	; offset current note
.2:	add.w	d4,d4
	add.w	n_noteoff(a2),d4
	cmp.w	#2*36,d4
	bhs	.4

	; set period with arpeggio offset from note table
	move.l	n_pertab(a2),a0
	move.w	(a0,d4.w),AUDPER(a5)
.4:	rts

arptab:
	dc.b	0,1,-1,0,1,-1,0,1,-1,0,1,-1,0,1,-1,0
	dc.b	1,-1,0,1,-1,0,1,-1,0,1,-1,0,1,-1,0,1


mt_fineportaup:
; cmd E 1 x (subtract x from period)
; d0 = x

	tst.b	mt_Counter(a4)
	beq	do_porta_up
	rts


mt_portaup:
; cmd 1 x x (subtract xx from period)
; d4 = xx

	move.w	d4,d0

do_porta_up:
	move.w	n_period(a2),d1
	sub.w	d0,d1
	cmp.w	#113,d1
	bhs	.1
	moveq	#113,d1
.1:	move.w	d1,n_period(a2)
	move.w	d1,AUDPER(a5)
	rts


mt_fineportadn:
; cmd E 2 x (add x to period)
; d0 = x

	tst.b	mt_Counter(a4)
	beq	do_porta_down
	rts


mt_portadown:
; cmd 2 x x (add xx to period)
; d4 = xx

	move.w	d4,d0

do_porta_down:
	move.w	n_period(a2),d1
	add.w	d0,d1
	cmp.w	#856,d1
	bls	.1
	move.w	#856,d1
.1:	move.w	d1,n_period(a2)
	move.w	d1,AUDPER(a5)
	rts


mt_toneporta:
; cmd 3 x y (xy = tone portamento speed)
; d4 = xy

	tst.b	d4
	beq	mt_toneporta_nc
	move.w	d4,n_toneportspeed(a2)
	move.b	d7,n_cmdlo(a2)

mt_toneporta_nc:
	move.w	n_wantedperiod(a2),d1
	beq	.6

	move.w	n_toneportspeed(a2),d0
	move.w	n_period(a2),d2
	cmp.w	d1,d2
	blo	.2

	; tone porta up
	sub.w	d0,d2
	cmp.w	d1,d2
	bgt	.3
	move.w	d1,d2
	move.w	d7,n_wantedperiod(a2)
	bra	.3

	; tone porta down
.2:	add.w	d0,d2
	cmp.w	d1,d2
	blt	.3
	move.w	d1,d2
	move.w	d7,n_wantedperiod(a2)

.3:	move.w	d2,n_period(a2)

	tst.b	n_gliss(a2)
	beq	.5

	; glissando: find nearest note for new period
	move.l	n_pertab(a2),a0
	moveq	#36-1,d0
	moveq	#-2,d1
.4:	addq.w	#2,d1
	cmp.w	(a0)+,d2
	dbhs	d0,.4

	move.w	d1,n_noteoff(a2)	; @@@ needed?
	move.w	-(a0),d2

.5:	move.w	d2,AUDPER(a5)
.6	rts


mt_vibrato:
; cmd 4 x y (x = speed, y = amplitude)
; d4 = xy

	moveq	#$0f,d2
	and.b	d4,d2
	beq	.1
	move.b	d2,n_vibratoamp(a2)
	bra	.2
.1:	move.b	n_vibratoamp(a2),d2

.2:	lsr.b	#4,d4
	beq	.3
	move.b	d4,n_vibratospd(a2)
	bra	mt_vibrato_nc
.3:	move.b	n_vibratospd(a2),d4

mt_vibrato_nc:
	; calculate vibrato table offset: 64 * amplitude + (pos & 63)
	lsl.w	#6,d2
	moveq	#63,d0
	and.b	n_vibratopos(a2),d0
	add.w	d0,d2

	; select vibrato waveform
	moveq	#3,d1
	and.b	n_vibratoctrl(a2),d1
	beq	.6
	subq.b	#1,d1
	beq	.5

	; ctrl 2 & 3 select a rectangle vibrato
	lea	mt_VibratoRectTable(pc),a0
	bra	.9

	; ctrl 1 selects a sawtooth vibrato
.5:	lea	mt_VibratoSawTable(pc),a0
	bra	.9

	; ctrl 0 selects a sine vibrato
.6:	lea	mt_VibratoSineTable(pc),a0

	; add vibrato-offset to period
.9:	move.b	(a0,d2.w),d0
	ext.w	d0
	add.w	n_period(a2),d0
	move.w	d0,AUDPER(a5)

	; increase vibratopos by speed
	add.b	d4,n_vibratopos(a2)
	rts


mt_tonevolslide:
; cmd 5 x y (x = volume-up, y = volume-down)
; d4 = xy

	pea	mt_volumeslide(pc)
	bra	mt_toneporta_nc


mt_vibrvolslide:
; cmd 6 x y (x = volume-up, y = volume-down)
; d4 = xy

	move.w	d4,d3
	move.b	n_vibratoamp(a2),d2
	move.b	n_vibratospd(a2),d4
	bsr	mt_vibrato_nc

	move.w	d3,d4
	bra	mt_volumeslide


mt_tremolo:
; cmd 7 x y (x = speed, y = amplitude)
; d4 = xy

	moveq	#$0f,d2
	and.b	d4,d2
	beq	.1
	move.b	d2,n_tremoloamp(a2)
	bra	.2
.1:	move.b	n_tremoloamp(a2),d2

.2:	lsr.b	#4,d4
	beq	.3
	move.b	d4,n_tremolospd(a2)
	bra	.4
.3:	move.b	n_tremolospd(a2),d4

	; calculate tremolo table offset: 64 * amplitude + (pos & 63)
.4:	lsl.w	#6,d2
	moveq	#63,d0
	and.b	n_tremolopos(a2),d0
	add.w	d0,d2

	; select tremolo waveform
	moveq	#3,d1
	and.b	n_tremoloctrl(a2),d1
	beq	.6
	subq.b	#1,d1
	beq	.5

	; ctrl 2 & 3 select a rectangle tremolo
	lea	mt_VibratoRectTable(pc),a0
	bra	.9

	; ctrl 1 selects a sawtooth tremolo
.5:	lea	mt_VibratoSawTable(pc),a0
	bra	.9

	; ctrl 0 selects a sine tremolo
.6:	lea	mt_VibratoSineTable(pc),a0

	; add tremolo-offset to volume
.9:	move.b	(a0,d2.w),d0
	add.w	n_volume(a2),d0
	bpl	.10
	moveq	#0,d0
.10:	cmp.w	#64,d0
	bls	.11
	moveq	#64,d0
.11:	move.w	n_period(a2),AUDPER(a5)
	move.l	mt_MasterVolTab(a4),a0
	move.b	(a0,d0.w),d0
	move.w	d0,AUDVOL(a5)

	; increase tremolopos by speed
	add.b	d4,n_tremolopos(a2)
	rts


mt_volumeslide:
; cmd A x y (x = volume-up, y = volume-down)
; d4 = xy

	move.w	n_volume(a2),d0
	moveq	#$0f,d1
	and.b	d4,d1
	lsr.b	#4,d4
	beq	vol_slide_down

	; slide up, until 64
	add.b	d4,d0
vol_slide_up:
	cmp.b	#64,d0
	bls	set_vol
	moveq	#64,d0
	bra	set_vol

	; slide down, until 0
vol_slide_down:
	sub.b	d1,d0
	bpl	set_vol
	moveq	#0,d0

set_vol:
	move.w	d0,n_volume(a2)
	move.w	n_period(a2),AUDPER(a5)
	move.l	mt_MasterVolTab(a4),a0
	move.b	(a0,d0.w),d0
	move.w	d0,AUDVOL(a5)
	rts


mt_posjump:
; cmd B x y (xy = new song position)
; d4 = xy

	move.b	d4,d0
	subq.b	#1,d0
	move.b	d0,mt_SongPos(a4)

jump_pos0:
	move.w	d7,mt_PBreakPos(a4)
	st	mt_PosJumpFlag(a4)
	rts


mt_volchange:
; cmd C x y (xy = new volume)
; d4 = xy

	cmp.w	#64,d4
	bls	.1
	moveq	#64,d4
.1:	move.w	d4,n_volume(a2)
	move.l	mt_MasterVolTab(a4),a0
	move.b	(a0,d4.w),d4
	move.w	d4,AUDVOL(a5)
	rts


mt_patternbrk:
; cmd D x y (xy = break pos in decimal)
; d4 = xy

	moveq	#$0f,d0
	and.w	d4,d0
	move.w	d4,d1
	lsr.w	#4,d1
	add.b	mult10tab(pc,d1.w),d0
	cmp.b	#63,d0
	bhi	jump_pos0

	lsl.w	#4,d0
	move.w	d0,mt_PBreakPos(a4)
	st	mt_PosJumpFlag(a4)
	rts

mult10tab:
	dc.b	0,10,20,30,40,50,60,70,80,90,0,0,0,0,0,0


mt_setspeed:
; cmd F x y (xy<$20 new speed, xy>=$20 new tempo)
; d4 = xy

	cmp.b	#$20,d4
	bhs	.1
	move.b	d4,mt_Speed(a4)
	beq	_mt_end
	rts

	; set tempo (CIA only)
.1:	and.w	#$00ff,d4
	move.l	mt_timerval(a4),d0
	divu	d4,d0
	move.b	d0,CIAB+CIATALO
	lsr.w	#8,d0
	move.b	d0,CIAB+CIATAHI
	rts


mt_e_cmds:
; cmd E x y (x=command, y=argument)
; d4 = xy

	moveq	#$0f,d0
	and.w	d4,d0			; pass E-cmd argument in d0

	move.w	d4,d1
	lsr.w	#4,d1
	add.w	d1,d1
	move.w	ecmd_tab(pc,d1.w),d1
	jmp	ecmd_tab(pc,d1.w)

ecmd_tab:
	dc.w	mt_filter-ecmd_tab
	dc.w	mt_fineportaup-ecmd_tab
	dc.w	mt_fineportadn-ecmd_tab
	dc.w	mt_glissctrl-ecmd_tab
	dc.w	mt_vibratoctrl-ecmd_tab
	dc.w	mt_finetune-ecmd_tab
	dc.w	mt_jumploop-ecmd_tab
	dc.w	mt_tremoctrl-ecmd_tab
	dc.w	mt_e8-ecmd_tab
	dc.w	mt_retrignote-ecmd_tab
	dc.w	mt_volfineup-ecmd_tab
	dc.w	mt_volfinedn-ecmd_tab
	dc.w	mt_notecut-ecmd_tab
	dc.w	mt_notedelay-ecmd_tab
	dc.w	mt_patterndelay-ecmd_tab
	dc.w	mt_funk-ecmd_tab


blocked_e_cmds:
; cmd E x y (x=command, y=argument)
; d4 = xy

	moveq	#$0f,d0
	and.w	d4,d0			; pass E-cmd argument in d0

	move.w	d4,d1
	lsr.w	#4,d1
	add.w	d1,d1
	move.w	blecmd_tab(pc,d1.w),d1
	jmp	blecmd_tab(pc,d1.w)

blecmd_tab:
	dc.w	mt_filter-blecmd_tab
	dc.w	mt_rts-blecmd_tab
	dc.w	mt_rts-blecmd_tab
	dc.w	mt_glissctrl-blecmd_tab
	dc.w	mt_vibratoctrl-blecmd_tab
	dc.w	mt_finetune-blecmd_tab
	dc.w	mt_jumploop-blecmd_tab
	dc.w	mt_tremoctrl-blecmd_tab
	dc.w	mt_e8-blecmd_tab
	dc.w	mt_rts-blecmd_tab
	dc.w	mt_rts-blecmd_tab
	dc.w	mt_rts-blecmd_tab
	dc.w	mt_rts-blecmd_tab
	dc.w	mt_rts-blecmd_tab
	dc.w	mt_patterndelay-blecmd_tab
	dc.w	mt_rts-blecmd_tab


mt_filter:
; cmd E 0 x (x=1 disable, x=0 enable)
; d0 = x

	lsr.b	#1,d0
	bcs	.1
	bclr	#2,CIAA+CIAPRA
	rts
.1:	bset	#2,CIAA+CIAPRA
mt_rts:
	rts


mt_glissctrl:
; cmd E 3 x (x gliss)
; d0 = x

	and.b	#$04,n_gliss(a2)
	or.b	d0,n_gliss(a2)
	rts


mt_vibratoctrl:
; cmd E 4 x (x = vibrato)
; d0 = x

	move.b	d0,n_vibratoctrl(a2)
	rts


mt_finetune:
; cmd E 5 x (x = finetune)
; d0 = x

	lea	mt_PerFineTune(pc),a0
	add.w	d0,d0
	add.w	(a0,d0.w),a0
	move.l	a0,n_pertab(a2)
	cmp.w	#2*8,d0
	shs	n_minusft(a2)
	rts


mt_jumploop:
; cmd E 6 x (x=0 loop start, else loop count)
; d0 = x

	tst.b	mt_Counter(a4)
	bne	.4

.1:	tst.b	d0
	beq	.3			; set start

	; otherwise we are at the end of the loop
	subq.b	#1,n_loopcount(a2)
	beq	.4			; loop finished
	bpl	.2

	; initialize loop counter
	move.b	d0,n_loopcount(a2)

	; jump back to start of loop
.2:	move.w	n_pattpos(a2),mt_PBreakPos(a4)
	st	mt_PBreakFlag(a4)
	rts

	; remember start of loop position
.3:	move.w	mt_PatternPos(a4),d0
	move.w	d0,n_pattpos(a2)
.4:	rts


mt_tremoctrl:
; cmd E 7 x (x = tremolo)
; d0 = x

	move.b	d0,n_tremoloctrl(a2)
	rts


mt_e8:
; cmd E 8 x (x = trigger value)
; d0 = x

	move.b	d0,mt_E8Trigger(a4)
	rts


mt_retrignote:
; cmd E 9 x (x = retrigger count)
; d0 = x

	tst.b	d0
	beq	.2

	; set new retrigger count when Counter=0
.1:	tst.b	mt_Counter(a4)
	bne	.3
	move.b	d0,n_retrigcount(a2)

	; avoid double retrigger, when Counter=0 and a note was set
	move.w	#$0fff,d2
	and.w	(a2),d2
	beq	do_retrigger
.2:	rts

	; check if retrigger count is reached
.3:	subq.b	#1,n_retrigcount(a2)
	bne	.2
	move.b	d0,n_retrigcount(a2)	; reset

do_retrigger:
	; DMA off, set sample pointer and length
	move.w	n_dmabit(a2),d0
	move.w	d0,DMACON(a6)
	move.l	n_start(a2),AUDLC(a5)
	move.w	n_length(a2),AUDLEN(a5)
	lea	mt_dmaon(pc),a0
	or.w	d0,(a0)
	rts


mt_volfineup:
; cmd E A x (x = volume add)
; d0 = x

	tst.b	mt_Counter(a4)
	beq	.1
	rts

.1:	add.w	n_volume(a2),d0
	bra	vol_slide_up


mt_volfinedn:
; cmd E B x (x = volume sub)
; d0 = x

	tst.b	mt_Counter(a4)
	beq	.1
	rts

.1:	move.b	d0,d1
	move.w	n_volume(a2),d0
	bra	vol_slide_down


mt_notecut:
; cmd E C x (x = counter to cut at)
; d0 = x

	cmp.b	mt_Counter(a4),d0
	bne	.1
	move.w	d7,n_volume(a2)
	move.w	d7,AUDVOL(a5)
.1:	rts


mt_notedelay:
; cmd E D x (x = counter to retrigger at)
; d0 = x

	cmp.b	mt_Counter(a4),d0
	bne	.1
	tst.w	(a2)			; trigger note when given
	bne	do_retrigger
.1:	rts


mt_patterndelay:
; cmd E E x (x = delay count)
; d0 = x

	tst.b	mt_Counter(a4)
	bne	.1
	tst.b	mt_PattDelTime2(a4)
	bne	.1
	addq.b	#1,d0
	move.b	d0,mt_PattDelTime(a4)
.1:	rts


mt_funk:
; cmd E F x (x = funk speed)
; d0 = x

	tst.b	mt_Counter(a4)
	bne	.1
	move.w	d0,n_funk(a2)
	bne	mt_updatefunk
.1:	rts

mt_updatefunk:
; d0 = funk speed

	move.b	mt_FunkTable(pc,d0.w),d0
	add.b	d0,n_funkoffset(a2)
	bpl	.2
	move.b	d7,n_funkoffset(a2)

	move.l	n_loopstart(a2),d0
	moveq	#0,d1
	move.w	n_replen(a2),d1
	add.l	d1,d1
	add.l	d0,d1
	move.l	n_wavestart(a2),a0
	addq.l	#1,a0
	cmp.l	d1,a0
	blo	.1
	move.l	d0,a0
.1:	move.l	a0,n_wavestart(a2)
	not.b	(a0)

.2:	rts


mt_FunkTable:
	dc.b	0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128

mt_VibratoSineTable:
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1
	dc.b	1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0
	dc.b	0,0,0,0,0,0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
	dc.b	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0
	dc.b	0,0,0,1,1,1,2,2,2,3,3,3,3,3,3,3
	dc.b	3,3,3,3,3,3,3,3,2,2,2,1,1,1,0,0
	dc.b	0,0,0,-1,-1,-1,-2,-2,-2,-3,-3,-3,-3,-3,-3,-3
	dc.b	-3,-3,-3,-3,-3,-3,-3,-3,-2,-2,-2,-1,-1,-1,0,0
	dc.b	0,0,1,1,2,2,3,3,4,4,4,5,5,5,5,5
	dc.b	5,5,5,5,5,5,4,4,4,3,3,2,2,1,1,0
	dc.b	0,0,-1,-1,-2,-2,-3,-3,-4,-4,-4,-5,-5,-5,-5,-5
	dc.b	-5,-5,-5,-5,-5,-5,-4,-4,-4,-3,-3,-2,-2,-1,-1,0
	dc.b	0,0,1,2,3,3,4,5,5,6,6,7,7,7,7,7
	dc.b	7,7,7,7,7,7,6,6,5,5,4,3,3,2,1,0
	dc.b	0,0,-1,-2,-3,-3,-4,-5,-5,-6,-6,-7,-7,-7,-7,-7
	dc.b	-7,-7,-7,-7,-7,-7,-6,-6,-5,-5,-4,-3,-3,-2,-1,0
	dc.b	0,0,1,2,3,4,5,6,7,7,8,8,9,9,9,9
	dc.b	9,9,9,9,9,8,8,7,7,6,5,4,3,2,1,0
	dc.b	0,0,-1,-2,-3,-4,-5,-6,-7,-7,-8,-8,-9,-9,-9,-9
	dc.b	-9,-9,-9,-9,-9,-8,-8,-7,-7,-6,-5,-4,-3,-2,-1,0
	dc.b	0,1,2,3,4,5,6,7,8,9,9,10,11,11,11,11
	dc.b	11,11,11,11,11,10,9,9,8,7,6,5,4,3,2,1
	dc.b	0,-1,-2,-3,-4,-5,-6,-7,-8,-9,-9,-10,-11,-11,-11,-11
	dc.b	-11,-11,-11,-11,-11,-10,-9,-9,-8,-7,-6,-5,-4,-3,-2,-1
	dc.b	0,1,2,4,5,6,7,8,9,10,11,12,12,13,13,13
	dc.b	13,13,13,13,12,12,11,10,9,8,7,6,5,4,2,1
	dc.b	0,-1,-2,-4,-5,-6,-7,-8,-9,-10,-11,-12,-12,-13,-13,-13
	dc.b	-13,-13,-13,-13,-12,-12,-11,-10,-9,-8,-7,-6,-5,-4,-2,-1
	dc.b	0,1,3,4,6,7,8,10,11,12,13,14,14,15,15,15
	dc.b	15,15,15,15,14,14,13,12,11,10,8,7,6,4,3,1
	dc.b	0,-1,-3,-4,-6,-7,-8,-10,-11,-12,-13,-14,-14,-15,-15,-15
	dc.b	-15,-15,-15,-15,-14,-14,-13,-12,-11,-10,-8,-7,-6,-4,-3,-1
	dc.b	0,1,3,5,6,8,9,11,12,13,14,15,16,17,17,17
	dc.b	17,17,17,17,16,15,14,13,12,11,9,8,6,5,3,1
	dc.b	0,-1,-3,-5,-6,-8,-9,-11,-12,-13,-14,-15,-16,-17,-17,-17
	dc.b	-17,-17,-17,-17,-16,-15,-14,-13,-12,-11,-9,-8,-6,-5,-3,-1
	dc.b	0,1,3,5,7,9,11,12,14,15,16,17,18,19,19,19
	dc.b	19,19,19,19,18,17,16,15,14,12,11,9,7,5,3,1
	dc.b	0,-1,-3,-5,-7,-9,-11,-12,-14,-15,-16,-17,-18,-19,-19,-19
	dc.b	-19,-19,-19,-19,-18,-17,-16,-15,-14,-12,-11,-9,-7,-5,-3,-1
	dc.b	0,2,4,6,8,10,12,13,15,16,18,19,20,20,21,21
	dc.b	21,21,21,20,20,19,18,16,15,13,12,10,8,6,4,2
	dc.b	0,-2,-4,-6,-8,-10,-12,-13,-15,-16,-18,-19,-20,-20,-21,-21
	dc.b	-21,-21,-21,-20,-20,-19,-18,-16,-15,-13,-12,-10,-8,-6,-4,-2
	dc.b	0,2,4,6,9,11,13,15,16,18,19,21,22,22,23,23
	dc.b	23,23,23,22,22,21,19,18,16,15,13,11,9,6,4,2
	dc.b	0,-2,-4,-6,-9,-11,-13,-15,-16,-18,-19,-21,-22,-22,-23,-23
	dc.b	-23,-23,-23,-22,-22,-21,-19,-18,-16,-15,-13,-11,-9,-6,-4,-2
	dc.b	0,2,4,7,9,12,14,16,18,20,21,22,23,24,25,25
	dc.b	25,25,25,24,23,22,21,20,18,16,14,12,9,7,4,2
	dc.b	0,-2,-4,-7,-9,-12,-14,-16,-18,-20,-21,-22,-23,-24,-25,-25
	dc.b	-25,-25,-25,-24,-23,-22,-21,-20,-18,-16,-14,-12,-9,-7,-4,-2
	dc.b	0,2,5,8,10,13,15,17,19,21,23,24,25,26,27,27
	dc.b	27,27,27,26,25,24,23,21,19,17,15,13,10,8,5,2
	dc.b	0,-2,-5,-8,-10,-13,-15,-17,-19,-21,-23,-24,-25,-26,-27,-27
	dc.b	-27,-27,-27,-26,-25,-24,-23,-21,-19,-17,-15,-13,-10,-8,-5,-2
	dc.b	0,2,5,8,11,14,16,18,21,23,24,26,27,28,29,29
	dc.b	29,29,29,28,27,26,24,23,21,18,16,14,11,8,5,2
	dc.b	0,-2,-5,-8,-11,-14,-16,-18,-21,-23,-24,-26,-27,-28,-29,-29
	dc.b	-29,-29,-29,-28,-27,-26,-24,-23,-21,-18,-16,-14,-11,-8,-5,-2

mt_VibratoSawTable:
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	dc.b	2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3
	dc.b	-3,-3,-3,-3,-3,-3,-3,-3,-2,-2,-2,-2,-2,-2,-2,-2
	dc.b	-1,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,1,1,1,1,1,2,2,2,2,2
	dc.b	3,3,3,3,3,3,4,4,4,4,4,5,5,5,5,5
	dc.b	-5,-5,-5,-5,-5,-5,-4,-4,-4,-4,-4,-3,-3,-3,-3,-3
	dc.b	-2,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1,0,0,0,0,0
	dc.b	0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3
	dc.b	4,4,4,4,5,5,5,5,6,6,6,6,7,7,7,7
	dc.b	-7,-7,-7,-7,-6,-6,-6,-6,-5,-5,-5,-5,-4,-4,-4,-4
	dc.b	-3,-3,-3,-3,-2,-2,-2,-2,-1,-1,-1,-1,0,0,0,0
	dc.b	0,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4
	dc.b	5,5,5,5,6,6,6,7,7,7,8,8,8,9,9,9
	dc.b	-9,-9,-9,-9,-8,-8,-8,-7,-7,-7,-6,-6,-6,-5,-5,-5
	dc.b	-4,-4,-4,-4,-3,-3,-3,-2,-2,-2,-1,-1,-1,0,0,0
	dc.b	0,0,0,1,1,1,2,2,3,3,3,4,4,4,5,5
	dc.b	6,6,6,7,7,7,8,8,9,9,9,10,10,10,11,11
	dc.b	-11,-11,-11,-10,-10,-10,-9,-9,-8,-8,-8,-7,-7,-7,-6,-6
	dc.b	-5,-5,-5,-4,-4,-4,-3,-3,-2,-2,-2,-1,-1,-1,0,0
	dc.b	0,0,0,1,1,2,2,3,3,3,4,4,5,5,6,6
	dc.b	7,7,7,8,8,9,9,10,10,10,11,11,12,12,13,13
	dc.b	-13,-13,-13,-12,-12,-11,-11,-10,-10,-10,-9,-9,-8,-8,-7,-7
	dc.b	-6,-6,-6,-5,-5,-4,-4,-3,-3,-3,-2,-2,-1,-1,0,0
	dc.b	0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7
	dc.b	8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15
	dc.b	-15,-15,-14,-14,-13,-13,-12,-12,-11,-11,-10,-10,-9,-9,-8,-8
	dc.b	-7,-7,-6,-6,-5,-5,-4,-4,-3,-3,-2,-2,-1,-1,0,0
	dc.b	0,0,1,1,2,2,3,3,4,5,5,6,6,7,7,8
	dc.b	9,9,10,10,11,11,12,12,13,14,14,15,15,16,16,17
	dc.b	-17,-17,-16,-16,-15,-15,-14,-13,-13,-12,-12,-11,-11,-10,-10,-9
	dc.b	-8,-8,-7,-7,-6,-6,-5,-4,-4,-3,-3,-2,-2,-1,-1,0
	dc.b	0,0,1,1,2,3,3,4,5,5,6,6,7,8,8,9
	dc.b	10,10,11,11,12,13,13,14,15,15,16,16,17,18,18,19
	dc.b	-19,-19,-18,-18,-17,-16,-16,-15,-14,-14,-13,-13,-12,-11,-11,-10
	dc.b	-9,-9,-8,-8,-7,-6,-6,-5,-4,-4,-3,-3,-2,-1,-1,0
	dc.b	0,0,1,2,2,3,4,4,5,6,6,7,8,8,9,10
	dc.b	11,11,12,13,13,14,15,15,16,17,17,18,19,19,20,21
	dc.b	-21,-21,-20,-19,-19,-18,-17,-17,-16,-15,-15,-14,-13,-12,-12,-11
	dc.b	-10,-10,-9,-8,-8,-7,-6,-6,-5,-4,-4,-3,-2,-1,-1,0
	dc.b	0,0,1,2,3,3,4,5,6,6,7,8,9,9,10,11
	dc.b	12,12,13,14,15,15,16,17,18,18,19,20,21,21,22,23
	dc.b	-23,-23,-22,-21,-20,-20,-19,-18,-17,-17,-16,-15,-14,-14,-13,-12
	dc.b	-11,-11,-10,-9,-8,-8,-7,-6,-5,-5,-4,-3,-2,-2,-1,0
	dc.b	0,0,1,2,3,4,4,5,6,7,8,8,9,10,11,12
	dc.b	13,13,14,15,16,17,17,18,19,20,21,21,22,23,24,25
	dc.b	-25,-25,-24,-23,-22,-21,-21,-20,-19,-18,-17,-16,-16,-15,-14,-13
	dc.b	-12,-12,-11,-10,-9,-8,-8,-7,-6,-5,-4,-3,-3,-2,-1,0
	dc.b	0,0,1,2,3,4,5,6,7,7,8,9,10,11,12,13
	dc.b	14,14,15,16,17,18,19,20,21,21,22,23,24,25,26,27
	dc.b	-27,-27,-26,-25,-24,-23,-22,-21,-20,-20,-19,-18,-17,-16,-15,-14
	dc.b	-13,-13,-12,-11,-10,-9,-8,-7,-6,-6,-5,-4,-3,-2,-1,0
	dc.b	0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14
	dc.b	15,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29
	dc.b	-29,-28,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15
	dc.b	-14,-13,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,0

mt_VibratoRectTable:
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
	dc.b	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
	dc.b	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
	dc.b	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
	dc.b	-3,-3,-3,-3,-3,-3,-3,-3,-3,-3,-3,-3,-3,-3,-3,-3
	dc.b	-3,-3,-3,-3,-3,-3,-3,-3,-3,-3,-3,-3,-3,-3,-3,-3
	dc.b	5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
	dc.b	5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
	dc.b	-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5
	dc.b	-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5
	dc.b	7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	dc.b	7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	dc.b	-7,-7,-7,-7,-7,-7,-7,-7,-7,-7,-7,-7,-7,-7,-7,-7
	dc.b	-7,-7,-7,-7,-7,-7,-7,-7,-7,-7,-7,-7,-7,-7,-7,-7
	dc.b	9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9
	dc.b	9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9
	dc.b	-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9
	dc.b	-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9,-9
	dc.b	11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11
	dc.b	11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11
	dc.b	-11,-11,-11,-11,-11,-11,-11,-11,-11,-11,-11,-11,-11,-11,-11,-11
	dc.b	-11,-11,-11,-11,-11,-11,-11,-11,-11,-11,-11,-11,-11,-11,-11,-11
	dc.b	13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13
	dc.b	13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13
	dc.b	-13,-13,-13,-13,-13,-13,-13,-13,-13,-13,-13,-13,-13,-13,-13,-13
	dc.b	-13,-13,-13,-13,-13,-13,-13,-13,-13,-13,-13,-13,-13,-13,-13,-13
	dc.b	15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	dc.b	15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	dc.b	-15,-15,-15,-15,-15,-15,-15,-15,-15,-15,-15,-15,-15,-15,-15,-15
	dc.b	-15,-15,-15,-15,-15,-15,-15,-15,-15,-15,-15,-15,-15,-15,-15,-15
	dc.b	17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17
	dc.b	17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17
	dc.b	-17,-17,-17,-17,-17,-17,-17,-17,-17,-17,-17,-17,-17,-17,-17,-17
	dc.b	-17,-17,-17,-17,-17,-17,-17,-17,-17,-17,-17,-17,-17,-17,-17,-17
	dc.b	19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19
	dc.b	19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19
	dc.b	-19,-19,-19,-19,-19,-19,-19,-19,-19,-19,-19,-19,-19,-19,-19,-19
	dc.b	-19,-19,-19,-19,-19,-19,-19,-19,-19,-19,-19,-19,-19,-19,-19,-19
	dc.b	21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21
	dc.b	21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21
	dc.b	-21,-21,-21,-21,-21,-21,-21,-21,-21,-21,-21,-21,-21,-21,-21,-21
	dc.b	-21,-21,-21,-21,-21,-21,-21,-21,-21,-21,-21,-21,-21,-21,-21,-21
	dc.b	23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23
	dc.b	23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23
	dc.b	-23,-23,-23,-23,-23,-23,-23,-23,-23,-23,-23,-23,-23,-23,-23,-23
	dc.b	-23,-23,-23,-23,-23,-23,-23,-23,-23,-23,-23,-23,-23,-23,-23,-23
	dc.b	25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25
	dc.b	25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25
	dc.b	-25,-25,-25,-25,-25,-25,-25,-25,-25,-25,-25,-25,-25,-25,-25,-25
	dc.b	-25,-25,-25,-25,-25,-25,-25,-25,-25,-25,-25,-25,-25,-25,-25,-25
	dc.b	27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27
	dc.b	27,27,27,27,27,27,27,27,27,27,27,27,27,27,27,27
	dc.b	-27,-27,-27,-27,-27,-27,-27,-27,-27,-27,-27,-27,-27,-27,-27,-27
	dc.b	-27,-27,-27,-27,-27,-27,-27,-27,-27,-27,-27,-27,-27,-27,-27,-27
	dc.b	29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29
	dc.b	29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,29
	dc.b	-29,-29,-29,-29,-29,-29,-29,-29,-29,-29,-29,-29,-29,-29,-29,-29
	dc.b	-29,-29,-29,-29,-29,-29,-29,-29,-29,-29,-29,-29,-29,-29,-29,-29


mt_PerFineTune:
	dc.w	mt_Tuning0-mt_PerFineTune,mt_Tuning1-mt_PerFineTune
	dc.w	mt_Tuning2-mt_PerFineTune,mt_Tuning3-mt_PerFineTune
	dc.w	mt_Tuning4-mt_PerFineTune,mt_Tuning5-mt_PerFineTune
	dc.w	mt_Tuning6-mt_PerFineTune,mt_Tuning7-mt_PerFineTune
	dc.w	mt_TuningM8-mt_PerFineTune,mt_TuningM7-mt_PerFineTune
	dc.w	mt_TuningM6-mt_PerFineTune,mt_TuningM5-mt_PerFineTune
	dc.w	mt_TuningM4-mt_PerFineTune,mt_TuningM3-mt_PerFineTune
	dc.w	mt_TuningM2-mt_PerFineTune,mt_TuningM1-mt_PerFineTune

mt_PeriodTable:
mt_Tuning0:	; Tuning 0, Normal c-1 - b3
	dc.w	856,808,762,720,678,640,604,570,538,508,480,453
	dc.w	428,404,381,360,339,320,302,285,269,254,240,226
	dc.w	214,202,190,180,170,160,151,143,135,127,120,113
mt_Tuning1:
	dc.w	850,802,757,715,674,637,601,567,535,505,477,450
	dc.w	425,401,379,357,337,318,300,284,268,253,239,225
	dc.w	213,201,189,179,169,159,150,142,134,126,119,113
mt_Tuning2:
	dc.w	844,796,752,709,670,632,597,563,532,502,474,447
	dc.w	422,398,376,355,335,316,298,282,266,251,237,224
	dc.w	211,199,188,177,167,158,149,141,133,125,118,112
mt_Tuning3:
	dc.w	838,791,746,704,665,628,592,559,528,498,470,444
	dc.w	419,395,373,352,332,314,296,280,264,249,235,222
	dc.w	209,198,187,176,166,157,148,140,132,125,118,111
mt_Tuning4:
	dc.w	832,785,741,699,660,623,588,555,524,495,467,441
	dc.w	416,392,370,350,330,312,294,278,262,247,233,220
	dc.w	208,196,185,175,165,156,147,139,131,124,117,110
mt_Tuning5:
	dc.w	826,779,736,694,655,619,584,551,520,491,463,437
	dc.w	413,390,368,347,328,309,292,276,260,245,232,219
	dc.w	206,195,184,174,164,155,146,138,130,123,116,109
mt_Tuning6:
	dc.w	820,774,730,689,651,614,580,547,516,487,460,434
	dc.w	410,387,365,345,325,307,290,274,258,244,230,217
	dc.w	205,193,183,172,163,154,145,137,129,122,115,109
mt_Tuning7:
	dc.w	814,768,725,684,646,610,575,543,513,484,457,431
	dc.w	407,384,363,342,323,305,288,272,256,242,228,216
	dc.w	204,192,181,171,161,152,144,136,128,121,114,108
mt_TuningM8:
	dc.w	907,856,808,762,720,678,640,604,570,538,508,480
	dc.w	453,428,404,381,360,339,320,302,285,269,254,240
	dc.w	226,214,202,190,180,170,160,151,143,135,127,120
mt_TuningM7:
	dc.w	900,850,802,757,715,675,636,601,567,535,505,477
	dc.w	450,425,401,379,357,337,318,300,284,268,253,238
	dc.w	225,212,200,189,179,169,159,150,142,134,126,119
mt_TuningM6:
	dc.w	894,844,796,752,709,670,632,597,563,532,502,474
	dc.w	447,422,398,376,355,335,316,298,282,266,251,237
	dc.w	223,211,199,188,177,167,158,149,141,133,125,118
mt_TuningM5:
	dc.w	887,838,791,746,704,665,628,592,559,528,498,470
	dc.w	444,419,395,373,352,332,314,296,280,264,249,235
	dc.w	222,209,198,187,176,166,157,148,140,132,125,118
mt_TuningM4:
	dc.w	881,832,785,741,699,660,623,588,555,524,494,467
	dc.w	441,416,392,370,350,330,312,294,278,262,247,233
	dc.w	220,208,196,185,175,165,156,147,139,131,123,117
mt_TuningM3:
	dc.w	875,826,779,736,694,655,619,584,551,520,491,463
	dc.w	437,413,390,368,347,328,309,292,276,260,245,232
	dc.w	219,206,195,184,174,164,155,146,138,130,123,116
mt_TuningM2:
	dc.w	868,820,774,730,689,651,614,580,547,516,487,460
	dc.w	434,410,387,365,345,325,307,290,274,258,244,230
	dc.w	217,205,193,183,172,163,154,145,137,129,122,115
mt_TuningM1:
	dc.w	862,814,768,725,684,646,610,575,543,513,484,457
	dc.w	431,407,384,363,342,323,305,288,272,256,242,228
	dc.w	216,203,192,181,171,161,152,144,136,128,121,114

MasterVolTab0:
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0
MasterVolTab1:
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	1
MasterVolTab2:
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b	2
MasterVolTab3:
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1
	dc.b	1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2
	dc.b	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
	dc.b	3
MasterVolTab4:
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	dc.b	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
	dc.b	3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
	dc.b	4
MasterVolTab5:
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1
	dc.b	1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2
	dc.b	2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3
	dc.b	3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4
	dc.b	5
MasterVolTab6:
	dc.b	0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1
	dc.b	1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2
	dc.b	3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4
	dc.b	4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5
	dc.b	6
MasterVolTab7:
	dc.b	0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1
	dc.b	1,1,1,2,2,2,2,2,2,2,2,2,3,3,3,3
	dc.b	3,3,3,3,3,4,4,4,4,4,4,4,4,4,5,5
	dc.b	5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6
	dc.b	7
MasterVolTab8:
	dc.b	0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1
	dc.b	2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3
	dc.b	4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5
	dc.b	6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7
	dc.b	8
MasterVolTab9:
	dc.b	0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,2
	dc.b	2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4
	dc.b	4,4,4,4,5,5,5,5,5,5,5,6,6,6,6,6
	dc.b	6,6,7,7,7,7,7,7,7,8,8,8,8,8,8,8
	dc.b	9
MasterVolTab10:
	dc.b	0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2
	dc.b	2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4
	dc.b	5,5,5,5,5,5,5,6,6,6,6,6,6,7,7,7
	dc.b	7,7,7,7,8,8,8,8,8,8,9,9,9,9,9,9
	dc.b	10
MasterVolTab11:
	dc.b	0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2
	dc.b	2,2,3,3,3,3,3,3,4,4,4,4,4,4,5,5
	dc.b	5,5,5,6,6,6,6,6,6,7,7,7,7,7,7,8
	dc.b	8,8,8,8,8,9,9,9,9,9,9,10,10,10,10,10
	dc.b	11
MasterVolTab12:
	dc.b	0,0,0,0,0,0,1,1,1,1,1,2,2,2,2,2
	dc.b	3,3,3,3,3,3,4,4,4,4,4,5,5,5,5,5
	dc.b	6,6,6,6,6,6,7,7,7,7,7,8,8,8,8,8
	dc.b	9,9,9,9,9,9,10,10,10,10,10,11,11,11,11,11
	dc.b	12
MasterVolTab13:
	dc.b	0,0,0,0,0,1,1,1,1,1,2,2,2,2,2,3
	dc.b	3,3,3,3,4,4,4,4,4,5,5,5,5,5,6,6
	dc.b	6,6,6,7,7,7,7,7,8,8,8,8,8,9,9,9
	dc.b	9,9,10,10,10,10,10,11,11,11,11,11,12,12,12,12
	dc.b	13
MasterVolTab14:
	dc.b	0,0,0,0,0,1,1,1,1,1,2,2,2,2,3,3
	dc.b	3,3,3,4,4,4,4,5,5,5,5,5,6,6,6,6
	dc.b	7,7,7,7,7,8,8,8,8,8,9,9,9,9,10,10
	dc.b	10,10,10,11,11,11,11,12,12,12,12,12,13,13,13,13
	dc.b	14
MasterVolTab15:
	dc.b	0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3
	dc.b	3,3,4,4,4,4,5,5,5,5,6,6,6,6,7,7
	dc.b	7,7,7,8,8,8,8,9,9,9,9,10,10,10,10,11
	dc.b	11,11,11,11,12,12,12,12,13,13,13,13,14,14,14,14
	dc.b	15
MasterVolTab16:
	dc.b	0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3
	dc.b	4,4,4,4,5,5,5,5,6,6,6,6,7,7,7,7
	dc.b	8,8,8,8,9,9,9,9,10,10,10,10,11,11,11,11
	dc.b	12,12,12,12,13,13,13,13,14,14,14,14,15,15,15,15
	dc.b	16
MasterVolTab17:
	dc.b	0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3
	dc.b	4,4,4,5,5,5,5,6,6,6,6,7,7,7,7,8
	dc.b	8,8,9,9,9,9,10,10,10,10,11,11,11,11,12,12
	dc.b	12,13,13,13,13,14,14,14,14,15,15,15,15,16,16,16
	dc.b	17
MasterVolTab18:
	dc.b	0,0,0,0,1,1,1,1,2,2,2,3,3,3,3,4
	dc.b	4,4,5,5,5,5,6,6,6,7,7,7,7,8,8,8
	dc.b	9,9,9,9,10,10,10,10,11,11,11,12,12,12,12,13
	dc.b	13,13,14,14,14,14,15,15,15,16,16,16,16,17,17,17
	dc.b	18
MasterVolTab19:
	dc.b	0,0,0,0,1,1,1,2,2,2,2,3,3,3,4,4
	dc.b	4,5,5,5,5,6,6,6,7,7,7,8,8,8,8,9
	dc.b	9,9,10,10,10,10,11,11,11,12,12,12,13,13,13,13
	dc.b	14,14,14,15,15,15,16,16,16,16,17,17,17,18,18,18
	dc.b	19
MasterVolTab20:
	dc.b	0,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4
	dc.b	5,5,5,5,6,6,6,7,7,7,8,8,8,9,9,9
	dc.b	10,10,10,10,11,11,11,12,12,12,13,13,13,14,14,14
	dc.b	15,15,15,15,16,16,16,17,17,17,18,18,18,19,19,19
	dc.b	20
MasterVolTab21:
	dc.b	0,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4
	dc.b	5,5,5,6,6,6,7,7,7,8,8,8,9,9,9,10
	dc.b	10,10,11,11,11,12,12,12,13,13,13,14,14,14,15,15
	dc.b	15,16,16,16,17,17,17,18,18,18,19,19,19,20,20,20
	dc.b	21
MasterVolTab22:
	dc.b	0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5
	dc.b	5,5,6,6,6,7,7,7,8,8,8,9,9,9,10,10
	dc.b	11,11,11,12,12,12,13,13,13,14,14,14,15,15,15,16
	dc.b	16,16,17,17,17,18,18,18,19,19,19,20,20,20,21,21
	dc.b	22
MasterVolTab23:
	dc.b	0,0,0,1,1,1,2,2,2,3,3,3,4,4,5,5
	dc.b	5,6,6,6,7,7,7,8,8,8,9,9,10,10,10,11
	dc.b	11,11,12,12,12,13,13,14,14,14,15,15,15,16,16,16
	dc.b	17,17,17,18,18,19,19,19,20,20,20,21,21,21,22,22
	dc.b	23
MasterVolTab24:
	dc.b	0,0,0,1,1,1,2,2,3,3,3,4,4,4,5,5
	dc.b	6,6,6,7,7,7,8,8,9,9,9,10,10,10,11,11
	dc.b	12,12,12,13,13,13,14,14,15,15,15,16,16,16,17,17
	dc.b	18,18,18,19,19,19,20,20,21,21,21,22,22,22,23,23
	dc.b	24
MasterVolTab25:
	dc.b	0,0,0,1,1,1,2,2,3,3,3,4,4,5,5,5
	dc.b	6,6,7,7,7,8,8,8,9,9,10,10,10,11,11,12
	dc.b	12,12,13,13,14,14,14,15,15,16,16,16,17,17,17,18
	dc.b	18,19,19,19,20,20,21,21,21,22,22,23,23,23,24,24
	dc.b	25
MasterVolTab26:
	dc.b	0,0,0,1,1,2,2,2,3,3,4,4,4,5,5,6
	dc.b	6,6,7,7,8,8,8,9,9,10,10,10,11,11,12,12
	dc.b	13,13,13,14,14,15,15,15,16,16,17,17,17,18,18,19
	dc.b	19,19,20,20,21,21,21,22,22,23,23,23,24,24,25,25
	dc.b	26
MasterVolTab27:
	dc.b	0,0,0,1,1,2,2,2,3,3,4,4,5,5,5,6
	dc.b	6,7,7,8,8,8,9,9,10,10,10,11,11,12,12,13
	dc.b	13,13,14,14,15,15,16,16,16,17,17,18,18,18,19,19
	dc.b	20,20,21,21,21,22,22,23,23,24,24,24,25,25,26,26
	dc.b	27
MasterVolTab28:
	dc.b	0,0,0,1,1,2,2,3,3,3,4,4,5,5,6,6
	dc.b	7,7,7,8,8,9,9,10,10,10,11,11,12,12,13,13
	dc.b	14,14,14,15,15,16,16,17,17,17,18,18,19,19,20,20
	dc.b	21,21,21,22,22,23,23,24,24,24,25,25,26,26,27,27
	dc.b	28
MasterVolTab29:
	dc.b	0,0,0,1,1,2,2,3,3,4,4,4,5,5,6,6
	dc.b	7,7,8,8,9,9,9,10,10,11,11,12,12,13,13,14
	dc.b	14,14,15,15,16,16,17,17,18,18,19,19,19,20,20,21
	dc.b	21,22,22,23,23,24,24,24,25,25,26,26,27,27,28,28
	dc.b	29
MasterVolTab30:
	dc.b	0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7
	dc.b	7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14
	dc.b	15,15,15,16,16,17,17,18,18,19,19,20,20,21,21,22
	dc.b	22,22,23,23,24,24,25,25,26,26,27,27,28,28,29,29
	dc.b	30
MasterVolTab31:
	dc.b	0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7
	dc.b	7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15
	dc.b	15,15,16,16,17,17,18,18,19,19,20,20,21,21,22,22
	dc.b	23,23,24,24,25,25,26,26,27,27,28,28,29,29,30,30
	dc.b	31
MasterVolTab32:
	dc.b	0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7
	dc.b	8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15
	dc.b	16,16,17,17,18,18,19,19,20,20,21,21,22,22,23,23
	dc.b	24,24,25,25,26,26,27,27,28,28,29,29,30,30,31,31
	dc.b	32
MasterVolTab33:
	dc.b	0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7
	dc.b	8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15
	dc.b	16,17,17,18,18,19,19,20,20,21,21,22,22,23,23,24
	dc.b	24,25,25,26,26,27,27,28,28,29,29,30,30,31,31,32
	dc.b	33
MasterVolTab34:
	dc.b	0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7
	dc.b	8,9,9,10,10,11,11,12,12,13,13,14,14,15,15,16
	dc.b	17,17,18,18,19,19,20,20,21,21,22,22,23,23,24,24
	dc.b	25,26,26,27,27,28,28,29,29,30,30,31,31,32,32,33
	dc.b	34
MasterVolTab35:
	dc.b	0,0,1,1,2,2,3,3,4,4,5,6,6,7,7,8
	dc.b	8,9,9,10,10,11,12,12,13,13,14,14,15,15,16,16
	dc.b	17,18,18,19,19,20,20,21,21,22,22,23,24,24,25,25
	dc.b	26,26,27,27,28,28,29,30,30,31,31,32,32,33,33,34
	dc.b	35
MasterVolTab36:
	dc.b	0,0,1,1,2,2,3,3,4,5,5,6,6,7,7,8
	dc.b	9,9,10,10,11,11,12,12,13,14,14,15,15,16,16,17
	dc.b	18,18,19,19,20,20,21,21,22,23,23,24,24,25,25,26
	dc.b	27,27,28,28,29,29,30,30,31,32,32,33,33,34,34,35
	dc.b	36
MasterVolTab37:
	dc.b	0,0,1,1,2,2,3,4,4,5,5,6,6,7,8,8
	dc.b	9,9,10,10,11,12,12,13,13,14,15,15,16,16,17,17
	dc.b	18,19,19,20,20,21,21,22,23,23,24,24,25,26,26,27
	dc.b	27,28,28,29,30,30,31,31,32,32,33,34,34,35,35,36
	dc.b	37
MasterVolTab38:
	dc.b	0,0,1,1,2,2,3,4,4,5,5,6,7,7,8,8
	dc.b	9,10,10,11,11,12,13,13,14,14,15,16,16,17,17,18
	dc.b	19,19,20,20,21,21,22,23,23,24,24,25,26,26,27,27
	dc.b	28,29,29,30,30,31,32,32,33,33,34,35,35,36,36,37
	dc.b	38
MasterVolTab39:
	dc.b	0,0,1,1,2,3,3,4,4,5,6,6,7,7,8,9
	dc.b	9,10,10,11,12,12,13,14,14,15,15,16,17,17,18,18
	dc.b	19,20,20,21,21,22,23,23,24,24,25,26,26,27,28,28
	dc.b	29,29,30,31,31,32,32,33,34,34,35,35,36,37,37,38
	dc.b	39
MasterVolTab40:
	dc.b	0,0,1,1,2,3,3,4,5,5,6,6,7,8,8,9
	dc.b	10,10,11,11,12,13,13,14,15,15,16,16,17,18,18,19
	dc.b	20,20,21,21,22,23,23,24,25,25,26,26,27,28,28,29
	dc.b	30,30,31,31,32,33,33,34,35,35,36,36,37,38,38,39
	dc.b	40
MasterVolTab41:
	dc.b	0,0,1,1,2,3,3,4,5,5,6,7,7,8,8,9
	dc.b	10,10,11,12,12,13,14,14,15,16,16,17,17,18,19,19
	dc.b	20,21,21,22,23,23,24,24,25,26,26,27,28,28,29,30
	dc.b	30,31,32,32,33,33,34,35,35,36,37,37,38,39,39,40
	dc.b	41
MasterVolTab42:
	dc.b	0,0,1,1,2,3,3,4,5,5,6,7,7,8,9,9
	dc.b	10,11,11,12,13,13,14,15,15,16,17,17,18,19,19,20
	dc.b	21,21,22,22,23,24,24,25,26,26,27,28,28,29,30,30
	dc.b	31,32,32,33,34,34,35,36,36,37,38,38,39,40,40,41
	dc.b	42
MasterVolTab43:
	dc.b	0,0,1,2,2,3,4,4,5,6,6,7,8,8,9,10
	dc.b	10,11,12,12,13,14,14,15,16,16,17,18,18,19,20,20
	dc.b	21,22,22,23,24,24,25,26,26,27,28,28,29,30,30,31
	dc.b	32,32,33,34,34,35,36,36,37,38,38,39,40,40,41,42
	dc.b	43
MasterVolTab44:
	dc.b	0,0,1,2,2,3,4,4,5,6,6,7,8,8,9,10
	dc.b	11,11,12,13,13,14,15,15,16,17,17,18,19,19,20,21
	dc.b	22,22,23,24,24,25,26,26,27,28,28,29,30,30,31,32
	dc.b	33,33,34,35,35,36,37,37,38,39,39,40,41,41,42,43
	dc.b	44
MasterVolTab45:
	dc.b	0,0,1,2,2,3,4,4,5,6,7,7,8,9,9,10
	dc.b	11,11,12,13,14,14,15,16,16,17,18,18,19,20,21,21
	dc.b	22,23,23,24,25,26,26,27,28,28,29,30,30,31,32,33
	dc.b	33,34,35,35,36,37,37,38,39,40,40,41,42,42,43,44
	dc.b	45
MasterVolTab46:
	dc.b	0,0,1,2,2,3,4,5,5,6,7,7,8,9,10,10
	dc.b	11,12,12,13,14,15,15,16,17,17,18,19,20,20,21,22
	dc.b	23,23,24,25,25,26,27,28,28,29,30,30,31,32,33,33
	dc.b	34,35,35,36,37,38,38,39,40,40,41,42,43,43,44,45
	dc.b	46
MasterVolTab47:
	dc.b	0,0,1,2,2,3,4,5,5,6,7,8,8,9,10,11
	dc.b	11,12,13,13,14,15,16,16,17,18,19,19,20,21,22,22
	dc.b	23,24,24,25,26,27,27,28,29,30,30,31,32,33,33,34
	dc.b	35,35,36,37,38,38,39,40,41,41,42,43,44,44,45,46
	dc.b	47
MasterVolTab48:
	dc.b	0,0,1,2,3,3,4,5,6,6,7,8,9,9,10,11
	dc.b	12,12,13,14,15,15,16,17,18,18,19,20,21,21,22,23
	dc.b	24,24,25,26,27,27,28,29,30,30,31,32,33,33,34,35
	dc.b	36,36,37,38,39,39,40,41,42,42,43,44,45,45,46,47
	dc.b	48
MasterVolTab49:
	dc.b	0,0,1,2,3,3,4,5,6,6,7,8,9,9,10,11
	dc.b	12,13,13,14,15,16,16,17,18,19,19,20,21,22,22,23
	dc.b	24,25,26,26,27,28,29,29,30,31,32,32,33,34,35,35
	dc.b	36,37,38,39,39,40,41,42,42,43,44,45,45,46,47,48
	dc.b	49
MasterVolTab50:
	dc.b	0,0,1,2,3,3,4,5,6,7,7,8,9,10,10,11
	dc.b	12,13,14,14,15,16,17,17,18,19,20,21,21,22,23,24
	dc.b	25,25,26,27,28,28,29,30,31,32,32,33,34,35,35,36
	dc.b	37,38,39,39,40,41,42,42,43,44,45,46,46,47,48,49
	dc.b	50
MasterVolTab51:
	dc.b	0,0,1,2,3,3,4,5,6,7,7,8,9,10,11,11
	dc.b	12,13,14,15,15,16,17,18,19,19,20,21,22,23,23,24
	dc.b	25,26,27,27,28,29,30,31,31,32,33,34,35,35,36,37
	dc.b	38,39,39,40,41,42,43,43,44,45,46,47,47,48,49,50
	dc.b	51
MasterVolTab52:
	dc.b	0,0,1,2,3,4,4,5,6,7,8,8,9,10,11,12
	dc.b	13,13,14,15,16,17,17,18,19,20,21,21,22,23,24,25
	dc.b	26,26,27,28,29,30,30,31,32,33,34,34,35,36,37,38
	dc.b	39,39,40,41,42,43,43,44,45,46,47,47,48,49,50,51
	dc.b	52
MasterVolTab53:
	dc.b	0,0,1,2,3,4,4,5,6,7,8,9,9,10,11,12
	dc.b	13,14,14,15,16,17,18,19,19,20,21,22,23,24,24,25
	dc.b	26,27,28,28,29,30,31,32,33,33,34,35,36,37,38,38
	dc.b	39,40,41,42,43,43,44,45,46,47,48,48,49,50,51,52
	dc.b	53
MasterVolTab54:
	dc.b	0,0,1,2,3,4,5,5,6,7,8,9,10,10,11,12
	dc.b	13,14,15,16,16,17,18,19,20,21,21,22,23,24,25,26
	dc.b	27,27,28,29,30,31,32,32,33,34,35,36,37,37,38,39
	dc.b	40,41,42,43,43,44,45,46,47,48,48,49,50,51,52,53
	dc.b	54
MasterVolTab55:
	dc.b	0,0,1,2,3,4,5,6,6,7,8,9,10,11,12,12
	dc.b	13,14,15,16,17,18,18,19,20,21,22,23,24,24,25,26
	dc.b	27,28,29,30,30,31,32,33,34,35,36,36,37,38,39,40
	dc.b	41,42,42,43,44,45,46,47,48,48,49,50,51,52,53,54
	dc.b	55
MasterVolTab56:
	dc.b	0,0,1,2,3,4,5,6,7,7,8,9,10,11,12,13
	dc.b	14,14,15,16,17,18,19,20,21,21,22,23,24,25,26,27
	dc.b	28,28,29,30,31,32,33,34,35,35,36,37,38,39,40,41
	dc.b	42,42,43,44,45,46,47,48,49,49,50,51,52,53,54,55
	dc.b	56
MasterVolTab57:
	dc.b	0,0,1,2,3,4,5,6,7,8,8,9,10,11,12,13
	dc.b	14,15,16,16,17,18,19,20,21,22,23,24,24,25,26,27
	dc.b	28,29,30,31,32,32,33,34,35,36,37,38,39,40,40,41
	dc.b	42,43,44,45,46,47,48,48,49,50,51,52,53,54,55,56
	dc.b	57
MasterVolTab58:
	dc.b	0,0,1,2,3,4,5,6,7,8,9,9,10,11,12,13
	dc.b	14,15,16,17,18,19,19,20,21,22,23,24,25,26,27,28
	dc.b	29,29,30,31,32,33,34,35,36,37,38,38,39,40,41,42
	dc.b	43,44,45,46,47,48,48,49,50,51,52,53,54,55,56,57
	dc.b	58
MasterVolTab59:
	dc.b	0,0,1,2,3,4,5,6,7,8,9,10,11,11,12,13
	dc.b	14,15,16,17,18,19,20,21,22,23,23,24,25,26,27,28
	dc.b	29,30,31,32,33,34,35,35,36,37,38,39,40,41,42,43
	dc.b	44,45,46,47,47,48,49,50,51,52,53,54,55,56,57,58
	dc.b	59
MasterVolTab60:
	dc.b	0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14
	dc.b	15,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29
	dc.b	30,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44
	dc.b	45,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59
	dc.b	60
MasterVolTab61:
	dc.b	0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14
	dc.b	15,16,17,18,19,20,20,21,22,23,24,25,26,27,28,29
	dc.b	30,31,32,33,34,35,36,37,38,39,40,40,41,42,43,44
	dc.b	45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60
	dc.b	61
MasterVolTab62:
	dc.b	0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14
	dc.b	15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30
	dc.b	31,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45
	dc.b	46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61
	dc.b	62
MasterVolTab63:
	dc.b	0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14
	dc.b	15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30
	dc.b	31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46
	dc.b	47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62
	dc.b	63
MasterVolTab64:
	dc.b	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
	dc.b	16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
	dc.b	32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
	dc.b	48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63
	dc.b	64
	even



	ifd	SDATA

	section	__MERGED,bss

mt_chan1:
	ds.b	n_sizeof
mt_chan2:
	ds.b	n_sizeof
mt_chan3:
	ds.b	n_sizeof
mt_chan4:
	ds.b	n_sizeof

mt_SampleStarts:
	ds.l	31

mt_mod:
	ds.l	1
mt_oldLev6:
	ds.l	1
mt_timerval:
	ds.l	1
mt_oldtimers:
	ds.b	4
mt_MasterVolTab:
	ds.l	1
mt_Lev6Ena:
	ds.w	1
mt_PatternPos:
	ds.w	1
mt_PBreakPos:
	ds.w	1
mt_PosJumpFlag:
	ds.b	1
mt_PBreakFlag:
	ds.b	1
mt_Speed:
	ds.b	1
mt_Counter:
	ds.b	1
mt_SongPos:
	ds.b	1
mt_PattDelTime:
	ds.b	1
mt_PattDelTime2:
	ds.b	1
mt_SilCntValid:
	ds.b	1

	xdef	_mt_Enable
_mt_Enable:
mt_Enable:
	ds.b	1

	xdef	_mt_E8Trigger
_mt_E8Trigger:
mt_E8Trigger:
	ds.b	1

	xdef	_mt_MusicChannels
_mt_MusicChannels:
mt_MusicChannels:
	ds.b	1

	xdef	_mt_SongEnd
_mt_SongEnd:
mt_SongEnd:
	ds.b	1


	else	; !SDATA : single section with local base register

	rsreset
mt_chan1	rs.b	n_sizeof
mt_chan2	rs.b	n_sizeof
mt_chan3	rs.b	n_sizeof
mt_chan4	rs.b	n_sizeof
mt_SampleStarts	rs.l	31
mt_mod		rs.l	1
mt_oldLev6	rs.l	1
mt_timerval	rs.l	1
mt_oldtimers	rs.b	4
mt_MasterVolTab	rs.l	1
mt_Lev6Ena	rs.w	1
mt_PatternPos	rs.w	1
mt_PBreakPos	rs.w	1
mt_PosJumpFlag	rs.b	1
mt_PBreakFlag	rs.b	1
mt_Speed	rs.b	1
mt_Counter	rs.b	1
mt_SongPos	rs.b	1
mt_PattDelTime	rs.b	1
mt_PattDelTime2	rs.b	1
mt_SilCntValid	rs.b	1
mt_Enable	rs.b	1		; exported as _mt_Enable
mt_E8Trigger	rs.b	1		; exported as _mt_E8Trigger
mt_MusicChannels rs.b	1		; exported as _mt_MusicChannels
mt_SongEnd	rs.b	1		; exported as _mt_SongEnd

mt_data:
	ds.b	mt_Enable
	xdef	_mt_Enable
_mt_Enable:
	ds.b	1
	xdef	_mt_E8Trigger
_mt_E8Trigger:
	ds.b	1
	xdef	_mt_MusicChannels
_mt_MusicChannels:
	ds.b	1
	xdef	_mt_SongEnd
_mt_SongEnd:
	ds.b	1

	endc	; SDATA/!SDATA

	end
