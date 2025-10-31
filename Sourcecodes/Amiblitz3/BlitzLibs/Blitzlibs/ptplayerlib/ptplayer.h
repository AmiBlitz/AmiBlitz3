#ifndef PTPLAYER_H
#define PTPLAYER_H

/**************************************************
 *    ----- Protracker V2.3B Playroutine -----    *
 **************************************************/

/*
  Version 6.4
  Written by Frank Wille in 2013, 2016-2024.

  Define __OSCOMPAT, when using the OS-compatible ptplayer variant.
*/

#ifndef EXEC_TYPES_H
#include <exec/types.h>
#endif

#ifndef SDI_COMPILER_H
#include <SDI_compiler.h>
#endif

#ifdef __OSCOMPAT
/*
  ok = mt_install()
    Register CIA-B interrupts with AmigaOS for calling mt_music or
    mt_sfxonly. Allocate all Paula audio channels via audio.device.
    The music module is replayed via mt_music when _mt_Enable is non-zero.
    Otherwise the interrupt handler calls mt_sfxonly to play sound
    effects only.
    Returns true (1) on success, false (0) otherwise. You must not call
    _mt_remove(), when _mt_install() failed!
*/

int ASM mt_install(void);

/*
  mt_remove()
    Unregister the CIA-B interrupts handlers and deallocate all
    audio channels.
*/

void ASM mt_remove(void);

#else
/*
  mt_install(a6=CUSTOM, a0=VectorBase, d0=PALflag.b)
    Install a CIA-B interrupt for calling mt_music or mt_sfxonly.
    The music module is replayed via mt_music when _mt_Enable is non-zero.
    Otherwise the interrupt handler calls mt_sfxonly to play sound
    effects only. VectorBase is 0 for 68000, otherwise set it to the CPU's
    VBR register. A non-zero PALflag selects PAL-clock for the CIA timers
    (NTSC otherwise).
*/

void ASM mt_install(REG(a6, void *custom),
	REG(a0, void *VectorBase), REG(d0, UBYTE PALflag));

/*
  mt_remove(a6=CUSTOM)
    Remove the CIA-B music interrupt and restore the old vector.
*/

void ASM mt_remove(REG(a6, void *custom));
#endif  /* !__OSCOMPAT */

/*
  mt_init(a6=CUSTOM, a0=TrackerModule, a1=Samples|NULL, d0=InitialSongPos.b)
    Initialize a new module.
    Reset speed to 6, tempo to 125 and start at the given position.
    Master volume is at 64 (maximum).
    When a1 is NULL the samples are assumed to be stored after the patterns.
*/

void ASM mt_init(REG(a6, void *custom),
	REG(a0, void *TrackerModule), REG(a1, void *Samples),
	REG(d0, UBYTE InitialSongPos));

/*
  mt_end(a6=CUSTOM)
    Stop playing current module.
*/

void ASM mt_end(REG(a6, void *custom));

/*
  mt_soundfx(a6=CUSTOM, a0=SamplePointer,
             d0=SampleLength.w, d1=SamplePeriod.w, d2=SampleVolume.w)
    Request playing of an external sound effect on the most unused channel.
    This function is for compatibility with the old API only!
    You should call mt_playfx() instead.
*/

void ASM mt_soundfx(REG(a6, void *custom),
	REG(a0, void *SamplePointer), REG(d0, UWORD SampleLength),
	REG(d1, UWORD SamplePeriod), REG(d2, UWORD SampleVolume));

/*
  SfxChanStatus = mt_playfx(a6=CUSTOM, a0=SfxStructurePointer)
    Request playing of a prioritized external sound effect, either on a
    fixed channel or on the most unused one.
    Structure layout of SfxStructure:
      void *sfx_ptr (pointer to sample start in Chip RAM, even address)
      WORD sfx_len  (sample length in words)
      WORD sfx_per  (hardware replay period for sample)
      WORD sfx_vol  (volume 0..64, is unaffected by the song's master volume)
      BYTE sfx_cha  (0..3 selected replay channel, -1 selects best channel)
      BYTE sfx_pri (priority, must be in the range 1..127)
    When multiple samples are assigned to the same channel the lower
    priority sample will be replaced. When priorities are the same, then
    the older sample is replaced.
    The chosen channel is blocked for music until the effect has
    completely been replayed.
    Returns pointer to SfxChanStatus when sample was scheduled for
    playing and NULL when the request was ignored.
*/

typedef struct SfxStructure
{
	void *sfx_ptr; /* pointer to sample start in Chip RAM, even address */
	UWORD sfx_len; /* sample length in words */
	UWORD sfx_per; /* hardware replay period for sample */
	UWORD sfx_vol; /* volume 0..64, is unaffected by the song's master volume */
	BYTE sfx_cha;  /* 0..3 selected replay channel, -1 selects best channel */
	BYTE sfx_pri;  /* priority, must be in the range 1..127 */
} SfxStructure;

typedef struct SfxChanStatus
{
  UWORD n_note;
  UWORD n_cmd;
  UBYTE n_index;   /* channel index 0..3 */
  UBYTE n_sfxpri;  /* sfx_pri when playing, becomes 0 when done */
  /* Rest of structure is currently not exported. Don't rely on it! */
} SfxChanStatus;

SfxChanStatus * ASM mt_playfx(REG(a6, void *custom),
	REG(a0, SfxStructure *SfxStructurePointer));

/*
  mt_loopfx(a6=CUSTOM, a0=SfxStructurePointer)
    Request playing of a looped sound effect on a fixed channel, which
    will be blocked for music until the effect is stopped (mt_stopfx()).
    It uses the same sfx-structure as mt_playfx(), but the priority is
    ignored. A looped sound effect has always highest priority and will
    replace a previous effect on the same channel. No automatic channel
    selection possible!
    Also make sure the sample starts with a zero-word, which is used
    for idling when the effect is stopped. This word is included in the
    total length calculation, but excluded when actually playing the loop.
*/

void ASM mt_loopfx(REG(a6, void *custom),
	REG(a0, SfxStructure *SfxStructurePointer));

/*
  mt_stopfx(a6=CUSTOM, d0=Channel.b)
    Immediately stop a currently playing sound effect on a channel (0..3)
    and make it available for music, or other effects, again. This is the
    only way to stop a looped sound effect (mt_loopfx()), besides stopping
    replay completely (mt_end()).
*/

void ASM mt_stopfx(REG(a6, void *custom),
	REG(d0, UBYTE ChannelNo));

/*
  mt_musicmask(a6=CUSTOM, d0=ChannelMask.b)
    Set bits in the mask define which specific channels are reserved
    for music only. Set bit 0 for channel 0, ..., bit 3 for channel 3.
    When calling mt_soundfx() or mt_playfx() with automatic channel selection
    (sfx_cha=-1) then these masked channels will never be picked.
    The mask defaults to 0.
*/

void ASM mt_musicmask(REG(a6, void *custom),
	REG(d0, UBYTE ChannelMask));

/*
  mt_mastervol(a6=CUSTOM, d0=MasterVolume.w)
    Set a master volume from 0 to 64 for all music channels.
    Note that the master volume does not affect the volume of external
    sound effects (which is desired).
*/

void ASM mt_mastervol(REG(a6, void *custom),
	REG(d0, UWORD MasterVolume));

/*
  mt_samplevol(d0=SampleNumber.w, d1=Volume.b)
    Redefine a sample's volume. May also be done while the song is playing.
    Warning: Does not check arguments for valid range! You must have done
    mt_init() before calling this function!
    The new volume is persistent. Even when the song is restarted.
*/

void ASM mt_samplevol(REG(d0, UWORD SampleNumber), REG(d1, UBYTE Volume));

/*
  mt_channelmask(a6=CUSTOM, d0=ChannelMask.b)
    Bits cleared in the mask define which specific channels are muted
    for music replay. Clear bit 0 for channel 0, ..., bit 3 for channel 3.
    Additionally a cleared bit prevents any access to the sample pointers
    of this channel.
    The mask defaults to all channels unmuted (bits set) and is reset to
    this state on mt_init() and mt_end().
*/

void ASM mt_channelmask(REG(a6, void *custom),
	REG(d0, UBYTE ChannelMask));

/*
  mt_music(a6=CUSTOM)
    The replayer routine. Can be called from your own VBlank interrupt
    handler when VBLANK_MUSIC is set. Is otherwise called automatically
    by Timer-A interrupts after mt_install().
*/

void ASM mt_music(REG(a6, void *custom));

/*
  mt_dmaon(void)
    NO_TIMERS=1 only!
    MUST be called ca. 550 ticks after calling mt_music(). Enables Audio
    DMA to play a new note.
*/

void ASM mt_dmaon(void);

/*
  mt_setrep(void)
    NO_TIMERS=1 only!
    MUST be called ca. 550 ticks after calling _mt_dmaon. Sets the
    repetition pointers and lengths for looped samples.
*/

void ASM mt_setrep(void);

/*
  mt_Enable
    Set this byte to non-zero to play music, zero to pause playing.
    Note that you can still play sound effects, while music is stopped.
    It is set to 0 by mt_install().
*/

extern UBYTE mt_Enable;

/*
  mt_E8Trigger
    This byte reflects the value of the last E8 command.
    It is reset to 0 after mt_init().
*/

extern UBYTE mt_E8Trigger;

/*
  mt_MusicChannels
    This byte defines the number of channels which should be dedicated
    for playing music. So sound effects will never use more
    than 4 - mt_MusicChannels channels at once. Defaults to 0.
*/

extern UBYTE mt_MusicChannels;

#endif
