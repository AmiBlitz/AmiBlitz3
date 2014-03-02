LibNum  EQU 224
NeedLib EQU LibNum
Is_Resource EQU 1

	Include "BlitzMacs.asm"
	Output "misc.resource1"

	sharedlibheader LibNum,Init,1,0,0

	slfunction NeedLib,-6,SD0,SA1
	slname "AllocMiscResource_","(unitNum,name)"

	slfunction NeedLib,-12,SD0
	slname "FreeMiscResource_","(unitNum)"

Init:
	nullsub InitFunc,0,0

	libfin
	shared_init

name:
	dc.b	"misc.resource",0
	END