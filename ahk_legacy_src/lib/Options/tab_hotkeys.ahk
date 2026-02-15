OptAddHotkeysTab()
{
  global opt_main_hotkey, opt_defHotkey, opt_clips_hotkey
  ,opt_hkey_glbOn, opt_wins_hotkey, opt_wndHideHkey, opt_memos_Hotkey
  , opt_recent_hotkey, but_opt_wndHideHkey
  
  Gui, GUI_OPT_HOTKEYS:New, +ParentGUI_OPT -Caption +hwndhwnd
  qcGui[ "opts_hws" ][ "Hotkeys" ] := hwnd
  Gui, GUI_OPT_HOTKEYS:Default
  QCSetGuiFont( "GUI_OPT_HOTKEYS" )
  Gui,Font,Bold
  Gui,Add,GroupBox,% "ym xm w" glb[ "defOptBoxW" ] " h" glb[ "defOptBoxH" ],Hotkeys
  Gui,Font,Normal
  ;Main Menu
  hk_text_options := "xs+90 c3C0078 w150"
  hk_lbl_options := "y+10 cNavy w80 -wrap"
  Gui, add, text,Section xp+15 %hk_lbl_options% yp+25,Main Menu
  Gui,add,text,yp %hk_text_options% vopt_main_hotkey,% HotkeyToString( qcOpt[ "main_hotkey" ] )
  Gui, add, button,xs+245 yp-5 W60 gg_opt_main_hotkey, Change
  Gui, add, button,x+10 yp W60 gg_opt_defHotkey vopt_defHotkey, Other
  ;Clips
  Gui, add, text,xs %hk_lbl_options%,Clips Menu
  Gui,add,text,yp %hk_text_options% vopt_clips_hotkey,% HotkeyToString( qcOpt[ "clips_hotkey" ] )
  Gui, add, button,xs+245 yp-5 W60 gg_opt_clips_hotkey, Change
  ;Wins
  Gui, Add, text, xs %hk_lbl_options%, Wins Menu
  Gui,add,text,yp %hk_text_options% vopt_wins_hotkey,% HotkeyToString( qcOpt[ "wins_hotkey" ] )
  Gui, add, button,xs+245 yp-5 W60 gg_opt_wins_hotkey, Change
  
  Gui, Add, text,xs %hk_lbl_options%,Hide Window
  Gui,add,text,yp %hk_text_options% vopt_wndHideHkey,% HotkeyToString( qcOpt[ "wins_wndHideHkey" ] )
  Gui, add, button,xs+245 yp-5 W60 gg_opt_wndHideHkey vbut_opt_wndHideHkey, Change
  Menu, menu_wndHideHkey, DeleteAll
  Menu, menu_wndHideHkey, Add, Custom...,g_menu_opt_wndHideHkey
  Menu, menu_wndHideHkey, Add, Ctrl+Space,g_menu_opt_wndHideHkey
  Menu, menu_wndHideHkey, Add, None,g_menu_opt_wndHideHkey
  ;Memos
  Gui, add, text,xs %hk_lbl_options%,Memos Menu
  Gui,add,text,yp %hk_text_options% vopt_memos_Hotkey,% HotkeyToString( qcOpt[ "memos_hotkey" ] )
  Gui, add, button,xs+245 yp-5 W60 gg_opt_memos_Hotkey, Change
  ;Recent
  Gui, add, text,xs %hk_lbl_options%,Recent Menu
  Gui,add,text,yp %hk_text_options% vopt_recent_hotkey,% HotkeyToString( qcOpt[ "recent_hotkey" ] )
  Gui, add, button,xs+245 yp-5 W60 gg_opt_recent_hotkey, Change
  Gui, add, text,% "xs y" glb[ "defOptBoxH" ]-20 " cMaroon vopt_hkey_glbOn gfakesub",% ( qcOpt[ "hkey_glbOn" ] != 1 ? "Hotkeys are currently turned OFF globally!" : "" )
  Gui,GUI_OPT_HOTKEYS:Show,% glb[ "defOptBoxPos" ] " Hide"
  return
  
  g_opt_wndHideHkey:
    p := ControlGetPos( A_GuiControl, "GUI_OPT_HOTKEYS" )
    CoordMode, Menu, Relative
    Menu, menu_wndHideHkey, Show,% p.X,% ( p.Y + p.H )
    CoordMode, Menu
    return
  
  g_menu_opt_wndHideHkey:
    if( A_ThisMenuItemPos = 1 )
      new_hk := CustomHotkey_EditGUI( qcOpt[ "wins_wndHideHkey" ],"GUI_OPT","Change Hotkey")
    else if( A_ThisMenuItemPos = 2 )
      new_hk := "^Space"
    else
      new_hk := ""
    if !( new_hk == qcOpt[ "wins_wndHideHkey" ] )
      qcOpt[ "wins_wndHideHkey" ] := new_hk
    GuiControlSet( "opt_wndHideHkey"
                , HotkeyToString( new_hk )
                , "", "GUI_OPT_HOTKEYS" )
    return
  
  g_opt_main_hotkey:
  g_opt_clips_hotkey:
  g_opt_memos_hotkey:
  g_opt_recent_hotkey:
  g_opt_wins_hotkey:
    lbl := A_ThisLabel
    hkopt := instr(lbl,"main") ? "main_hotkey"
            : instr(lbl,"memos") ? "Memos_Hotkey"
            : instr(lbl,"clips") ? "clips_hotkey"
            : instr(lbl,"Recent") ? "Recent_Hotkey"
            : instr(lbl,"wins") ? "wins_hotkey"
            : ShowExc( "Bad label: " lbl )
    old_hk := qcOpt[ hkopt ]
    new_hk := CustomHotkey_EditGUI( qcOpt[ hkopt ],"GUI_OPT","Change Hotkey")
    if ( new_hk == old_hk )
      return
    if( new_hk = "" && hkopt = "main_hotkey" )
    {
      DTP( "You cannot disable main menu hotkey, alas..." )
      return
    }
    qcOpt[ hkopt ] := new_hk
    Hotkey( old_hk, 0 )
    GuiControlSet( substr( lbl, 3 )
                , HotkeyToString( new_hk )
                , "", "GUI_OPT_HOTKEYS" )
    return
  
  g_opt_defHotkey:
    GUI_OptMainDefHK_Show()
    return
}

GUI_OptMainDefHK_Show()
{
  global opt_ctrlRbHkey, opt_ctrlMbHkey, opt_ctrlLRbHKey
  gui, GUI_OPT_DEF_HKS:default
  gui, +ownerGUI_OPT
  Gui, GUI_OPT:+Disabled
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  Gui, Add, Checkbox,% "vopt_ctrlRbHkey gg_defHkeyChange checked" qcOpt[ "main_ctrlRbHkey" ], Ctrl + Right Mouse Button
  Gui, Add, Checkbox,% "vopt_ctrlMbHkey gg_defHkeyChange checked" qcOpt[ "main_ctrlMbHkey" ], Ctrl + Middle Mouse Button
  Gui, Add, Checkbox,% "vopt_ctrlLRbHKey gg_defHkeyChange checked" qcOpt[ "main_ctrlLRbHKey" ], Left + Right Mouse Button
  ;################################
  Gui, +ToolWindow ;removing maximize,minimize buttons
  Gui, Show,,Default Hotkeys
  return
  
  GUI_OPT_DEF_HKSGuiClose:
    Gui, GUI_OPT:-Disabled
    Gui, GUI_OPT_DEF_HKS:Destroy
    return
  
  g_defHkeyChange:
    optName := "main" SubStr( A_GuiControl, 4 )
    qcOpt[ optName ] := GuiControlGet( A_GuiControl, "GUI_OPT_DEF_HKS" )
    return
}