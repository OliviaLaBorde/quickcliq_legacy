OptAddBackupTab()
{
  global opt_gen_paste_method, opt_gen_copy_method
  
  Gui, GUI_OPT_BACKUP:New,+ParentGUI_OPT -Caption +hwndhwnd
  qcGui[ "opts_hws" ][ "Other" ] := hwnd
  Gui, GUI_OPT_BACKUP:Default
  QCSetGuiFont( "GUI_OPT_BACKUP" )
  Gui,Font,Bold
  Gui,Add,GroupBox,% "ym xm w" glb[ "defOptBoxW" ] " h" glb[ "defOptBoxH" ],Other
  Gui,Font,Normal
  
  Gui, Add, button,section Yp+25 xp+15 W60 h25 Center gg_qc_saveBackup, Save...
  Gui, Add, text, yp+4 x+10 w200,% "Save all " glb["appName"] " settings"
  Gui, Add, button,xs W60 h25 Center gg_qc_restoreBackup, Restore...	
  Gui, Add, text, yp+4 x+10 w200, Restores previously saved settings
  Gui, Add, GroupBox,% "xs y+15 w" glb[ "defOptBoxW" ]-30 " h60",Copy-Paste methods
  Gui, Add, Text, xp+10 yp+25 section,Copy
  Gui, Add, DropDownList,% "xp+40 yp-3 w100 AltSubmit vopt_gen_copy_method gg_opt_gen_copy_method"
            . " choose" qcOpt[ "gen_copy_method" ]
      ,CTRL+Insert|CTRL+C
  Gui, Add, Text, x+25 yp+3,Paste
  Gui, Add, DropDownList,% "xp+40 yp-3 w100 AltSubmit vopt_gen_paste_method gg_opt_gen_paste_method"
            . " choose" qcOpt[ "gen_paste_method" ]
      ,SHIFT+Insert|CTRL+V
  Gui, Add, Link, x+10 yp+3 gg_copy_paste_hint,<a>?</a>
  Gui,GUI_OPT_BACKUP:Show,% glb[ "defOptBoxPos" ] " Hide"
  return
  
  g_opt_gen_copy_method:
    qcOpt[ "gen_copy_method" ] := GuiControlGet( "opt_gen_copy_method", "GUI_OPT_BACKUP" )
    return
    
  g_opt_gen_paste_method:
    qcOpt[ "gen_paste_method" ] := GuiControlGet( "opt_gen_paste_method", "GUI_OPT_BACKUP" )
    return
  
  g_copy_paste_hint:
    MouseGetPos,,,, hwndp,2
    msg =
    (LTrim
    Send methods used to copy&paste clips and sending memos to window.
    If you experiencing problems performing any of this actions, try to change this option.
    )
    ShowCtrlTlp( msg, hwndp )
    return
  
  g_qc_saveBackup:
    Gui, GUI_OPT:+OwnDialogs
    FileSelectFile, backuppath, S18, qc_conf.xml, Choose where to save backup
    if backuppath
      FileCopy,% glb[ "xmlConfPath" ],%backuppath%, 1
    return

  g_qc_restoreBackup:
    Gui, GUI_OPT:+OwnDialogs
    if( "Yes" != QMsgBoxP( { title : "Restoring Backup"
                             ,msg : "This action will perform " glb[ "appName" ] " restart on completion.`nDo you want to proceed?"
                             ,modal : 1, pic : "!", buttons : "Yes|No", pos : "GUI_OPT" }, "GUI_OPT" ) )
      return
    FileSelectFile, backuppath, 1,,% "Choose " glb[ "appName" ] "'s backup file", *.xml
    if backuppath
    {
      FileCopy, %backuppath%,% glb[ "xmlConfPath" ], 1
      QCRestart()
    }
    return	
}