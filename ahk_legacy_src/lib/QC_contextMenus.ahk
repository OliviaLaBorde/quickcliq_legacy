MenuOnRButton( event, item )
{
  MenuShowContext( item )
  SetTimer( "MenuShowContext", -100 )
  return
}

MenuShowContext( p* )
{
  static s_item
  if IsObject( p )
  {
    s_item := p[1]
    return
  }
  SetTimer( A_ThisFunc, "OFF" )
  menuc := qcPum.CreateMenu( { iconssize : 16 } )
  if ( s_item.uid = "FolderMenu_Item" ) {
    Gui,PUM_MENU_GUI:+LastFoundExist
    ShellContextMenu( s_item.FM_Target,WinExist() )
  }
  else if RegExMatch( s_item.uid, "iO)Memos_([0-9]+)", match )
  {
    MakeMemosMenu( menuc )
    MouseGetPos,X,Y
    if ( oItem := menuc.Show( x,y, "context" ) )
      MemosActions( oItem.ctx_uid, match[1] )
  }
  else if RegExMatch( s_item.uid, "iO)Clips_Sub([0-9])", match )
  {
    clipNum := match[ 1 ]
    clip := qcClips[ clipNum ]
    isClipEmpty := clip[ clipNum ? "iIsEmpty" : "IsEmpty" ]()
    fHasFormat := clipNum ? "iHasFormat" : "HasFormat"
    ; ---
    menuc.add( { name : "Edit", uid : "CtxItem", ctx_uid : "Clips_View" } )
    if clipNum
      menuc.add( { name : "To Clipboard", uid : "CtxItem",  ctx_uid : "Clips_ToSysClip", disabled : isClipEmpty ? 1 : 0 } )
    tofilesub := qcPUM.CreateMenu( { iconssize : 16 } )
    tofilesub.add( { name : "Text", uid : "CtxItem",  ctx_uid : "Clips_ToFileText"
                   , disabled : isClipEmpty ? 1 : ( clip[ fHasFormat ]( 13 ) || clip[ fHasFormat ]( 15 ) ? 0 : 1 ) } )
    tofilesub.add( { name : "Html", uid : "CtxItem",  ctx_uid : "Clips_ToFileHTML"
                   , disabled : isClipEmpty ? 1 : ( clip[ fHasFormat ]( "HTML Format" ) ? 0 : 1 )} )
    tofilesub.add( { name : "Bitmap", uid : "CtxItem",  ctx_uid : "Clips_ToFileBitmap"
                   , disabled : isClipEmpty ? 1 : ( clip[ fHasFormat ]( 8 ) ? 0 : 1 )} )
    tofilesub.add( { name : "Binary", uid : "CtxItem",  ctx_uid : "Clips_ToFileBinary"
                   , disabled : isClipEmpty ? 1 : 0 } )
    menuc.add( { name : "To File", submenu : tofilesub } )
    menuc.add( { name : "Run Links", uid : "CtxItem",  ctx_uid : "Clips_RunLinks", disabled : isClipEmpty ? 1 : 0 } )
    menuc.Add()
    menuc.add( { name : "Clear", uid : "CtxItem",  ctx_uid : "Clips_Clear", disabled : isClipEmpty ? 1 : 0 } )
    MouseGetPos,X,Y
    oItem := menuc.Show( x,y, "context" )
    if oItem
      ClipsActions( oItem.ctx_uid clipNum )
  }
  else if IsInteger( s_item.uid )
  {
    IsSep := s_item.issep
    IsMenu := qcconf.IsMenu( s_item.uid )
    itemName := IsSep ? "Separator" : s_item.name
    menuc.Add( { name : itemName, disabled : 1, bold : 1, uid : "CtxItem" } )
    menuc.Add()
    if !( IsSep || IsMenu )
    {
      cmdMenu := qcPum.CreateMenu( { noicons : 1 } )
      for i,cmd in GetFullCmdList( qcconf.GetItemCmdByID( s_item.uid ) )
      {
        name := StrLen( cmd ) > glb[ "CtxMaxCmdLen" ] 
              ? SubStr( cmd, 1, glb[ "CtxMaxCmdLen" ] ) ".." : cmd
        cmdMenu.Add( { name : name, uid : "CtxItem", ctx_uid : "Cmd", ctx_cmd : cmd } )
      }
      menuc.Add( { name : "Run", uid : "CtxItem", ctx_uid : "Run" } )
      menuc.Add( { name : "Open Location", uid : "CtxItem", ctx_uid : "Location" } )
      menuc.Add( { name : "Commands", uid : "CtxItem", ctx_uid : "CmdMenu", submenu : cmdMenu } )
      menuc.Add( { name : "Switch To", uid : "CtxItem", ctx_uid : "Switch" } )
    }
    if !glb[ "fSMenuRun" ]
      menuc.Add( { name : "Edit", uid : "CtxItem", ctx_uid : "Edit" } )
    if( s_item.assocMenu.FolderMenu )
    {
      menuc.Add()
      menuc.Add( { name : "Refresh Menu", uid : "CtxItem", ctx_uid : "FM_Refresh" } )
    }
    menuc.Add()
    menuc.Add( { name : "Delete", uid : "CtxItem", ctx_uid : "Del" } )
    MouseGetPos,X,Y
    if( oItem := menuc.Show( x,y, "context" ) )
      MenuContextProc( oItem, s_item )
  }
  menuc.Destroy()
  sleep 30  ;with this delay first click outside of context menu will not run the item
  return
}

OpenItemLocation( ItemUID )
{
  path := QCGetFirstTarget( qcconf.GetItemCmdByID( ItemUID ) )
  path := QCRemoveSpecials( path )["cmd"]
  if !FileExist( path )
    path := PathRemoveArgs( path )
  if path
  {
    path := "explorer /select," path
    RunCommand( { cmd : path, nolog : True , noctrl : True , noshift : True } )
  }
  return
}

MenuContextProc( chItem, hvItem )
{
  sleep 30 ;to let menu redraw itself and regain focus
  uid := chItem.ctx_uid
  if( uid = "Run" )
    qcCmdThread( hvItem )
  else if( uid = "Edit" )
    QCEditItem( hvItem )
  else if( uid = "Del" )
  {
    GUI_Main_TV_DelByID( hvItem.uid )
    hvItem.Destroy()
  }
  else if( uid = "Cmd" )
    RunCommand( { cmd : chItem.ctx_cmd, nolog : 1 } )
  else if( uid = "Switch" )
    ChangeFolderTo( glb[ "ActiveWinHWND" ], qcconf.GetItemCmdByID( hvItem.uid ) )
  else if( uid = "FM_Refresh" )
    FM_Reset( hvItem.assocMenu )
  else if( uid = "Location" )
    OpenItemLocation( hvItem.uid )
  return
}

MakeMemosMenu( oMenu )
{
  sleep 30 ;to let menu redraw itself and regain focus
  oMenu.Add( { name : "Edit", uid : "CtxItem", ctx_uid : "Memos_edit" } )
  oMenu.Add( { name : "Show On Top", uid : "CtxItem", ctx_uid : "Memos_showontop" } )
  oMenu.Add( { name : "E-mail", uid : "CtxItem", ctx_uid : "Memos_email" } )
  oMenu.Add( { name : "To Clipboard", uid : "CtxItem", ctx_uid : "Memos_clip" } )
  oMenu.Add( { name : "To File", uid : "CtxItem", ctx_uid : "Memos_tofile" } )
  return
}