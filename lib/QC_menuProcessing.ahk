MenuRunCommand( event, item )
{
  if( item.uid = "CtxItem" )
    return
  qcCmdThread( item )
  return
}

ProcessCustomHotkey( hotk )
{
  for i,hk in HotkeyFromVK( hotk )
    if ( itemID := qcCustomHotkeys[ hk ] )
      if ( item := qcPUM.GetItemByID( itemID ) )
      {
        qcCmdThread( item, 1 )
        break
      }
  return
}

MenuOnInit( event, menu )
{
  if menu.FolderMenu
  { 
    FM_CheckMenuTime( menu )
    if !menu.FM_Built
      FM_BuildMenu( menu )
  }
  return
}

MenuOnUninit( event, menu )
{
  SetTimer( "MenuOnSelect_Tooltip", "OFF" )
  Tooltip,,,,7
  SetTimer,MenuOnUninit_Timer, -200
  return
  
  MenuOnUninit_Timer:
    WinsPreview( False )
    return
}

MenuOnSwitch( event, menu )    ;handle PUM events onshow, onclose
{
  if ( event = "onshow" )
  {
    if !( qcOpt[ "aprns_transp" ] ~= "^(255||0)$" )
      SetTimer( "MenuTranspCheck", 10 )
  }
  else if ( event = "onclose" )
    SetTimer( "MenuTranspCheck", "OFF" )
}

MenuTranspCheck( p* )
{
  Thread, interrupt, 0
  target_transp := qcOpt[ "aprns_transp" ]
  DetectHiddenWindows, On
  IfWinExist, ahk_class #32768
  {
    WinGet,transp_level, Transparent, ahk_class #32768
    if ( transp_level = target_transp )
      return
    WinSet, Transparent,% target_transp, ahk_class #32768
  }
  return
}

MenuOnMButton( event, item )
{
  if( IsInteger( item.uid ) && !item.assocMenu )
    ChangeFolderTo( glb[ "ActiveWinHWND" ], qcconf.GetItemCmdByID( item.uid ) )
  else if( item.uid = "CtxItem" && item.ctx_uid = "Cmd" )
    ChangeFolderTo( glb[ "ActiveWinHWND" ], item.ctx_cmd )
  return
}

MenuOnSelect( event, item )
{
  static TooltipData, sel_Item
  sel_Item := item
  SetTimer, MenuOnSelect_Handler, -1
  return
  
  MenuOnSelect_Handler:
    SetTimer( "MenuOnSelect_Tooltip", "OFF" )
    Tooltip,,,,7
    uid := sel_Item.uid, tlpDelay := 30, TooltipData := ""
    ctrl_pressed := GetKeyState("CTRL","P")
    WinsPreview( False )    ;disabling any shown windows preview
    if sel_Item.assocMenu
      return
    
    if ( uid = "CtxItem" && sel_Item.ctx_uid = "Cmd"           ;means this is context menu item
      && StrLen( sel_Item.ctx_cmd ) > glb[ "CtxMaxCmdLen" ] )  
      tlpDelay := 500,TooltipData := sel_Item.ctx_cmd
    else if ctrl_pressed
    {
      if ( InStr( uid, "wins_" ) && RegExMatch( uid, "^wins_[0-9a-fA-FxX\-]+$" ) )
        WinsPreview( SubStr( uid, 6 ) )
      else
      {
        TooltipData := uid = "QCEditor" ? "Allows you to add/change menu items, colors and settings`n`nctrl+win+click - exit " glb[ "appName" ]
          : uid = "Recent_Cmd" ? GetTimeFormat( sel_Item.Recent_CmdTime, "h:mm:ss dd/MM" ) "`n" sel_Item.Recent_Cmd
          : uid = "QuickHelp" ? "List of enabled features, hotkeys, gestures"
          : IsInteger( uid ) ? sel_Item.name "`n`nCommands:`n" GetShortCmdList( qcconf.GetItemCmdByID( uid ) )
          : RegExMatch( uid,"^Memos_[0-9]+$") ? GetMemoPreview( SubStr( uid, 7 ) )
          : uid = "HK_Susp" ? "Suspend all hotkeys except Main Menu hotkey`nUseful in certain applications like Photoshop or games"
          : uid = "GS_Susp" ? "Suspend all mouse gestures`n`nCTRL + Click - Temporarily suspend gestures for " qcOpt[ "gest_time" ]/1000 " second(s)`nYou may set the delay time in the settings"
          : RegExMatch( uid,"^Clips_Sub[0-9]$" ) ? GetClipPreview( SubStr( uid, 0 ) )
          : uid = "FolderMenu_Item" ? sel_Item.FM_Target
          : ""
      }
    }
    else if ( qcOpt[ "aprns_IconsTlp" ] && qcOpt[ "aprns_iconsOnly" ] && IsInteger( uid ) ) 
    {
      tlpDelay := 600
      TooltipData := sel_Item.name
    }
    else if ( uid = "IconsMenu_ico" )
    {
      tlpDelay := 500
      TooltipData := sel_Item.name
    }

    if !IsEmpty( TooltipData )
    {
      glb[ "onselect_tlpData" ] := TooltipData
      SetTimer( "MenuOnSelect_Tooltip", tlpDelay )
    }
    sel_Item := ""
    return
}

MenuOnSelect_Tooltip( p* )
{
  SetTimer( A_ThisFunc, "OFF" )
  if qcPUM.IsMenuShown
    Tooltip,% glb[ "onselect_tlpData" ],,,7
  return
}