OptAddMemosTab()
{
  global opt_Memos_On, opt_memos_sub, opt_memos_DelConf
  ,OTM_bg_default_color, OTM_t_default_color, OTM_default_font
  
  Gui, GUI_OPT_MEMOS:New,+ParentGUI_OPT -Caption +hwndhwnd
  qcGui[ "opts_hws" ][ "Memos" ] := hwnd
  Gui, GUI_OPT_MEMOS:Default
  QCSetGuiFont( "GUI_OPT_MEMOS" )
  Gui,Font,Bold
  Gui,Add,GroupBox,% "ym xm w" glb[ "defOptBoxW" ] " h" glb[ "defOptBoxH" ],Memos
  Gui,Font,Normal
  
  Gui, Add, Checkbox,% "section yp+25 xp+15 cNavy vopt_Memos_On gg_opt_Memos_On checked" qcOpt[ "Memos_On" ], Enable "Memos"
  Gui, Add, Checkbox,% "y+5 cNavy vopt_memos_sub gg_opt_memos_sub checked" qcOpt[ "memos_sub" ] " Disabled" !qcOpt[ "Memos_On" ]
          , Show "Memos" sub in main menu
  Gui, Add, Checkbox,% "y+5 cNavy vopt_memos_DelConf gg_opt_memos_DelConf checked" qcOpt["memos_DelConf"] " Disabled" !qcOpt[ "Memos_On" ]
          , Memo delete confirmation

  Gui, Add, Text,y+15,Default colors for On-Top memos:
  Gui, Add, button,y+5 vOTM_bg_default_color gg_OTM_bg_default_color, Change...
  Gui, Add, Text,x+5 yp+4,Change default background color
  Gui, Add, button,xs y+12 vOTM_t_default_color gg_OTM_t_default_color, Change...
  Gui, Add, Text,x+5 yp+4,Change default text color
  Gui, Add, button,xs y+12 vOTM_default_font gg_OTM_default_font, Change...
  Gui, Add, Text,x+5 yp+4,Change default font
  
  Gui,GUI_OPT_MEMOS:Show,% glb[ "defOptBoxPos" ] " Hide"
  return
  
  g_opt_Memos_On:
    qcOpt[ "Memos_On" ] := GuiControlGet( A_GuiControl, "GUI_OPT_MEMOS" )
    GuiControlSet("opt_memos_sub|opt_memos_DelConf"
            ,"","Enable" qcOpt[ "Memos_On" ],"GUI_OPT_MEMOS",0)
    return
  
  g_opt_memos_sub:
    qcOpt[ "memos_sub" ] := GuiControlGet( A_GuiControl, "GUI_OPT_MEMOS" )
    return
  
  g_opt_memos_DelConf:
    qcOpt["memos_DelConf"] := GuiControlGet( A_GuiControl, "GUI_OPT_MEMOS" )
    return
  
  g_OTM_bg_default_color:
  g_OTM_t_default_color:
    clr := qcOpt[ A_GuiControl ]
    if !IsInteger( clr )
      clr := 0
    if Dlg_Color( clr, qcGui[ "opts" ] )
      qcOpt[ A_GuiControl ] := clr
    return
  
  g_OTM_default_font:
    if( ret := Dlg_Font( qcOpt[ "OTM_default_font" ], False, qcGui[ "opts" ] ) )
      qcOpt[ "OTM_default_font" ] := ret
    return
}