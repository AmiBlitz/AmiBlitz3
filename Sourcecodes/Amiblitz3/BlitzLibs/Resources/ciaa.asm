LibNum  EQU 242
NeedLib EQU LibNum
Is_Resource EQU 1

	Include "BlitzMacs.asm"
	Output "ciaa.resource1"

	sharedlibheader LibNum,Init,1,0,0

	slfunction NeedLib,-6,SD0,SA1
	slname "AddICRVector_A","(iCRBit,interrupt)"

	slfunction NeedLib,-12,SD0,SA1
	slname "RemICRVector_A","(iCRBit,interrupt)"

	slfunction NeedLib,-18,SD0
	slname "AbleICR_A","(mask)"

	slfunction NeedLib,-24,SD0
	slname "SetICR_A","(mask)"

Init:
	nullsub InitFunc,0,0

	libfin
	shared_init
name:
	dc.b	"ciaa.resource",0
	END