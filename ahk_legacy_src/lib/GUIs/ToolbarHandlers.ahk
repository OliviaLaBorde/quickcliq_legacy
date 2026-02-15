Gui_Main_TlbTop_MenuRebuild( butID )
{
  global hMainGuiToolbar
  qcconf.Save()
  TB_Enable( hMainGuiToolbar, butID, 0 )
  QCMenuRebuild( "main" )
  HotkeysCompare( 1 )
  TB_Enable( hMainGuiToolbar, butID, 1 )
}

GUI_Main_TlbTop_Handler( Hwnd, Event, Txt, Pos, Id )
{
  global hMainGuiToolbar
  static staticID, staticPos
  static cmd
  if Event not in click,menu
    return 0
  staticID := id,staticPos := Pos
  cmd := id = 1 ? "addItem"
                : id = 2 ? "addMenu"
                : id = 3 ? "addSep"
                : id = 4 ? "expand"
                : id = 5 ? "move_down"
                : id = 6 ? "del"
                : id = 7 ? "move_up"
                : id = 8 ? "hints"
                : id = 9 ? "rebuild"
                : Exception( "What the shit passed> " id "" )
  SetTimer, lbl_TlbTop, -1
  return 1
  
  ;using another thread to avoid messages processing troubles
  lbl_TlbTop:
    Gui,1:Default
    ret := cmd = "del"            ? GUI_Main_TV_Del()
        : cmd = "addItem"   ? GUI_Main_TV_Add( "item" )
        : cmd = "addMenu" ? GUI_Main_TV_Add( "menu" )
        : cmd = "addSep"    ? GUI_Main_TV_Add( "sep" )
        : cmd = "expand"    ? ( state := GUI_Main_TV_ExpandToggle()
                        ,Toolbar_SetButtonImage( hMainGuiToolbar, staticID, state ? 4 : 3 ) )
        : cmd = "move_down" ? GUI_Main_TV_Move( TV_GetSelection(), "D" )
        : cmd = "move_up"   ? GUI_Main_TV_Move( TV_GetSelection(), "U" )
        : cmd = "rebuild"       ? Gui_Main_TlbTop_MenuRebuild( staticID )
        : cmd = "hints"         ? GUI_Main_TlbTop_ShowHints() : ""
    cmd =
    return
}

GUI_Main_TlbTop_ShowHints()
{
    Gui,1:+OwnDialogs
  TV_hints = 
  (LTrim
  -Drag and Drop files and folders to add them to the selected menu
  -Double click or F2 to rename item or menu
  
  Hotkeys:
  CTRL+UP or DOWN to move selected item up or down
  CTRL+Z - add new item
  CTRL+X - add menu
  CTRL+S - add separator
  DEL to delete selected item
  
  Commands Hints:
  -Use "Switch View" button at the right top of the list to switch between single and multiple commands view
  -Double click or F2 on command line to edit it
  -Del to delete line
  )
  Msgbox, 64, Hints, % TV_hints
  return
}

Gui_Main_TlbProp_Handler(Hwnd, Event, Txt, Pos, Id)
{
  static staticID,staticPos
  if Event not in menu,click
    return 0
  staticID := id,staticPos := Pos
  if (id = 3)
    SetTimer,Gui_Main_TVItem_ChangeHotkey,-1
  else if (id = 1)
    Gui_Main_TlbProp_ChangeIcon( pos )
  else if (id = 2)	;change boldness
  {
    Gui, 1:Default
    tv_id := TV_GetSelection()
    b_state := TB_IsChecked( qcGui[ "main_tlbprop" ], staticID )
    Gui_Main_TVItem_SetBold( tv_id, b_state )
    TV_Modify( tv_id, ( b_state ? "" : "-" ) "Bold" )
  }
  else if (id = 4)
    Gui_Main_TVItem_ChangeColorMenu( "t", Pos )
  else if (id = 5)
    Gui_Main_TVItem_ChangeColorMenu( "bg", Pos )
  else if (id = 7)
    Gui_Main_TVItem_SortMenu( Pos )
  else if (id = 6)
    Gui_Main_TVItem_SetMenuRandColors()
  else if (id = 8)
    Gui_Main_TVItem_CreateSMenu()
  else if (id = 12)
  {
    Gui, 1:Default
    tv_id := TV_GetSelection()
    b_state := TB_IsChecked( qcGui[ "main_tlbprop" ], staticID )
    Gui_Main_TVItem_SetAutorun( tv_id, b_state )
    qcTVAutorunItems[ tv_id ] := b_state
  }
  return 1
}

Gui_Main_TBBot_Handler(Hwnd, Event, Txt, Pos, Id)
{
  static staticID,staticPos
  if Event not in menu,click
    return 0
  staticID:=id,staticPos:=pos
  if (id = 1)
    SetTimer,IE_AddBlank,-1
  else if (id = 3)
    GoSub,MG_TBCmd_MoveDown
  else if (id = 8)
    GoSub,MG_TBCmd_MoveUp	
  else if (id = 4)
    GoSub,MG_TBCmd_Change
  else if (id = 5)
    SetTimer,MG_TBCmd_Run,-1
  else if (id = 6)
    SetTimer,MG_TBCmd_RunAll,-1
  else if (id = 7)
    qcOpt[ "main_cmd_LVView" ] ? GUI_Main_LV_Del()
                          : GUI_Main_ED_Set( "" )
  return
  
  MG_TBCmd_RunAll:
    Gui, 1:+OwnDialogs
    SplashWait( 1, "", 1, 0 )
    RunCommand( { cmd : ( qcOpt[ "main_cmd_LVView" ] ? GUI_Main_LV_GetList() : GUI_Main_ED_Get() )
          , nolog : 1, noctrl : 1 } )
    SplashWait( 0 )
    return
  
  MG_TBCmd_Run:
    Gui,1:Default
    Gui, 1:+OwnDialogs
    row := 0
    while row := LV_GetNext( row )
    {
      LV_GetText( tg, row )
      cmds .= ( cmds ? glb[ "optMTDivider" ] : "" ) tg
    }
    RunCommand( { cmd : cmds, nolog : 1, noctrl : 1 } )
    return
  
  MG_TBCmd_MoveUp:
  MG_TBCmd_MoveDown:
    moveDir := (A_ThisLabel = "MG_TBCmd_MoveUp" ? "UP" : "DOWN")
    GUI_Main_LV_Move( 1, moveDir )
    Gui_Main_SyncFrom( "LV" )
    GuiControl, Focus,% qcGui[ "main_lv" ]
    return

  MG_TBCmd_Change:
    ControlGetPos,x,y,w,h,,% "ahk_id " qcGui[ "main_tbbot" ]
    p := StrSplit(Toolbar_GetRect( qcGui[ "main_tbbot" ], staticPos )," ")
    x += p[1], y += p[2]
    ShowMenu( "Main_Menu_CmdChange", x, y+p[4] )
    return
}

ShowMenu(menu_name,x="",y="")
{
  CoordMode,Menu,Relative
  Menu,% menu_name, Show,% x,% y
  return
}

Gui_Main_TlbProp_Update( isMenu, isSep, isItem )
{
  static s_set
  new_set := isMenu isSep isItem
  if ( s_set = new_set )
    return
  s_set := new_set
  TB_Enable( qcGui[ "main_tlbprop" ],"1|2|3|4|5|6|7|8|9|10|11|12",1)
  if isItem
    TB_Enable( qcGui[ "main_tlbprop" ],"6|7|8|9",0)
  else if isSep
    TB_Enable( qcGui[ "main_tlbprop" ],"1|2|3|4|5|6|7|8|9|10|11|12",0)
  else if ( isMenu = 2 )	;means it is main menu, and itemID = 0
    TB_Enable( qcGui[ "main_tlbprop" ],"1|2|3|10|11|12",0)
  else if ( isMenu = 1 )
    {}
  return
}

Gui_Main_TlbProp_SetIcon( itemID )
{
  hi := TV_IL.Get( TV_GetIconIndex( qcGui[ "main_tv" ], itemID ) )
  if ( itemID && hi )
    IL_AddIcon( qcGui[ "main_tlbprop_IL" ], hi, 0)
  else
    IL_AddIcon( qcGui[ "main_tlbprop_IL" ], glb[ "hIcoNone" ], 0, 0 )
}

Gui_Main_TlbProp_SetBold( itemID )
{
  if ( itemID && TV_Get( ItemID, "Bold" ) )
    Toolbar_CheckButton( qcGui[ "main_tlbprop" ], 2, 1 )
  else
    Toolbar_CheckButton( qcGui[ "main_tlbprop" ], 2, 0 )
}

Gui_Main_TlbProp_SetAutorun( itemID )
{
  if ( qcTVAutorunItems[ itemID ] )
    Toolbar_CheckButton( qcGui[ "main_tlbprop" ], 12, 1 )
  else
    Toolbar_CheckButton( qcGui[ "main_tlbprop" ], 12, 0 )
}

Gui_Main_TlbProp_SetHotkey( itemID )
{
  if ( itemID && ( ItemHotkey := GetCustomHotkey( itemID ) ) )
  {
    Toolbar_SetButtonText(  qcGui[ "main_tlbprop" ], 3, HotkeyToString( ItemHotkey ) )
    qcTVHKItems[ itemID ] := 1
  }
  else
  {
    Toolbar_SetButtonText( qcGui[ "main_tlbprop" ], 3, "None")
    qcTVHKItems.Delete( itemID )
  }
}

Gui_Main_TlbProp_SetItemName( name )
{
  GuiControlSet( "props_item_label", name, "", qcGui[ "main_props" ] )
  return
}

Gui_Main_UpdControls( itemID )
{
  Gui,1:Default
  if ( qcTVItems[ itemID ] = "" ) ;check that item in the array, in rare cases it may not be there, idk why :(
    return False
  TV_GetText( CurItemName, itemID )
  if !itemID
    CurItemName := "Main Menu"
  isMenu := TV_GetChild( itemID ) || itemID = 0 ? ( ItemID ? 1 : 2 ) : 0
  isSep := itemID && qcconf.ItemGetAttr( qcTVItems[ itemID ], "issep" ) ? 1 : 0
  isItem := !( isMenu || isSep )

  Gui_Main_TlbProp_Update( isMenu, isSep, isItem )
  GuiControlSet(qcGui[ "main_tg_name" ],isItem ? CurItemName "'s command line" : isSep ? "Separator" : "Menu: " CurItemName,"",1)
  Gui_Main_TlbProp_SetIcon( itemID )
  Gui_Main_TlbProp_SetBold( itemID )
  Gui_Main_TlbProp_SetHotkey( itemID )
  Gui_Main_TlbProp_SetItemName( isSep ? "Separator" : CurItemName " (id:" qcTVItems[ itemID ] ")" )
  Gui_Main_TlbProp_SetAutorun( itemID )
  
  Toolbar_AutoSize( qcGui[ "main_tlbprop" ], 2 )
  
  ;disabling/enabling edit line or LV according to type of selected item
  GuiControlSet( qcGui[ "main_ed" ],"",isItem ? "Enabled" : "Disabled",1,0 )
  GuiControlSet( qcGui[ "main_lv" ], "", isItem ? "Enabled" : "Disabled",1,0 )
  cmd := isItem ? qcconf.GetItemCmdByID( qcTVItems[ itemID ] ) : ""
  GUI_Main_ED_Set( cmd, False )
  GUI_Main_LV_SetList( cmd, False )
  
  Gui_Main_TBBot_SetState( isItem ? 1 : 0 )	;disabling bottom toolbar if selected item is menu or separator
  Gui_Main_TBBot_BtnsUpdate()	;checking & enabling/disabling TB buttons related to LV of commands
  return True
}