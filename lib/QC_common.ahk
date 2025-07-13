CheckMenuNode( xmlNode )
{
  if ( xmlNode = "main" )
    xmlNode := qcconf.GetMenuNode()
  if !qcconf.IsMenu( xmlNode )
    ShowExc( "Node is not a menu" )
  return xmlNode
}

GesturesSuspend( timer = 0 )
{
  SetTimer( "GesturesRestore", "OFF" )
  state := qcOpt[ "gest_glbOn" ] := !qcOpt[ "gest_glbOn" ]
  if !timer
    qcconf.Save() ; saving global gestures state
  Menu,tray, Rename,% state ? glb[ "l_gstrs_on" ] : glb[ "l_gstrs_off" ],% state ? glb["l_gstrs_off" ] : glb[ "l_gstrs_on" ]
  qcPUM.GetItemByUID( "GS_Susp" ).SetParams( { icon : state ? glb[ "icoSuspOn" ] : glb[ "icoSuspOff" ]
                                        , name : state ? glb["l_gstrs_off" ] : glb[ "l_gstrs_on" ] } )
  SetGestureState( state )
  if ( timer && !state )
  {
    if qcOpt[ "gest_tempNotify" ]
      DTP("Gestures will be restored in " . Round( qcOpt[ "gest_time" ]/1000 ) . " seconds",2000)
    SetTimer( "GesturesRestore", qcOpt[ "gest_time" ] )
  }
  return
}

GesturesRestore( p* )
{
  SetTimer( A_ThisFunc, "OFF" )
  if qcOpt[ "gest_tempNotify" ]
    DTP("Gestures have been restored!",2000)
  GesturesSuspend()
  return
}

HotkeysSuspend()
{
  state := qcOpt[ "hkey_glbOn" ] := !qcOpt[ "hkey_glbOn" ]
  qcconf.Save() ; saving global hotkeys state
  Menu,tray, Rename,% state ? glb[ "l_hkeys_on" ] : glb[ "l_hkeys_off" ],% state ? glb[ "l_hkeys_off" ] : glb[ "l_hkeys_on" ]
  qcPUM.GetItemByUID( "HK_Susp" ).SetParams( { icon : state ? glb[ "icoSuspOn" ] : glb[ "icoSuspOff" ]
                      , name : state ? glb[ "l_hkeys_off" ] : glb[ "l_hkeys_on" ] } )
  SetHotkeys( state )
}

MenuProcessing( hk, label )
{
  if !glb[ "HotKeysAllowed" ]
  {
    DTP( "Please wait...`nMenu Building", 1000 )
    return
  }
  MouseGetPos,X,Y
  xshift := 0, yshift := 0
  if (A_ThisHotkey = "~LButton & RButton")
  {
    xshift := X > A_ScreenWidth-150 ? 4 : -4
    yshift := Y > A_ScreenHeight-250 ? 4 : -4
  }
  glb[ "ActiveWinHWND" ] := WinExist( "A" )
  if ( label = "MainMenu" )
    GetDesktopSelection( glb[ "ActiveWinHWND" ] )	;main
  if label in MainMenu,ClipsMenu
    ClipsCheck()
  menu := label = "MainMenu" ? qcMainMenu
          : label = "ClipsMenu" ? qcClipsMenu
          : label = "MemosMenu" ? qcMemosMenu
          : label = "WinsMenu" ? qcWinsMenu
          : label = "RecentMenu" ? qcRecentMenu : ""
  if qcPUM.IsMenuShown
  {
    menu.EndMenu()
    return
  }
  menu.Show( x, y )
}

GestureProcessing( hk )
{
  if ( hk != GestureGetHK() )
    return
  gesture := MG_Recognize( qcOpt[ "gest_curBut" ], 4, 0, 1 )
  if ( gesture = qcOpt[ "clips_gesture" ] && qcOpt[ "clips_gestOn" ] && qcOpt[ "clips_on" ] )
    Gosub, ClipsMenu
  else if ( gesture = qcOpt[ "main_gesture" ] && qcOpt[ "main_gestOn" ] )
    Gosub, MainMenu
  else if ( gesture = qcOpt[ "wins_gesture" ] && qcOpt[ "wins_gestOn" ] && qcOpt[ "wins_on"] )
    Gosub, WinsMenu
  else if ( gesture = qcOpt[ "Memos_Gesture" ] && qcOpt[ "memos_gestOn" ] && qcOpt[ "Memos_On" ] )
    Gosub, MemosMenu
  else if ( gesture = qcOpt[ "Recent_Gesture" ] && qcOpt[ "recent_gestOn" ] && qcOpt[ "recent_on" ] )
    Gosub, RecentMenu
  return
}

QCPathMakeRelative( path )
{
  dRet := QCRemoveSpecials( path )
  path := dRet["cmd"]
  args := PathGetArgs( path )
  if args
    path := PathRemoveArgs( path )
  path := PathRelativeTo( path )
  path := dRet["prefix"] path (args ? " " args : "") dRet["postfix"]
  return path
}

QCPathMakeFull( path )
{
  dRet := QCRemoveSpecials( path )
  path := dRet["cmd"]
  args := PathGetArgs( path )
  if args
    path := PathRemoveArgs( path )
  path := PathResolve( path )
  path := dRet["prefix"] path (args ? " " args : "") dRet["postfix"]
  return path
}

GetShortCmdList( tg )
{
  for i,cmd in StrSplit( tg, glb[ "optMTDivider" ], A_Tab A_Space )
  {
    str := strlen(cmd)>100 ? substr(cmd,1,100) . "..." : cmd
    targets_list .= ( i=1 ? "" : "`n" ) . str
  }
  return targets_list
}

GetFullCmdList( tg )
{
  return StrSplit( tg, glb[ "optMTDivider" ], A_Tab A_Space )
}

ExitQC(wParam, lParam, msg, hwnd)
{
  ExitApp
  return
}

QCLoadLibs()
{
  DllCall( "LoadLibraryW", "Wstr", "msi.dll", "UPtr" )
  DllCall( "LoadLibraryW", "Wstr", "Shlwapi.dll", "UPtr" )
  DllCall( "LoadLibraryW", "Wstr", "msvcrt.dll", "UPtr" )
  DllCall( "LoadLibraryW", "Wstr", "Gdi32.dll", "UPtr" )
  DllCall( "LoadLibraryW", "Wstr", "Comctl32.dll", "UPtr" )
}

QCFreeMem()
{
  SetTimer( "QCFreeMem_T", 5000 )
  return
}

QCFreeMem_T( p* )
{
  SetTimer( A_ThisFunc, "OFF" )
  if !( IsWindowVisible( qcGui[ "clips" ] )
          || IsWindowVisible( qcGui[ "memos" ] )
          || IsWindowVisible( qcGui[ "help" ] )
          || IsWindowVisible( qcGui[ "main" ] ) )
    Emptymem()
  return 1
}

QCGetFirstTarget( tg )
{
  if InStr( tg, glb[ "optMTDivider" ] )
    tg := StrSplit( tg, glb[ "optMTDivider" ], A_Space A_Tab )[1]
  return tg
}

QCGetDir( tg )
{
  if ( tg := QCGetFirstTarget( tg ) )
  {
    tg := QCRemoveSpecials( tg )["cmd"]
    regex = i)^\s*"*\s*shell:.*$
    if !RegExMatch( tg, regex ) ; check for Shell:* like folders
      tg := PathResolve( PathGetDir( tg ) ), tg := PathUnquoteSpaces( tg )
    else
      tg := PathParseName( tg )
  }
  if !PathIsDir( tg )
    tg := ""
  return tg
}

QCRestart( fNoNotify = True )
{
  if fNoNotify
    glb[ "fExitNoNotify" ] := 1
  Reload
  ExitApp
}

QCKillProcs( procc2Kill )
{
  for k,v in StrSplit( procc2Kill, ",", A_Space A_Tab )
  {
    ;closing all processes with this name
    while True
    {
      Process, Close,% v
      procPID := ErrorLevel
      if ( procPID = 0 )
        break
      Process, WaitClose,% procPID, 5
    }
  }
}