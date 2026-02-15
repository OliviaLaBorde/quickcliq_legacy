QCMainGui( fActivate = True )
{
  global
  static mg_static_var
  Gui, 1:Default
  If IsWindow( qcGui[ "main" ] )
  {
    if !IsWindowVisible( qcGui[ "main" ] )
      GoSub,ReEnableMainGui
    ShowWindow( qcGui[ "main" ] )
    if fActivate
      while( !WinActive( "ahk_id " qcGui[ "main" ] ) && IsWindowVisible( qcGui[ "main" ] ) )
      {
        ShowWindow( qcGui[ "main" ] )
        WinActivate,% "ahk_id " qcGui[ "main" ] ;the window won't activate sometimes
        sleep 200
      }
    return
  }
  Gui, +OwnDialogs +LabelMainGui
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  Gui, 1:+LastFound
  qcGui[ "main" ] := WinExist() + 0
  QCSetGuiFont( 1 )
  
  ; menus
  Menu, Help, Delete
  Menu, GuiMenuBar, Delete
  Menu, MoveItem, Delete
  Menu, QuickLinks, Delete
  Menu, AfoMenu, Delete
  Menu, Settings, Delete
  
  Menu, Settings, Add, &Options..., OptionsGui
  Menu, Settings, Add, List Custom &Hotkeys..., CustomHotkey_OpenGui
  Menu, Settings, Add
  Menu, Settings, Add, View..., GUI_TV_Options_Show
  
  Menu, AfoMenu, Add, Copy, AfoCopy
  Menu, AfoMenu, Add, Send New, AfoSend
  
  Menu, QuickLinks, Add, &Homepage, GoHomepage
  Menu, QuickLinks, Add, Check the &News, CheckTheNews
  Menu, QuickLinks, Add
  Menu, QuickLinks, Add, Join our Fa&cebook page, ApathyFacebook
  Menu, QuickLinks, Add, Follow us on T&witter, ApathyTwitter
  Menu, QuickLinks, Add
  Menu, QuickLinks, Add, Change &Log, ShowChangeLog
  Menu, QuickLinks, Add
  Menu, QuickLinks, Add, Donate, DonateLNK
    
  Menu, Help, Add, Web &Help, Help
  Menu, Help, Add
  Menu, Help, Add, &About, About
  Menu, GuiMenuBar, Add, &Settings, :Settings
  Menu, GuiMenuBar, Add, Check for &Updates, Update
  Menu, GuiMenuBar, Add, &Feedback, FeedbackSub
  Menu, GuiMenuBar, Add, &Quick Links, :QuickLinks
  Menu, GuiMenuBar, Add, &Help, :Help
  Gui, Menu, GuiMenuBar
  
  ; gui controls
  hMainTbImageList := IL_CreateNew(16, 16, 7, 1 )
  loop,% glb[ "icoMainCnt" ]
  {
    ico := glb[ "iconListPath" ] . glb[ "icoMainInd" ]+(A_Index-1)
    IL_AddIcon(hMainTbImageList,IconExtract( ico,16))
  }
  hMainGuiToolbar := Toolbar_Add( qcGui[ "main" ], "GUI_Main_TlbTop_Handler","LIST FLAT NODIVIDER TOOLTIPS",hMainTbImageList, "x10 y5")
  ;DO NOT change IDs since they are hardly linked with events
  btns = 
  (LTrim
  Add Shortcut,1,,,1
  Add Menu,2,,,2
  Add Separator,3,,,3
  --
  Expand/Collapse All Menus,4,,,4
  Move Item Down,6,,,5
  Move Item Up,7,,,7
  --
  Delete Selected Item,8,,,6
  --
  Hints,9,,,8
  Save changes and rebuild Menu,10,,,9
  )
  Toolbar_Insert( hMainGuiToolbar, btns )
  Toolbar_AutoSize( hMainGuiToolbar )
  Gui,Add,Button,hwndhwnd h20 w100 hidden gMAIN_GUI_DONATE_BUT,% "Like " glb["appName"] "?"
  qcGui[ "main_donate_but" ] := hwnd
  if ( ( !qcOpt["gen_donated"] && QCGetDaysUsing() > 7 ) || !A_IsCompiled )
    ClShow( qcGui[ "main_donate_but" ] )
    
  Gui, Add, TreeView, AltSubmit Section x10 y30 w470 h290 -ReadOnly gGUI_Main_TV_Event HWNDTV_hwnd -0x2 +0x1 +0x1000 ;+0x200	;+TVS_TRACKSELECT -TVS_HASLINES +TVS_HASBUTTONS
  qcGui[ "main_tv" ] := TV_hwnd
  
  Gui, Add, Text, x10 y+30 w520 hwndchwnd
  qcGui[ "main_tg_name" ] := chwnd
  Gui, Add, Edit,-Background -WantReturn xs y+5 w470 h40 vctrl_Main_ED HwndTargetHWND gOnTargetChange
  qcGui[ "main_ed" ] := TargetHWND
  
  Gui, Add, StatusBar,vAfoSB gSB_afo_change -Tabstop +0x100,% GetRandomAphorism()
  
  MG_AddEditLV()

  Gui, +Resize +MinSize400x430 ;+0x02000000
  Gui_Main_TlbProp_ShowGUI( False )
  GuiControl,Focus,% qcGui[ "main_tv" ]
  QCTVSetFont() ;set font settings to tree view
  Gui, Show,% Gui_Main_GetPos(),% glb[ "appName" ] " Editor"
  SendMessage( qcGui[ "main_tv" ], 0x1100 + 44, 0x0004, 0x0004 )			; TVM_SETEXTENDEDSTYLE to TVS_EX_DOUBLEBUFFER
  SetTimer( "Gui_Main_UpdAfo", glb[ "afoDelay" ] )
  Gui_Main_SetView( qcOpt[ "main_cmd_LVView" ] )
  QC_BuildTV( 0 )
  if !TV_GetChild( 0 )          ; in case QC first start when no items
    Gui_Main_UpdControls( 0 )
  else
    TV_Modify( TV_GetNext( 0, "Full" ), "Select" )
  if glb[ "firstRun" ]
    FirstRun_ShcutAddTut()
  return
  
  MAIN_GUI_DONATE_BUT:
    GUIDonation()
    return
  
  MainGuiSize:
    GUI_Main_Resize(A_GuiWidth,A_GuiHeight)
    return
  
  CustomHotkey_OpenGui:
    CustomHotkeysGui_Show()
    return
  
  ReEnableMainGui:
    Gui, 1:Default
    QC_BuildTV( 0 )
    TV_Modify( TV_GetNext( 0, "Full" ), "Select" )
    GuiControl,Focus,% qcGui[ "main_tv" ]
    SetTimer( "Gui_Main_UpdAfo", glb[ "afoDelay" ] )
    return

  OnTargetChange:
    if !TG_ASaveStop()
      SetTimer,TargetAutosaveSub,-200
    return
  
  TargetAutosaveSub:
    if !TG_ASaveStop()
      Gui_Main_SyncFrom( "ED" )
    return

  GUI_TV_Options_Show:
    GUI_TV_Options()
    return
  
  DonateLNK:
    Run,% glb[ "urlDonate" ],,UseErrorLevel
    return
  
  CheckTheNews:
    Run,% glb[ "urlNews" ],,UseErrorLevel
    return
  
  GoHomepage:
    Run,% glb[ "urlQCHome" ],,UseErrorLevel
    return
  
  ApathyFacebook:
    Run,% glb[ "urlFacebook" ],,UseErrorLevel
    return
  
  ApathyTwitter:
    Run,% glb[ "urlTwitter" ],,UseErrorLevel
    return
  
  FeedbackSub:
    SendFeedback( "", 1 )
    return
    
  fakesub:
    return

  ShowChangeLog:
    Main_Changelog_GUI()
    return

  ;#################################################
  MainGuiDropFiles:
    Gui_Main_FileDnD(A_GuiControl,A_GuiEvent)
    Return
  ;#################################################	
  OptionsGui:
    OptionsGUI()
    return

  Update:
    Program_Update( 1 )
    return

  Help:
    Run,% glb[ "urlWebHelp" ],,UseErrorLevel
    if (ErrorLevel = ERROR)
      MsgBox,16,Another bug,% "Can't open help url`. Please open it manually`.`n" glb[ "urlWebHelp" ]
    return
  ;#################################################
  MainGuiClose:
    Gui,+OwnDialogs
    HideWindow( qcGui[ "main" ] )
    Gui_Main_SavePos()
    SetTimer( "Gui_Main_Props_CheckActive", "OFF" )
    gui,12:hide
    SetTimer( "Gui_Main_UpdAfo", "OFF" )
    qcconf.Save()
    QCMenuRebuild( "main" )
    sleep 50
    HotkeysCompare()
    QCFreeMem()
  return
  ;############################### SET TARGETS
  
  TG_Spc:
    GUI_Special_Show(1)
    return
  
  SB_afo_change:
    Gui, 1:Default
    if (A_GuiEvent = "Normal")
    {
      SB_SetText( GetRandomAphorism() )
      SetTimer( "Gui_Main_UpdAfo", glb[ "afoDelay" ] )
      oGuiTooltip.UpdateTlp( glb[ "afo_cur_details" ] )
    }
    else if (A_GuiEvent = "RightClick")
      SetTimer,ShowAfoMenu,-50
    return
  
  ShowAfoMenu:
    Menu, AfoMenu,Show
    return
    
  AfoCopy:
    WinClip.Clear()
    WinClip.SetText( glb[ "afo_cur" ] "`r`n" glb[ "afo_cur_details" ] )
    DTP()
    full_afo =
    return
    
  AfoSend:
    SendAfoForm()
    return
}

Main_Changelog_GUI()
{
  static change_log_ed
  SplashWait(1,"",1,0)
  Sleep 50

  if ( ret := DwnFile( glb[ "urlChangelog" ], glb[ "pathChangelog" ] ) ).rcode
  {
    SplashWait( -1, "", 1, 0 )
    QMsgBoxP( { title : "Error retrieving changelog"
                , msg : "Sorry, the changelog is currently unavailable."
                  . "`nPlease try again later or when you have an internet connection."
                  . "`n`nError:`n" ret.err, pos : 1, modal : 1 } )
    return
  }
  change_log := FileOpen( glb[ "pathChangelog" ], "r", "CP0" ).Read()
  SplashWait( -1, "", 1, 0 )
  Gui, 29:Default
  QCSetGuiFont( 29 )
  Gui, 1:+Disabled
  Gui, +owner1
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  Gui, Add, Edit, vchange_log_ed w400 h300 +Multi +ReadOnly, %change_log%
  GuiControl, Focus, change_log_ed
  Gui, +ToolWindow
  Gui, 1:+LastFoundExist
  WinGetPos, X, Y, W, H,% "AHK_ID " WinExist()
  Gui,Show,% "x" . round(x+(w/2)-200) . " y" . round(y+(h/2)-200), Change log
  return
  
  
  29GuiClose:
    Gui, 1:+OwnDialogs
    Gui, 1:-Disabled
    Gui, -owner1
    Gui, 29:Destroy
    Gui, 1:Default
    return
}