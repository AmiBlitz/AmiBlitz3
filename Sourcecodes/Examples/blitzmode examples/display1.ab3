;
; 2 slices AGA example
;

BitMap 0,320,256,8

For i=0 To 255:AGAPalRGB 0,i,i,i,i:Next

InitCopList 0,44,120,$13008,8,256,0         ;2 slices
InitCopList 1,44+132,120,$13008,8,256,0

BLITZ

CreateDisplay 0,1
DisplayBitMap 0,0:DisplayPalette 0,0
DisplayBitMap 1,0:DisplayPalette 1,0

For i=255 To 0 Step -1:Circlef 160,128,i/2,i:Next

MouseWait

End

