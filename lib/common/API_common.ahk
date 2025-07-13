IL_GetIcon(hIL,ind)
{
	return dllcall("ImageList_GetIcon","Ptr",hIL,"Uint",ind,"Uint",0x00000001,"UPtr")	;ILD_TRANSPARENT
}

IL_CreateNew( width, height, initVal=10,growVal=5)
{
	return dllcall("ImageList_Create","Uint",width,"Uint",height,"Uint",0x00000020 | 0x00000001,"Uint",initVal,"Uint",growVal,"UPtr")	;ILC_COLOR32 + ILC_ORIGINALSIZE + ILC_MASK
}

IL_AddMasked( hIL, hBitmap, mask )
{
  return dllcall( "ImageList_AddMasked","UPtr",hIL,"UPtr",hBitmap,"UInt",mask )
}

IL_AddBitmap( hIL, hBitmap )
{
  return dllcall( "ImageList_Add", "Ptr", hIL, "Ptr", hBitmap, "Ptr", 0 )
}

IL_AddIcon(hIL,hIcon,ind=-1,erase=1) ;ind -1 to add icon to the end of list
{
	ret := dllcall("ImageList_ReplaceIcon","UPtr",hIL,"Uint",ind,"UPtr",hIcon,"Uint")
	if erase
      DestroyIcon( hIcon )
	return 
}

IL_Remove( hIL, ind )
{
  return dllcall( "ImageList_Remove", "UPtr", hIL, "Uint", ind )
}

LoadDllFunction( file, function ) {
    if !hModule := DllCall( "GetModuleHandleW", "Wstr", file, "UPtr" )
        hModule := DllCall( "LoadLibraryW", "Wstr", file, "UPtr" )
	
    ret := DllCall("GetProcAddress", "Ptr", hModule, "AStr", function, "UPtr")
	return ret
}

SendMessage( hWnd, Msg, wParam, lParam )
{
   static SendMessageW

   If not SendMessageW
      SendMessageW := LoadDllFunction( "user32.dll", "SendMessageW" )

   ret := DllCall( SendMessageW, "UPtr", hWnd, "UInt", Msg, "UPtr", wParam, "UPtr", lParam )
   return ret
}

GUID(ByRef GUID, sGUID) ; Converts a string to a binary GUID and returns its address.
{
    VarSetCapacity(GUID, 16, 0)
    return DllCall("ole32\CLSIDFromString", "wstr", sGUID, "ptr", &GUID) >= 0 ? &GUID : ""
}

memcopy( dst, src, cnt ) {
  return DllCall("MSVCRT\memcpy", "Ptr", dst, "Ptr", src, "uint", cnt)
}

HBITMAPfromHICON( hIcon )
{
  VarSetCapacity( ICONINFO, 8 + 3*A_PtrSize, 0 )
  ret := DllCall( "User32\GetIconInfo","Ptr", hIcon, "Ptr", &ICONINFO )
  hbmMask := NumGet( &ICONINFO, 8 + A_PtrSize, "UPtr" )
  DllCall("DeleteObject", "Ptr", hbmMask )
  hbmColor := NumGet( &ICONINFO, 8 + 2*A_PtrSize, "UPtr" )
  return hbmColor
}

GlobalSize( hObj )
{
  return DllCall( "GlobalSize", "Ptr", hObj )
}

GlobalLock( hMem )
{
  return DllCall( "GlobalLock", "Ptr", hMem )
}

GlobalUnlock( hMem )
{
  return DllCall( "GlobalUnlock", "Ptr", hMem )
}

GlobalAlloc( flags, size )
{
  return DllCall( "GlobalAlloc", "Uint", flags, "Uint", size )
}

RegRead( regclass, regsubkey, valuename = "" )
{
  RegRead, value,% regclass,% regsubkey,% valuename
  return value
}

RegDelete( regclass, regsubkey, valuename = "" )
{
  RegDelete,% regclass,% regsubkey,% valuename
}

RegWrite( regtype, regclass, regsubkey, regvaluename = "", regvalue= "" )
{
  RegWrite,% regtype,% regclass,% regsubkey,% regvaluename,% regvalue
}

GetDeviceCaps( hWnd = 0, flags = 90 )
{
  return DllCall( "GetDeviceCaps", "Ptr", DllCall( "GetDC", "Ptr", hWnd ), "uint", flags )
}

MulDiv( a, b, c )
{
  return DllCall( "MulDiv", "int", a, "int", b, "int", c )
}

CloseHandle( handle )
{
  return DllCall( "CloseHandle", "Ptr", handle )
}