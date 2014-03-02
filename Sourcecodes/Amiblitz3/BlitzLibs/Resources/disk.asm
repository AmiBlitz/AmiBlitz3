LibNum  EQU 238
NeedLib EQU LibNum
Is_Resource EQU 1

	Include "BlitzMacs.asm"
	Output "disk.resource1"

	sharedlibheader LibNum,Init,1,0,0

	slfunction NeedLib,-6,SD0
	slname "AllocUnit_","(unitNum)"

	slfunction NeedLib,-12,SD0
	slname "FreeUnit_","(unitNum)"

	slfunction NeedLib,-18,SA1
	slname "GetUnit_","(unitPointer)"

	slfunction NeedLib,-24
	slname "GiveUnit_",""

	slfunction NeedLib,-30,SD0
	slname "GetUnitID_","(unitNum)"

	slfunction NeedLib,-36,SD0
	slname "ReadUnitID_","(unitNum)"

Init:
	nullsub InitFunc,0,0

	libfin
	shared_init

name:
	dc.b	"disk.resource",0
	END