OptAddAprnsTab()
{
  global opt_iconsSize, opt_transp_lbl, opt_transp, opt_heightAdjust, opt_heightAdjust_lbl
  ,opt_noTheme, opt_lightMenu, opt_iconsOnly, opt_IconsTlp, opt_columns
  ,opt_ColNum, opt_colBar, opt_TForm, opt_fontqlty, opt_numpercol, opt_col_mode1, opt_col_mode2
  ,opt_frame_sel_mode,opt_frame_sel_mode_edit
  static hopt_mainfont
  Gui, GUI_OPT_APPR:New,+ParentGUI_OPT -Caption +hwndhwnd
  qcGui[ "opts_hws" ][ "Appearance" ] := hwnd
  Gui, GUI_OPT_APPR:Default
  QCSetGuiFont( "GUI_OPT_APPR" )
  Gui,Font,Bold
  Gui,Add,GroupBox,% "ym xm w" glb[ "defOptBoxW" ] " h" glb[ "defOptBoxH" ],Appearance
  Gui,Font,Normal
  Gui, add, text,xp+15 yp+25 Section cNavy,Icons Size:
  Gui, Add, DropDownList,x+50 yp-3 W100 vopt_iconsSize gg_opt_iconsSize, 16|24|32
  GuiControl, ChooseString, opt_iconsSize,% qcOpt[ "aprns_iconsSize" ]

  Gui, add, text,xs y+8 cNavy,Transparency:
  Gui, Add, Slider,x+25 yp-3 W115 ToolTip Range0-255 vopt_transp gg_opt_transp,% qcOpt[ "aprns_transp" ]
  Gui, add, text,x+-1 yp+3 cTeal vopt_transp_lbl w30,% qcOpt[ "aprns_transp" ]

  Gui, add, text,xs y+20 cNavy,Items height adjust:
  Gui, Add, Slider,x+2 yp-3 W115 ToolTip Range0-10 vopt_heightAdjust gg_opt_heightAdjust,% qcOpt[ "aprns_heightAdjust" ]
  Gui, add, text,x+-1 yp+3 cTeal w30 vopt_heightAdjust_lbl,% "+" qcOpt[ "aprns_heightAdjust" ]
  
  Gui, Add, Checkbox,% "xs y+15 vopt_lightMenu gg_opt_lightMenu cNavy +Wrap Checked" qcOpt[ "aprns_lightMenu" ]
     , Light-Style Menu
  Gui, Add, Checkbox,% "xs y+5 vopt_noTheme gg_opt_noTheme cNavy +Wrap Checked" qcOpt[ "gen_noTheme" ]
     , Remove Theme
  Gui, Add, Checkbox,% "xs y+5 gg_opt_frame_sel_mode vopt_frame_sel_mode cNavy +Wrap Checked" qcOpt[ "aprns_frameSelMode" ]
     ,Highlight items by frame. Width 
  Gui,Add,Edit,% "x+10 w50 yp-5 Limit2 cNavy vopt_frame_sel_mode_edit gg_opt_frame_sel_mode_edit Number"
     ,% qcOpt[ "aprns_frameWidth" ]
  Gui, Add, Checkbox,% "xs y+5 vopt_iconsOnly gg_opt_iconsOnly cNavy +Wrap Checked" qcOpt[ "aprns_iconsOnly" ]
     , Show icons only
  Gui, Add, Checkbox,% "xs+30 y+5 vopt_IconsTlp gg_opt_IconsTlp cNavy +Wrap Checked" qcOpt[ "aprns_IconsTlp" ] . " Disabled" !qcOpt[ "aprns_iconsOnly" ]
     , Show tooltips
  Gui, Add, Checkbox,% "xs y+5 vopt_columns gg_opt_columns cNavy +Wrap Checked" qcOpt[ "aprns_columns" ]
     , Divide menu by columns.
  Gui, Add, Radio,% "x+10 yp-7 cNavy vopt_col_mode1 gg_opt_col_mode Checked" qcOpt[ "aprns_col_mode" ] " Disabled" !qcOpt[ "aprns_columns" ]
      , Number of columns:
  Gui, Add, Radio,% "xp y+10 cNavy vopt_col_mode2 gg_opt_col_mode Checked" !qcOpt[ "aprns_col_mode" ] " Disabled" !qcOpt[ "aprns_columns" ]
      ,Max items per column:
  Gui,Add,Edit,% "x+10 w50 yp-30 Limit3 cNavy vopt_ColNum gg_opt_ColNum Number Disabled" !qcOpt[ "aprns_columns" ]
     ,% qcOpt[ "aprns_ColNum" ]
  Gui,Add,Edit,% "xp w50 y+5 Limit3 cNavy vopt_numpercol gg_opt_numpercol Number Disabled" !qcOpt[ "aprns_columns" ]
     ,% qcOpt[ "aprns_numpercol" ]
  Gui, Add, Checkbox,% "xs+30 y+1 vopt_colBar gg_opt_colBar cNavy +Wrap Checked" qcOpt[ "aprns_colBar" ]
     . " Disabled" !qcOpt[ "aprns_columns" ]
     , Show column bar break
  Gui, Add, Checkbox,% "xs+30 y+5 vopt_TForm gg_opt_TForm cNavy +Wrap Checked" qcOpt[ "aprns_TForm" ] . " Disabled" !qcOpt[ "aprns_columns" ]
     , T-Form
  
  Gui, Add, Text, xs y+25, Menu Font
  Gui, Add, Text,% "x+10 w140 center H" glb[ "defButH" ] " yp-5 +0x1000 hwndhopt_mainfont"
  ApprnsTabSetMainFont( hopt_mainfont )
  Gui, Add, Button,% "x+10 gg_opt_mainfont yp w" glb[ "defButW" ] " h" glb[ "defButH" ],Change
  Gui, Add, Button,x+10 yp hp wp gg_opt_mainfont_def, Default
  Gui,Add, Text, xs y+10, Font Quality
  qval := { 0 : 1, 4 : 2, 5 : 3, 6 : 4 }[ qcOpt[ "aprns_fontqlty" ] ]
  Gui,Add, DropDownList, x+22 yp-3 gg_opt_fontqlty vopt_fontqlty Choose%qval%,default|antialiased|cleartype|cleartype natural
  Gui,GUI_OPT_APPR:Show,% glb[ "defOptBoxPos" ] " Hide"
  return
  
  g_opt_frame_sel_mode:
    qcOpt[ "aprns_frameSelMode" ] := GuiControlGet( "opt_frame_sel_mode", "GUI_OPT_APPR" )
    return
  
  g_opt_frame_sel_mode_edit:
    qcOpt[ "aprns_frameWidth" ] := GuiControlGet( "opt_frame_sel_mode_edit", "GUI_OPT_APPR" )
    return
  
  g_opt_col_mode:
    qcOpt[ "aprns_col_mode" ] := GuiControlGet( "opt_col_mode1", "GUI_OPT_APPR" )
    return
  
  g_opt_fontqlty:
    val := GuiControlGet( "opt_fontqlty", "GUI_OPT_APPR" )
    qlty := val = "default" ? 0
            : val = "antialiased" ? 4
            : val = "cleartype" ? 5
            : val = "cleartype natural" ? 6 : 0
    qcOpt[ "aprns_fontqlty" ] := qlty
    ApprnsTabSetMainFont( hopt_mainfont )
    return
  
  g_opt_mainfont:
    if( ret := Dlg_Font( qcOpt[ "aprns_mainfont" ], False, qcGui[ "opts" ] ) )
    {
      qcOpt[ "aprns_mainfont" ] := ret
      ApprnsTabSetMainFont( hopt_mainfont )
    }
    return
  
  g_opt_mainfont_def:
    qcOpt[ "aprns_mainfont" ] := ""
    ApprnsTabSetMainFont( hopt_mainfont )
    return
    
  g_opt_iconsSize:
    qcOpt[ "aprns_iconsSize" ] := GuiControlGet( "opt_iconsSize", "GUI_OPT_APPR" )
    FM_GetIcon( "deleteAll", "" )
    return
  g_opt_transp:
    qcOpt[ "aprns_transp" ] := GuiControlGet( "opt_transp", "GUI_OPT_APPR" )
    GuiControlSet( "opt_transp_lbl", qcOpt[ "aprns_transp" ], "", "GUI_OPT_APPR" )
    return
  g_opt_heightAdjust:
    qcOpt[ "aprns_heightAdjust" ] := GuiControlGet( "opt_heightAdjust", "GUI_OPT_APPR" )
    GuiControlSet( "opt_heightAdjust_lbl", qcOpt[ "aprns_heightAdjust" ], "", "GUI_OPT_APPR" )
    return
  g_opt_lightMenu:
    qcOpt[ "aprns_lightMenu" ] := GuiControlGet( "opt_lightMenu", "GUI_OPT_APPR" )
    return
  g_opt_noTheme:
    qcOpt[ "gen_noTheme" ] := GuiControlGet( "opt_noTheme", "GUI_OPT_APPR" )
    Gui,+OwnDialogs
    MsgBox,68,% glb[ "appName" ] " restart required",% glb[ "appName" ] " requires a restart to change this option.`nDo you want to restart now?"
    IfMsgBox,Yes
    {
      qcconf.Save()
      QCRestart()
    }
    return
  g_opt_iconsOnly:
    qcOpt[ "aprns_iconsOnly" ] := GuiControlGet( "opt_iconsOnly", "GUI_OPT_APPR" )
    GuiControlSet( "opt_IconsTlp","","Enabled" qcOpt[ "aprns_iconsOnly" ],"GUI_OPT_APPR",0)
    return
  g_opt_IconsTlp:
    qcOpt[ "aprns_IconsTlp" ] := GuiControlGet( "opt_IconsTlp", "GUI_OPT_APPR" )
    return
  g_opt_columns:
    qcOpt[ "aprns_columns" ] := GuiControlGet( "opt_columns", "GUI_OPT_APPR" )
    GuiControlSet("opt_col_mode1|opt_col_mode2|opt_numpercol|opt_ColNum|opt_colBar|opt_TForm"
                  ,"","Enabled" qcOpt[ "aprns_columns" ],"GUI_OPT_APPR",0)
    return
  g_opt_ColNum:
    qcOpt[ "aprns_ColNum" ] := GuiControlGet( "opt_ColNum", "GUI_OPT_APPR" )
    return
  g_opt_numpercol:
    qcOpt[ "aprns_numpercol" ] := GuiControlGet( "opt_numpercol", "GUI_OPT_APPR" )
    return
  g_opt_colBar:
    qcOpt[ "aprns_colBar" ] := GuiControlGet( "opt_colBar", "GUI_OPT_APPR" )
    return
  g_opt_TForm:
    qcOpt[ "aprns_TForm" ] := GuiControlGet( "opt_TForm", "GUI_OPT_APPR" )
    return
}

ApprnsTabSetMainFont( hCtrl )
{
  static hMainFont
  fontObj := QCGetFontSets()
  fontObj["height"] := 12
  GuiControlSet( hCtrl, fontObj[ "name" ], "", "GUI_OPT_APPR" )
  DeleteObject( hMainFont )
  hMainFont := ControlSetFont( hCtrl, fontObj )
  return hMainFont
}