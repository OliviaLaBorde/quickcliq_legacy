ClipsHotkeys( state )
{
  Loop, 9
  {
    if qcOpt[ "Clips_CopyHK" ] {
      if ( err := Hotkey( qcOpt[ "Clips_CopyHK" ] A_Index, state, "ClipsHotkeys" ) )
        QMsgBoxP( { title : "Clips copy hotkey error", msg : err, pic : "x" } )
    }
    if qcOpt[ "Clips_AppendHK" ] {
      if ( err := Hotkey( qcOpt[ "Clips_AppendHK" ] A_Index, state, "ClipsHotkeys" ) )
        QMsgBoxP( { title : "Clips append hotkey error", msg : err, pic : "x" } )
    }
    if qcOpt[ "Clips_PasteHK" ] {
      if ( err := Hotkey( qcOpt[ "Clips_PasteHK" ] A_Index, state, "ClipsHotkeys" ) )
        QMsgBoxP( { title : "Clips paste hotkey error", msg : err, pic : "x" } )
    }
  }
  if ( err := Hotkey( qcOpt[ "clips_hotkey" ], state, "ClipsMenu" ) )
    QMsgBoxP( { title : "Clips hotkey error", msg : err, pic : "x" } )
  return
}

ClipsToFile( clipNum, type, ParentGui = 0 )
{
  if ParentGui
    Gui,% ParentGui ":+OwnDialogs"
  ext := type = "text" || type = "binary" ? "txt" : type = "html" ? "html" : type = "bitmap" ? "png" : "bin"
  fileName := "clip_" clipNum "_" type "." ext
  FileSelectFile, o_file, s16,% fileName
  If Errorlevel
    Return 0
  fprefix := clipNum = 0 ? "" : "i"
  clip := qcclips[ clipNum ]
  if ( type = "bitmap" )
    clip[ fprefix "SaveBitmap" ]( o_file, "png" )
  else
  {
    if ( type = "text" )
      clipData := clip[ fprefix "GetText" ]() . clip[ fprefix "GetFiles" ]()
    else if ( type = "html" )
      clipData := clip[ fprefix "GetHTML" ]()
    else if ( type = "binary" )
      clipSize := clip[ clipNum = 0 ? "Snap" : "iGetData" ]( clipData )
    if ( clipData = "" )
    {
      DTP( "Nothing to save!", 2000 )
      return 0
    }
    f := FileOpen( o_file, 5, type = "text" ? "UTF-16" : "CP0" )
    if !IsObject(f) {
      DTP("Could not open file for saving.")
      return 0
    }
    bytes := type = "binary" ? f.RawWrite( clipData, clipSize ) : f.Write( clipData )
    f.Close()
  }
  DTP((clipnum = 0 ? "System clipboard" : "Clip # " . clipnum) . " has been saved to `n" . o_file, 2000 )
  return bytes
}

GetClipPreview( clipNum )
{
  textData := ClipsGetText( clipNum )
  if ( textData = "")
    textData := "Empty!"
  else if (StrLen( textData ) > 100)
    textData := SubStr( textData, 1, 100 ) . "`n..."
  return textData
}

ClipsGetText( ClipNum, IncludeExtra = False )
{
  clip := qcclips[ ClipNum ]
  pfx := ClipNum = 0 ? "" : "i"
  sData := clip[ pfx "GetText" ]() clip[ pfx "GetFiles" ]()
                  . ( IncludeExtra ? clip[ pfx "GetHtml" ]() : "" )
  return sData
}

StrGetLinks( sData, DoRun = False )
{
  if !sData
    return
  links := object()
  Loop
  {
    if !RegExMatch( sData, "`ai)((http|https|ftp)://|www\.)(.+?)(?=($|[\s<>""``,\(\)]))", link )
      break
    StringReplace,sData,sData,% link,,0
    links.insert( URLEscape( link ) )
  }
  if !links[ 1 ]    ;just check
  {
    DTP( "No links found!" )
    return
  }
  links := RemoveDubls( links )
  if DoRun
  {
    runList := Arr2Str( links, glb[ "optMTDivider" ] )
    RunCommand( { cmd : runList, name : "Clips Links", noctrl : 1, noshift : 1 } )
  }
  return Arr2Str( links, "`n" )
}

SaveClips()
{
  IfNotExist,% glb[ "clipsDir" ]
    FileCreateDir,% glb[ "clipsDir" ]
  Loop,9
  {
    sPath := glb[ "clipsDir" ] "\clip_" A_Index ".bin"
    FileDelete,% sPath
    qcclips[ A_Index ].iSave( sPath )
  }
  return
}

RestoreClips()
{
  Loop,9
    qcclips[ A_Index ].iLoad( glb[ "clipsDir" ] "\clip_" A_Index ".bin" )
  return
}

RemoveNulls(byref string)
{
  temp := string
  Loop,% VarSetCapacity(string)/2	
  {
    dec := NumGet(temp, (A_Index-1)*2, "UShort")
    if (dec = 0)
      NumPut(32,temp, (A_Index-1)*2, "UShort") 
  }
  return temp
}

ClipToSysClip( clipNum )
{
  if !clipNum
    return
  t_clip := qcClips[ clipNum ]
  t_clip.iGetData( clipData )
  WinClip.Restore( clipData )
  return
}

ClipToWindow( clipNum, win_hwnd )
{
  t_clip := qcClips[ clipNum ]
  if t_clip[ clipNum ? "iIsEmpty" : "IsEmpty" ]()
  {
    DTP( "Clip empty!", 1000 )
    return
  }
  PUM_Menu.EndMenu()
  WinActivate, ahk_id %win_hwnd%
  WinWaitActive, ahk_id %win_hwnd%, , 1
  if clipNum
    ret := t_clip.iPaste( qcOpt[ "gen_paste_method" ] )
  else
    ret := t_clip.Paste( "", qcOpt[ "gen_paste_method" ] )
  if !ret
    DTP( "Could not send to the window.`nPlease try again.", 1000 )
  return
}
