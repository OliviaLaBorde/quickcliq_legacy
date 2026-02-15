OptAddRecentTab()
{
  global opt_recent_on, opt_recent_sub, opt_recent_logQC
  ,opt_recent_logFolders, opt_recent_logProcs, opt_recent_logWinRI
  ,opt_recent_maxItems, opt_recent_maxItems_ED, opt_recent_maxItems_lbl
  
  Gui, GUI_OPT_RECENT:New, +ParentGUI_OPT -Caption +hwndhwnd
  qcGui[ "opts_hws" ][ "Recent" ] := hwnd
  Gui, GUI_OPT_RECENT:Default
  QCSetGuiFont( "GUI_OPT_RECENT" )
  Gui,Font,Bold
  Gui,Add,GroupBox,% "ym xm w" glb[ "defOptBoxW" ] " h" glb[ "defOptBoxH" ],Recent
  Gui,Font,Normal
  
  rec_state := qcOpt[ "recent_on" ]
  Gui, Add, Checkbox,% "Section xp+15 yp+25 cNavy vopt_recent_on gg_opt_recent_on Checked" rec_state
                    , Enable "Recent"
  Gui, Add, Checkbox,% "y+5 xs+25 cNavy vopt_recent_sub gg_opt_recent_sub Checked" qcOpt[ "recent_sub" ] 
                  . " Disabled" !rec_state
                  , Show "Recent" sub in Main Menu
  Gui,Add,Checkbox,% "y+5	xs+25 cNavy vopt_recent_logQC gg_opt_recent_logQC Checked" qcOpt[ "recent_logQC" ] 
                  . " Disabled" !rec_state
                  ,% "Log recently used " glb[ "appName" ] " shortcuts"
  Gui,Add,Checkbox,% "y+5 xs+25 cNavy vopt_recent_logFolders gg_opt_recent_logFolders Checked" qcOpt[ "recent_logFolders" ] 
                  . " Disabled" !rec_state
                  , Log closed Windows Explorer folders
  Gui,Add,Checkbox,% "y+5	xs+25 cNavy vopt_recent_logProcs gg_opt_recent_logProcs Checked" qcOpt[ "recent_logProcs" ] 
                  . " Disabled" !rec_state
                  , Log closed Processes
  Gui,Add,Checkbox,% "y+5	xs+25 cNavy vopt_recent_logWinRI gg_opt_recent_logWinRI Checked" qcOpt[ "recent_logWinRI" ] 
                  . " Disabled" !rec_state
                  , Log Windows Recent Items
  Gui,Add,Text,% "y+7	xs+25 cNavy vopt_recent_maxItems_lbl Disabled" !rec_state,Max items in menu:
  Gui,Add,Edit,% "x+10 w50 yp-3 Limit2 cNavy vopt_recent_maxItems_ED gg_opt_recent_maxItems Number Disabled" !rec_state, 
  Gui,Add,UpDown,% "x+10 cNavy vopt_recent_maxItems gg_opt_recent_maxItems Range" glb[ "optRecentMin" ] "-" glb[ "optRecentMax" ] 
                . " Disabled" !rec_state
                ,% qcOpt[ "recent_maxItems" ]
                
  Gui,GUI_OPT_RECENT:Show,% glb[ "defOptBoxPos" ] " Hide"
  return
  
  g_opt_recent_on:
    qcOpt[ "recent_on" ] := GuiControlGet( A_GuiControl, "GUI_OPT_RECENT" )
    GuiControlSet("opt_recent_sub|opt_recent_logFolders|opt_recent_logProcs|opt_recent_maxItems_lbl"
                . "|opt_recent_maxItems_ED|opt_recent_maxItems|opt_recent_logWinRI|opt_recent_logQC"
                ,"", "Disabled" !qcOpt[ "recent_on" ], "GUI_OPT_RECENT", 0 )
    return
  
  g_opt_recent_sub:
    qcOpt[ "recent_sub" ] := GuiControlGet( A_GuiControl, "GUI_OPT_RECENT" )
    return
  
  g_opt_recent_logQC:
    qcOpt[ "recent_logQC" ] := GuiControlGet( A_GuiControl, "GUI_OPT_RECENT" )
    return
  
  g_opt_recent_logFolders:
    qcOpt[ "recent_logFolders" ] := GuiControlGet( A_GuiControl, "GUI_OPT_RECENT" )
    return
  
  g_opt_recent_logProcs:
    qcOpt[ "recent_logProcs" ] := GuiControlGet( A_GuiControl, "GUI_OPT_RECENT" )
    return
  
  g_opt_recent_logWinRI:
    val := GuiControlGet( A_GuiControl, "GUI_OPT_RECENT" )
    if ( val && !GetWindowsRecentState() )
      if( "Yes" = QMsgBoxP( { title : "Windows Recent Items disabled"
                             ,msg : "It seems you have Recent Items tracking disabled in Windows.`nYou must enable it in order to use this feature.`n`nDo you want us to that for you?"
                             ,modal : 1, pic : "?", buttons : "Yes|No", pos : "GUI_OPT" }, "GUI_OPT" ) )
          EnableWindowsRecent()
    qcOpt[ "recent_logWinRI" ] := val
    return
  
  g_opt_recent_maxItems:
    val := GuiControlGet( A_GuiControl, "GUI_OPT_RECENT" )
    val > glb[ "optRecentMax" ] ? val := glb[ "optRecentMax" ], GuiControlSet( "opt_recent_maxItems",val )
    val < glb[ "optRecentMin" ] ? val := glb[ "optRecentMin" ], GuiControlSet( "opt_recent_maxItems",val )
    qcOpt[ "recent_maxItems" ] := val
    return
}