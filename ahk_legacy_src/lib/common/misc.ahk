;############################## Empty Memory into Page File
EmptyMem(PID="AHK Rocks") {
    pid:=(pid="AHK Rocks") ? DllCall("GetCurrentProcessId") : pid
    h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
    DllCall("SetProcessWorkingSetSize", "Ptr", h, "Int", -1, "Int", -1)
    DllCall("CloseHandle", "Ptr", h)
  return
}

;convert name like Name23 to Name24
NameGetNext( Name, Count = 3 ) 
{
  if RegExMatch( Name, "\d{1," Count "}(?=\s*$)", num )
  {
    StringTrimRight, name, name, StrLen( num )
    return name . ++num
  }
  return name "1"
}

GetTimeFormat(pStandard,pFormat)
{
  FormatTime, fTime,% pStandard,% pFormat
  return fTime
}

RandColor()
{
  sleep 2
  return Rand(0,255) << 16 | Rand(0,255) << 8 | Rand(0,255)
}

Rand( num_start, num_end )
{
  Random, num,% num_start,% num_end
  return num
}

StrRemoveChars( str, chr)
{
  smb := strsplit(chr,"|",A_TAB A_Space)
  for i,char in smb
    StringReplace, str, str,% char,,1
  return str
}

QueryPerformanceCounter()
{
  DllCall( "QueryPerformanceCounter", "Ptr*", counter )
  return counter
}

/*
HLControl - function allow you to highlight specific ocntrols in window using graphical lines
  w_hwnd - HWND of the window where you like to draw lines
  hwnds - "|" delimeted list of controls hwnds which you like to highlight
  clr,clr2 - two colors for hoghlight

*/
HLControl(w_hwnd,hwnds,clr=0x0000FF,clr2=0xB73443)
{
  WinActivate,ahk_id %w_hwnd%
  Gui, +Disabled
  DC := DllCall("GetWindowDC","Ptr",w_hwnd,"UPtr") ;User32
  Pen := DllCall("CreatePen","Int",0,"Int",3,"UInt",clr,"UPtr")
  Pen2 := DllCall("CreatePen","Int",0,"Int",3,"UInt",clr2,"UPtr")
  obj_orig := DllCall("SelectObject","Ptr",DC,"Ptr",Pen,"UPtr")
  
    if !hModule := DllCall( "GetModuleHandleW", "Wstr", "Gdi32.dll", "UPtr" )
        hModule := DllCall( "LoadLibraryW", "Wstr", "Gdi32.dll", "UPtr" )
  MoveToP := DllCall("GetProcAddress", "Ptr", hModule, "Astr", "MoveToEx","UPtr")
  LineToP := DllCall("GetProcAddress", "Ptr", hModule, "Astr", "LineTo","UPtr")
  VarSetCapacity(pp,16,0)
  hwnd := StrSplit(hwnds,"|",A_Tab A_Space)
  loop, 12
  {
    sleep 10
    for i,hw in hwnd
    {
      ControlGetPos, X, Y, W, H,,% "ahk_id " hw
      DllCall(MoveToP,"Ptr",DC,"Int",X,"Int",Y,"Ptr",&pp)
      DllCall(LineToP,"Ptr",DC,"Int",X+W,"Int",Y)
      DllCall(LineToP,"Ptr",DC,"Int",X+W,"Int",Y+H)
      DllCall(LineToP,"Ptr",DC,"Int",X,"Int",Y+H)
      DllCall(LineToP,"Ptr",DC,"Int",X,"Int",Y)
    }
    sleep 100
    DllCall("SelectObject","Ptr",DC,"UInt",Mod(A_Index,2)=0 ? Pen2 : Pen)
  }
  WinSet,ReDraw,,ahk_id %w_hwnd%		;removing lines at this point
  DllCall("SelectObject","Ptr",DC,"Ptr",obj_orig)
  DllCall("DeleteObject","Ptr",Pen)
  DllCall("DeleteObject","Ptr",Pen2)
  DllCall("ReleaseDC","Ptr",w_hwnd,"Ptr",DC) ;User32

  Gui, -Disabled
  return
}

IsUAC()
{
  RegRead,value,HKLM,Software\Microsoft\Windows\CurrentVersion\Policies\System,EnableLUA
  if ErrorLevel
    value := ErrorLevel
  return value
}

EvalMetaData( str )
{
  while RegExMatch( str, "iO)%(d|dl|t|ym|clip)([+\-]\d+)?%", match )
  {
    c_time := A_Now
    result := ""
    if( match[1] = "clip" )
      result := ClipsGetText( 0 )
    else
    {
      if match[2]
        c_time += match[2], M
      fmt := match[1] = "d" ? "ShortDate"
            : match[1] = "dl" ? "LongDate"
            : match[1] = "t" ? "Time"
            : match[1] = "ym" ? "YearMonth" : ShowExc( "Invalid time format: " match[1] )
      FormatTime, result,% c_time,% fmt
    }
    StringReplace,str,str,% match[0],% result,1
  }
  return str
}

SyntaxHelp()
{
  if A_Gui
    Gui, %A_Gui%:+OwnDialogs
  MsgBox,,Syntax Help,
  (LTrim
You can use following syntax to get dynamic date, time or clipboard values when clip or memo pasted.

`%d`%	  - Short date representation, such as 02/29/04
`%dl`%	  - Long date representation, such as Friday, April 23, 2004
`%t`%	  - Current time representation, such as 5:26 PM
`%ym`%	  - Year and month format, such as February, 2004
`%clip`%	  - The text data of system clipboard
  )
}

StringUpper( string )
{
  StringUpper, out_string, string
  return out_string
}

StringLower( string )
{
  StringLower, out_string, string
  return out_string
}

StringTitle( string )
{
  StringUpper, out_string, string, T
  return out_string
}

StringSentence( string )
{
  return RegExReplace( StringLower( string ), "`a)(\.\s*.|^\s*.|`n\s*.)", "$U0")
}

Str2Int( strNum )
{
  v := 0
  v += strNum
  return v
}

CallStack( offset = -1, deepness = 5, printLines = 1 )
{
  if A_IsCompiled
    return
  ident := "  "
  cnt := 0
  loop,% deepness
  {
    lvl := offset - deepness + A_Index
    oEx := Exception( "", lvl )
    codeLine := Trim( FileReadLine( oEx.file, oEx.line ), "`t " )
    if(oEx.What = lvl)
      continue
    oExPrev := Exception( "", lvl - 1 )
    cnt++
    stack .= ( cnt = 1 ? "" : "`n--`n" )
                  . "File '" oEx.file "', Line " oEx.line ( oExPrev.What < 0 ? "" : ", in " oExPrev.What )
                  . ( printLines ? ":`n" ident codeLine : "" )
  }
  return stack
}

ShowErr( foo, p* )
{
  le := A_LastError
  el := ErrorLevel
  dd := ErrorFormat( le )
  msg := foo " failed:`nEL=" el " LE=" le "`nDescr: " dd
  for k,v in p
  {
    if( k=1 )
      msg .= "`nOther Data:"
    msg .= "`n" k ": " v
  }
  ans := QMsgBoxP( { title : "Error info", msg : msg, pic : "!", "buttons" : "Ok|Skip|Report" } )
  if( ans = "Skip" )
    Exit
  else if( ans = "Report" )
  {
    fb_msg =
    ( LTrim
    Please let us know when does this error happens:
    
    
    ==== Error Text
    %msg%
    ==============
    )
    SendFeedback( fb_msg )
  }
  return
}

ShowExc( exc )
{
  if isObject( exc )
    exc := "Error: " exc.message ( exc.Extra ? "`nExtra: " exc.Extra : "" ) "`n"
  exc .= "`n`n" CallStack( -2 )
  ans := QMsgBoxP( { title : "Exception info", msg : exc, pic : "!", editbox : 1, editbox_w : 500, editbox_h : 300, "buttons" : "Continue|Skip|Report|Quit App", rsz : 1 } )
  if ( "Quit App" = ans )
    ExitApp
  else if ( "Report" = ans )
  {
    fb_msg =
    ( LTrim
    Please let us know when does this error happens:
    
    
    ==== Error Text
    %exc%
    ==============
    )
    SendFeedback( fb_msg )
  }
  else if ( "Continue" != ans )
    Exit
  return 0
}

IsDirModified( sPath,ByRef oDirs = "" )
{
  res := object()
  loop,% PathAppend( sPath, "*" ), 2, 1
    res[ A_LoopFileLongPath ] := A_LoopFileTimeModified
  bResl := 0
  if oDirs
  {
    for path,time in res
      if ( oDirs[ path ] != time )
      {
        bResl := 1
        break
      }
  }
  else
    bResl := 1
  oDirs := res
  return bResl
}