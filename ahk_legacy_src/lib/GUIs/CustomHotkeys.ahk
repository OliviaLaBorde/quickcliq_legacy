CustomHotkeysGui_Show()
{
  static CustomHK_LV, But1, But2, But3, But4, But5
  if WinExist( "ahk_id " qcGui[ "main_hotkey_list" ] )
  {
    WinActivate,% "ahk_id " qcGui[ "main_hotkey_list" ]
    return
  }
  GuiCreateNew( "GUI_HOTKEY_LIST", "main_hotkey_list", "Custom Hotkey List", qcGui[ "main" ], False )
  Gui,Add,ListView,xm ym w260 h370 Section AltSubmit vCustomHK_LV -Multi gCustomHotkeys_LV_Events
      ,Hotkey|Target|PUM_ID|Hotkey_orig
  LV_ModifyCol(1, 100)
;###### Adding hotkeys to list
  CustomHotkeys_Update()
  LV_ModifyCol(3,0) ;hiding PUM_ID field
  LV_ModifyCol(4,0) ;hiding hk field
;######################################

  Gui,Add,Button,ym xs+270 w80 h20 vBut3 gCustomHotkey_Edit,Edit
  Gui,Add,Button,y+5 xp w80 h20 vBut5 gCustomHotkey_Refresh,Refresh
  Gui,Add,Button,y+25 xp w80 h20 vBut2 gCustomHotkey_Delete,Delete
  GuiShowChildWindow( qcGui[ "main_hotkey_list" ], qcGui[ "main" ], "show_far_right" )
  return
  
  GUI_HOTKEY_LISTGuiEscape:
  GUI_HOTKEY_LISTGuiClose:
    if !HotkeysCompare( qcGui[ "main_hotkey_list" ] )
      GuiDestroyChild( qcGui[ "main_hotkey_list" ], qcGui[ "main" ] )
    return
    
  CustomHotkeys_LV_Events:
    if (A_GuiEvent = "Normal")
      SetTimer,CustomHotkey_ShowItem,-20
    if (A_GuiEvent = "DoubleClick")
      goSub,CustomHotkey_Edit
    return
    
  CustomHotkey_ShowItem:
    Gui,% qcGui[ "main_hotkey_list" ] ":Default"
    if !IsWindowVisible( qcGui["main"] )
      return
    row_num := CustomHotkeys_GetHiddenData( PUM_ID, itemHotkey )
    if !row_num
      return
    if( item := qcPUM.GetItemByID( PUM_ID ) )
      QCEditItem( item, False )
    return
  
  CustomHotkey_Delete:
    Gui,+OwnDialogs
    GuiControl,Focus,CustomHK_LV
    if !( row_num := CustomHotkeys_GetHiddenData( PUM_ID, itemHotkey ) )
      return
    if ( item := qcPUM.GetItemByID( PUM_ID ) )
    {
      qcconf.ItemSetAttr( item.uid, "hotkey", "" ) ;removing attribute
      CustomHotkeys_Del( itemHotkey )
      if ( tvid := TVGetIDbyUID( item.uid ) )
        qcTVHKItems[ tvid ] := 0
      lines_count := LV_GetCount()
      LV_Delete( row_num )
      if ( row_num = lines_count )
        LV_Modify( row_num-1,"Select" )
      else
        LV_Modify( row_num,"Select" )
      if ( LV_GetCount() == 0 )
      {
        Gui,% qcGui["main"] ":Default"
        TV_Modify(0)
      }
      SetTimer,CustomHotkey_ShowItem,-20
    }
    return
    
  CustomHotkey_Edit:
    Gui,% qcGui[ "main_hotkey_list" ] ":Default"
    GuiControl,Focus,CustomHK_LV
    if !( row_num := CustomHotkeys_GetHiddenData( PUM_ID, itemHotkey) )
      return
    if ( item := qcPUM.GetItemByID( PUM_ID ) )
    {
      if ( itemHotkey != qcconf.ItemGetAttr( item.uid, "hotkey" ) )  ;comparing hotkey currenly used with the actual in the xml
      {
        if ( "Rebuild" = QMsgBoxP( { title : "Wrong hotkey"
                , msg : "Choosen hotkey have been changed.`nDo you want to rebuild menu and update hotkeys list?"
                , buttons : "Rebuild|Cancel", pic : "!", pos : qcGui[ "main_hotkey_list" ] }, qcGui[ "main_hotkey_list" ] ) )
          CustomHotkeys_Update( 1 )
        return
      }
      new_hotkey := CustomHotkey_EditGUI( itemHotkey, qcGui[ "main_hotkey_list" ] )
      if ( new_hotkey == itemHotkey )
        return
      qcconf.ItemSetAttr( item.uid, "hotkey", new_hotkey )
      CustomHotkeys_Change( itemHotkey, new_hotkey )
      CustomHotkeys_Update()
    }
    return
    
  CustomHotkey_Refresh:
    CustomHotkeys_Update()
    return
}

CustomHotkey_EditGUI( hk, AGui, title="Edit Hotkey" )
{
  global New_custom_hk,New_hk_win, hkey_changer_hint
  If !IsWindow( qcGui[ "hkey_changer" ] )
  {
    Gui, HKEY_CHANGER:New,+hwndhwnd +ToolWindow 
    qcGui[ "hkey_changer" ] := hwnd
    Gui, HKEY_CHANGER:Default
    QCSetGuiFont( "HKEY_CHANGER" )
    if qcOpt[ "gen_noTheme" ]
      Gui,-Theme
    
    Gui,Add,Hotkey,w140 h20 xm ym vNew_custom_hk
    Gui,add,Checkbox,h20 yp+1 x+5 vNew_hk_win,+WIN
    gui,font,s6
    Gui,Add,Text, xm +Wrap vhkey_changer_hint gfakesub,While this window is opened - all hotkeys disabled.
    gui,font,normal s8
    Gui,add,button,w50 h20 xm y+10 gSave_Edited_Hotkey Default,OK
    Gui,add,button,w50 h20 y20 x+95 yp gClose_Edit_GUI,Cancel
  }
  If IsWindowVisible( qcGui[ "hkey_changer" ] )
  {
    WinActivate,% "ahk_id " qcGui[ "hkey_changer" ]
    DTP( "Hotkey changing window is already opened!", 2000 )
    return
  }
  HotkeySetAll( 0 )
  new_hk := ""
  hk_orig := hk
  GuiControlSet( "New_custom_hk", HotkeyGetVK( RemWINhk(hk) )[1], "", "HKEY_CHANGER" )
  GuiControlSet( "New_hk_win", IsWINhk(hk), "", "HKEY_CHANGER" )
  Gui,HKEY_CHANGER:Default
  parent_guis := StrSplit(AGui,"|",A_Tab A_Space)
  for i,v in parent_guis
    Gui,%v%:+Disabled
  Gui,% "+owner" parent_guis[1]
  Gui,% parent_guis[1] ":+LastFoundExist"
  WinGetPos, X, Y, W, H,% "AHK_ID " WinExist()
  Gui, show,% "x" . round(x+w/2-100) . " y" . round(y+h/2-90) . " h80 w215",% title
  GuiControl,Focus,New_custom_hk
  go_on := 0
  while !go_on
    sleep 200
  HotkeySetAll( 1 )
  return (instr(new_hk,"vk00") ? "" : new_hk)
  
  Save_Edited_Hotkey:
  Close_Edit_GUI:
  HKEY_CHANGERGuiClose:
  HKEY_CHANGERGuiEscape:
    if (A_ThisLabel = "Save_Edited_Hotkey")
    {
      Gui,Submit,NoHide
      if (New_custom_hk != "")
        new_hk := (New_hk_win ? "#" : "") . New_custom_hk
    }
    else
      new_hk := hk_orig
    for i,v in parent_guis
      Gui,%v%:-Disabled
    Gui,HKEY_CHANGER:+Owner
    Gui,HKEY_CHANGER:Hide
    go_on := 1
    return
}

CustomHotkeys_Update( rebuildMenu = 0 )
{
  Gui,% qcGui[ "main_hotkey_list" ] ":Default"
  Gui,+OwnDialogs
  if rebuildMenu
    QCMenuRebuild( "main" )
  LV_Delete()
  for hk,PUM_ID in qcCustomHotkeys
    if ( item := qcPUM.GetItemByID( PUM_ID ) )
      LV_Add( "", HotkeyToString( hk ), item.name, PUM_ID, hk )
  LV_ModifyCol(2, "AutoHDR")
  return
}

CustomHotkeys_Del( hk )
{
  qcCustomHotkeys[ hk ] := ""
  Hotkey( hk, 0 )
  return
}

CustomHotkeys_Change( hk, new_hk )
{
  if !( PUM_ID := qcCustomHotkeys[ hk ] )
    return
  CustomHotkeys_Del( hk )
  qcCustomHotkeys[ new_hk ] := PUM_ID
  if ( err := Hotkey( new_hk, 1, "CHK_Processing" ) )
    QMsgBoxP( { title : "Custom hotkey error", msg : err
            , buttons : "OK", pic : "x", pos : qcGui[ "main_hotkey_list" ] } )
  return
}


CustomHotkeys_GetHiddenData( byref PUM_ID, byref itemHotkey )
{
  Gui,% qcGui[ "main_hotkey_list" ] ":Default"
  Gui,+OwnDialogs
  row_num := LV_GetNext()
  if !row_num
    return 0
  LV_GetText( PUM_ID, row_num, 3 )
  LV_GetText( itemHotkey, row_num, 4 )
  return row_num
}

SetCustomHotkeys( state )
{
  errors := ""
  for hk,id in qcCustomHotkeys
    errors .= ( errors ? "`n" : "" ) Hotkey( hk, state, "CHK_Processing" )
  if errors
    QMsgBoxP( { title : "Custom hotkeys error"
              , msg : err, buttons : "OK", pic : "x"
              , editbox : 1, editbox_h : 200 } )
  return
  
  CHK_Processing:
    ProcessCustomHotkey( A_ThisHotkey )
    return
}