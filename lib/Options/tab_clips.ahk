OptAddClipsTab()
{
  global opt_clips_on,opt_clips_SaveOnExit,opt_clips_sub
  ,CC_Ctrl,CC_Alt,CC_Shift,CC_Win,CA_Ctrl,CA_Alt,CA_Shift,CA_Win,CP_Ctrl,CP_Alt,CP_Shift,CP_Win,CC,CA,CP
  
  Gui, GUI_OPT_CLIPS:New,+ParentGUI_OPT -Caption +hwndhwnd
  qcGui[ "opts_hws" ][ "Clips" ] := hwnd
  Gui, GUI_OPT_CLIPS:Default
  QCSetGuiFont( "GUI_OPT_CLIPS" )
  Gui,Font,Bold
  Gui,Add,GroupBox,% "ym xm w" glb[ "defOptBoxW" ] " h" glb[ "defOptBoxH" ],Clips
  Gui,Font,Normal
  
  Gui, Add, Checkbox,% "Section xp+15 yp+25 cNavy vopt_clips_on gg_opt_clips_on checked" qcOpt[ "clips_on" ]
          , Enable "Clips"
  Gui, Add, Checkbox,% "y+5 cNavy vopt_clips_sub gg_opt_clips_sub checked" qcOpt[ "clips_sub" ]
              . " Disabled" !qcOpt[ "clips_on" ]
          , Show "Clips" sub in Main Menu
  Gui, Add, Checkbox,% "y+5 cNavy vopt_clips_SaveOnExit gg_opt_clips_SaveOnExit Checked" qcOpt[ "clips_SaveOnExit" ]
              . " Disabled" !qcOpt[ "clips_on" ]
          , Save/Restore Clips on exit/startup
          
  Gui, Add, Text, xs y+10 cNavy, Hotkeys:
  Gui, Add, Text, xs+3 y+10 cNavy vCC, Clip Copy:
  Gui, Add, Text, xs+3 y+10 cNavy vCA, Clip Append:
  Gui, Add, Text, xs+3 y+10 cNavy vCP, Clip Paste:
  ;Copy
  hk := qcOpt[ "Clips_CopyHK" ]
  Gui, Add, Checkbox,% "Section xs+80 ys+92  cNavy gClipsModifyHotkeysChanged vCC_Ctrl Checked" . instr(hk,"^"),Ctrl +
  Gui, Add, Checkbox,% "x+1 yp cNavy gClipsModifyHotkeysChanged vCC_Alt Checked" . instr(hk,"!"),Alt +
  Gui, Add, Checkbox,% "x+1 yp cNavy gClipsModifyHotkeysChanged vCC_Shift Checked" . instr(hk,"+"),Shift +
  Gui, Add, Checkbox,% "x+1 yp cNavy gClipsModifyHotkeysChanged vCC_Win Checked" . instr(hk,"#"),Win
  ;Append
  hk := qcOpt[ "Clips_AppendHK" ]
  Gui, Add, Checkbox,% "xs y+10 cNavy gClipsModifyHotkeysChanged vCA_Ctrl Checked" . instr(hk,"^"),Ctrl +
  Gui, Add, Checkbox,% "x+1 yp cNavy gClipsModifyHotkeysChanged vCA_Alt Checked" . instr(hk,"!"),Alt +
  Gui, Add, Checkbox,% "x+1 yp cNavy gClipsModifyHotkeysChanged vCA_Shift Checked" . instr(hk,"+"),Shift +
  Gui, Add, Checkbox,% "x+1 yp cNavy gClipsModifyHotkeysChanged vCA_Win Checked" . instr(hk,"#"),Win
  Gui, Add, Text, x+20 yp cNavy, + 1-9
  ;Paste
  hk := qcOpt[ "Clips_PasteHK" ]
  Gui, Add, Checkbox,% "xs y+10 cNavy gClipsModifyHotkeysChanged vCP_Ctrl Checked" . instr(hk,"^"),Ctrl +
  Gui, Add, Checkbox,% "x+1 yp cNavy gClipsModifyHotkeysChanged vCP_Alt Checked" . instr(hk,"!"),Alt +
  Gui, Add, Checkbox,% "x+1 yp cNavy gClipsModifyHotkeysChanged vCP_Shift Checked" . instr(hk,"+"),Shift +
  Gui, Add, Checkbox,% "x+1 yp cNavy gClipsModifyHotkeysChanged vCP_Win Checked" . instr(hk,"#"),Win
  
  Gui,GUI_OPT_CLIPS:Show,% glb[ "defOptBoxPos" ] " Hide"
  return
  
  g_opt_clips_on:
    qcOpt[ "clips_on" ] := GuiControlGet( A_GuiControl, "GUI_OPT_CLIPS" )
    GuiControlSet( "opt_clips_sub|opt_clips_SaveOnExit"
                 , "", "Enable" qcOpt[ "clips_on" ], "GUI_OPT_CLIPS", 0 )
    if( qcOpt[ "clips_on" ] && qcOpt[ "clips_SaveOnExit" ] && !qcClipsMenu.alive )
      RestoreClips()
    return
  
  g_opt_clips_sub:
    qcOpt[ "clips_sub" ] := GuiControlGet( A_GuiControl, "GUI_OPT_CLIPS" )
    return
    
  g_opt_clips_SaveOnExit:
    qcOpt[ "clips_SaveOnExit" ] := GuiControlGet( A_GuiControl, "GUI_OPT_CLIPS" )
    return
    
  ClipsModifyHotkeysChanged:
    ;getting current states
    clips_copy := GuiControlGet("CC_Ctrl") . GuiControlGet("CC_Alt") . GuiControlGet("CC_Shift") . GuiControlGet("CC_Win")
    clips_append := GuiControlGet("CA_Ctrl") . GuiControlGet("CA_Alt") . GuiControlGet("CA_Shift") . GuiControlGet("CA_Win")
    clips_paste := GuiControlGet("CP_Ctrl") . GuiControlGet("CP_Alt") . GuiControlGet("CP_Shift") . GuiControlGet("CP_Win")
    ;return back default color first
    GuiControlSet("CC_Ctrl|CC_Alt|CC_Shift|CC_Win|"
                . "CA_Ctrl|CA_Alt|CA_Shift|CA_Win|"
                . "CP_Ctrl|CP_Alt|CP_Shift|CP_Win|CP|CC|CA",""," +cNavy","", False )
    ;we able to have "empty" hotkeys, in which way they will just not be set
    err := False
    if( clips_copy = "0000" )
      GuiControlSet( "CC_Ctrl|CC_Alt|CC_Shift|CC_Win|CC",""," +cRed","",0 ),err:=True
    if( clips_paste = "0000" )
      GuiControlSet( "CP_Ctrl|CP_Alt|CP_Shift|CP_Win|CP",""," +cRed","",0 ),err:=True
    if( clips_append = "0000" )
      GuiControlSet( "CA_Ctrl|CA_Alt|CA_Shift|CA_Win|CA",""," +cRed","",0 ),err:=True
    if ( clips_copy = clips_append )	
      GuiControlSet("CC_Ctrl|CC_Alt|CC_Shift|CC_Win|CA_Ctrl|CA_Alt|CA_Shift|CA_Win|CC|CA",""," +cRed","",0),err:=True
    if ( clips_copy = clips_paste )
      GuiControlSet("CC_Ctrl|CC_Alt|CC_Shift|CC_Win|CP_Ctrl|CP_Alt|CP_Shift|CP_Win|CC|CP",""," +cRed","",0),err:=True
    if ( clips_append = clips_paste )
      GuiControlSet("CA_Ctrl|CA_Alt|CA_Shift|CA_Win|CP_Ctrl|CP_Alt|CP_Shift|CP_Win|CA|CP",""," +cRed","",0),err:=True
    
    if err
      return
    
    pref := substr(A_GuiControl,1,2)
    optName := pref = "CC" ? "Clips_CopyHK" 
            : pref = "CA" ? "Clips_AppendHK" 
            : pref = "CP" ? "Clips_PasteHK" : ShowExc( "Shit happend here" )
    hkey := ( GuiControlGet( pref "_Win") ? "#" : "" )
          . ( GuiControlGet( pref "_Ctrl") ? "^" : "" )
          . ( GuiControlGet( pref "_Shift") ? "+" : "" )
          . ( GuiControlGet( pref "_Alt" ) ? "!" : "" )
    qcOpt[ optName ] := hkey
    return
}