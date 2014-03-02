LibNum  EQU 243
NeedLib EQU LibNum
Is_Resource EQU 1

	Include "BlitzMacs.asm"
	Output "card.resource1"

	sharedlibheader LibNum,Init,1,0,0

	slfunction NeedLib,-6,SA1
	slname "OwnCard_","(handle)"

	slfunction NeedLib,-12,SA1,SD0
	slname "ReleaseCard_","(handle,flags)"

	slfunction NeedLib,-18
	slname "GetCardMap_",""

	slfunction NeedLib,-24,SA1
	slname "BeginCardAccess_","(handle)"

	slfunction NeedLib,-30,SA1
	slname "EndCardAccess_","(handle)"

	slfunction NeedLib,-36
	slname "ReadCardStatus_",""

	slfunction NeedLib,-42,SA1,SD0
	slname "CardResetRemove_","(handle,flag)"

	slfunction NeedLib,-48,SA1,SD1
	slname "CardMiscControl_","(handle,control_bits)"

	slfunction NeedLib,-54,SA1,SD0
	slname "CardAccessSpeed_","(handle,nanoseconds)"

	slfunction NeedLib,-60,SA1,SD0
	slname "CardProgramVoltage_","(handle,voltage)"

	slfunction NeedLib,-66,SA1
	slname "CardResetCard_","(handle)"

	slfunction NeedLib,-72,SA1,SA0,SD1,SD0
	slname "CopyTuple_","(handle,buffer,tuplecode,size)"

	slfunction NeedLib,-78,SA0,SA1
	slname "DeviceTuple_","(tuple_data,storage)"

	slfunction NeedLib,-84,SA2
	slname "IfAmigaXIP_","(handle)"

	slfunction NeedLib,-90
	slname "CardForceChange_",""

	slfunction NeedLib,-96
	slname "CardChangeCount_",""

	slfunction NeedLib,-102
	slname "CardInterface_",""

Init:
	nullsub InitFunc,0,0

	libfin
	shared_init

name:
	dc.b	"card.resource",0
	END