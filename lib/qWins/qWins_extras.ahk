WinsChangeOnTop( hWnd )
{
  If hWnd=
    Return "EMPTY"
  WinSet, AlwaysOnTop, Toggle, ahk_id %hWnd%
  WinActivate, ahk_id %hWnd%
  if IsWinTopmost( hWnd )
    DTP("Always-On-Top ON")
  else
    DTP("Always-On-Top OFF")
  return
}

WinsChangeWindow( hWin )
{
  global wins_cht_ed, wins_cht_transp, wins_cht_aot, wins_cht_ghost
  prevHIcon := qcGui[ "wins_cht" ].hIcon
  qcGui[ "wins_cht" ] := object()
  Gui, GUI_WINS_CHT:New, +hwndguihwnd +AlwaysOnTop
  qcGui[ "wins_cht" ] := { hwnd : guihwnd, hwin : hWin, hIcon : prevHIcon }
  Gui, GUI_WINS_CHT:Default
  Gui, Add, Text,,Hwnd
  Gui, Add, Text,xm+40 yp cNavy,% hWin
  Gui, Add, Groupbox,Section xm w250 h110,Title
  Gui, Add, Button,% "w" 24 " h" 24 " xp+10 yp+18 +0x40 +0x8000 hwndhIcoBut gGUI_WINS_CHT_ChangeIco"
  qcGui[ "wins_cht" ][ "hIcoBut" ] := hIcoBut
  if !IsInteger( hIcon := WinGetIcon( hWin, 16 ) )
  {
    qcGui[ "wins_cht" ].pIcon := hIcon
    hIcon := IconExtract( hIcon, 16 )
  }
  SendMessage( hIcoBut, BM_SETIMAGE := 0x00F7, 1, hIcon )
  Gui, Add, Edit,x+10 yp w200 R3 -WantReturn vwins_cht_ed gGUI_WINS_CHT_newtitle,% WinGetTitle( hWin )
  Gui, Add, Button,% "xs+10 y+10 gGUI_WINS_CHT_Apply w"  glb[ "defButW" ] " h" glb[ "defButH" ],Apply
  
  Gui, Add, Groupbox,Section xm w250 h120,Misc
  Gui, add, text,xs+10 ys+20,Transparency
  Gui, Add, Slider,x+15 yp-6 W115 ToolTip Range0-255 gGUI_WINS_CHT_chtransp vwins_cht_transp AltSubmit +0x20 TickInterval25 Line10
          ,% WinGetTrans( qcGui[ "wins_cht" ].hwin )
  
  Gui, Add, Checkbox,% "xs+10 y+5 gGUI_WINS_CHT_aot vwins_cht_aot Checked" IsWinTopmost( qcGui[ "wins_cht" ].hwin )
          , Always-On-Top
  Gui, Add, Checkbox,% "xs+10 y+5 vwins_cht_ghost gGUI_WINS_CHT_ghost Checked" WinsIsGhost( hWin ), Ghost window
  Gui, Add, Button,% "xs+10 y+5 gGUI_WINS_CHT_unghostall w"  glb[ "defButW" ] " h" glb[ "defButH" ],Un-Ghost all
  Gui, Add, Button,% "xm ys+130 Default gGUI_WINS_CHT_butOK w"  glb[ "defButW" ] " h" glb[ "defButH" ],OK
  Gui, Show,,Change window
  return
  
  GUI_WINS_CHT_unghostall:
    WinsUnGhostAll()
    GuiControlSet( "wins_cht_ghost"
                  ,0
                  ,"","GUI_WINS_CHT" )
    return
  
  GUI_WINS_CHT_ghost:
    state := GuiControlGet( "wins_cht_ghost", "GUI_WINS_CHT" )
    WinsMakeGhost( qcGui[ "wins_cht" ].hwin, state )
    GuiControlSet( "wins_cht_transp"
                  ,WinGetTrans( qcGui[ "wins_cht" ].hwin )
                  ,"","GUI_WINS_CHT" )
    return
  
  GUI_WINS_CHT_aot:
    state := GuiControlGet( "wins_cht_aot", "GUI_WINS_CHT" )
    WinSet, AlwaysOnTop,% state ? "ON" : "OFF",% "ahk_id " qcGui[ "wins_cht" ].hwin
    if state    ;toggle aot for our gui to bring window to front
    {
      WinSet, AlwaysOnTop,% "OFF",% "ahk_id " qcGui[ "wins_cht" ].hwnd
      WinSet, AlwaysOnTop,% "ON",% "ahk_id " qcGui[ "wins_cht" ].hwnd
    }
    return
  
  GUI_WINS_CHT_chtransp:
    WinSetTrans( qcGui[ "wins_cht" ].hwin
               , GuiControlGet( "wins_cht_transp", "GUI_WINS_CHT" ) )
    return
  
  GUI_WINS_CHT_newtitle:
    qcGui[ "wins_cht" ].title := GuiControlGet( "wins_cht_ed", "GUI_WINS_CHT" )
    return
  
  GUI_WINS_CHT_ChangeIco:
    ;~ pm := ControlGetPos( qcGui[ "wins_cht" ].hIcoBut, "GUI_WINS_CHT" )
    WinGetPos, X, Y,W,H,% "ahk_id " qcGui[ "wins_cht" ].hIcoBut
    if ( ico := Gui_Main_IconsMenu( qcGui[ "wins_cht" ].hwnd
                                      , qcGui[ "wins_cht" ].pIcon, x, y+h ) )
    {
      qcGui[ "wins_cht" ].pIcon := ico
      DestroyIcon( qcGui[ "wins_cht" ].hIcon )
      qcGui[ "wins_cht" ].hIcon := IconExtract( qcGui[ "wins_cht" ].pIcon, 16 )
      hPrevIco := SendMessage( qcGui[ "wins_cht" ].hIcoBut, BM_SETIMAGE := 0x00F7
          , 1, qcGui[ "wins_cht" ].hIcon )
      DestroyIcon( hPrevIco )
    }
    return
  
  GUI_WINS_CHT_Apply:
    if qcGui[ "wins_cht" ].title
      WinSetTitle( qcGui[ "wins_cht" ].hwin
                  , qcGui[ "wins_cht" ].title )
    if qcGui[ "wins_cht" ].hIcon
    {
      hPrevIco := WinSetIcon( qcGui[ "wins_cht" ].hwin
                , qcGui[ "wins_cht" ].hIcon )
      if( hPrevIco != qcGui[ "wins_cht" ].hIcon )
        DestroyIcon( hPrevIco )
    }
    return
  
  GUI_WINS_CHT_butOK:
  GUI_WINS_CHTGuiClose:
  GUI_WINS_CHTGuiEscape:
    Gui,GUI_WINS_CHT:Destroy
    return
}

WinsUnGhostAll()
{
  iter := qcconf.wins.selectNodes( "./win[ @type = ""ghosted"" ]" )
  iter.reset()
  Loop,% iter.length
  {
    if !( nextNode := iter.nextNode() )
      break
    winHWND := nextNode.getAttribute( "hwnd" )
    if !IsWindow( winHWND )
      continue
    WinsMakeGhost( winHWND, 0, True )
    qcconf.wins.removeChild( nextNode )
  }
  qcconf.Save()
}

WinsGhostAdd( hWnd )
{
  if ( winNode := qcconf.NewNode( "win" ) )
  {
    winNode.setAttribute( "type", "ghosted" )
    winNode.setAttribute( "hwnd", hWnd+0 )
    qcconf.wins.appendChild( winNode )
  }
  return
}

WinsGhostRemove( hWnd )
{
  hWnd += 0
  query = win[ @hwnd = "%hwnd%" and @type = "ghosted" ]
  if ( winNode := qcconf.wins.selectSingleNode( query ) )
    qcconf.wins.removeChild( winNode )
  return
}


WinsIsGhost( hWnd )
{
  WinGet, ExStyle, ExStyle,ahk_id %hWnd%
  if ( ExStyle & 0x00080000 && ExStyle & 0x00000020 )
    return 1
  return 0
}

WinsMakeGhost( hWnd, state, batch = False )
{
  WinSetTrans( hWnd, state ? 115 : 255 )
  WinSet, ExStyle,% ( state ? "+" : "-" ) "0x00080000", ahk_id %hWnd%
  WinSet, ExStyle,% ( state ? "+" : "-" ) "0x00000020", ahk_id %hWnd%
  if !batch
  {
    if state
      WinsGhostAdd( hWnd )
    else
      WinsGhostRemove( hWnd )
    qcconf.Save()
  }
  return
}

;not used
WinsChangeTransp( hW )
{
  global WHT_O, WHT_T, SliderTransp, WinHandle
  WinHandle := hW
  Gui, 24:Default
  QCSetGuiFont( 24 )
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  InitialTransLevel := WinGetTrans( hW )
  Gui,Add,Text,vWHT_O,Opaque
  Gui,Add,Text,vWHT_T,Transparent
  Gui,Add,Slider,x15 y17 h100 Buddy1WHT_O Buddy2WHT_T vSliderTransp gChangeActWinTransp AltSubmit +0x20 TickInterval25 Invert Line10 Center Range0-255 Vertical,%InitialTransLevel%
  Gui, -Caption +ToolWindow +AlwaysOnTop +0x400000
  MouseGetPos,X,Y
  if (X>A_ScreenWidth-65)
    X := A_ScreenWidth-65
  if (Y-135<0)
    Y := 135
  Gui,Show,% "x" . X . " y" . (Y-135) . " w75 h140"
  SetTimer,Is_Trans_Slider_Active,20
  return
  
  ChangeActWinTransp:
    Gui, 24:Default
    GuiControlGet, TranspToSet,,SliderTransp
    ;~ TranspToSet := GuiControlGet("SliderTransp",24)
    WinSetTrans( WinHandle, TranspToSet )
    DTP(TranspToSet = 255 ? "Opaque" : TranspToSet = 0 ? "Fully Transparent" : TranspToSet,1000)
    return
  
  Close_Trans_Slider:
  24GuiEscape:
    Gui,24:Destroy
    Tooltip
    SetTimer,Is_Trans_Slider_Active,OFF
    return
    
  Is_Trans_Slider_Active:
    Gui,24:+LastFound
    IfWinNotActive
      GoSub,Close_Trans_Slider
    return
}