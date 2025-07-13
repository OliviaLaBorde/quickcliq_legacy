ClipsAddMenu( objMenu )
{
  qcClipsMenu.Destroy()
  ClipsHotkeys( 0 )
  if !qcOpt[ "clips_on" ]
  {
    ClipsClearAll( True )
    return
  }
  
  clipsMenuParams := { iconssize : toInt( 16 )
          ,tcolor    : NodeGetColor( "mtcolor", qcconf.GetMenuNode() )
          ,bgcolor   : NodeGetColor( "mbgcolor", qcconf.GetMenuNode() )
          ,textoffset: glb[ "menuIconsOffset" ]
          ,noicons   : qcOpt[ "aprns_lightMenu" ]
          ,nocolors  : qcOpt[ "aprns_lightMenu" ]
          ,notext    : 0
          ,ymargin   : 3 + toInt( qcOpt[ "aprns_heightAdjust" ] ) }
  
  qcClipsMenu := qcPUM.CreateMenu( clipsMenuParams )
                  
  Loop, 10
  {
    num := A_Index = 10 ? 0 : A_Index
    if ( num = 0 )
    {
      qcClipsMenu.Add()
      qcClipsMenu.add( { name : "System Clipboard", uid : "Clips_Sub" num } )
    }
    else
      qcClipsMenu.add( { name : "Clip " . num, uid : "Clips_Sub" num } )
  }
  qcClipsMenu.Add()
  qcClipsMenu.add( { name : "Clear All", icon : glb[ "icoClipClearAll" ], uid : "Clips_ClearAll" } )

  if qcOpt[ "clips_sub" ]
  {
    objMenu.Add( { name : glb[ "clipsName" ]
                , icon : glb[ "icoClips" ]
                , uid : "Clips"
                , ClipsID : glb[ "clipsItemID" ]
                , submenu : qcClipsMenu
                , break : IsNewCol( objMenu, glb[ "mItemsNum" ] ) } )
  }
  ClipsHotkeys( 1 )
  return
}


ClipsCheck() 
{
  Loop, 10
  {
    num := A_Index - 1
    clip := qcClips[ num ]
    isClipEmpty := clip[ num ? "iIsEmpty" : "IsEmpty" ]()
    fHasFormat := num ? "iHasFormat" : "HasFormat"
    qcPUM.GetItemByUID( "Clips_Sub" num ).SetParams( { icon : isClipEmpty ? 0 : glb[ "icoClipData" ] } )
  }
}

ClipsClear( clipNum, silent = 0 )
{
  if ( clipNum = 0 )
    qcClips[ clipNum ].Clear()  ;clearing windows clipboard
  else
    qcClips[ clipNum ].iClear()
  if !silent
  {
    qcPUM.GetItemByUID( "Clips_Sub" clipNum ).SetParams( { icon : 0 } )
    DTP( clipNum = 0 ? "System clipboard has been cleared" : "Clip # " . clipNum . " has been cleared")
  }
  return
}

ClipsClearAll( silent = False )
{
  qcClipsSubs := object()
  Loop, 9
    ClipsClear( A_Index, 1 )
  if !silent
    DTP("The extra clipboards have been cleared")
  Return
}

ClipsActions( uid )
{
  if ( uid = "Clips_ClearAll" )
    ClipsClearAll()
  else
  {
    ClipNum := SubStr( uid, 0 )
    if instr( uid, "View" )
      ClipsGui( clipNum )
    else if instr( uid, "ToSysClip" )
      ClipToSysClip( clipNum )
    else if InStr( uid, "ToFileText" )
      ClipsToFile( ClipNum, "text" )
    else if InStr( uid, "ToFileHTML" )
      ClipsToFile( ClipNum, "html" )
    else if InStr( uid, "ToFileBitmap" )
      ClipsToFile( ClipNum, "bitmap" )
    else if InStr( uid, "ToFileBinary" )
      ClipsToFile( ClipNum, "binary" )
    else if InStr( uid, "Clear" )
      ClipsClear( ClipNum )
    else if InStr( uid, "RunLinks" ) 
      StrGetLinks( ClipsGetText( ClipNum, True ), True )
  }
  return
}

Clip_Catch( clipnum ) 
{
  if qcClips[ clipnum ].iCopy( glb[ "copyTO" ], qcOpt[ "gen_copy_method" ] )
    DTP( "Copied to Clip " . clipnum, 1000 )
  else
    DTP( "Nothing to copy!", 1000 )
  ClipsGui( clipnum, True )
  return
}

Clip_Send( clipnum ) 
{
  if !qcClips[ clipnum ].iPaste( qcOpt[ "gen_paste_method" ] )
    DTP( "Clip Empty!", 1000 )
  return
}

Clip_Append( clipnum ) 
{
  qcClips[ 0 ].Snap( data )
  qcClips[ 0 ].Clear()
  qcClips[ 0 ].Copy( glb[ "copyTO" ], qcOpt[ "gen_copy_method" ] )
  textData := qcClips[ 0 ].GetText()
  qcClips[ 0 ].Restore( data )
  if textData
  {
    curClip := qcClips[ clipnum ]
    curData := curClip.iGetText()
    curClip.iClear()
    curClip.iSetText( curData . ( curData ? "`n" : "" ) . textData )
    DTP("Text appended to Clip " . clipnum,1000)
  }
  else
    DTP("Nothing to append!",1000)
  ClipsGui( clipnum, True )
  return
}

ProcessClipsCommand( hkey )
{
  ClipNum := SubStr( hkey, 0 )
  hkey := SubStr( hkey, 1, -1 )
  if ( hkey = qcOpt[ "Clips_CopyHK" ] )
    Clip_Catch( ClipNum )
  else if ( hkey = qcOpt[ "Clips_AppendHK" ] )
    Clip_Append( ClipNum )
  else if ( hkey = qcOpt[ "Clips_PasteHK" ] )
    Clip_Send( ClipNum )
  return
}