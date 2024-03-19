;
; Darts program by Simon Armstrong
;
; Please note copyright notice on the projection algorithm
;

; increase the dart variable if you have an accelerated machine
;
; press esc to quit

darts=10

NPrint "Setting up, please wait..."

; processor cls for extra speed

Statement mycls{a.l}
  MOVE.l d0,a0:ADD.l#40*256,a0
  MOVEQ#0,d0:MOVEQ#0,d1:MOVEQ#0,d2:MOVEQ#0,d3:MOVEQ#0,d4
  MOVEQ#0,d5:MOVEQ#0,d6:MOVE.ld0,a1:MOVE.ld0,a2:MOVE.ld0,a3
  MOVE#255,d7
  loop1:MOVEM.l d0-d6/a1-a3,-(a0):DBRA d7,loop1
  AsmExit
End Statement

Macro p {SizeOf.object\`1}(a5):End Macro

Statement calcid{object.l,rottable.l}
  MOVEM.l a4-a6,-(a7):MOVE.l d0,a5:MOVE.l d1,a3
  MOVEM.l!p{rotx-2},d0-d2:MOVE#4092,d3:AND d3,d0:AND d3,d1
  AND d3,d2:LEA !p{id},a4
  MOVEM 0(a3,d2.w),d4-d5
  MOVEM 0(a3,d1.w),d2-d3
  MOVEM 0(a3,d0.w),d0-d1
  MOVE d5,d6:MULS d3,d6:MOVE.l d6,a0:MOVE d4,d7:MULS d0,d7
  SWAP d7:ADD d7,d7:MOVE d7,a1:MULS d2,d7:ADD.l d6,d7:SWAP d7
  ADD d7,d7:MOVE d7,(a4)+
  MOVE d4,d7:MULS d1,d7:SWAP d7:ADD d7,d7:MOVE d7,(a4)+
  MOVE d5,d6:MULS d2,d6:MOVE.l d6,a2:MOVE a1,d7:MULS d3,d7
  SUB.l d6,d7:SWAP d7:ADD d7,d7:MOVE d7,(a4)+
  MOVE d4,d6:MULS d3,d6:MOVE.l a2,d7:SWAP d7:ADD d7,d7
  MULS d0,d7:SUB.l d6,d7:SWAP d7:ADD d7,d7:MOVE d7,(a4)+
  MOVE d5,d7:MULS d1,d7:SWAP d7:ADD d7,d7:MOVE d7,(a4)+
  MOVE d2,d6:MULS d4,d6:MOVE.l a0,d7:SWAP d7:ADD d7,d7
  MULS d0,d7:ADD.l d6,d7:SWAP d7:ADD d7,d7:MOVE d7,(a4)+
  MULS d1,d2:SWAP d2:ADD d2,d2:MOVE d2,(a4)+
  NEG d0:MOVE d0,(a4)+:MULS d1,d3:SWAP d3:ADD d3,d3:MOVE d3,(a4)+
  MOVEM.l (a7)+,a4-a6:AsmExit
End Statement

Statement moveonz{object.l,shift.w}
  EXG d0,a5
  MOVEM !p{id+12},d3-d5:ASL.l d1,d3:ASL.l d1,d4:ASL.l d1,d5
  MOVEM.l d3-d5,!p{vx}
  EXG d0,a5:AsmExit
End Statement

Macro genvert
  MOVEM.l !p{x},d0-d2:ASR.l#2,d0:ASR.l#2,d1
  CNIF `1<>0
    MOVEM !p{id+0},d3-d5:ASL.l#`1,d3:ASL.l#`1,d4:ASL.l#`1,d5
    `2.ld3,d0:`2.ld4,d1:`2.ld5,d2
  CEND
  CNIF `3<>0
    MOVEM !p{id+6},d3-d5:ASL.l#`3,d3:ASL.l#`3,d4:ASL.l#`3,d5
    `4.ld3,d0:`4.ld4,d1:`4.ld5,d2
  CEND
  CNIF `5<>0
    MOVEM !p{id+12},d3-d5:ASL.l#`5,d3:ASL.l#`5,d4:ASL.l#`5,d5
    `6.ld3,d0:`6.ld4,d1:`6.ld5,d2
  CEND
  SWAP d2:TST d2:BLE flow:DIVS d2,d0:BVS flow:DIVS d2,d1:BVS flow
  MULS#640,d0:MULS#512,d1
  SWAP d0:SWAP d1:ADD#160,d0:ADD#128,d1:MOVEM d0-d1,(a6):ADDQ#4,a6
End Macro

Function.w gendart{object.l}
  MOVEM.l a4-a6,-(a7):MOVE.l d0,a5:LEA !p{v},a6
  !genvert{0,0,0,0,8,ADD}
  !genvert{0,0,7,SUB,8,SUB}
  !genvert{8,SUB,0,0,8,SUB}:!genvert{8,ADD,0,0,8,SUB}
  !genvert{7,SUB,0,0,8,SUB}:!genvert{7,ADD,0,0,8,SUB}
  MOVEM.l (a7)+,a4-a6:MOVEQ#-1,d0:AsmExit
  flow:MOVEM.l (a7)+,a4-a6:MOVEQ#0,d0:AsmExit
End Statement

Function.w genstar{object.l}
  MOVEM.l a4-a6,-(a7):MOVE.l d0,a5:LEA !p{v},a6
  !genvert{8,ADD,0,0,0,0}:!genvert{8,SUB,0,0,0,0}
  !genvert{0,0,8,ADD,0,0}:!genvert{0,0,8,SUB,0,0}
  !genvert{0,0,0,0,8,ADD}:!genvert{0,0,0,0,8,SUB}
  MOVEM.l (a7)+,a4-a6:AsmExit
End Statement

Statement genline{object.l}
  MOVEM.l a4-a6,-(a7):MOVE.l d0,a5:LEA !p{v},a6
  MOVEM.l (a6),d0-d7:MOVEM.l d0-d7,4(a6)
  MOVEM.l !p{x},d0-d2
  ASR.l#2,d0:ASR.l#2,d1:SWAP d2:DIVS d2,d0:DIVS d2,d1
  MULS#640,d0:MULS#512,d1:SWAP d0:SWAP d1
  ADD#160,d0:ADD#128,d1:MOVEM d0-d1,(a6)
  MOVEM.l (a7)+,a4-a6:AsmExit
End Statement

;-------------------------------------------------------------

NEWTYPE .vert
  x.w:y
End NEWTYPE

NEWTYPE .object
  x.q:y:z
  vx:vy:vz
  thrust
  rotx:roty:rotz
  rvx:rvy:rvz
  v.vert[64]    ;verticies go here
  id.w[9]
End NEWTYPE

Dim List nme.object(darts) ;wow variable dimensioning in a compiler!
Dim List bul.object(20)
Dim List fire.object(5)
Dim List bang.object(10)

;generate sin_cos table

Dim rots.w(2049):rt.l=&rots(0)
For i=0 To 2048 Step 2
  rots(i)=Sin(i*2*Pi/2048)*32766
  rots(i+1)=Cos(i*2*Pi/2048)*32766
Next

;setup display

BitMap 0,320,256,1
BitMap 1,320,256,1
For i=0 To 7
  BitMap 2+i,320,256,1
  BitMapOutput 2+i:Locate 2,0
  NPrint "BLITZ DARTS BY SIMON   ESC TO EXIT"
  For r=0 To 2*Pi-Pi/32 Step Pi/32
    j=r+i*Pi/256
    Circle 160,128,Tan(j/4)*50,1
    Line 160,128,160+Sin(j)*320,128+Cos(j)*256,1
    Circlef 160,128,12,1
  Next
Next

BLITZ

InitCopList 0,$22
PalRGB 0,1,15,12,15
PalRGB 0,9,4,4,8
DisplayPalette 0,0
CreateDisplay 0

f=2     ;frame of anim
xo=1000 ;current laser

Mouse On:MouseArea -150,-150,120,120:BlitzKeys On

.mainloop

Repeat
  VWait:DisplayBitMap 0,db,f
  db=1-db:Use BitMap db  ;double buffer
  f+1:If f=10 Then f=2
  mycls{Peek.l (Addr BitMap(db)+8)}
;do you
  x=MouseX:y=MouseY
  Line x+155,y+128,x+165,y+128,1:Line x+160,y+123,x+160,y+133,1
  If Joyb(0)=1 AND reload<1 Then Gosub addfire:reload=15
  Gosub dofire:reload-1:If Joyb(0)=0 Then reload=-1
;do nme
  Gosub addnme
  Gosub movenme
  Gosub dobang
Until RawStatus($45)

End

Macro myline Line \v[`1]\x,\v[`1]\y,\v[`2]\x,\v[`2]\y,1:End Macro

USEPATH bang()

.dobang
  ResetList bang()
  While NextItem(bang())
    \x+\vx:\y+\vy:\z+\vz
    \rotx+\rvx:\roty+\rvy:\rotz+\rvz
    calcid{bang(),rt}
    If genstar{bang()}
      For i=0 To 4 Step 2:!myline {i,i+1}:Next
    Else
      KillItem bang()
    EndIf
  Wend
  Return

USEPATH nme()

.addnme:
  newnme-1
  If newnme<0
    If AddItem(nme())
      newnme=5
      \x=Rnd(8000)-4000,Rnd(24000)-12000,6000
      \rotx=0,Rnd(4096),512
      \rvx=0,Rnd(16)+16,0
      \thrust=Rnd(4)+6
    EndIf
  EndIf
  Return

.movenme:
  ResetList nme()
  While NextItem(nme())
    calcid{nme(),rt}
    moveonz{nme(),\thrust}
    \x+\vx:\y+\vy:\z+\vz:
    \rotx+\rvx:\roty+\rvy:\rotz+\rvz
    If \z>1000
      If gendart{nme()}
        For i=1 To 5:!myline {0,i}:Next
        !myline {2,3}:!myline {1,4}:!myline {1,5}

        ResetList fire()
        While NextItem(fire())
          If Abs(\x-fire()\x)<1000
            If Abs(\y-fire()\y)<1000
              If Abs(\z-fire()\z)<1000
                If AddItem(bang())
                  bang()\x=\x,\y,\z,\vx,\vy,\vz
                  bang()\rvx=100,130,90
                EndIf
                KillItem nme():KillItem fire():Goto popout
              EndIf
            EndIf
          EndIf
        Wend:popout

      EndIf
    Else
      KillItem nme()
    EndIf
  Wend
  Return

USEPATH fire()

.addfire:
  If AddItem(fire())
    xo=-xo
    \x=xo,1000,1000
    calcid{fire(),rt}
    genline{fire()}:xx.w=\v[0]\x:yy.w=\v[0]\y
    For i=1 To 7:\v[i]\x=xx,yy:Next
  EndIf
  \vx=x*6.5-xo/24,y*8-32,1000
  Return

.dofire:
  ResetList fire()
  While NextItem(fire())
    \x+\vx:\y+\vy:\z+\vz
    If \z<16000
      genline{fire()}:!myline{0,7}
    Else
      KillItem fire()
    EndIf
  Wend
  Return

