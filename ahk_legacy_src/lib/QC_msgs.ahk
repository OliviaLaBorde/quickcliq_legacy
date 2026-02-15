IPCProcessMsg( wParam, lParam, msg, hwnd )
{
  pTxt := NumGet( lParam+0,2*A_PtrSize,"UPtr" )
  if( sData := StrGet( pTxt, "UTF-16" ) )
  {
    mode := SubStr( sData, 1, 7 )
    sData := RegExReplace( sData, "^.{7}" )
    if( mode = "{ADDSH}" )  ; add new shortcut
    {
      Gui_AddSh_AddTimer( sData )
      SetTimer( "Gui_AddSh_AddTimer", 50 )
    }
  }
  return True
}

IPCSendMsg( sMsg )
{
  wmg := WMIObj()
  query := "SELECT * FROM Win32_Process WHERE ProcessId != '" DllCall( "GetCurrentProcessId" ) "' AND Name = '" A_ScriptName "'"
  /*
  WM_COPYDATA                     0x004A
  typedef struct tagCOPYDATASTRUCT {
  ULONG_PTR dwData;
  DWORD     cbData;
  PVOID     lpData;
} COPYDATASTRUCT, *PCOPYDATASTRUCT;
  */
  VarSetCapacity( scd, 3*A_PtrSize, 0 )
  sLen := StrLen( sMsg )*2+2
  NumPut( sLen, scd, A_PtrSize, "UInt" )
  NumPut( &sMsg, scd, 2*A_PtrSize, "UPtr" )

  Prev_DetectHiddenWindows := A_DetectHiddenWindows
  Prev_TitleMatchMode := A_TitleMatchMode
  DetectHiddenWindows, On
  SetTitleMatchMode 2
  result := False
  for proc in wmg.ExecQuery( query )
  {
    pid := proc.ProcessId
    hWnd := WinExist( "ahk_pid " pid " ahk_class AutoHotkey" )
    if hWnd
      if SendMessage( hWnd, 0x004A, 0, &scd )
        result := True
  }
  DetectHiddenWindows %Prev_DetectHiddenWindows%  ; Restore original setting for the caller.
  SetTitleMatchMode %Prev_TitleMatchMode%         ; Same.
  return result
}