Gui_Main_TlbProp_ChangeIcon( tbButtonPos )
{
  Gui, 1:Default
  Gui, +Disabled
  Gui, 12:+LastFoundExist
  WinGet, hWnd, ID
  WinGetPos, X, Y,,,% "ahk_id " qcGui[ "main_tlbprop" ]
  p := StrSplit( Toolbar_GetRect( qcGui[ "main_tlbprop" ], tbButtonPos ), A_Space )
  x := x+p[1], y := y+p[4]
  ItemID := TV_GetSelection()
  CurIco := Gui_Main_TVItem_GetIcon( itemID )
  NewIco := Gui_Main_IconsMenu( hWnd, CurIco, x, y )

  if ( NewIco = "-1" )
  {
    Gui_Main_TVItem_SetIcon( ItemID,"" )
    TV_Modify(ItemID,"Select Vis Icon" . glb[ "BlankIcoNum" ])
  }
  else if NewIco
  {
    if ( ItemIcon := TV_IL.Add( NewIco ) )
    {
      TV_Modify(ItemID,"Select Vis Icon" . ItemIcon)
      Gui_Main_TVItem_SetIcon( ItemID, NewIco )
    }
  }
  Gui_Main_TlbProp_SetIcon( itemID )
  Gui, -Disabled
  return
}

GUI_Main_TV_Add( type )
{
  if type not in item,menu,sep
    ShowExc( A_ThisFunc ": Wrong item type passed: " type )
  Gui,1:Default
  IsItem := type = "item" ? 1 : 0
  IsMenu := type = "menu" ? 1 : 0
  IsSepar  :=  type = "sep" ? 1 : 0
  ItemID := TV_GetSelection()
  itemName := IsItem ? "NewShortcut"
                : IsMenu ? "NewMenu" : glb[ "separator" ]
  itemNode := QC_AddXMLItem( { name : IsSepar ? "" : itemName
                                  , menuID : qcTVItems[ PID := TV_GetParent( ItemID ) ]
                                  , afterID : qcTVItems[ ItemID ]
                                  , issep : IsSepar ? 1 : "" } )
  if IsItem
    qcconf.ItemSetCmd( itemNode, "command" )
  tvid := QC_TVAdd( itemName, PID,  ItemID " Select Vis Icon" . glb[ "BlankIcoNum" ], itemNode.getAttribute( "ID" ) )
  if IsMenu
  {
    childName :=  "NewShortcut"
    childNode := QC_AddXMLItem( { name : childName, menuNode : itemNode } )
    qcconf.ItemSetCmd( childNode, "command" )
    QC_TVAdd( childName, tvid,  "Vis Icon" . glb[ "BlankIcoNum" ], childNode.getAttribute( "ID" ) )
    QC_ArrangeTVColors( tvid )
  }
  GuiControl,Focus,% qcGUI[ "main_tv" ]
  return tvid
}

GUI_Main_TV_ExpandToggle()
{
  static state
  Gui, 1:Default
  ItemID := 0, state := !state
  GuiControl, -Redraw,% qcGui[ "main_tv" ]
  while ( ItemID := TV_GetNext(ItemID, "Full") )
    if TV_GetChild( itemID )
      TV_Modify( ItemID, state ? "Expand" : "-Expand" )
  GuiControl, +Redraw,% qcGui[ "main_tv" ]
  GuiControl,Focus,% qcGui[ "main_tv" ]
  return state
}

GUI_Main_TV_Del( in_id = "", menuCheck = True )
{
  Gui,1:Default
  Gui,+OwnDialogs
  if ( ItemID := in_id ? in_id : TV_GetSelection() )
  {
    if ( TV_GetChild( ItemID ) && menuCheck && !GetKeyState( "SHIFT", "P" ) )
    {
      MsgBox,36,Delete Confirmation,Are you sure you want to delete selected menu?
      IfMsgBox,No
        return
    }
    qcconf.ItemDel( qcTVItems[ itemID ] )
    QC_TVDel( ItemID )
    GuiControl,Focus,% qcGui[ "main_tv" ]
  }
  return
}

GUI_Main_TV_DelByID( xmlID )
{
  qcconf.ItemDel( xmlID )
  if IsWindowVisible( qcGui[ "main" ] )
  {
    for tvid,uid in qcTVItems
      if( uid = xmlID )
      {
        QC_TVDel( tvid )
        break
      }
  }
  qcconf.Save()
  return
}

Gui_Main_SyncFrom( from, itemID = "" ) ;1 - Edit to LV, 2 - LV to Edit
{
  if ( from = "ED" )
    GUI_Main_LV_SetList( GUI_Main_ED_Get(), False )
  else if ( from = "LV" )
    GUI_Main_ED_Set( GUI_Main_LV_GetList(), False )
  else
    Exception( "wrong 'from' param passed: " from "`n" CallStack() )
  Gui_Main_ED_SaveCmd( itemID )
  return
}

Gui_Main_ED_SaveCmd( itemID = "" )
{
  Gui, 1:Default
  ItemID := itemID = "" ? TV_GetSelection() : itemID
  if ( TV_GetChild( ItemID ) || ItemID=0 || qcconf.ItemGetAttr( qcTVItems[ ItemID ], "issep" ) )
    return
  qcconf.ItemSetCmd( qcTVItems[ ItemID ], GUI_Main_ED_Get() )
  return
}

;target autosave switch
;if mode = 1, then disable autosave, otherwise reenable
;returns current state if called without parameters
TG_ASaveStop(mode="")	
{
  static disablecount, stop_autosave
  if (mode = 2)
    stop_autosave := 0
  else if (mode = 1)
  {
    disablecount++
    stop_autosave := 1
    SetTimer,ReEnable_TargAS,OFF
  }
  else if (mode = 0 && (--disablecount <= 0))
  {
    SetTimer,ReEnable_TargAS,-10
    disablecount := 0
  }
  return stop_autosave
  
  ReEnable_TargAS:
    TG_ASaveStop(2)
    return	
}

Gui_Main_FileDnD( ctrl_name, dropped_files )
{
  Gui,1:Default
  MouseGetPos,,,,hwnd,2
  ItemID := TV_GetSelection()
  PID := TV_GetParent( ItemID )
  if ( hwnd = qcGui[ "main_ed" ] || hwnd = qcGui[ "main_lv" ] )
  {
    if !ClIsEnabled( hwnd )
      DTP("Fail to add commands!")
    else
    {
      SplashWait(1)
      tt := ( GuiControlGet( qcGui[ "main_ed" ] ) ? " " glb[ "optMTDivider" ] " " : "" )
      Loop, parse, dropped_files, `n
      {
        fileExt := PathGetExt( A_LoopField )
        if (fileExt = "lnk")
        {
          PathShortcutGet( A_LoopField, sTarget, sIcon )
          sTarget := sTarget ? sTarget : A_LoopField
        }
        else
          sTarget := PathQuoteSpaces( A_LoopField )
        if !IsEmpty( sTarget )
          tt .= ( A_Index = 1 ? "" : " " glb[ "optMTDivider" ] " " ) sTarget
      }
      GuiControlSet( qcGui[ "main_ed" ], GuiControlGet( qcGui[ "main_ed" ] ) . tt)
      free( tt )
      ControlSend,, {End},% "ahk_id " qcGui[ "main_ed" ]
      Gui_Main_SyncFrom( "ED" )
      SplashWait(0)
    }
  }
  else if ( hwnd = qcGui[ "main_tv" ] )
  {
    SplashWait(1)
    Loop, parse, dropped_files, `n
    {
      cmd := A_LoopField
      SplitPath, cmd,,FileDir,FileExt,DroppedFileName
      cmd := PathQuoteSpaces( cmd )
      if !DroppedFileName
        DroppedFileName := FileDir
      if (fileExt = "lnk")
      {
        PathShortcutGet( cmd, targ, sIcon )
        cmd := targ ? targ : cmd
      }
      FileGetAttrib, attrs,% PathUnquoteSpaces( cmd )
      icoPath := instr(attrs,"D") ? ( RegExMatch( PathUnquoteSpaces( cmd ),"^\\.*") 
                                    ? glb[ "icoRemoteFol" ] : glb[ "icoFolder" ] )
                                  : sIcon ? sIcon : IconGetFromPath( PathRemoveArgs( cmd ) )
      if !( iIcon := TV_IL.Add( icoPath ) )
        iIcon := glb[ "BlankIcoNum" ]
      itemNode := QC_AddXMLItem( { name : DroppedFileName
                    , icon  : icoPath
                    , cmd   : cmd
                    , menuID : qcTVItems[ PID ]
                    , afterID : qcTVItems[ ItemID ] } )
      ItemID := QC_TVAdd( DroppedFileName, PID, ItemID " Select Vis Icon" . iIcon, itemNode.getAttribute( "ID" ) )
      PID := TV_GetParent( ItemID )
    }
    QC_ArrangeTVColors( PID )
    WinActivate,% "ahk_id " qcGui[ "main_tv" ]
    SplashWait(0)
  }
  else
  {
    DTP("Drag files to the menu to add them as shortcuts`nor to the commands list to add their paths",5000)
    HLControl( qcGui[ "main" ],qcGui[ "main_tv" ] "|" ( qcOpt[ "main_cmd_LVView" ] ? qcGui[ "main_lv" ] : qcGui[ "main_ed" ] ) )
  }
  return	
}

GUI_Main_Resize( new_width, new_height )
{
  static s_width, s_height
  ;if windows was minimized/maximized - do nothing
  if ( !new_width || !new_height )
    || ( new_width = s_width && new_height = s_height )
    return
  GuiControl, -Redraw,% qcGui[ "main_tv" ]
  s_width := new_width, s_height := new_height
  Gui,1:Default
  gui_width := s_width - 20
  TV_height := s_height*0.618
  tg_edit_h := lv_h := s_height - TV_height - 120
  sw_but_y := TV_height + 35
  sw_but_x := s_width - 40
  label_y := sw_but_y + 30
  tg_edit_y := lv_y := label_y + 20
  GuiControl,Move,% qcGui[ "main_tv" ],% "w" gui_width " h" TV_height
  GuiControl,Move,% qcGui[ "main_ed" ],% "w" gui_width " y" tg_edit_y " h" tg_edit_h
  GuiControl,Move,% qcGui[ "main_tg_name" ],% "w" gui_width " y" label_y
  GuiControl,Move,% qcGui[ "main_lv" ],% "w" gui_width " y" lv_y " h" lv_h
  GuiControl,Move,% qcGui[ "main_svBut" ],% "x" sw_but_x " y" sw_but_y
  GuiControl,Move,% qcGui[ "main_donate_but" ],% "x" (gui_width - 90 ) " y5"
  GuiControl,MoveDraw,AfoSB
  ;x,y coords used by ControlMove different from GuiControl,MoveDraw, but the same as given us by ControlGetPos
  ControlGetPos,x,y,w,h,,% "ahk_id " qcGui[ "main_tv" ]
  TB_y := y + h + 5
  ControlMove,,,% TB_y,,,% "ahk_id " qcGui[ "main_tbbot" ]
  LV_ModifyCol(1,gui_width-30)
  SetTimer( "GUI_Main_Redraw", 50 )
  return
}

GUI_Main_Redraw( p* )
{
  SetTimer( A_ThisFunc, "OFF" )
  for i,hCtrl in [ qcGui[ "main_ed" ]
                  ,qcGui[ "main_lv" ]
                  ,qcGui[ "main_tg_name" ]
                  ,qcGui[ "main_svBut" ]
                  ,qcGui[ "main_tv" ] ]
  {
    if !ClIsVisible( hCtrl )
      continue
    GuiControl, -Redraw,% hCtrl
    GuiControl, +Redraw,% hCtrl
  }
  return
}

Gui_Main_UpdAfo( p* )
{
  Gui, 1:Default
  Gui, 21:+LastFoundExist
  if !WinExist()
    SB_SetText( GetRandomAphorism() )
  return
}

Gui_Main_GetPos()
{
  winPos := qcOpt[ "main_pos" ]
  if !winPos
    return ""
  for i,v in StrSplit( winPos, " ", A_Space A_Tab )
  {
    StringTrimLeft,v,v,1
    if ( v < 0 )
      return ""
  }
  return winPos
}

Gui_Main_SavePos()
{
  if ( winPosClient := WinGetClientPos( qcGui[ "main" ] ) )
    && ( winPos := WinGetPos( qcGui[ "main" ] ) )
    qcOpt[ "main_pos" ] := "x" winPos.x " y" winPos.y
                         . " w" winPosClient.w " h" winPosClient.h
  return
}