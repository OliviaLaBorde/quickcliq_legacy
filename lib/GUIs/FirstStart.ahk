GUI_FirstRun_Show()
{
  global FirstRun_HK_Main, FirstRun_HK_Clips, FirstRun_HK_Memos, FirstRun_HK_Recent, FirstRun_HK_Wins
  ,FirstRun_Gest_Main, FirstRun_Gest_Clips, FirstRun_Gest_Memos, FirstRun_Gest_Recent, FirstRun_Gest_Wins
  ,FirstRun_En_Main, FirstRun_En_Clips, FirstRun_En_Memos, FirstRun_En_Recent, FirstRun_En_Wins
  ,FirstRun_GestBut, FirstRun_SkipTut
  static fr_hws := object()
  global msgMain, msgClips, msgWins, msgMemos, msgRecent, msgGests
  Gui, GUI_FIRSTRUN:New, +Caption -SysMenu
  Gui, GUI_FIRSTRUN:Default
  QCSetGuiFont( "GUI_FIRSTRUN" )
  Gui,-Theme
  appname := glb[ "appName" ]
  msg = 
  ( LTrim
    %appname% is an application launcher with many additional features and possibilities.
    
    At your first start you can customize general settings as you feel better.
    You may change them anytime later through "Options" screen.
    
    Visit our official web site: <a href="http://apathysoftworks.com">www.apathysoftworks.com</a>
  )
  msgGests = 
  (LTrim
    Gesture consist from sequence of one or more mouse moves,
    which must be performed while holding choosen 'trigger' button.
    Each move defined by following letters:
    L - left, R- right, U - up, D - down.
  )
  msgMain =
  ( LTrim
    This is a menu from which you can access all your shortcuts,
    special features and %appname% Editor.
    This menu to be opened most often.
  )
  msgClips = 
  ( LTrim
    Clips feature gives you 9 more clipboards, all of which works 
    similar to the standard Windows one.
    Default hotkeys for using clips are following ( customizable through options ):
    ctrl + 1-9 - copy anything to corresponding clipboard,
    alt + 1-9 - paste clipboard's content
    ctrl+alt + 1-9 - append text to current clipboard's plain text
  )
  msgWins = 
  ( LTrim
    Wins feature offer you a few useful commands to manipulate windows, like
    hiding them, making transparent or changing their order.
  )
  msgMemos = 
  ( LTrim
    Memos work like your personal notes keeper. Any memo can be encrypted 
    with password preventing unauthorized access to your info.
  )
  msgRecent =
  ( LTrim
    Recent feature stores recently opened %appname% shortcuts, closed folders,
    closed processes or Windows Recent Items.
    Only %appname% shortcuts logged by default. See Options to change this.
  )
  Gui,Font,Bold
  Gui,Add,Text,,Welcome!
  Gui,Font,Normal
  Gui,Add, Link,y+5,% msg
  Gui,Add, Text,,Gesture button
  Gui,Add, DropDownList, x+5 yp-3 w150 vFirstRun_GestBut gg_FirstRun_GestBut AltSubmit,Right Mouse Button|Middle Mouse Button|Mouse 3|Mouse 4
  
  ggb := qcOpt[ "gest_curBut" ]
  num := ggb = "RButton" ? 1
      : ggb = "MButton" ? 2
      : ggb = "XButton1" ? 3
      : ggb = "XButton2" ? 4
  GuiControl, Choose, FirstRun_GestBut,% num
  
  Gui,Add, Link, x+5 yp+3 gFirstRun_Links,<a href="gests">Whats this?</a>
  feats := [ "Main", "Clips", "Memos", "Wins", "Recent" ]
  y := 158
  for i,ftr in feats
  {
    m := mod( i, 2 )
    x := m = 1 ? 0 : 260
    y := m ? ( y + (i=1?0:90) ) : y
    Gui,Font,Bold
    Gui,Add,GroupBox,xm+%x% y%y% w255 h85 Section,% ftr " Menu"
    Gui,Font,Normal
    Gui,Add,Link,xs+10 ys+20 gFirstRun_Links, <a href="%ftr%">Whats this?</a>
    if( i != 1 )
    {
      state := qcOpt[ ftr "_on" ]
      Gui,Add,CheckBox,xp y+15 vFirstRun_En_%ftr% Checked%state% gFirstRun_Enabler,Enable
    }
    Gui,Add,Text,% "xs+83 ys+20 Section",Hotkey:
    Gui,Add,Text,x+5 yp cNavy w90 +Wrap R2 hwndhwnd,% FirstRun_FixHkLen( HotkeyToString( qcOpt[ ftr "_hotkey" ] ) )
    fr_hws[ "hLbl" ftr ] := hwnd
    Gui,Add,Button, x+5 yp-3 vFirstRun_HK_%ftr% gFirstRun_HKChange,...
    Gui,Add,Text,xs y+13,Gesture:
    Gui,Add,Edit,w75 x+5 yp-3 +Uppercase Limit4 vFirstRun_Gest_%ftr% gFirstRun_GestChange,% qcOpt[ ftr "_gesture" ]
  }
  Gui,Add,Checkbox, gg_FirstRun_SkipTut vFirstRun_SkipTut xm y+20,Skip tutorial
  Gui,Add, button,% "gGUI_FIRSTRUNClose xm w" glb[ "defButW" ] " h" glb[ "defButH" ], GO!
  GuiControl, Focus,% fr_hws[ "hLblMain" ]
  Gui,Show,,% glb[ "appName" ] " first run"
  loop
  {
    Gui,GUI_FIRSTRUN:+LastFoundExist
    If !WinExist()
      break
    sleep 200
  }
  return
  
  g_FirstRun_SkipTut:
    glb[ "firstRun" ] := !GuiControlGet( "FirstRun_SkipTut", "GUI_FIRSTRUN" )
    return
  
  GUI_FIRSTRUNClose:
    Gui, GUI_FIRSTRUN:Destroy
    return
  
  g_FirstRun_GestBut:
    val := GuiControlGet( "FirstRun_GestBut", "GUI_FIRSTRUN" )
    qcOpt[ "gest_curBut" ] := val = 1 ? "RButton"
                          : val = 2 ? "MButton"
                          : val = 3 ? "XButton1"
                          : val = 4 ? "XButton2"
    return
  
  FirstRun_HKChange:
    name := FirstRun_ParseCN( A_GuiControl )
    optName := name "_hotkey"
    ol_hk := qcOpt[ optName ]
    new_hk := CustomHotkey_EditGUI( ol_hk, "GUI_FIRSTRUN" )
    if( ol_hk == new_hk )
      return
    new_hk_str := FirstRun_FixHkLen( HotkeyToString( new_hk ) )
    GuiControlSet( fr_hws[ "hLbl" name ], new_hk_str, "", "GUI_FIRSTRUN" )
    qcOpt[ optName ] := new_hk
    return
  
  FirstRun_GestChange:
    newGesture := GuiControlGet( A_GuiControl, "GUI_FIRSTRUN" )
    temp := RegExReplace( newGesture, "i)[^LRUD]" )
    temp := RegExReplace( temp, "i)((?<=L)L|(?<=R)R|(?<=U)U|(?<=D)D)" )
    if !( temp == newGesture )
    {
      GuiControlSet( A_GuiControl, temp, "", "GUI_FIRSTRUN" )
      GuiControlGet, chwnd, hwnd,% A_GuiControl
      ControlSend,,{END},ahk_id %chwnd%
      newGesture := temp
    }
    optName := FirstRun_ParseCN( A_GuiControl ) "_gesture"
    qcOpt[ optName ] := newGesture
    return
  
  FirstRun_Enabler:
    optName := FirstRun_ParseCN( A_GuiControl ) "_on"
    qcOpt[ optName ] := GuiControlGet( A_GuiControl, "GUI_FIRSTRUN" )
    return
  
  FirstRun_Links:
    MouseGetPos,,,, hwndp,2
    ShowCtrlTlp( msg%ErrorLevel%, hwndp )
    GuiControl, Focus,% fr_hws[ "hLblMain" ]
    return
}

FirstRun_ParseCN( cn )
{
  RegExMatch( cn, "O)_([^_]+)$", oMatch )
  return oMatch[ 1 ]
}

FirstRun_FixHkLen( sHK )
{
  maxLen := 10
  if !( StrLen( sHK ) > maxLen )
    return sHK
  fDiv := False
  for i,p in StrSplit( sHK, "+", A_Tab A_Space )
  {
    out .= StrLen( out ) > maxLen && !fDiv ? ( "+ ", fDiv := True ) 
          : out ? "+" : ""
    out .= p
  }
  return out
}

FirstRun_OpenMenuMsg()
{
  hk := HotkeyToString( qcOpt[ "main_hotkey" ] )
  appname := glb[ "appName" ]
  msg =
  ( LTrim
    Good start!
    
    It's only a few %appname%s left to start launching your programs!
    
    From now you may see your menu by calling it with hotkey
    you had specified on the previous screen:
    
    %hk%
    
    The next step is to add few shortcuts to the menu,
    so all this could have a sense.
    
    For this you need to call a menu and click "Open Editor" item.
    
    Please do this!
  )
  qBox := new QMsgBox( { title : "You've done it!"
                        , msg : msg
                        , pic : "i", buttons : "", ontop : 1 } )
  FirstRun_OpenMenuTimer( qBox )
  SetTimer( "FirstRun_OpenMenuTimer", 500 )
  qBox.Show()
  SetTimer( "FirstRun_OpenMenuTimer", "OFF" )
  return
}

FirstRun_OpenMenuTimer( p* )
{
  static qBox
  if isObject( p )
  {
    qBox := p[1]
    return
  }
  Gui,1:+LastFoundExist
  if WinExist()
  {
    qBox.Destroy()
    SetTimer( A_ThisFunc, "OFF" )
  }
  return
}

FirstRun_ShcutAddTut()
{
  sleep 300
  appname := glb[ "appName" ]
  msg =
  ( LTrim
    Very good!
    
    You see main %appname% window before you, through which all magic flows...
    
    You can Add/Modify/Delete your shortcuts set from here, 
    as well as access "Options", check for updates and make yourself happier in many ways :)
    
    First of all you need to add shortcut to your menu by pressing 
    leftmost button on the top toolbar 
    ( blue line with green "+" sign )
    
    Please do this!
  )
  qBox := new QMsgBox( { title : "Good job!"
                        , msg : msg
                        , pic : "i", buttons : "", ontop : 1 } )
  FirstRun_ShcutAddTut_Timer( qBox )
  SetTimer( "FirstRun_ShcutAddTut_Timer", 500 )
  qBox.Show( 1 )
  SetTimer( "FirstRun_ShcutAddTut_Timer", "OFF" )
  sleep 500
  FirstRun_AddCmd()
  return
}

FirstRun_ShcutAddTut_Timer( p* )
{
  static qBox
  if isObject( p )
  {
    qBox := p[1]
    return
  }
  Gui,1:Default
  if TV_GetCount()
  {
    qBox.Destroy()
    SetTimer( A_ThisFunc, "OFF" )
  }
}

FirstRun_AddCmd()
{
  msg =
  ( LTrim
    Just Great!
    
    The next step is to set a command for this shortcut.
    
    To do this - press ">_" button and choose type of command you wish it to be.
    
    You may also enter any command manually. Just double click the line.
    
    Please do this!
  )
  qBox := new QMsgBox( { title : "The last step!"
                        , msg : msg
                        , pic : "i", buttons : "", ontop : 1 } )
  FirstRun_AddCmd_Timer( qBox )
  SetTimer( "FirstRun_AddCmd_Timer", 500 )
  qBox.Show( 1 )
  SetTimer( "FirstRun_AddCmd_Timer", "OFF" )
  sleep 500
  FirstRun_FinishTut()
  return
}

FirstRun_AddCmd_Timer( p* )
{
  static qBox
  if isObject( p )
  {
    qBox := p[1]
    return
  }
  Gui,1:Default
  LV_GetText( firstRowText, 1 )
  if( LV_GetCount() && firstRowText != "command" )
  {
    qBox.Destroy()
    SetTimer( A_ThisFunc, "OFF" )
  }
  return
}

FirstRun_FinishTut()
{
  appname := glb[ "appName" ]  
  msg =
  ( LTrim
    Thats all! Glad you made it so far!
    
    To update existing menu - press rightmost button on the top toolbar.
    
    As you can see your shortcut's name and icon
    changed according to the command you've specified.
    
    This is happens every time you change the command as long as you have only one command in the list. 
    And you may have unlimited number of commands for each shortcut!
    Awesome, isn't it? :)
    
    You may change name of any shortcut by double clicking on it or by pressing F2. The same goes for commands.
    
    You may access advanced customization options for each shortcut by right clicking on it.
    
    Thats all you may need to know for good start!
    I wish you good luck and thank you for trying %appname%!
  )
  QMsgBoxP( { msg : msg, title : "Congratulations!", pic : "i" }, 1 )
  return
}