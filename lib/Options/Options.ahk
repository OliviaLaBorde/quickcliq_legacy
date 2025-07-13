OptionsGUI()
{
  global
  Gui GUI_OPT:+LastFoundExist
  IfWinExist
  {
    if !ClIsVisible( WinExist() )
      Gui, GUI_OPT:Show
    WinActivate
    return
  }
  Gui, GUI_OPT:New, +hwndhwnd +OwnDialogs +owner1,% glb[ "AppName"] " Settings"
  Gui, GUI_OPT:Default
  QCSetGuiFont( "GUI_OPT" )
  Gui, Margin, 10, 10
  Gui, 1:+Disabled
  qcGui[ "opts" ] := hwnd
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  ;hwnds for each tab of options
  arTabs := [ "General","Appearance","Hotkeys"
            ,"Gestures","Clips","Wins","Memos"
            ,"Recent", "Folder Menu", "Other" ]
  qcGui[ "opts_hws" ] := object() ;here we hold handles to the options windows ( hwnds )
  Gui,Add,ListView,% "xm ym w" glb[ "defOptLVW" ] " h" glb[ "defOptBoxH" ] " -Hdr -Multi +LV0x00010000 hwndhwnd gOpt_LV_Events AltSubmit NoSort",name ;LVS_EX_DOUBLEBUFFER
  qcGui[ "opts_lv" ] := hwnd
  for i,v in arTabs
    LV_Add( "", v )
  Gui, add, button,% "xm W" glb[ "defButW" ] " H" glb[ "defButH" ] " gOpt_AcceptSettingsBtn", OK
  xpos := glb[ "defOptBoxW" ] + glb[ "defOptLVW" ] - glb[ "defButW" ]*3 + 5
  Gui, add, button,% "x+" xpos " yp W" glb[ "defButW" ] " H" glb[ "defButH" ] " gOpt_ApplySettingsBtn", Apply
  Gui, add, button,% "x+" 5 " yp W" glb[ "defButW" ] " H" glb[ "defButH" ] " gopt_resettodefaults", Defaults
  OptAddGenTab()
  OptAddAprnsTab()
  OptAddHotkeysTab()
  OptAddGestrsTab()
  OptAddClipsTab()
  OptAddWinsTab()
  OptAddMemosTab()
  OptAddRecentTab()
  OptAddFolderMenuTab()
  OptAddBackupTab()

  Gui,GUI_OPT:Default
  LV_Modify( 1, "Select" )
  Gui 1:+LastFoundExist
  WinGetPos, X, Y, W, H,% "AHK_ID " WinExist()
  
  Gui,Show,% "x" . round( x + w/2 - 320 ) 
          . " y" . round( y + h/10 ) 
          . " w" ( glb[ "defOptBoxW" ] + glb[ "defOptLVW" ] + 30 )
          . " h" ( glb[ "defOptBoxH" ] + glb[ "defButH" ] + 25 )
  return  
  
  opt_resettodefaults:
    if( "Yes" != QMsgBoxP( { title : "Reset to default"
                             ,msg : "Are you sure you want to reset all your settings to their defaults?`nThis action will perform " glb[ "appName" ] " restart on completion."
                             ,modal : 1, pic : "!", buttons : "Yes|No", pos : "GUI_OPT" }, "GUI_OPT" ) )
      return
    expr = //opt[ @name != "settings_ct" ]
    qcconf.GetOptNode().selectNodes( expr ).removeAll()
    qcconf.Save()
    QCRestart( False )
    return
  
  Opt_LV_Events:
    Gui, GUI_OPT:Default
    if ( A_GuiEvent = "I" && InStr( ErrorLevel, "S", True ) )
    {
      LV_GetText( row_name, A_EventInfo )
      WinShow( hw := qcGui[ "opts_hws" ][ row_name ] )
      WinHide( qcGui[ "opts_hws" ][ "cur_hw" ] )
      qcGui[ "opts_hws" ][ "cur_hw" ] := hw
    }
    return
  
  Opt_ApplySettingsBtn:
  Opt_AcceptSettingsBtn:
    if ( errors := HotkeysCompare( "", False ) )
    {
      QMsgBoxP( { title : "Using of similar hotkeys"
                , msg : "Some of your hotkeys/mouse gestures are the same:`n`n" errors
                , pic : "!", pos : "GUI_OPT", buttons : "Ok", modal : 1
                , editbox : 1, rsz : 1 }, "GUI_OPT" )
      return
    }
    qcconf.Save()
    if( A_ThisLabel = "Opt_AcceptSettingsBtn" )
      GoSub,CloseOptionsGui
    QCMenuRebuild( "main" )
    return

  ;###############################
  CloseOptionsGui:
  GUI_OPTGuiClose:
  GUI_OPTGuiEscape:
    Gui, 1:-Disabled
    Gui, GUI_OPT:Destroy
    Gui, 3:Destroy
    Gui 1:Default
    WinActivate,% "ahk_id " qcGui[ "main" ]
    return
}

