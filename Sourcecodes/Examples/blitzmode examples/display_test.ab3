;
; display library demo requires WB2.0 or greater
;
; see ABOUT requester for details
;

.main:
  Gosub setupui
  Gosub setuppalette
  Gosub doui
  End

#msg=13:#flag=12:#exit=11:#about=10:#test=9:#mc=8:#bp=7:#fetch=6
#spres=5:#ham=4:#ehb=3:#dp=2:#smooth=1:#res=0:#w0=0

.doui:
  bp=1:fetch=0:spres=0:res=0
  ham=0:ehb=0:dp=0:smooth=0:mc=0
  AttachGTList #w0,#w0
  Repeat
    Gosub displayflags
    ev.l=WaitEvent
    If ev=$20 OR ev=$40 Then Gosub readui
  Until GadgetHit=#exit
  Return

.readui:
  Select GadgetHit
    Case #bp:bp=EventCode
    Case #res:res=EventCode
    Case #smooth:smooth=EventCode
    Case #dp:dp=EventCode
    Case #ehb:ehb=EventCode
    Case #ham:ham=EventCode
    Case #spres:spres=EventCode
    Case #fetch:fetch=EventCode
    Case #mc:mc=EventCode
    Case #test:Gosub testmode
    Case #about:Gosub doabout
  End Select
  Return

.displayflags:
  flags.l=bp+smooth*$10+dp*$20+ehb*$40+ham*$80
  flags.l+res*$100+spres*$400+fetch*$1000+mc*$10000
  GTSetString #w0,#flag,"$"+Right$(Hex$(flags),5)
  Return

.setupui:
  Screen 0,0,0,640,256,2,-32768,"TEST",0,1
  GTText #w0,#msg,74,137,280,16,"MESSAGE:",1,""
  GTText #w0,#flag,74,119,280,16,"FLAGS:",1,""
  GTButton #w0,#exit,238,156,112,18,"EXIT",16
  GTButton #w0,#about,121,156,105,17,"ABOUT",16
  GTButton #w0,#test,8,156,97,16,"TEST",16
  GTCheckBox #w0,#mc,5,104,26,11,"24BIT PALETTE",2
  f$="%2ld":GTTags $8008002a,&f$,$80080029,2
  GTSlider #w0,#bp,132,22,202,13,"BITPLANES =   ",1,1,8,1
  GTCycle #w0,#fetch,100,4,233,15,"FETCH MODE",1,"  SINGLE  |DOUBLE (1)|DOUBLE (2)|  TRIPLE  "
  GTMX #w0,#spres,185,85,161,28,"",2," LO-RES SPRITES  | HI-RES SPRITES  |SUPER-RES SPRITES"
  GTCheckBox #w0,#ham,4,89,26,11,"HAM",2
  GTCheckBox #w0,#ehb,5,74,26,11,"EHB",2
  GTCheckBox #w0,#dp,5,59,26,11,"DUAL PLAYFIELD",2
  GTCheckBox #w0,#smooth,6,45,26,11,"SMOOTH SCROLL",2
  GTMX #w0,#res,186,45,113,28,"",2,"  LO-RES   |  HI-RES   |SUPER-HIRES"
  Window #w0,111,15,369,188,$1000,"DISPLAY DEMO",1,2
  Return

.doabout
  Window 1,111,15,369,188,$1008,"ABOUT DISPLAY DEMO",1,2
  WindowOutput 1
  NPrint ""
  NPrint "*        BLITZ 2 DISPLAY DEMO v0.1          *"
  NPrint "         -------------------------           "
  NPrint " Hopefully this program will enable you to  "
  NPrint " find out what value to put in Blitz's new  "
  NPrint " InitCopList command's flags field.         "
  NPrint ""
  NPrint " If you select smoothscroll you can move da "
  NPrint " mouse around in the test mode. I chose not "
  NPrint " to blit the shape all around the screen    "
  NPrint " as this logic would have slowed it down    "
  NPrint " Instead the program just blits the shape   "
  NPrint " down in the top left where it picks it up. "
  NPrint ""
  NPrint " Sorry no dualplayfield testmode as yet....  "
  NPrint " Also would like to support the different    "
  NPrint " Blit modes such as BBlit and QBlit.         "
  NPrint ""
  NPrint "Maybe add sprites and overscan stuff?        "
  Repeat:Until WaitEvent=$200
  CloseWindow 1
  Return

.setuppalette:
  For i=1 To 255:AGAPalRGB 0,i,Rnd(255),Rnd(255),Rnd(255):Next
  Return

.testmode:
  ;
  width=320*(2^res):height=256:cols=2^bp
  If ehb Then cols=32
  If ham Then If bp<7 Then cols=16 Else cols=64
  ;
  If cols>32 AND mc=0
    GTSetString #w0,#msg,"SET 24BIT MODE FOR > 32 COLORS!"
    BeepScreen 0:Return
  EndIf
  If fetch=0 AND ((res=1 AND bp>4) OR (res=2 AND bp>2))
    GTSetString #w0,#msg,"INCREASE FETCH MODE!"
    BeepScreen 0:Return
  EndIf
  If fetch<3 AND res=2 AND bp>4
    GTSetString #w0,#msg,"INCREASE FETCH MODE!"
    BeepScreen 0:Return
  EndIf
  ;
  bwidth=width:bheight=height:If smooth Then bwidth*2:bheight*2
  BitMap 0,bwidth,bheight,bp
  For i=0 To 100:Line Rnd(bwidth),Rnd(bheight),Rnd(cols):Next
  Circlef 7,7,7,-1:GetaShape 0,0,0,16,16
  ;
  InitCopList 0,44,256,flags,8,cols,0
  DisplayPalette 0,0
  BLITZ
  Mouse On:MouseArea 0,0,bwidth/2,bheight/2
  ;
  SetInt 5
    If smooth Then DisplayBitMap 0,0,MouseX,MouseY
    nf.l+1
  End SetInt
  ;
  CreateDisplay 0:DisplayBitMap 0,0
  ;
  nf.l=0:nb.l=0
  While Joyb(0)=0:Blit 0,0,0:nb+1:Wend
  ClrInt 5
  VWait 20
  AMIGA
  msg$="16x16 blits per frame = "+Str$(nb/nf)
  GTSetString #w0,#msg,msg$
  Return
