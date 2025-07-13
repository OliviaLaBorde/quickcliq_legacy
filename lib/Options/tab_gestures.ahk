OptAddGestrsTab()
{
  global opt_main_gestOn, opt_main_gesture, opt_clips_gesture, opt_clips_gestOn
  ,opt_wins_gesture,opt_wins_gestOn,opt_Memos_Gesture,opt_memos_gestOn
  ,opt_recent_gestOn,opt_Recent_Gesture,opt_gest_tempNotify,g_opt_gest_tempNotify
  ,opt_gest_time,opt_gest_curBut,opt_gest_glbOn
  ,opt_gest_modctrl,opt_gest_modshift,opt_gest_modwin,opt_gest_win_excl
  
  Gui, GUI_OPT_GESTURES:New, +ParentGUI_OPT -Caption +hwndhwnd
  qcGui[ "opts_hws" ][ "Gestures" ] := hwnd
  Gui, GUI_OPT_GESTURES:Default
  QCSetGuiFont( "GUI_OPT_GESTURES" )
  Gui,Font,Bold
  Gui,Add,GroupBox,% "ym xm w" glb[ "defOptBoxW" ] " h" glb[ "defOptBoxH" ],Gestures
  Gui,Font,Normal
  
  Gui, Add, Text,Section xp+15 yp+25 +Wrap W250, Use the following letters for mouse gestures:
  Gui, Add, Text,xs w200 y+5 cTeal, U - up`, D - down`, L - left`, R - right
  
  Gui, Add, Checkbox,% "xs y+10 cNavy vopt_main_gestOn gg_opt_main_gestOn checked" qcOpt[ "main_gestOn" ],Main Menu
  Gui, Add, Edit,xs+110 yp-3 +Uppercase W120 Limit4 vopt_main_gesture gg_opt_main_gesture,% qcOpt[ "main_gesture" ]
  
  Gui, Add, Checkbox,% "xs y+10 cNavy vopt_clips_gestOn gg_opt_clips_gestOn checked" qcOpt[ "clips_gestOn" ],Clips Menu
  Gui, Add, Edit, xs+110 yp-3 +Uppercase W120 Limit4 vopt_clips_gesture gg_opt_clips_gesture,% qcOpt[ "clips_gesture" ]
  
  Gui, Add, Checkbox,% "xs y+10 cNavy vopt_wins_gestOn gg_opt_wins_gestOn checked" qcOpt[ "wins_gestOn" ],Windows Menu
  Gui, Add, Edit,xs+110 yp-3 +Uppercase W120 Limit4 vopt_wins_gesture gg_opt_wins_gesture,% qcOpt[ "wins_gesture" ]
  
  Gui, Add, Checkbox,% "xs y+10 cNavy vopt_memos_gestOn gg_opt_memos_gestOn checked" qcOpt[ "memos_gestOn" ],Memos Menu
  Gui, Add, Edit,xs+110 yp-3 W120 +Uppercase Limit4 vopt_Memos_Gesture gg_opt_Memos_Gesture,% qcOpt[ "memos_gesture" ]
  
  Gui, Add, Checkbox,% "xs y+10 cNavy vopt_recent_gestOn gg_opt_recent_gestOn Checked" qcOpt[ "recent_gestOn" ],Recent Menu
  Gui, Add, Edit,xs+110 yp-3 W120 +Uppercase Limit4 vopt_Recent_Gesture gg_opt_Recent_Gesture,% qcOpt[ "recent_gesture" ]
  
  Gui, Add, Checkbox,% "xs y+15 cNavy vopt_gest_win_excl gg_opt_gest_win_excl Checked" qcOpt[ "gest_win_excl_on" ],Enable windows filter
  Gui, Add, Button,% "xs+160 yp-5 w" glb[ "defButW" ] " h" glb[ "defButH" ] " gg_opt_gest_excl",Change
  
  Gui, Add, Text, xs y+10 cNavy, Gesture disable timer (Seconds):
  Gui, Add, Edit,w100 limit3 Number vopt_gest_time gg_opt_gest_time,% floor(qcOpt[ "gest_time" ]/1000)
  Gui, Add, CheckBox,% "x+15 yp+3 vopt_gest_tempNotify gg_opt_gest_tempNotify Checked" qcOpt[ "gest_tempNotify" ], Notification

  Gui, Add, Text,cNavy xs y+10, Global Gesture Button:
  Gui, Add, DropDownList, xs y+5 w150 vopt_gest_curBut gg_opt_gest_curBut AltSubmit
     , Right Mouse Button|Middle Mouse Button|Mouse 3|Mouse 4
  
  ggb := qcOpt[ "gest_curBut" ]
  num := ggb = "RButton" ? 1
      : ggb = "MButton" ? 2
      : ggb = "XButton1" ? 3
      : ggb = "XButton2" ? 4
  GuiControl, Choose, opt_gest_curBut,% num
  Gui, Add, Text, x+5 yp+3,+
  mods := qcOpt[ "gest_butMods" ]
  Gui, Add, Checkbox,% "x+8 yp+1 vopt_gest_modctrl gg_opt_gest_mods checked" instr( mods, "^" ),Ctrl
  Gui, Add, Checkbox,% "x+5 yp vopt_gest_modshift gg_opt_gest_mods checked" instr( mods, "+" ),Shift
  Gui, Add, Checkbox,% "x+5 yp vopt_gest_modwin gg_opt_gest_mods checked" instr( mods, "#" ),Win

  Gui, add, text,% "xs y" glb[ "defOptBoxH" ]-15 " w" glb[ "defOptBoxW" ]-40 " cMaroon  vopt_gest_glbOn gfakesub",% (qcOpt[ "gest_glbOn" ] != 1 ? "Gestures are currently turned OFF globally!" : "")

  Gui,GUI_OPT_GESTURES:Show,% glb[ "defOptBoxPos" ] " Hide"
  return
  
  g_opt_gest_win_excl:
    qcOpt[ "gest_win_excl_on" ] := GuiControlGet(A_GuiControl,"GUI_OPT_GESTURES")
    return
  
  g_opt_gest_mods:
    mods := ( GuiControlGet( "opt_gest_modctrl", "GUI_OPT_GESTURES" ) ? "^" : "" )
          . ( GuiControlGet( "opt_gest_modshift", "GUI_OPT_GESTURES" ) ? "+" : "" )
          . ( GuiControlGet( "opt_gest_modwin", "GUI_OPT_GESTURES" ) ? "#" : "" )
    qcOpt[ "gest_butMods" ] := mods
    return
  
  g_opt_main_gestOn:
  g_opt_clips_gestOn:
  g_opt_wins_gestOn:
  g_opt_memos_gestOn:
  g_opt_recent_gestOn:
    optName := SubStr( A_ThisLabel, 7 )
    qcOpt[ optName ] := GuiControlGet( A_GuiControl, "GUI_OPT_GESTURES" )
    return
  
  g_opt_main_gesture:
  g_opt_clips_gesture:
  g_opt_wins_gesture:
  g_opt_Memos_Gesture:
  g_opt_Recent_Gesture:
    newGesture := GuiControlGet( A_GuiControl, "GUI_OPT_GESTURES" )
    temp := RegExReplace( newGesture, "i)[^LRUD]" )
    temp := RegExReplace( temp, "i)((?<=L)L|(?<=R)R|(?<=U)U|(?<=D)D)" )
    if !( temp == newGesture )
    {
      GuiControlSet( A_GuiControl, temp, "", "GUI_OPT_GESTURES" )
      GuiControlGet, chwnd, hwnd,% A_GuiControl
      ControlSend,,{END},ahk_id %chwnd%
      newGesture := temp
    }
    optName := SubStr( A_ThisLabel, 7 )
    qcOpt[ optName ] := newGesture
    return
  
  g_opt_gest_tempNotify:
    qcOpt[ "gest_tempNotify" ] := GuiControlGet(A_GuiControl,"GUI_OPT_GESTURES")
    return
    
  g_opt_gest_time:
    val := GuiControlGet( A_GuiControl, "GUI_OPT_GESTURES" )
    if ( val = 0 )
    {
      val := 5
      GuiControlSet( A_GuiControl, val, "", "GUI_OPT_GESTURES" )
    }
    qcOpt[ "gest_time" ] := val * 1000
    Return
    
  g_opt_gest_curBut:
    val := GuiControlGet( "opt_gest_curBut", "GUI_OPT_GESTURES" )
    qcOpt[ "gest_curBut" ] := val = 1 ? "RButton"
                          : val = 2 ? "MButton"
                          : val = 3 ? "XButton1"
                          : val = 4 ? "XButton2"
    return
  
  g_opt_gest_excl:
    GUIGestureExclusions()
    return
}