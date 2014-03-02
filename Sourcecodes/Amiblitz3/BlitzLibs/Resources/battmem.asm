LibNum  EQU 245
NeedLib EQU LibNum
Is_Resource EQU 1

	Include "BlitzMacs.asm"
	Output "battmem.resource1"

	sharedlibheader LibNum,Init,1,0,0

	slfunction NeedLib,-6
	slname "ObtainBattSemaphore_",""

	slfunction NeedLib,-12
	slname "ReleaseBattSemaphore_",""

	slfunction NeedLib,-18,SA0,SD0,SD1
	slname "ReadBattMem_","(buffer,offset,length)"

	slfunction NeedLib,-24,SA0,SD0,SD1
	slname "WriteBattMem_","(buffer,offset,length)"

Init:
	nullsub InitFunc,0,0

	libfin
	shared_init

name:
	dc.b	"battmem.resource",0
	END