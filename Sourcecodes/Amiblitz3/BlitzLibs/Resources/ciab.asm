LibNum  EQU 241
NeedLib EQU LibNum
Is_Resource EQU 1

	Include "BlitzMacs.asm"
	Output "ciab.resource1"

	sharedlibheader LibNum,Init,1,0,0

	slfunction NeedLib,-6,SD0,SA1
	slname "AddICRVector_B","(iCRBit,interrupt)"

	slfunction NeedLib,-12,SD0,SA1
	slname "RemICRVector_B","(iCRBit,interrupt)"

	slfunction NeedLib,-18,SD0
	slname "AbleICR_B","(mask)"

	slfunction NeedLib,-24,SD0
	slname "SetICR_B","(mask)"

Init:
	nullsub InitFunc,0,0

	libfin
	shared_init
name:
	dc.b	"ciab.resource",0
	END