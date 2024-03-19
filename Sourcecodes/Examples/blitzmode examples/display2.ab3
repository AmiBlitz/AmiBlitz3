;
; display sprites demo for AGA amigas
;

; 8 sprite channels require horizontal underscan
; use the below display adjust to acheive this
; effective screen size is now 304 pixels wide

; the sprite is actually 16 colour 64 pixel wide and so
; each sprite requires 2 sprite channels in AGA mode

; also not the displaycontrols that means our sprites
; palette comes from color registers 240..255

SpriteMode 2                 ; 64 pixel wide sprites

BitMap 0,1024,516,4
For i=0 To 255:AGAPalRGB 0,i,Rnd(255),Rnd(255),Rnd(255):Next
For i=0 To 15:Boxf Rnd(1024),Rnd(516),Rnd(1024),Rnd(516),i:Next

Box 0,0,304,266,-1

LoadShape 0,"data/sprite.iff":GetaSprite 0,0
LoadPalette 0,"data/sprite.iff",240

InitCopList 0,34,267,$10814,8,256,0 ;hires sprite smooth scroll 4 bitplanes

DisplayAdjust 0,-2,8,0,16,0        ;under scan!

DisplayControls 0,0,0,$ee

BLITZ

Mouse On:MouseArea 0,0,700,250

CreateDisplay 0
DisplayPalette 0,0

For i=0 To 3:DisplaySprite 0,0,50+i*50,50,i*2:Next

While Joyb(0)=0
  VWait
  DisplayBitMap 0,0,MouseX,MouseY
Wend
End

