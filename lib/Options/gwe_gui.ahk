GUIGestureExclusions()
{
  global gwe_search_chb
  static hGwe_Srch := 0
  
  Menu, GWE_menu, Delete
  Menu, GWE_menu, Add,% "Add New", GWE_add_new
  Menu, GWE_menu, Add,% "Remove", GWE_remove_item
  
  Menu, GWE_search_menu, Delete
  Menu, GWE_search_menu, Add,% "As Title", GWE_from_search
  Menu, GWE_search_menu, Add,% "As Class", GWE_from_search
  Menu, GWE_search_menu, Add,% "As Process", GWE_from_search
  
  Gui,GUI_OPT_GEST_WIN_EXCL:New, +hwndhwnd +ownerGUI_OPT +ToolWindow,Gesture Win Exclusions
  qcGui[ "opts_hws" ][ "gest_win_excl" ] := hwnd
  Gui,GUI_OPT_GEST_WIN_EXCL:Default
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  Gui, GUI_OPT:+Disabled
  QCSetGuiFont( "GUI_OPT_GEST_WIN_EXCL" )
  Gui,Add,Link,Section w200 gg_open_gest_exc_help,% "Add windows on which Quick Cliq gestures must be ignored. See <a>help</a> for details."  
  Gui,Add,Checkbox,% "x+5 w"  glb[ "defButH" ] " h"  glb[ "defButH" ] " +0x1000 gg_gwe_find_window vgwe_search_chb +0x00000040 +hwndhwnd"
  
  if !hGwe_Srch
    hGwe_Srch := IconExtract( glb[ "icoGWESrch" ], 16 )
  SendMessage( hwnd, BM_SETIMAGE := 0x00F7, 1, hGwe_Srch )
  
  Gui, Add, ListView,xs w230 h200 gg_opt_gest_win_exc_lv -ReadOnly -Hdr AltSubmit Grid +0x8 +hwndhwnd, windows
  qcGui[ "gwe_lv" ] := hwnd
  GWE_Set_List()
  Gui,Add,Button,% "xs w" glb[ "defButW" ] " h" glb[ "defButH" ] " gg_GWE_but_ok", Save
  Gui,Add,Button,% "x+90 yp w" glb[ "defButW" ] " h" glb[ "defButH" ] " gg_GWE_but_cancel", Cancel
  GuiControl,Focus,% qcGui[ "gwe_lv" ]
  WinGetPos, X, Y, W, H,% "ahk_id " qcGui[ "opts" ]
  pos := "x" . round(x+w/2+30) . " y" . round(y+h/2-210)
  Gui,Show,% pos
  return
    
  g_gwe_find_window:
    if !GuiControlGet( "gwe_search_chb", "GUI_OPT_GEST_WIN_EXCL" )
      return
    GWE_SearchWindow()
    GuiControlSet( "gwe_search_chb", 0, "", "GUI_OPT_GEST_WIN_EXCL" )
    return
  
  GWE_add_new:
    GWE_Add_New()
    return
    
  GWE_remove_item:
    GWE_Remove_Item()
    return
  
  GWE_show_ctx:
    Gui, GUI_OPT_GEST_WIN_EXCL:Default
    if LV_GetNext()
      Menu,GWE_menu,Enable,% "Remove"
    else
      Menu,GWE_menu,Disable,% "Remove"
    Menu,GWE_menu,Show
    return
  
  g_open_gest_exc_help:
    msg = 
    ( LTrim
    To specify a window which must be ignored by gestures, use one of the following options.
    Please use "find" button to make it easier.
    
    Title
    To use title of the window for filtering - just write it's exact or partial content as a row.
    Hovewer, this method may not be reliable enough since many windows may contain entered string in their title.
    It's better to use of the next two methods.
    
    Class
    To use window class for window identification, write "ahk_class" before actual window class.
    For example, to exclude all Windows Explorer windows, use the following string:
      ahk_class ExploreWClass
      ahk_class CabinetWClass ( for Vista+ )
      
    Process name
    To exclude all windows owned by specific process, write "ahk_exe" before actual process name or full process path.
    For example, to exclude all windows belonging to Chrome browser, use following string:
      ahk_exe chrome.exe
    
    If one of the methods doesn't work for specific window - try another one.
    )
    msparams := { "title"		: "Gesture exclusions help"
          ,"editbox" : 1
          ,"editbox_w" : 300
          ,"editbox_h" : 150
          ,"msg" 		: msg
          ,"buttons" : "OK"
          ,"nosysmenu": 1
          ,"pos"	    : "GUI_OPT"
          ,"pic"		: "i" }
    QMsgBoxP( msparams, "GUI_OPT_GEST_WIN_EXCL" )
    return
  
  g_opt_gest_win_exc_lv:
    GUI_Opt_Gest_Excl( A_GuiEvent, A_EventInfo )
    return
    
  g_GWE_but_ok:
    GWE_Save_List()
  g_GWE_but_cancel:
  GUI_OPT_GEST_WIN_EXCLGuiClose:
  GUI_OPT_GEST_WIN_EXCLGuiEscape:
    Gui, GUI_OPT:-Disabled
    Gui, GUI_OPT_GEST_WIN_EXCL:Destroy
    Gui, GUI_OPT:Default
    WinActivate,% "ahk_id " qcGui[ "opts" ]
    return
}

GWE_SearchWindow()
{
  while GuiControlGet( "gwe_search_chb", "GUI_OPT_GEST_WIN_EXCL" )
  {
    sleep 50
    WinGet, procName, ProcessName, A
    WinGetTitle, title, A
    WinGetClass, wclass, A
    tooltip % "Current window attributes:`nTitle: " title "`nClass: " wclass "`nProcess: " procName
              . "`n`nClick on window to see its attributes`nCTRL+Click to add window to the list"
    if( GetKeyState( "CTRL", "P" ) && GetKeyState( "LBUTTON", "P" ) )
    {
      glb[ "gwe_last_search_result" ] := { "title" : title, "proc" : procName, "class" : wclass }
      SetTimer,GWE_srch_menu,-1
      break
    }
  }
  tooltip
  return
  
  GWE_srch_menu:
    Menu,GWE_search_menu,Show
    return
    
  GWE_from_search:
    mit := A_ThisMenuItem
    Gui, GUI_OPT_GEST_WIN_EXCL:Default
    if InStr( mit, "title" )
      LV_Add( "", glb[ "gwe_last_search_result" ].title )
    else if InStr( mit, "class" )
      LV_Add( "", "ahk_class " glb[ "gwe_last_search_result" ].class )
    else if InStr( mit, "proc" )
      LV_Add( "", "ahk_exe " glb[ "gwe_last_search_result" ].proc )
    WinActivate,% "ahk_id " qcGui[ "opts_hws" ][ "gest_win_excl" ]
    return
}

GWE_Set_List()
{
  Gui, GUI_OPT_GEST_WIN_EXCL:Default
  for k,v in qcOpt[ "gest_win_excl" ]
    LV_Add( "", v )
  return 0
}

GWE_Save_List()
{
  Gui, GUI_OPT_GEST_WIN_EXCL:Default
  ret_list := object()
  Loop % LV_GetCount()
  {
    LV_GetText( win_title, A_Index )
    ret_list.insert( win_title )
  }
  qcOpt[ "gest_win_excl" ] := ret_list
  GWE_SetWinGroup()
  return 0
}

GWE_Add_New()
{
  Gui, GUI_OPT_GEST_WIN_EXCL:Default
  GuiControl, Focus,% qcGui[ "gwe_lv" ]
  LV_Modify( 0, "-Select -Focus" ) ;deselect all items
  LV_Add( "Focus Select", "New Title" )
  return
}

GWE_Remove_Item()
{
  Gui, GUI_OPT_GEST_WIN_EXCL:Default
  while ( next_row := LV_GetNext() )
    LV_Delete( next_row )
  return
}

GUI_Opt_Gest_Excl( event, evInfo )
{
  Gui, GUI_OPT_GEST_WIN_EXCL:Default
  If ( event = "RightClick" )
      SetTimer,GWE_show_ctx,-20
  else If ( event = "K" )
  {
    If GetKeyState( "Del", "P" )
      GWE_Remove_Item()
  }
  else If ( event = "DoubleClick" )
  {
    if LV_GetNext()
      SendMessage( qcGui[ "gwe_lv" ], LVM_EDITLABELW := 0x1000 + 118, evInfo-1, 0 )
    else
      GWE_Add_New()
  }
  return
}

GWE_SetWinGroup()
{
  static s_grp_cnt := 0
  if !glb[ "gwe_default_name" ]
  {
    GroupAdd, GWE_Default, % "ahk_pid " glb[ "QC_PID" ]
    glb[ "gwe_default_name" ] := "GWE_Default"
  }
  grp_name := "GWE_Group" s_grp_cnt++
  GroupAdd,% grp_name, % "ahk_pid " glb[ "QC_PID" ]
  for k,win in qcOpt[ "gest_win_excl" ]
    GroupAdd,% grp_name, % win
  glb[ "gwe_group_name" ] := grp_name
  return 0
}