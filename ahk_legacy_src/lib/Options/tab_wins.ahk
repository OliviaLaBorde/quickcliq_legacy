OptAddWinsTab()
{
  global opt_wins_on, opt_wins_sub, opt_wins_fade
  ,opt_wins_viewTransp, opt_wins_viewTransp_lbl

  Gui, GUI_OPT_WINS:New,+ParentGUI_OPT -Caption +hwndhwnd
  qcGui[ "opts_hws" ][ "Wins" ] := hwnd
  Gui, GUI_OPT_WINS:Default
  QCSetGuiFont( "GUI_OPT_WINS" )
  Gui,Font,Bold
  Gui,Add,GroupBox,% "ym xm w" glb[ "defOptBoxW" ] " h" glb[ "defOptBoxH" ],Wins
  Gui,Font,Normal
  
  Gui, Add, Checkbox,% "Section xp+15 yp+25 cNavy vopt_wins_on gg_opt_wins_on checked" qcOpt[ "wins_on" ], Enable "Wins"
  Gui, Add, Checkbox,% "y+5 cNavy vopt_wins_sub gg_opt_wins_sub checked" qcOpt[ "wins_sub" ] " Disabled" !qcOpt[ "wins_on" ]
          , Show "Wins" sub in Main Menu
  Gui, Add, Checkbox,% "y+5 cNavy vopt_wins_fade gg_opt_wins_fade checked" qcOpt[ "wins_fade" ] " Disabled" !qcOpt[ "wins_on" ]
          , Enable fading while hiding/showing windows
  
  Gui, Add, Text,% "y+15 w" glb[ "defOptBoxW" ]-50, Transparency level for a hidden windows preview:`n(hold CTRL while navigating "Wins" menu to see preview)
  Gui, Add, Slider,y+5 ToolTip Range0-255 vopt_wins_viewTransp gg_opt_wins_viewTransp,% qcOpt[ "wins_viewTransp" ]
  Gui, Add, Text, x+2 yp+3 w20 vopt_wins_viewTransp_lbl cTeal,% qcOpt[ "wins_viewTransp" ]
  Gui, Add, Text, x+10 yp cTeal, (less - more transparent)
  
  Gui,GUI_OPT_WINS:Show,% glb[ "defOptBoxPos" ] " Hide"
  return
  
  g_opt_wins_on:
    qcOpt[ "wins_on" ] := GuiControlGet( A_GuiControl, "GUI_OPT_WINS" )
    GuiControlSet("opt_wins_sub|opt_wins_fade"
        ,"","Enable" qcOpt[ "wins_on" ],"GUI_OPT_WINS",0)
    return
  
  g_opt_wins_sub:
    qcOpt[ "wins_sub" ] := GuiControlGet( A_GuiControl, "GUI_OPT_WINS" )
    return
  
  g_opt_wins_fade:
    qcOpt[ "wins_fade" ] := GuiControlGet( A_GuiControl, "GUI_OPT_WINS" )
    return
  
  g_opt_wins_viewTransp:
    qcOpt[ "wins_viewTransp" ] := GuiControlGet( A_GuiControl, "GUI_OPT_WINS" )
    GuiControlSet( "opt_wins_viewTransp_lbl", qcOpt[ "wins_viewTransp" ], "", "GUI_OPT_WINS" )
    return
}