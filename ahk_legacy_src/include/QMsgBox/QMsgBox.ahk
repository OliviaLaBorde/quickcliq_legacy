QMsgBoxP( params, sGuis = "" )
{
  box := new QMsgBox( params )
  return box.Show( sGuis )
}

class QMsgBox extends QMsgBox_base
{

  static _defaults := { "title"		: "Message"
                        ,"editbox" : 0
                        ,"editbox_w" : 0
                        ,"editbox_h" : 0
                        ,"msg" 		: "press any button to continue"
                        ,"buttons" : "OK"
                        ,"ontop"	: 0 
                        ,"nocaption": 0 
                        ,"nosysmenu": 0
                        ,"modal"	: 0
                        ,"pos"	    : "center"
                        ,"pic"		: 0
                        ,"rsz"      : 0 }
  static defButtonWidth := 70
  ,defWidth := 300
  ,defHeight := 100

  __New( params )
  {
    this.SetParams( params )
    this.alive := 1
    this.hBox := 0
    this.hBtns := object()
  }
  
  _GetFreeGuiName()
  {
    loop
    {
      name := "GUI_QMSGBOX_" A_Index
      Gui, %name%:+LastFoundExist
      if !WinExist()
      {
        this.guiname := name
        break
      }
    }
  }
  
  SetParams( params )
  {
    if !IsObject( params )
    {
      if ( params != "" )
        this.msg := params
    }
    else
    {
      for name,val in params
        this[ name ] := val
    }
  }
  
  Destroy()
  {
    if !this.alive
      return
    this._ChangeModal( -1 )
    if( this.guiname != "" )
      Gui,% this.guiname ":Destroy"
    this.guiname := ""
    this.alive := 0
  }
  
  __Delete()
  {
    this.Destroy()
    return
  }
  
  ; returns defaults
  __Get( name )
  {
    return QMsgBox._defaults[ name ]
  }
  
  _ChangeModal( mode )
  {
    for i,nGui in StrSplit( this.pGuis, "|", A_tab A_Space )
    {
      if ( !nGui )
        continue
      Gui,%nGui%:+LastFoundExist
      if !WinExist()
        continue
      Gui,% this.guiname ":" ( mode = 1 ? "+owner" : "-owner" ) nGui
      if this.modal
        Gui,%  nGui ":" ( mode = 1 ? "+Disabled" : "-Disabled" )
    }
  }
  
  _GetPos()
  {
    if( !this.pos || this.pos = "center" )
      return "center"
    storeDHW := A_DetectHiddenWindows
    DetectHiddenWindows, On
    if( this.pos = "mouse" )
    {
      ControlGetPos, bX, bY, bW, bH, Button1,% "ahk_id " this.handle
      CoordMode,Mouse,Screen
      MouseGetPos, mX, mY
      x := round( mX - bW/2 - bX )
      y := round( mY - bH/2 - bY )
    }
    else
    {
      Gui,% this.pos ":+LastFoundExist"
      if( hwnd := WinExist() )
      {
        WinGetPos,wX,wY,wW,wH,% "ahk_id " hwnd
        WinGetPos,,,qW,qH,% "ahk_id " this.handle
        x := round( wX + wW/2 - qW/2 )
        y := round( wY + wH/2 - qH )
      }
      else
      {
        DetectHiddenWindows,% storeDHW
        return "center"
      }
    }
    WinGetPos,,,wW,wH,% "ahk_id " this.handle
    x := ( x + wW ) > A_ScreenWidth ? ( A_ScreenWidth - wW ) : x < 0 ? 0 : x
    y := ( y + wH ) > A_ScreenHeight ? ( A_ScreenHeight - wH ) : y < 0 ? 0 : y
    
    DetectHiddenWindows,% storeDHW
    return "x" x " y" y
  }
  
  _AddPic()
  {
    token := QMsgBoxAPI.Gdip_Startup()
    pic := this.pic
    if !pic
      hBitmap := 0
    if QMsgBoxAPI.IsInteger( pic )
      hBitmap := pic
    else if pic in !,?,x,i,s
    {
      IDI := pic = "!" ? 32515
        :  pic = "?" ? 32514
        :  pic = "x" ? 32513
        :  pic = "i" ? 32516
        :  pic = "s" ? 32518 : 0
      if !IDI
        return 0
      if hIcon := DllCall( "LoadImageW"
              , "Ptr", 0
              , "Uint", IDI
              , "UInt", 1
              , "UInt", 0
              , "UInt", 0
              , "Uint", 0x00008000
              ,"Ptr" )
        hBitmap := QMsgBoxAPI.HBITMAPfromHICON( hIcon )
      else
        hBitmap := 0
    }
    else
    {
      resPath := QMsgBoxAPI.IconGetPath( pic )
      resIdx  := QMsgBoxAPI.IconGetIndex( pic )
      if ( resIdx = "" )
      {
        DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", resPath, "Ptr*", pBitmap )
        DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hBitmap, "int", 0xffffffff )
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
      }
      else
      {
        if hIcon := QMsgBoxAPI.IconExtract( resPath ":" resIdx, 0 )
          hBitmap := QMsgBoxAPI.HBITMAPfromHICON( hIcon )
        else
          hBitmap := 0
        DllCall( "DestroyIcon", "Ptr", hIcon )
      }
    }
    if !hBitmap
      return 0
    Gui,% this.guiname ":Default"
    Gui, Add, Picture,% "hwndPicHwnd +" SS_BITMAP := 0xE
    SendMessage,% STM_SETIMAGE := 0x0172,% IMAGE_BITMAP := 0,% hBitmap,, ahk_id %PicHwnd%
    DllCall("DeleteObject", "Ptr", hBitmap )
    QMsgBoxAPI.Gdip_Shutdown( token )
    return PicHwnd
  }
  
  Show( pGuis = "" ) 
  {
    this._GetFreeGuiName()
    this.pressed := ""
    this.alive := 1
    options .= this.ontop ? " +AlwaysOnTop " : ""
    options .= this.nocaption ? " -Caption +Border " : ""
    options .= this.nosysmenu ? " -SysMenu " : ""
    Gui,% this.guiname ":New", % "+LabelQMsgBox -MaximizeBox -MinimizeBox -Theme" options
    Gui,% this.guiname ":Default"
    fontname := glb[ "QC_GUI_FONT" ] ? glb[ "QC_GUI_FONT" ] : "Times New Roman"
    Gui, Font,norm s10 q6,% fontname
    Gui, +HWNDhandle
    this.handle := handle
    this.pGuis := ( this.modal ? A_Gui "|" : "" ) . pGuis
    aBtns := StrSplit( this.buttons, "|", A_Space A_Tab )
    cnt := aBtns.MaxIndex()
    defButWid := QMsgBox.defButtonWidth
    btnsWidth := ( ( cnt * defButWid ) + ( cnt-1 )*5 )
    
    this._ChangeModal( 1 )
    
    if PicHwnd := this._AddPic()
      ControlGetPos,,,pW,pH,,ahk_id %PicHwnd%
    else
      pW := 0, pH := 0
    boxWidth := btnsWidth > QMsgBox.defWidth ? btnsWidth : QMsgBox.defWidth
    boxHeight := pH > QMsgBox.defHeight ? pH : QMsgBox.defHeight
    if this.editbox
    {
      Gui,Add,Edit,% "ym +Multi +ReadOnly +hwndhBox "
                                . "x+" pW+10 " w" ( this.editbox_w ? this.editbox_w : boxWidth )
                                . " h" ( this.editbox_h ? this.editbox_h : boxHeight ), % this.msg
      CColor( hBox, 0xFFFFFF )
      GuiControl,Focus,% PicHwnd
    }
    else
      Gui, Add, Link,% "ym +Wrap +hwndhBox +Multi x+" pW+10 " w" boxWidth,% this.msg
    this.hBox := hBox
    ControlGetPos,,,,tH,,ahk_id %hBox%
    ButPosY := ( tH > pH ? tH : pH ) + 15
    for i,btn in aBtns
    {
      Gui,Add,Button,% "hwndhB y" ButPosY " x" (i=1?"p":"+5") " w" defButWid " gQMsgBoxOnPress",% btn
      this.hBtns.insert( hB )
    }
    Gui,Show,hide autosize
    if this.rsz
    {
      p := QMsgBoxAPI.WinGetPos( this.handle )
      Gui,% "+Resize +MinSize" p.W "x" p.H
    }
    GuiControl, Focus,% this.hBtns[1]
    Gui, Show,% this._GetPos(),% this.title
    while this.alive
      sleep 100
      ,sleep -1
    return this.pressed
    
    QMsgBoxClose:
      this.Destroy()
      return
      
    QMsgBoxOnPress:
      this.pressed := A_GuiControl
      this.Destroy()
      return
      
    QMsgBoxSize:
      if( !this.curW || !this.curH )
        this.curW := A_GuiWidth, this.curH := A_GuiHeight
      changeW := A_GuiWidth - this.curW
      changeH := A_GuiHeight - this.curH
      this.curW := A_GuiWidth
      this.curH := A_GuiHeight
      ControlGetPos,,,tW,tH,,% "ahk_id " this.hBox
      GuiControl, MoveDraw,% this.hBox,% "w" tW+changeW " h" tH+changeH
      for i,hBut in this.hBtns
      {
        if( p := QMsgBoxAPI.ControlGetClientPos( hBut ) )
          GuiControl, MoveDraw,% hBut,% "y" p.y+changeH
      }
      return
  }
}