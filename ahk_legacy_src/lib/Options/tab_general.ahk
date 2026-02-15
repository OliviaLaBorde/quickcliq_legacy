OptAddGenTab()
{
  global opt_editorItem, opt_helpSub, opt_suspendSub, opt_trayIcon
  ,opt_ContextQC, opt_RunOnStartup, opt_autoUpd, opt_smenusOn, opt_cmdDelay
  ,opt_IconRelPath, opt_CmdRelPath, opt_mnem_method
  Gui, GUI_OPT_GENERAL:New,+ParentGUI_OPT -Caption +hwndhwnd 
  qcGui[ "opts_hws" ][ "General" ] := hwnd
  Gui, GUI_OPT_GENERAL:Default
  QCSetGuiFont( "GUI_OPT_GENERAL" )
  Gui,Font,Bold
  Gui,Add,GroupBox,% "ym xm w" glb[ "defOptBoxW" ] " h" glb[ "defOptBoxH" ],General
  Gui,Font,Normal
  Gui, Add, Checkbox,% "Section xp+15 yp+25 vopt_editorItem cNavy +Wrap gg_opt_editorItem Checked" qcOpt[ "gen_editorItem" ]
     ,Show "Open Editor" item in main menu
  Gui, Add, Checkbox,% "xs y+5 cNavy vopt_helpSub W210 gg_opt_helpSub Checked" . qcOpt[ "gen_helpSub" ]
     ,Show "Help" item in main menu
  Gui, Add, Checkbox,% "xs y+5 cNavy vopt_suspendSub W210 gg_opt_suspendSub Checked" . qcOpt[ "gen_suspendSub" ]
     ,Show "Suspend" menu
  Gui, Add, Checkbox,% "vopt_trayIcon cNavy +Wrap gg_opt_trayIcon Checked" qcOpt[ "gen_trayIcon" ]
     ,Show tray icon
  Gui, Add, Checkbox,% "xs y+25 vopt_ContextQC gg_opt_ContextQC cNavy Checked" . qcOpt[ "gen_ContextQC" ]
     ,% "Add '" glb[ "qcctxname" ] "' item to file's context menu"
  Gui, Add, Checkbox,% "xs y+5 vopt_RunOnStartup gg_opt_RunOnStartup cNavy +Wrap Checked" . qcOpt[ "gen_RunOnStartup" ]
     ,Run on Windows startup
  Gui, Add, Checkbox,% "xs y+5 vopt_autoUpd gg_opt_autoUpd cNavy +Wrap Checked" qcOpt[ "gen_autoUpd" ]
     ,Check for updates automatically	
  Gui, Add, Checkbox,% "xs y+5 vopt_smenusOn gg_opt_smenusOn cNavy +Wrap Checked" qcOpt[ "gen_smenusOn" ]
     ,Enable S-Menus
  Gui, add, text,xs y+20 cNavy, Delay between commands
  Gui, add, Edit,xs+150 yp-2 R1 W55 vopt_cmdDelay gg_opt_cmdDelay Number Limit5
     ,% qcOpt[ "gen_cmdDelay" ]
  Gui, add, text,x+8 cNavy yp+2, msec
  Gui, add, text,xs cNavy,Menu mnemonic method
  Gui, Add, DropDownList,xs+150 yp-3 W65 vopt_mnem_method gg_opt_mnem_method, run|select
  GuiControl, ChooseString, opt_mnem_method,% qcOpt[ "gen_mnem_method" ]
  
  Gui, add, GroupBox,xs Section cNavy y+15 w330 h70, Portability options
  Gui, add, Checkbox,% "xs+10 ys+25 cNavy w300 vopt_IconRelPath gg_opt_IconRelPath Checked" qcOpt[ "gen_IconRelPath" ]
     ,Always save icons relative path
  Gui, add, Checkbox,% "xs+10 y+5 cNavy w300 vopt_CmdRelPath gg_opt_CmdRelPath Checked" qcOpt[ "gen_CmdRelPath" ]
     ,Always save commands relative path
  Gui,GUI_OPT_GENERAL:Show,% glb[ "defOptBoxPos" ] " Hide"
  return
  
  g_opt_mnem_method:
    qcOpt[ "gen_mnem_method" ] := GuiControlGet( "opt_mnem_method", "GUI_OPT_GENERAL" )
    return
  
  g_opt_editorItem:
    qcOpt[ "gen_editorItem" ] := GuiControlGet( "opt_editorItem", "GUI_OPT_GENERAL" )
    return
  g_opt_helpSub:
    qcOpt[ "gen_helpSub" ] := GuiControlGet( "opt_helpSub", "GUI_OPT_GENERAL" )
    return
  g_opt_suspendSub:
    qcOpt[ "gen_suspendSub" ] := GuiControlGet( "opt_suspendSub", "GUI_OPT_GENERAL" )
    return
  g_opt_trayIcon:
    qcOpt[ "gen_trayIcon" ] := GuiControlGet( "opt_trayIcon", "GUI_OPT_GENERAL" )
    Menu, Tray,% qcOpt[ "gen_trayIcon" ] ? "Icon" : "NoIcon"
    return
  g_opt_ContextQC:
    Gui,+OwnDialogs
    val := GuiControlGet( "opt_ContextQC", "GUI_OPT_GENERAL" )
    if Context_Reg( val )
      qcOpt[ "gen_ContextQC" ] := val
    else
      GuiControlSet( "opt_ContextQC", !val, "", "GUI_OPT_GENERAL" )
    return
  g_opt_RunOnStartup:
    qcOpt[ "gen_RunOnStartup" ] := GuiControlGet( "opt_RunOnStartup", "GUI_OPT_GENERAL" )
    CheckStartupShortcut()
    return
  g_opt_autoUpd:
    qcOpt[ "gen_autoUpd" ] := GuiControlGet( "opt_autoUpd", "GUI_OPT_GENERAL" )
    return
  g_opt_smenusOn:
    Gui,+OwnDialogs
    val := GuiControlGet( "opt_smenusOn", "GUI_OPT_GENERAL" )
    if SMenu_SetRegistry( val )
      qcOpt[ "gen_smenusOn" ] := val
    else
      GuiControlSet( "opt_smenusOn", !val, "", "GUI_OPT_GENERAL" )
    Return
  g_opt_cmdDelay:
    val := GuiControlGet( "opt_cmdDelay", "GUI_OPT_GENERAL" )
    If (val > 10000)
      GuiControlSet( "opt_cmdDelay", val := 10000, "", "GUI_OPT_GENERAL" ) 
    qcOpt[ "gen_cmdDelay" ] := val
    return
  g_opt_IconRelPath:
  g_opt_CmdRelPath:
    Gui, +OwnDialogs
    val := GuiControlGet( A_GuiControl, "GUI_OPT_GENERAL" )
    if val
    {
      appname := glb[ "appName" ]
      msg =
      ( LTrim
      If checked, every path for icon or cmmand will be automatically saved in relative form.
      
      It can be very useful if you use %appname% from portable device and most of your shortcuts point to programs on this device.
      However, if you moved %appname%'s executable from one place to another, all such commands/icons will stop work.
      
      Enable it only if you sure what you doing. Turn ON?
      )
      ans := QMsgBoxP( { title : "Confirmation"
                        , msg : msg, pos : "GUI_OPT", modal : 1, pic : "?"
                        , buttons : "Yes|No" }, "GUI_OPT" )
      If !( ans = "Yes" )
      {
        GuiControlSet( A_GuiControl, 0, "", "GUI_OPT_GENERAL" )
        return
      }
    }
    if InStr( A_GuiControl, "Icon" )
      qcOpt[ "gen_IconRelPath" ] := val
    else
      qcOpt[ "gen_CmdRelPath" ] := val
    return
}