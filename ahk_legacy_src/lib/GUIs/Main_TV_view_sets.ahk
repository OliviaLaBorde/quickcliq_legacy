GUI_TV_Options()
{
  global opt_main_tv_defColors, opt_main_tv_glFont, opt_main_tv_fontSize
  
  Gui, GUI_TV_OPTS:New, +owner1 +ToolWindow
  Gui,1:+Disabled
  Gui, GUI_TV_OPTS:Default
  Gui, Add, Checkbox,% "vopt_main_tv_defColors gg_opt_main_tv_defColors checked" qcOpt[ "main_tv_defColors" ],Default colors
  Gui, Add, Checkbox,% "vopt_main_tv_glFont gg_opt_main_tv_glFont checked" qcOpt[ "main_tv_glFont" ],Use menu font
  Gui, Add, Text,% "y+10",Font size
  Gui, Add, DropDownList,% "x+5 yp-3 w50 vopt_main_tv_fontSize gg_opt_main_tv_fontSize", 8|9|10|11|12|14|16|18|20
  GuiControl, ChooseString, opt_main_tv_fontSize,% qcOpt[ "main_tv_fontSize" ]
  Gui, Add, Button,% "xm y+15 w" glb[ "defButW" ] " h" glb[ "defButH" ] " gtv_opt_exit",OK
  
  Gui, 1:+LastFoundExist
  WinGetPos, X, Y, W, H,% "AHK_ID " WinExist()
  Gui,Show,% "x" . round(x+(w/2)-200) . " y" . round(y+(h/2)-200) " w200", Tree View options
  return
  
  g_opt_main_tv_fontSize:
    qcOpt[ "main_tv_fontSize" ] := GuiControlGet( "opt_main_tv_fontSize", "GUI_TV_OPTS" )
    QCTVSetFont()
    return
  
  g_opt_main_tv_glFont:
    qcOpt[ "main_tv_glFont" ] := GuiControlGet( "opt_main_tv_glFont", "GUI_TV_OPTS" )
    QCTVSetFont()
    return
  
  g_opt_main_tv_defColors:
    qcOpt[ "main_tv_defColors" ] := GuiControlGet( "opt_main_tv_defColors", "GUI_TV_OPTS" )
    GUI_Main_TV_ToggleColors( qcOpt[ "main_tv_defColors" ] )
    return
  
  tv_opt_exit:
  GUI_TV_OPTSGuiClose:
  GUI_TV_OPTSGuiEscape:
    Gui,1:-Disabled
    Gui,GUI_TV_OPTS:Destroy
    return
}