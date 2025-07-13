IconFromExt( ext, isfile = "" )	;getting icon path for specific extension
{
  if isfile
  {
    isfile := PathUnquoteSpaces( isfile )
    splitpath, isfile,,,ext
  }
  if (ext = "exe")
    return isfile . ":0"
  if (ext = "ico")
    return isfile	
  RegRead, extDefApp, HKEY_CLASSES_ROOT, .%ext%
  if extDefApp
  {
    RegRead, iconPath, HKEY_CLASSES_ROOT, %extDefApp%\DefaultIcon
    if !iconPath
    {
      RegRead, extDefApp, HKEY_CLASSES_ROOT, %extDefApp%\CurVer
      RegRead, iconPath, HKEY_CLASSES_ROOT, %extDefApp%\DefaultIcon
    }
  }
  if !iconPath
    RegRead, iconPath, HKEY_CLASSES_ROOT, Unknown\DefaultIcon
  StringReplace,iconPath,iconPath,`",,1
  StringReplace,iconPath,iconPath,`,,:
  if instr(iconPath,"%1")
    return ""
  return iconPath
}

IconLoad(pPath,pSize,type = 1)	;1 - IMAGE_ICON, 2 - IMAGE_CURSOR, 0 - IMAGE_BITMAP
{
  return,  DllCall( "LoadImageW" 
         , "Ptr", 0 
         , "str", pPath
         , "uint", type
         , "int", pSize
         , "int", pSize
         , "uint", 0x10 ) ;| 0x20     ; LR_LOADFROMFILE | LR_TRANSPARENT	
}

IconCopy(handle,size,type = 1,flags = 0x8)	;type: 1 - IMAGE_ICON, 2 - IMAGE_CURSOR, 0 - IMAGE_BITMAP, 0x8 = LR_COPYDELETEORG 	
{
  return DllCall("user32\CopyImage"
          , "Ptr", handle ;image handle
          , "uint", type
          , "int", size
          , "int", size
          , "UInt",flags)		
}

IconExtract( icoPath, size = 32 ) 
{
  static PrivateExtractIconsW
  if !PrivateExtractIconsW
    PrivateExtractIconsW := LoadDllFunction( "user32.dll", "PrivateExtractIconsW" )
  pPath := IconGetPath( icoPath )
  pNum := IconGetIndex( icoPath )
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

IconGetAssociated( pFile, IconIndex = "")
{
  if !IconIndex
    VarSetCapacity(IconIndex,2)
  return DllCall("Shell32\ExtractAssociatedIconW"
        , "Ptr", 0							;A handle to the instance of the application calling the function. 
        , "WStr", pFile						;The full path and file name of the file that contains the icon
        , "UShort*", IconIndex)				;The index of the icon whose handle is to be obtained. 
                          ;If the icon handle is obtained from an executable file, the function stores the icon's identifier in this parameter.
}

IconGetPath(Ico)	{
  spec := Ico
  pos := InStr(Ico, ":", 0, 0)
  if (pos > 4)
    spec := substr(Ico,1,pos-1)
  return PathUnquoteSpaces( spec )
}

IconGetIndex(Ico)	
{	
  pos := InStr(Ico, ":", 0, 0)
  if (pos > 4)
  {
    ind := substr(Ico,pos+1)
    if !ind
      ind := 0
    return ind
  }
}

; return previous icon handle
Icon2Button( hButton, hIcon )
{
  return SendMessage( hButton, BM_SETIMAGE := 0x00F7, 1, hIcon )
}

IconPickDlg( hWin, ByRef sIconPath = "shell32.dll", ByRef nIndex = 0)
{
  if sIconPath
    sIconPath := PathResolve( sIconPath )
  VarSetCapacity( iPath, glb[ "MAX_PATH" ], 0 )
  StrPut( sIconPath, &iPath )

  if DllCall("shell32\PickIconDlg", "Ptr", hWin, "Ptr", &iPath, "Uint", glb[ "MAX_PATH" ], "uint*", nIndex)
  {
    sIconPath := StrGet( &iPath )
    free( iPath )
    return 1
  }
  return 0
}

IconGetRelative( ico )
{
  return PathRelativeTo( IconGetPath( ico ) ) ":" IconGetIndex( ico )
}

DestroyIcon( hIcon )
{
  return DllCall( "DestroyIcon", "Ptr", hIcon )
}

DrawIconEx( hDC, xLeft, yTop, hIcon )
{
    retVal :=  DllCall( "DrawIconEx"
              ,"Ptr", hDC
              ,"int", xLeft
              ,"int", yTop
              ,"Ptr", hIcon
              ,"int",  0 ;cxWidth
              ,"int",  0 ;cyWidth
              ,"uint", 0 ;istepIfAniCur
              ,"Ptr", 0 ;hbrFlickerFreeDraw
              ,"uint", 3 ) ;diFlags
  return retVal
}

IconGetFromPath( sPath, ByRef out_ext = "" )
{
  sIcon := ""
  if PathIsDir( sPath )
    sIcon := glb[ "icoFolder" ]
  else if ( fileExt := PathGetExt( sPath ) )
  {
    out_ext := fileExt
    if  ( fileExt = "lnk" )
    {
      PathShortcutGet( sPath, sTarget, sIcon, False )
      if( !sIcon && sTarget )
        sIcon := IconGetFromPath( PathUnquoteSpaces( sTarget ) )
    }
    else if ( fileExt = "ico" )
      sIcon := sPath
    else if ( fileExt = "exe" )
      sIcon := sPath ":0"
    else
      sIcon := IconFromExt( fileExt )
  }
  return sIcon
}