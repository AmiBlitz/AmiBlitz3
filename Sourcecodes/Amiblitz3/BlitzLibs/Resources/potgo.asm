LibNum  EQU 223
NeedLib EQU LibNum
Is_Resource EQU 1

	Include "BlitzMacs.asm"
	Output "potgo.resource1"

	sharedlibheader LibNum,Init,1,0,0

	slfunction NeedLib,-6,SD0
	slname "AllocPotBits_","(bits)"

	slfunction NeedLib,-12,SD0
	slname "FreePotBits_","(bits)"

	slfunction NeedLib,-18,SD0,SD1
	slname "WritePotgo_","(word,mask)"

Init:
	nullsub InitFunc,0,0

	libfin
	shared_init

name:
	dc.b	"potgo.resource",0
	END