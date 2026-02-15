HelpGUI()
{
  global
  Gui, 7:Default
  Gui +LastFoundExist	
  ifWinExist
  {
    WinActivate
    return
  }
  QCSetGuiFont( 7 )
  Gui, font, Bold
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  Gui, 7:+LastFound
  qcGui[ "help" ] := WinExist() + 0
  Gui, Add, Text, xm ym +Left BackgroundTrans,% glb[ "appName" ] " v" glb[ "ver" ] " " glb[ "qcArch" ]
  Gui,Add,Text,cNavy,Enabled Features:
  local clips_state := qcOpt[ "clips_on" ]
  local win_state := qcOpt[ "wins_on" ]
  local memos_state := qcOpt[ "Memos_On" ]
  local recent_state := qcOpt[ "recent_on" ]
  Gui,Add,Text,% "y+5 cGreen Disabled" . !clips_state,Clips
  Gui,Add,Text,% "x+10 cGreen Disabled" . !win_state,Windows
  Gui,Add,Text,% "x+10 cGreen Disabled" . !memos_state,Memos
  Gui,Add,Text,% "x+10 cGreen Disabled" . !recent_state,Recent
  
  Gui, Add, Picture,% "y+20 xm w16 h16 Icon" . IconGetIndex( glb[ "icoQC" ] )+1,% IconGetPath( glb[ "icoQC" ] )
  Gui, font, Bold
  Gui,Add,Text,x+5 cNavy,Main menu hotkey/gesture:
  Gui, font, Norm
  Gui,Add,Text,y+2,% HotkeyToString( qcOpt[ "main_hotkey" ] ) " / " qcOpt[ "main_gesture" ]
  Gui, Add, Picture,% "xm w16 h16 Disabled" . !clips_state . " Icon" . IconGetIndex( glb[ "icoClips" ] )+1,% IconGetPath( glb[ "icoClips" ] )
  Gui, font, Bold
  Gui,Add,Text,% "x+5 cNavy Disabled" . !clips_state,Clips menu hotkey/gesture:
  Gui, font, Norm
  Gui,Add,Text,% "y+2 Disabled" . !clips_state
      ,% HotkeyToString( qcOpt[ "clips_hotkey" ] ) " / " qcOpt[ "clips_gesture" ] 
      . "`n" HotkeyToString(qcOpt[ "Clips_CopyHK" ]) "1-9 - Copy data to clipboard"
      . "`n" HotkeyToString(qcOpt[ "Clips_AppendHK" ]) "1-9 - Append data to clipboard"
      . "`n" HotkeyToString(qcOpt[ "Clips_PasteHK" ]) "1-9 - Paste from clipboard"
  Gui, Add, Picture,% "xm w16 h16 Disabled" . !win_state . " Icon" . IconGetIndex( glb[ "icoWins" ] )+1,% IconGetPath( glb[ "icoWins" ] )
  Gui, font, Bold
  Gui,Add,Text,% "x+5 cNavy Disabled" . !win_state,Windows menu hotkey/gesture:
  Gui, font, Norm
  local hk := qcOpt[ "wins_wndHideHkey" ] ? "^Space" : qcOpt[ "wins_wndHideHkey" ]
  Gui,Add,Text,% "y+2 Disabled" . !win_state,% HotkeyToString( qcOpt[ "wins_hotkey" ] ) " / " qcOpt[ "wins_gesture" ] "`n" HotkeyToString( hk ) " - hide active window"
  Gui, Add, Picture,% "xm w16 h16 Disabled" . !memos_state . " Icon" . IconGetIndex( glb[ "icoMemos" ] )+1,% IconGetPath( glb[ "icoMemos" ] )
  Gui, font, Bold
  Gui,Add,Text,% "x+5 cNavy Disabled" . !memos_state,Memos menu hotkey/gesture:
  Gui, font, Norm
  Gui,Add,Text,% "y+2 Disabled" . !memos_state,% HotkeyToString( qcOpt[ "Memos_Hotkey" ] ) " / " qcOpt[ "Memos_Gesture" ]
  Gui, Add, Picture,% "xm w16 h16 Disabled" . !recent_state . " Icon" . IconGetIndex( glb[ "icoRecent" ] )+1,% IconGetPath( glb[ "icoRecent" ] )
  Gui, font, Bold
  Gui,Add,Text,% "x+5 cNavy Disabled" . !recent_state,Recent menu hotkey/gesture:
  Gui, font, Norm
  Gui,Add,Text,% "y+2 Disabled" . !recent_state,% HotkeyToString( qcOpt[ "Recent_Hotkey" ] ) " / " qcOpt[ "Recent_Gesture" ]
  
  Gui, font, Bold
  Gui,Add,Text,xm y+10 cNavy,Gesture button:
  Gui, font, Norm
  Gui,Add,Text,xm,% HotkeyToString( GestureGetHK() )
  
  Gui,add,button,xm y+10 gHelpShowCHK,Show custom hotkeys >>
  
  Gui, font, Bold s8
  Gui, Add, Link,y+20 x75,% "<a href=""" glb[ "urlWebHelp" ] """>Open Web Help</a>"
  Gui, font, Norm s8
  Gui,Add,Button,x95 y+20 Center gCloseHelp w50 h25,Close
  
  Gui,Show,autosize,Quick Help
  return
  
  CloseHelp:
  7GuiClose:
  7GuiEscape:
    QCFreeMem()
    Gui, 7:Destroy
    return
    
  HelpShowCHK:
    CustomHotkeysGui_Show()
    return
}
