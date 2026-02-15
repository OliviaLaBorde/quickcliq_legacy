GUIAddItemFromRecent( byRef oTarget )
{
  static hRefreshIco
  if !qcOpt["recent_on"]
  {
    QMsgBoxP( { title : "Recent feature disabled", "modal"	: 1
              , msg : "You must enable Recent in options before using this function"
              , pic : "!" }, qcGui[ "main" ] )
    return
  }
  if !WinExist( "ahk_id " qcGui[ "main_recent_list" ] )
  {
    GuiCreateNew( "GUI_RECENT_LIST", "main_recent_list", "Recent List", qcGui[ "main" ] )
    Gui,Add,ListView,h400 w600 hwndhwnd gGUI_RECENT_LIST_LVHandle AltSubmit Grid +0x8 -Multi
        ,Name|Executable|Cmd ;LVS_SHOWSELALWAYS
    qcGui[ "recentList_lv" ] := hwnd
    Gui,Add,Text,xm,Command Line
    Gui,Add,Edit,W450 xp+100 hwndhwnd
    qcGui[ "recentList_cmdEdit" ] := hwnd
    Gui,Add,Text,xm,Executable
    Gui,Add,Edit,W450 xp+100 hwndhwnd
    qcGui[ "recentList_execEdit" ] := hwnd
    Gui,Add,Button,% "x+7 yp-25 w40 h40 hwndhwnd gGUI_RECENT_LIST_Refresh +0x00000040" ;BS_ICON
    qcGui[ "recentList_refrBut" ] := hwnd
    if !hRefreshIco
        hRefreshIco := IconExtract( glb[ "icoRecentList_refrBut" ], 32 )
    Icon2Button( qcGui[ "recentList_refrBut" ], hRefreshIco )
        
    Menu, GUI_RECENT_LIST_AddMenu, Add, Add cmd line,GUI_RECENT_LIST_AddCmd
    Menu, GUI_RECENT_LIST_AddMenu, Default, Add cmd line
    Menu, GUI_RECENT_LIST_AddMenu, Add, Add executable path,GUI_RECENT_LIST_ExecPath
  }
  GuiShowChildWindow( qcGui[ "main_recent_list" ], qcGui[ "main" ] )
  RecentList_Add2LV()
  return qcGui[ "main_recent_list" ]
  
  GUI_RECENT_LISTGuiClose:
  GUI_RECENT_LISTGuiEscape:
  GUI_RECENT_LISTStop:
    GuiDestroyChild( qcGui[ "main_recent_list" ], qcGui[ "main" ] )
    return
    
  GUI_RECENT_LIST_AddCmd:
  GUI_RECENT_LIST_ExecPath:
    Gui,GUI_RECENT_LIST:Default
    rowNum := LV_GetNext()
    if !rowNum
      return
    LV_GetText( cmdName, rowNum, 1 )
    LV_GetText( execPath, rowNum, 2 )
    LV_GetText( cmdLine, rowNum, 3 )
    if ( isEmpty( execPath ) && isEmpty( cmdLine ) )
      return
    oTarget.name := cmdName
    if PathIsURL( execPath )
      execPath := PathParseName( execPath )
    if PathIsURL( cmdLine )
      cmdLine := PathParseName( cmdLine )
    oTarget.iconPath := execPath != "" ? execPath : cmdLine
    if instr( A_ThisLabel, "AddCmd" )
      oTarget.cmd := cmdLine != "" ? cmdLine : execPath
    else
      oTarget.cmd := execPath != "" ? execPath : cmdLine
    
    SetTimer,GUI_RECENT_LISTStop,-20
    return
    
  GUI_RECENT_LIST_ShowCtxMenu:
    Menu, GUI_RECENT_LIST_AddMenu, Show
    return
    
  GUI_RECENT_LIST_LVHandle:
    Gui,GUI_RECENT_LIST:Default
    event := A_GuiEvent
    ev_info := A_EventInfo
    If ( event = "RightClick" || ( event = "K" && ev_info = 93 ) )
    {
      if LV_GetNext()
        SetTimer,GUI_RECENT_LIST_ShowCtxMenu,-20
    }
    else If ( event = "DoubleClick" || ( event = "K" && ev_info = 32 ))
    {
      if LV_GetNext()
        SetTimer,GUI_RECENT_LIST_AddCmd,-1
    }
    else if ( event ~= "Normal|I" )
    {
      LV_GetText( cmdLine, ev_info, 3 )
      LV_GetText( execPath, ev_info, 2 )
      GuiControlSet( qcGui[ "recentList_cmdEdit" ],cmdLine,"",qcGui[ "main_recent_list" ] )
      GuiControlSet( qcGui[ "recentList_execEdit" ],execPath,"",qcGui[ "main_recent_list" ] )
    }
    return
    
  GUI_RECENT_LIST_Refresh:
    RecentList_Add2LV()
    return
}

RecentList_Add2LV()
{
  Gui, GUI_RECENT_LIST:Default
  GuiControl, -Redraw,% qcGui[ "recentList_lv" ]
  LV_Delete()
  for i,item in qcRecentMenu.GetItems()
  {
    if ( item.uid != "Recent_Cmd" )
      continue
    cmd := item.Recent_Cmd
    exect := PathRemoveArgs( cmd )
    name := item.name
    LV_Add( "", name, exect, cmd )
  }
  LV_ModifyCol()
  LV_ModifyCol(1,90) ;name
  LV_ModifyCol(2,240) ;exec
  LV_ModifyCol(3,260) ;cmd
  LV_ModifyCol( 1, "Sort" )
  GuiControl, +Redraw,% qcGui[ "recentList_lv" ]
  return 0
}