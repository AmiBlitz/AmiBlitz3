; Amiga Blitz Basic Library wrapper of PT Player by Frank Wille (PHX) in 2013, 2016-2024.
; Converted to BlitzBasic library by E-Penguin based on work by idrougge
; Wrapper concept and macros by earok

		include	"blitz.i"

; Blitz Libraries used
audiolib equ   116
banklib  equ   76

; This Blitz library
ptplayerlib equ 48

		libheader ptplayerlib,0,0,blitz_finit,0
		
		astatement
			args	word,byte
			libs	banklib,$1080
			subs	MTInit_bank,0,0
			args	long,long,byte
			libs
			subs	MTInit,0,0
		name "MTInit","Bank#, startpos | module addr, instr addr, startpos (inserts module into player)",0
		
		astatement
			args	byte
			libs
			subs	MTInstall,0,0
		name "MTInstall","Install player routine. PAL=true, NTSC=false",0
		
		astatement
			args	byte
			libs
			subs	MTPlay,0,0
		name "MTPlay","On/Off for module playback",0
		
		astatement
			args
			libs
			subs	MTRemove,0,0
		name "MTRemove","Remove player from system",0

		astatement
			args
			libs
			subs	MTEnd,0,0
		name "MTEnd","Stop playing current module",0

		astatement
			args	long,word,word,word
			libs
			subs	MTSoundFX,0,0
			args	word,word
			libs	audiolib,$1080
			subs	MTSoundFX_soundobject,0,0
		name "MTSoundFX","Sound#, volume (0..64)| sample_addr.l, length.w, period.w, volume.w"
		
		afunction long
			args	long
			libs
			subs	MTPlayFx,0,0
		name	"MTPlayFx","SfxStructurePointer, returns SfxChanStatus pointer"

		astatement
			args	word
			libs
			subs	MTMasterVolume,0,0
		name	"MTMasterVolume","Master volume (0..64) for all music channels."

		astatement
			args	byte
			libs
			subs	MTMusicMask,0,0
		name	"MTMusicMask","Set bits 0-3 to reserve channels for music only."

		astatement
			args	byte
			libs
			subs	MTMusicChannels,0,0
		name	"MTMusicChannels","number of channels dedicated to music."

		afunction	byte
			args
			libs
			subs	MTE8Trigger,0,0
		name	"MTE8Trigger","Value of the last E8 command."
		
		astatement
			args	long
			libs
			subs	MTLoopFx,0,0
		name	"MTLoopFx","SfxStructurePointer"
		
		astatement
			args	byte
			libs
			subs	MTStopFx,0,0
		name	"MTStopFx","channel to stop FX loop"
		
		astatement
			args	word,byte
			libs
			subs	MTSampleVolume,0,0
		name	"MTSampleVolume", "Redefine a sample's volume"
		
		astatement
			args	byte
			libs
			subs	MTChannelMask,0,0
		name	"MTChannelMask", "Clear bits 0-3 to mute channel for music"
		
		astatement
			args	byte
			libs
			subs	MTSetSongEnd,0,0
		name	"MTSetSongEnd","Set value of the mt_SongEnd flag to 0xFF to end after it has finished"		

		afunction byte
			args
			libs
			subs	MTIsEnabled,0,0
		name	"MTIsEnabled","Get status of playback"

blitz_finit:
		nullsub	_blitz_mt_lib_finit,0,0 ; Call deinit routine on exit

		libfin ; End of Blitz library header

; Deinitialisation for Blitz so that user doesn't have to call MTRemove
_blitz_mt_lib_finit:
	bra	_mt_remove_cia
;--------------------

; Macros by earok / Scorpion 
; https://github.com/earok/ptplayer_blitzwrapper_scorpion
storeAddressRegisters	macro
	movem.l a4-a6,-(sp) ; Save registers for Blitz 2
	lea     CUSTOM,a6 ;Store the custom register in A6
	endm
	
storeAddressRegistersVBR macro
	movem.l a4-a6,-(sp) ; Save registers for Blitz 2
	;Load vector base into A0
	sub.l   a0,a0
	move.l  4.w,a6
	btst    #0,297(a6)              ; check for 68010
	beq     .novbr
	lea     getvbr(pc),a5
	jsr     -30(a6) 		        ; Supervisor()
.novbr: lea     CUSTOM,a6
	endM

restoreAddressRegisters	macro
	movem.l (sp)+,a4-a6	; Restore registers for Blitz
	rts ;Return to Blitz
	endm
;--------------------


; VBR Hack by phx
; https://eab.abime.net/showpost.php?p=1516508&postcount=7
;----- Get VBR 68010+ ---
        mc68010
getvbr:
        movec   vbr,a0
        rte
        mc68000
;------------------------

; Install a CIA-B interrupt for calling mt_music.
MTInstall:
	storeAddressRegistersVBR	
	jsr _mt_install_cia
	restoreAddressRegisters

MTRemove:
	storeAddressRegisters	
	jsr _mt_remove_cia
	restoreAddressRegisters

;---------------------------------------------------------------------------
;_mt_init:
; Initialize new module.
; Reset speed to 6, tempo to 125 and start at given song position.
; Master volume is at 64 (maximum).
; --- Init for Blitz ----    
MTInit_bank: 
    move.l	#0,a1   ; Set sample pointer to NULL
	move.b	d1,d0   ; Set starting position
	move.l	(a0),a0 ; Set module address
	bra	MTInit_done
MTInit:
	move.l D0,A0 ; a0 = module pointer
	move.l D1,A1 ; a1 = sample pointer (NULL means samples are stored within the module)
	move.w D2,D0 ; d0 = initial song position
MTInit_done:
	storeAddressRegisters
	jsr _mt_init
	restoreAddressRegisters

MTEnd:
	storeAddressRegisters
	jsr _mt_end
	restoreAddressRegisters
    
MTPlay:
	move.b	d0,_mt_Enable
	rts	

MTIsEnabled:
	move.b	_mt_Enable,d0
	rts

MTSetSongEnd:
; Set mt_SongEnd to 0xFF to stop after current song is played
	move.b	d0,mt_SongEnd(a4)
	rts
	
;-------------------------------------
MTSoundFX_soundobject:
	move.w	d1,d2      ; volume
	move.w	4(a0),d1   ; period
	move.w	6(a0),d0   ; length
	move.l	(a0),a0    ; sample data
	bra	MTSoundFX_done
MTSoundFX:	
	move.l D0,A0 ;a0 = sample pointer
	move.w D1,D0 ;d0.w = sample length in words
	move.w D2,D1 ;d1.w = sample period
	Move.w D3,D2 ;d2.w = sample volume
MTSoundFX_done:	
	storeAddressRegisters
	jsr _mt_soundfx
	restoreAddressRegisters	

MTPlayFx:	
	storeAddressRegisters
	move.l D0,A0 ;a0=SfxStructurePointer
	jsr _mt_playfx
	restoreAddressRegisters	

MTLoopFx:	
	storeAddressRegisters
	move.l D0,A0 ;a0=SfxStructurePointer
	jsr _mt_loopfx
	restoreAddressRegisters	

MTStopFx:	
	storeAddressRegisters
	jsr _mt_stopfx
	restoreAddressRegisters	

MTMusicMask:
	storeAddressRegisters
	jsr _mt_musicmask
	restoreAddressRegisters

MTMasterVolume:
	storeAddressRegisters
	jsr _mt_mastervol
	restoreAddressRegisters

MTSampleVolume:
	storeAddressRegisters
	jsr _mt_samplevol
	restoreAddressRegisters

MTChannelMask:
	storeAddressRegisters
	jsr _mt_channelmask
	restoreAddressRegisters
    
MTMusicChannels:
	move.b	d0,_mt_MusicChannels
	rts

MTE8Trigger:    
	move.b	_mt_E8Trigger,d0
	rts

		include "ptplayer.asm"