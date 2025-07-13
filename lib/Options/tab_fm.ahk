OptAddFolderMenuTab()
{
  global opt_fm_refresh_on, opt_fm_refresh_time, opt_fm_show_open_item
  ,opt_fm_extractExe, opt_fm_showicons, opt_fm_show_files_ext
  ,opt_fm_iconssize, opt_fm_files_first, opt_fm_show_lnk
  ,opt_fm_sort_type, opt_fm_sort_mode
  
  Gui, GUI_OPT_FM:New, +ParentGUI_OPT -Caption +hwndhwnd
  qcGui[ "opts_hws" ][ "Folder Menu" ] := hwnd
  Gui, GUI_OPT_FM:Default
  QCSetGuiFont( "GUI_OPT_FM" )
  Gui,Font,Bold
  Gui,Add,GroupBox,% "ym xm w" glb[ "defOptBoxW" ] " h" glb[ "defOptBoxH" ],Folder Menu
  Gui,Font,Normal
  
  Gui, Add, Text,% "Section xp+15 yp+25 cNavy +Wrap",Icons Size
  Gui, Add, DropDownList,% "xs+65 yp-3 w100 +Wrap vopt_fm_iconssize gg_opt_fm_iconssize",% "global|16|24|32"
  GuiControl, ChooseString, opt_fm_iconssize,% qcOpt[ "fm_iconssize" ]
  
  Gui, Add, Text,% "xs y+10 cNavy", Sort files by
  Gui, Add, DropDownList,% "xs+65 yp-3 w100 vopt_fm_sort_type gg_opt_fm_sort_type", Name|Time Created|Time Modified|Type|Size
  GuiControl, ChooseString, opt_fm_sort_type,% qcOpt[ "fm_sort_type" ]
  Gui, Add, DropDownList,% "x+5 yp w60 vopt_fm_sort_mode gg_opt_fm_sort_mode", Asc|Desc
  GuiControl, ChooseString, opt_fm_sort_mode,% qcOpt[ "fm_sort_mode" ]
  
  Gui, Add, Checkbox,% "xs y+10 vopt_fm_refresh_on cNavy +Wrap gg_opt_fm_refresh_on Checked" qcOpt[ "fm_refresh_on" ]
     ,Refresh Folder Menu each
  Gui,Add,Edit,% "x+5 yp-3 w50 vopt_fm_refresh_time number limit3 gg_opt_fm_refresh_time",% qcOpt[ "fm_refresh_time" ]
  Gui,Add,Text,% "x+5 yp+3 cNavy",minutes
  Gui, Add, CheckBox,% "xs y+10 cNavy +Wrap vopt_fm_show_open_item gg_opt_fm_show_open_item Checked" qcOpt[ "fm_show_open_item" ]
     , Show "open" item at the top of each menu ( .. )
  Gui, Add, CheckBox,% "xs y+10 cNavy +Wrap vopt_fm_extractExe gg_opt_fm_extractExe Checked" qcOpt[ "fm_extractexe" ]
     , Extract original icons for .exe files
  Gui, Add, CheckBox,% "xs y+10 cNavy +Wrap vopt_fm_showicons gg_opt_fm_showicons Checked" qcOpt[ "fm_showicons" ]
     , Show icons
  Gui, Add, CheckBox,% "xs y+10 cNavy +Wrap vopt_fm_show_files_ext gg_opt_fm_show_files_ext Checked" qcOpt[ "fm_show_files_ext" ]
     , Show files extension
  Gui, Add, CheckBox,% "xs y+10 cNavy +Wrap vopt_fm_show_lnk gg_opt_fm_show_lnk Checked" qcOpt[ "fm_show_lnk" ]
     , Show .lnk extension
  Gui, Add, CheckBox,% "xs y+10 cNavy +Wrap vopt_fm_files_first gg_opt_fm_files_first Checked" qcOpt[ "fm_files_first" ]
     , Show files before folders
  
  Gui, GUI_OPT_FM:Show,% glb[ "defOptBoxPos" ] " Hide"
  return
  
  g_opt_fm_sort_type:
    qcOpt[ "fm_sort_type" ] := GuiControlGet( "opt_fm_sort_type", "GUI_OPT_FM" )
    return
    
  g_opt_fm_sort_mode:
    qcOpt[ "fm_sort_mode" ] := GuiControlGet( "opt_fm_sort_mode", "GUI_OPT_FM" )
    return
  
  g_opt_fm_iconssize:
    qcOpt[ "fm_iconssize" ] := GuiControlGet( "opt_fm_iconssize", "GUI_OPT_FM" )
    FM_GetIcon( "deleteAll", "" )
    return
  
  g_opt_fm_refresh_on:
    qcOpt[ "fm_refresh_on" ] := GuiControlGet( "opt_fm_refresh_on", "GUI_OPT_FM" )
    return
    
  g_opt_fm_refresh_time:
    qcOpt[ "fm_refresh_time" ] := GuiControlGet( "opt_fm_refresh_time", "GUI_OPT_FM" )
    return
    
  g_opt_fm_show_open_item:
    qcOpt[ "fm_show_open_item" ] := GuiControlGet( "opt_fm_show_open_item", "GUI_OPT_FM" )
    return
    
  g_opt_fm_extractExe:
    qcOpt[ "fm_extractexe" ] := GuiControlGet( "opt_fm_extractExe", "GUI_OPT_FM" )
    return
    
  g_opt_fm_showicons:
    qcOpt[ "fm_showicons" ] := GuiControlGet( "opt_fm_showicons", "GUI_OPT_FM" )
    return
    
  g_opt_fm_show_files_ext:
    qcOpt[ "fm_show_files_ext" ] := GuiControlGet( "opt_fm_show_files_ext", "GUI_OPT_FM" )
    return
    
  g_opt_fm_files_first:
    qcOpt[ "fm_files_first" ] := GuiControlGet( "opt_fm_files_first", "GUI_OPT_FM" )
    return
    
  g_opt_fm_show_lnk:
    qcOpt[ "fm_show_lnk" ] := GuiControlGet( "opt_fm_show_lnk", "GUI_OPT_FM" )
    return
}