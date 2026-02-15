class QMsgBox_base
{
  __Call( aTarget, aParams* ) {
    if ObjHasKey( PUM_base, aTarget )
      return PUM_base[ aTarget ].( this, aParams* )
    throw Exception( "Unknown function '" aTarget "' requested from object '" this.__Class "'", -1 )
  }
  
  Err( msg ) {
    throw Exception( this.__Class " : " msg ( A_LastError != 0 ? "`n" this.ErrorFormat( A_LastError ) : "" ), -2 )
  }
  
  ErrorFormat( error_id ) {
    VarSetCapacity(msg,1000,0)
    if !len := DllCall("FormatMessageW"
          ,"UInt",FORMAT_MESSAGE_FROM_SYSTEM := 0x00001000 | FORMAT_MESSAGE_IGNORE_INSERTS := 0x00000200		;dwflags
          ,"Ptr",0		;lpSource
          ,"UInt",error_id	;dwMessageId
          ,"UInt",0			;dwLanguageId
          ,"Ptr",&msg			;lpBuffer
          ,"UInt",500)			;nSize
      return
    return 	strget(&msg,len)
  }
}

class QMsgBoxAPI_base extends QMsgBox_base
{
  __Get( name ) {
    if !ObjHasKey( this, initialized )
      this.Init()
    else
      throw Exception( "Unknown field '" name "' requested from object '" this.__Class "'", -1 )
  }
}

class QMsgBoxAPI extends QMsgBoxAPI_base
{
  HBITMAPfromHICON( hIcon ) {
    VarSetCapacity( ICONINFO, 8 + 3*A_PtrSize, 0 )
    ret := DllCall( "User32\GetIconInfo","Ptr", hIcon, "Ptr", &ICONINFO )
    hbmMask := NumGet( &ICONINFO, 8 + A_PtrSize, "UPtr" )
    DllCall("DeleteObject", "Ptr", hbmMask )
    hbmColor := NumGet( &ICONINFO, 8 + 2*A_PtrSize, "UPtr" )
    return hbmColor
  }
  Gdip_Startup() {
      static hmodule
      if ( !hmodule || !DllCall( "GetModuleHandleW", "Wstr", "gdiplus", "UPtr" ) )
          hmodule := DllCall( "LoadLibraryW", "Wstr", "gdiplus", "UPtr" )
      
      VarSetCapacity(GdiplusStartupInput , 3*A_PtrSize, 0), NumPut(1,GdiplusStartupInput ,0,"UInt") ; GdiplusVersion = 1
      DllCall("gdiplus\GdiplusStartup", "Ptr*", pToken, "Ptr", &GdiplusStartupInput, "Ptr", 0)
      return pToken
  }
  Gdip_Shutdown(pToken) {
      DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
      return 0
  }
  IconExtract( icoPath, size = 32 ) 
  {
      static PrivateExtractIconsW
      if !PrivateExtractIconsW
          PrivateExtractIconsW := this.LoadDllFunction( "user32.dll", "PrivateExtractIconsW" )
      pPath := this.IconGetPath( icoPath )
      pNum := this.IconGetIndex( icoPath )
      pNum := pNum = "" ? 0 : pNum
      ;http://msdn.microsoft.com/en-us/library/ms648075%28v=VS.85%29.aspx
      DllCall(PrivateExtractIconsW, "Str", pPath, "UInt", pNum, "UInt", size, "UInt", size, "Ptr*", handle, "Ptr", 0,"UInt",1, "UInt", 0)
      if !handle
      {
          SplitPath, pPath,,,Ext
          if (Ext = "exe")
              DllCall(PrivateExtractIconsW, "Str", "shell32.dll", "UInt", 2, "UInt", size, "UInt", size, "Ptr*", handle, "Ptr", 0,"UInt",1, "UInt", 0)
      }
      return handle
  }
  LoadDllFunction( file, function ) {
      if !hModule := DllCall( "GetModuleHandleW", "Wstr", file, "UPtr" )
          hModule := DllCall( "LoadLibraryW", "Wstr", file, "UPtr" )
      
      ret := DllCall("GetProcAddress", "Ptr", hModule, "AStr", function, "UPtr")
      return ret
  }
  IconGetPath(Ico)	{
      spec := Ico
      pos := InStr(Ico, ":", 0, 0)
      if (pos > 4)
          spec := substr(Ico,1,pos-1)
      return this.PathUnquoteSpaces( spec )
  }
  IconGetIndex(Ico)	{	
      pos := InStr(Ico, ":", 0, 0)
      if (pos > 4)
      {
          ind := substr(Ico,pos+1)
          if !ind
              ind := 0
          return ind
      }
  }
  PathUnquoteSpaces( path )
  {
      path := Trim( path )
      regex = ^"\K.*(?="$)
      while RegExMatch( path, regex, cmd_new )
          path := cmd_new
      return path
  }
  IsInteger( var )
  {
    if var is integer
      return True
    else 
      return False
  }
  ControlGetClientPos( hwnd )
  {
    GuiControlGet, p, Pos,% hwnd
    VarSetCapacity( RECT, 16, 0 )
    if ( pX < 0 || pY < 0 || pW <= 0 || pH <= 0 )
      return 0
    return { "x" : pX,"y" : pY, "w" : pW, "h" : pH }
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
}



