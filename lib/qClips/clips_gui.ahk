;in case isUpdate flag clips window will be updated to selected clipnum only if it opened and not minimized
ClipsGui( clipNum = "", isUpdate = False )
{
  global clip0,clip1,clip2,clip3,clip4,clip5,clip6,clip7,clip8,clip9
  global Clips_Edit,Change_Case,Edit_Opts,ClipsGui_BTNSaveClip,ToFileButtonClipX,ClearButtonClipX,NotepadOpen
  global wrapControl,ontopControl,URL_MetaDataHelp,hwClipsEdit
  
  if ( clipNum = "" )
    clipNum := 1
  if isUpdate
  {
    If ( IsWindow( qcGui[ "clips" ] ) && !WinIsMin( qcGui[ "clips" ] ) )
      ClipsGui_Switch( clipNum )
    return
  }

  Gui, 22:Default
  QCSetGuiFont( 22 )
  If IsWindow( qcGui[ "clips" ] )
  {
    WinActivate,% "ahk_id" qcGui[ "clips" ]
    ClipsGui_Switch( clipNum )
    return
  }
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  Gui, 22:+LastFound
  qcGui[ "clips" ] := WinExist() + 0
  
  Loop, 9
    Gui, Add, Button, x5 w30 h30 vclip%A_Index% gClipsGui_Switch, %A_Index%
  Gui, Add, Button, x5 w30 h30 vclip0 gClipsGui_Switch, S
  Gui, Add, Edit, x40 y5 +wrap +HScroll +hwndhwClipsEdit +WantReturn WantTab Multi gOnEditControlChange,% ClipsGetText( clipNum )

  ;Menus
  Menu,Clips_Edit_Case,Delete
  Menu,Clips_Edit_OtherOpts,Delete
  
  Menu,Clips_Edit_Case,Add,Upper,Case_Up
  Menu,Clips_Edit_Case,Add,Lower,Case_Lo
  Menu,Clips_Edit_Case,Add,Sentence,Case_Sent
  Menu,Clips_Edit_Case,Add,Title,Case_Tit
  
  Menu,Clips_Edit_OtherOpts,Add,Convert to list,ConvertClip_ToList
  Menu,Clips_Edit_OtherOpts,Add,Convert to enumeration,ConvertClip_ToEnum
  Menu,Clips_Edit_OtherOpts,Add,Remove extra lines,Clip_RemLines
  Menu,Clips_Edit_OtherOpts,Add
  Menu,Clips_Edit_OtherOpts,Add,Extract Links,ClipsGUI_GetLinks
  Menu,Clips_Edit_OtherOpts,Add,Run Links,ClipsGUI_RunLinks
  
  Gui, Add, Button, x40 w80 h20 vChange_Case gOpenCaseMenu, Change Case
  Gui, Add, Button, x+5 w80 h20 vEdit_Opts gOpenEditMenu, Quick Edit
  
  Gui, Add, Button, x40 h30 w100 gClipsGUI_SaveClip vClipsGui_BTNSaveClip +Disabled, Apply Changes
  Gui, Add, Button, w40 h30 gClipsGui_ToFile vToFileButtonClipX,To File
  Gui, Add, Button, w40 h30 gClipsGui_ClearClip vClearButtonClipX, Clear
  Gui, Add, Button, w50 h30 vNotepadOpen gOpenInNotepad, Notepad
  Gui, Add, Checkbox, gwrapChange Checked vwrapControl, Word Wrap
  Gui, Add, Checkbox, gontopChange Checked vontopControl, On Top
  
  Gui, +LastFoundExist
  WinSet,AlwaysOnTop,On
  Gui,Font,bold s18
  GuiControl,Font,clip%ClipNum%
  Gui,Font,norm s8
  Gui, +Resize MinSize400x480 +LabelClipsGui
  Gui, Show, h480 w400,% "Clip # " . ClipNum
  ClipsGui_CurClip( clipNum )
  WinActivate,% "ahk_id "  qcGui[ "clips" ]
  Return		

  ClipsGui_ClearClip:
    ClipsClear( ClipsGui_CurClip() )
    GuiControlSet( hwClipsEdit, "", "", 22 )
    GuiControl, Disable, ClipsGui_BTNSaveClip
    return
  
  ClipsGui_ToFile:
    GuiControlGet, IsEnabled, Enabled, ClipsGui_BTNSaveClip
    if IsEnabled
      GoSub, ClipsGUI_SaveClip
    ontopState := GuiControlGet( "ontopControl", 22 )
    if ontopState
    {
      GuiControlSet("ontopControl",0,"",22)
      GoSub, ontopChange
    }
    ClipsToFile( ClipsGui_CurClip(), "text", 22 )
    Return

  ClipsGUI_GetLinks:
  ClipsGUI_RunLinks:
    Gui, 22:Default
    if ( A_ThisLabel = "ClipsGUI_GetLinks" )
    {
      links_list := StrGetLinks( ClipsGetText( ClipsGui_CurClip(), True ) )
      if links_list
      {
        GuiControlSet( hwClipsEdit, links_list, "", 22)
        GuiControl, Enable, ClipsGui_BTNSaveClip
      }
      links_list =
    }
    if ( A_ThisLabel = "ClipsGUI_RunLinks" )
      StrGetLinks( ClipsGetText( ClipsGui_CurClip(), True ), True )
    return

  ClipsGuiSize: ;changing size of controls on resizong
    ClipsGui_Resize( A_GuiWidth, A_GuiHeight )
    return

  ConvertClip_ToEnum:
  ConvertClip_ToList:
  Clip_RemLines:
    Gui, 22:Default
    if ( A_ThisLabel == "ConvertClip_ToList" )
      GuiControlSet( hwClipsEdit, RegExReplace( GuiControlGet( hwClipsEdit, 22 ), ",", "`n" ), "", 22 )
    else if ( A_ThisLabel == "ConvertClip_ToEnum" )
      GuiControlSet( hwClipsEdit, RegExReplace( GuiControlGet( hwClipsEdit, 22 ), "`a )`n", "," ), "", 22 )
    else if ( A_ThisLabel == "Clip_RemLines" )
      GuiControlSet( hwClipsEdit,RegExReplace(GuiControlGet( hwClipsEdit,22 ),"`a)`n`n+","`n"),"",22)
    GuiControl, Enable, ClipsGui_BTNSaveClip
    return

  ClipsGui_Switch:
    ClipsGui_Switch( SubStr( A_GuiControl, 0  ) )
    return

  OpenCaseMenu:
  OpenEditMenu:
    CoordMode, Menu, Relative
    GuiControlGet, contr_hwnd, Hwnd, %A_GuiControl%
    ControlGetPos, X, Y, W, H,, ahk_id %contr_hwnd%
    Menu,% A_ThisLabel = "OpenCaseMenu" ? "Clips_Edit_Case" : "Clips_Edit_OtherOpts",Show,% X,% (Y + H)
    CoordMode, Menu
    return
  
  Case_Up:
  Case_Lo:
  Case_Sent:
  Case_Tit:
    Gui, 22:Default
    if (A_ThisLabel == "Case_Up")
      GuiControlSet( hwClipsEdit, StringUpper( GuiControlGet( hwClipsEdit, 22 ) ), "", 22 )
    if (A_ThisLabel == "Case_Lo")
      GuiControlSet( hwClipsEdit, StringLower( GuiControlGet( hwClipsEdit, 22 ) ), "", 22 )
    if (A_ThisLabel == "Case_Tit")
      GuiControlSet( hwClipsEdit, StringTitle( GuiControlGet( hwClipsEdit, 22 ) ), "", 22 )
    if (A_ThisLabel == "Case_Sent")
      GuiControlSet( hwClipsEdit, StringSentence( GuiControlGet( hwClipsEdit, 22 ) ), "", 22 )
    GuiControl, Enable, ClipsGui_BTNSaveClip
    return
  
  OpenInNotepad:
    GuiControlGet, IsEnabled, Enabled, ClipsGui_BTNSaveClip
    if IsEnabled
      GoSub, ClipsGUI_SaveClip
      
    GuiControlSet("ontopControl",0,"",22)
    GoSub, ontopChange
    path := A_Temp "\clip" ClipsGui_CurClip()
    f := FileOpen( path, 5 )
    if !IsObject( f ) {
      DTP( "Could not open file: `n" path, 1500 )
      return
    }
    f.Write( GuiControlGet( hwClipsEdit, 22 ) )
    f.Close()
    Run,% "notepad.exe " path,,UseErrorLevel
    return
  
  OnEditControlChange:
    GuiControl, Enable, ClipsGui_BTNSaveClip
    return

  ontopChange:
    Gui, 22:+LastFoundExist
    if GuiControlGet("ontopControl")
      WinSet,AlwaysOnTop,On
    else
      WinSet,AlwaysOnTop,Off			
    return

  wrapChange:
    ClipsGui_WrapChange( GuiControlGet( "wrapControl", 22 ) )
    return

  ClipsGUIEscape:
  ClipsGUIClose:
    gui, destroy
    QCFreeMem()
    Return

  ClipsGUI_SaveClip:
    Gui, 22:Default
    clipNum := ClipsGui_CurClip()
    qcClips[ clipNum ][ ( clipNum = 0 ? "" : "i" ) "SetText" ]( GuiControlGet( hwClipsEdit,22 ) )
    GuiControl, Disable, ClipsGui_BTNSaveClip
    Return
}

ClipsGui_WrapChange( state )
{
  global hwClipsEdit
  data := GuiControlGet( hwClipsEdit, 22 )
  DestroyWindow( hwClipsEdit )
  Gui,22:Default
  Gui, Add, Edit,% "x40 y5 " ( state ? "+" : "-" ) "wrap +HScroll +hwndhwClipsEdit +WantReturn WantTab Multi gOnEditControlChange cBlack",% data
  ClipsGui_Resize()
  return
}

ClipsGui_CurClip( clipNum = "" )
{
  static curClipNum := 1
  if ( clipNum != "" )
    curClipNum :=clipNum
  return curClipNum
}

ClipsGui_Switch( clipNum )
{
  global hwClipsEdit
  Gui, 22:Default
  GuiControl, Disable, ClipsGui_BTNSaveClip
  ClipsGui_CurClip( clipNum )
  loop, 9
  {
    Gui,Font,norm s8
    GuiControl,Font,clip%A_Index%	
  }
  GuiControl,Font,clip0
  Gui,Font,bold s18
  GuiControl,Font,clip%clipNum%
  GuiControl,MoveDraw, clip%clipNum%
  Gui,Font,norm s8
  GuiControlSet( hwClipsEdit, ClipsGetText( clipNum ), "", 22 )
  Gui, Show,,% "Clip # " clipNum
  return
}

ClipsGui_Resize( new_width = "", new_height = "" )
{
  global hwClipsEdit
  static sWidth, sHeight
  if ( new_width = "" || new_height = "" )
    new_width := sWidth, new_height := sHeight
  else
    sWidth := new_width, sHeight := new_height
  Gui, 22:Default
  EditWidth := new_width - 50
  EditHeight := new_height - 120
  OtherButtonsWidth := new_width/8 + 10
  wo_nullsX := new_width - 4.2*OtherButtonsWidth - 15
  ToFileX := wo_nullsX + OtherButtonsWidth + 5
  ClearX := ToFileX + OtherButtonsWidth + 5
  OpenNPx := ClearX + OtherButtonsWidth + 5
  buttonsY := new_height - 35
  Line1 := new_height - 108
  WrapCheckBoxX := new_width - 90
  Line2 := Line1 + 20
  Line3 := Line2 + 20
  ; moving control according new gui size
  GuiControl, MoveDraw,% hwClipsEdit, w%EditWidth% h%EditHeight%
  GuiControl, MoveDraw, ClipsGui_BTNSaveClip, y%buttonsY%
  GuiControl, MoveDraw, ToFileButtonClipX, w%OtherButtonsWidth% x%ToFileX% y%buttonsY%
  GuiControl, MoveDraw, ClearButtonClipX, w%OtherButtonsWidth% x%ClearX% y%buttonsY%
  GuiControl, MoveDraw, wrapControl, y%Line1% x%WrapCheckBoxX%
  GuiControl, MoveDraw, NotepadOpen, y%buttonsY% x%OpenNPx% w%OtherButtonsWidth%
  GuiControl, MoveDraw, ontopControl, y%Line2% x%WrapCheckBoxX%
  GuiControl, MoveDraw, URL_MetaDataHelp, % "y" . Line3 . " x" . WrapCheckBoxX
  GuiControl, MoveDraw, Change_Case, % "Y" Line2
  GuiControl, MoveDraw, Edit_Opts, % "Y" Line2
  return
}