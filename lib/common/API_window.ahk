IsWindowVisible( winHWND )
{
  return DllCall( "IsWindowVisible", "Ptr", winHWND )
}

IsWindowEnabled( winHWND )
{
  return DllCall( "IsWindowEnabled", "Ptr", winHWND )
}

IsWindow( winHWND )
{
  return DllCall("IsWindow", "Ptr", winHWND )
}

ShowWindow( winHWND, mode = 5 )
{
  return DllCall( "ShowWindow", "Ptr", winHWND, "Uint", mode )
}

HideWindow( winHWND )
{
  return DllCall( "ShowWindow", "Ptr", winHWND, "Uint", 0 )
}

DestroyWindow( hwnd )
{
  return DllCall( "DestroyWindow", "Ptr", hwnd )
}

IsWinTopmost( hwnd )
{
  WinGet, ret, ExStyle, ahk_id %hwnd%
  return ret & 0x8 ? True : False
}

WinGetPos( handle )
{
  DetectHiddenWindows, On
  WinGetPos, X, Y, W, H, ahk_id %handle%
  DetectHiddenWindows, OFF
  if ( X < 0 || Y < 0 || W <= 0 || H <= 0 )
    return ""
  return  { "x" : X,"y" : Y, "w" : W, "h" : H }
}

WinGetClientPos( hwnd )
{
  VarSetCapacity( RECT, 16, 0 )
  if DllCall( "GetClientRect", "Ptr", hwnd, "Ptr", &RECT )
  {
    x := NumGet( RECT, 0, "UInt" )
    y := NumGet( RECT, 4, "UInt" )
    w := x + NumGet( RECT, 8, "UInt" )
    h := y + NumGet( RECT, 12, "UInt" )
    if ( X < 0 || Y < 0 || W <= 0 || H <= 0 )
      return 0
    return { "x" : X,"y" : Y, "w" : W, "h" : H }
  }
  return 0
}

WinShow( Window_Handle )
{
    WinShow, ahk_id %Window_Handle%
}

WinGetClass( winHWND ) 
{
  WinGetClass, WinClass, AHK_ID %winHWND%
  Return WinClass
}

WinSetTrans( hwnd, transp )
{
    WinSet, Transparent, %transp%, ahk_id %hwnd%
}

WinGetTrans( hwnd )
{
  WinGet, transp, Transparent, ahk_id %hwnd%
  return transp
}

WinActivate( Window_Handle )
{
    WinActivate, ahk_id %Window_Handle%
}

WinHide( hwnd )
{
    WinHide, ahk_id %hwnd%
}

WinGetTitle( pHWND )
{
	WinGetTitle, win_title,ahk_id %pHWND%
	return win_title
}

WinSetTitle( pHWND, new_title )
{
  WinSetTitle, ahk_id %pHWND%,,% new_title
  return
}

WinIsMin( hWin )
{
  WinGet, w_st, MinMax,% "ahk_id " hWin
  return ( w_st == -1 )
}

WinIsMax( hWin )
{
  WinGet, w_st, MinMax,% "ahk_id " hWin
  return ( w_st == 1 )
}

WinGetProcID( whwnd )
{
  DllCall("GetWindowThreadProcessId","UPtr",whwnd,"UInt*",pro_id)
  return pro_id
}

;############################### GET ICON HANDLE OF WINDOW
WinGetIcon( hWindow, size ) 
{	
  Winget, WinPID, PID, AHK_ID %hWindow%
  IconHandle := SendMessage( hWindow, 0x7F, 0, 0 )
  if (IconHandle == 0)
    IconHandle := GetModuleFileNameEx( WinPID ) . ":0"
  else
    IconHandle := IconCopy( IconHandle, size, 1, 0 )
  if ( StrLen( IconHandle ) < 4 )
    return "shell32.dll:34"
  else
    return IconHandle
}

WinSetIcon( hWin, hIcon, size = 0 ) ;0 means small
{
  return SendMessage( hWin, 0x0080, size, hIcon )
}

ShellGetWindows()
{
  oWins := object()
  try
    comWins := ComObjCreate("Shell.Application").Windows()
  catch oEx
  {
    if DBG_SHOW_ERRORS
      ShowExc( oEx )
    return
  }
  for win in comWins
  {
    try
      if win.HWND
        oWins.insert( win )
    catch oEx
      if DBG_SHOW_ERRORS
        msgbox % "Failed to retrieve folder:`n" win.LocationName "`nError: " oEx.Message "`nExtra: " oEx.Extra "`nFile: " oEx.File "`nWhat: " oEx.What "`nLine: " oEx.Line
  }
  return oWins
}

WinGetParent( hwnd )
{
  return DllCall( "GetParent", "Ptr", hwnd )
}