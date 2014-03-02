LibNum  EQU 246
NeedLib EQU LibNum
Is_Resource EQU 1

	Include "BlitzMacs.asm"
	Output "battclock.resource1"

	sharedlibheader LibNum,Init,1,0,0

	slfunction NeedLib,-6
	slname "ResetBattClock_",""

	slfunction NeedLib,-12
	slname "ReadBattClock_",""

	slfunction NeedLib,-18,SD0
	slname "WriteBattClock_","(time)"

Init:
	nullsub InitFunc,0,0

	libfin
	shared_init

name:
	dc.b	"battclock.resource",0
	END