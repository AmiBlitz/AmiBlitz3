# blitz_ptplayer
Port of Frank Wille's Protracker player v6.4 as a Blitz Basic library

Blitz Basic function/statement entry points added by idrougge, macros by earok

Further development by E-Penguin

VBR fix by phx

compiled with vasm 2.0a, with the following options:
vasmm68k_mot.exe -devpac -Fhunkexe -kick1hunks -nosym  ptplayer.asm -o ptplayer.obj

Built wit the following configuration flags:

MINIMAL		equ	0

ENABLE_SAWRECT	equ	0

NULL_IS_CLEARED	equ	0

New for ptplayer 6.4 is "OS Compatible" mode; there is a separate build for this with the OSCOMPAT flag = 1. As a result, the MTInstall statement has changed, see below if using this version. Rename the obj to remove "_oscompat" and rebuild the blitzlibs accordingly.

Command reference:
LoadBank 0,"mod.song",2 (loads module into bank 0 in chipmem (2))

MTInstall PAL=True, NTSC=False (installs player in program) [OSCOMPAT=0, default]

success.l = MTInstall (installs player in program) [OSCOMPAT=1]

MTInit Bank#, startpos (inserts module into player)

MTInit &module_addr, &instr_addr, startpos (inserts INCBIN module into player, set instr_addr to 0 for normal modules)

MTPlay On/Off (start/stop module playback)

MTEnd (Stop playing current module)

MTSoundFX Sound#, volume (0..64)

MTSoundFX &sample_addr.l, length.w, period.w, volume.w (0..64)

MTPlayFx &SfxStructure

MTMasterVolume 0..64 (Master volume for all music channels)

MTMusicMask bitmask.b (Set bits 0-3 to reserve channels for music only.)

MTMusicChannels 0..4 (number of channels dedicated to music)

MTE8Trigger (Value of the last E8 command in case you want to trigger game events from a module)
