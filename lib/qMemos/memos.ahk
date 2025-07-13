MemosAddMenu( objMenu ,justUpdate = 0)
{
  qcMemosMenu.Destroy()
  MemosHotkeys( 0 )
  if !qcOpt[ "Memos_On" ]
    return
  
  memosMenuParams := { iconssize : toInt( 16 )
                    ,tcolor    : NodeGetColor( "mtcolor", qcconf.GetMenuNode() )
                    ,bgcolor   : NodeGetColor( "mbgcolor", qcconf.GetMenuNode() )
                    ,textoffset: glb[ "menuIconsOffset" ]
                    ,noicons   : qcOpt[ "aprns_lightMenu" ]
                    ,nocolors  : qcOpt[ "aprns_lightMenu" ]
                    ,notext    : 0
                    ,ymargin   : 3 + toInt( qcOpt[ "aprns_heightAdjust" ] ) }
  memosMenuParams[ "noicons" ] := 1
  qcMemosMenu := qcPUM.CreateMenu( memosMenuParams )
  memosMenuParams[ "noicons" ] := qcOpt[ "aprns_lightMenu" ]

  BuildMemosMenu( objMenu, memosMenuParams )
  
  if ( qcOpt[ "memos_sub" ] && !justUpdate )
  {
    objMenu.Add( { name : glb[ "memosName" ]
            , icon : glb[ "icoMemos" ]
            , uid : glb[ "memosItemID" ]
            , submenu : qcMemosMenu
            , break : IsNewCol( objMenu, glb[ "mItemsNum" ] ) } )
  }
  else if qcOpt[ "memos_sub" ]
    qcPUM.GetItemByUID( glb[ "memosItemID" ] ).SetParams( { submenu : qcMemosMenu } )
  MemosHotkeys( 1 )
  return
}

BuildMemosMenu( objMenu, menuParams )
{    
  qcMemos := object()   ;cleaning up this array
  
  Loop,% glb[ "memosDir" ] "\*.mmo"
  {
    StringReplace, memoName,A_LoopFileName,% "." A_LoopFileExt
    qcMemos[ A_Index ] := memoName    
    qcMemosMenu.add( { name : memoName, uid : "Memos_" A_Index } )
    MemosCount++
  }
  if !MemosCount
    qcMemosMenu.add( { name : "No Memos", uid : "Memos_empty" } )
  qcMemosMenu.Add()
  qcMemosMenu.Add( { name : "Memos Editor", uid : "Memos_Change" } )
  return
}

MemosActions( command, memo_num )
{
  ChoosedMemo_name := qcMemos[ memo_num ] ;getting memo name from array

  if InStr( command, "clip" )												;sending memo to clipboard
    MemoToClip( ChoosedMemo_name )
  else if InStr( command,"showontop" )											;sending memo to always-on-top gui window
    ShowMemoOnTop( ChoosedMemo_name )
  else if InStr( command, "edit" )
  {
    Memos_Change_GUI()			;opening memos gui
    WinWait,% glb[ "memosTitle" ],,3		;waiting till gui appear
    gui, 8:default
    LV_Modify( memo_num, "Select Vis" )		;selecting memo choosed from popup menu
  }
  else if InStr( command, "email" )
  {
    if GetMemoText( memoText, ChoosedMemo_name )
    {
      if (memoText = "")
        DTP( "Memo empty!", 1000 )
      else
      {
        MailEscape( memoText )
        mail_string := "mailto:?subject=" . ChoosedMemo_name . "&body=" . memoText
        RunCommand( { cmd : mail_string, noctrl : 1, nolog : 1, noshift : 1 } )
        mail_string =
      }
    }
  }
  else if InStr( command, "tofile" )
    CopyMemoToFile( ChoosedMemo_name )
  return
}

Memos_Change_GUI()
{
  global
  gui, 8:default
  If IsWindow( qcGui[ "memos" ] )
  {
    WinActivate,% "ahk_id " qcGui[ "memos" ]
    Return
  }
  QCSetGuiFont( 8 )
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  Gui 8:+LastFound
  qcGui[ "memos" ] := WinExist() + 0
  Menu, MemosActions, Delete

  gui, add, text, , Memos:
  gui, add, text,xm+160 yp vmemoname_gui w400 R1
  ;**------------
  gui, Add, ListView,xm h250 w150 AltSubmit vMemosList hwndmemoHwnd gOnMemoSelect -ReadOnly Count%MemosCount% -Multi -hdr +BackGroundTeal +cWhite, Memos
  Loop,% glb[ "memosDir" ] "\*.mmo"
  {
    SplitPath, A_LoopFileName,,,,MemoToAdd
    LV_Add("", MemoToAdd)
  }
  GuiControl, MoveDraw, MemosList
  ;**------------
  Gui, Add, Edit, yp xp+160 w400 hp vMemoPreview +Multi +Wrap gMemoPreviewChanged
  LV_Modify(1,"Select")
  GuiControlGet,memo_edit_hwnd,Hwnd,MemoPreview												;saving edit field hwnd
  
  ;**------------
  Gui, Add, Button, xm h30 w100 vSaveMemosButton gApplyMemosChanges +Disabled, Save Changes
  Gui, font, s14
  Gui, Add, Button, x+10 h30 W30 vaddMemo gaddMemo, +
  Gui, font, s8
  
  Gui, Add, Button, x+20 h20 W50 vSendMemoE gSendMemoEmail, E-Mail
  gui, add, text, x+10, Case:
  Gui, Add, DropDownList, x+10 vCaseDDL gMemoCaseChange, Upper|Lower|Sentence|Title
  Gui,Add,Button,x+10 vmmo_MemoEncrypt_but gCryptThatShit,Encrypt
  Gui,Add,Button,x+1 vmmo_MemoDecrypt_but gCryptThatShit,Decrypt
  Gui, Add, Text, x+10 W70 cBlue vURL_MemoSyntaxHelp gOpen_MemoSyntaxHelp, Syntax Help
  
  If !LV_GetNext()																			;if no memos in list
    GuiControlSet("MemoPreview|CaseDDL|SendMemoE|mmo_MemoEncrypt_but|mmo_MemoDecrypt_but","","Disable",8,0)

  Menu, MemosActions, Add, Show on Top, ShowMemoOnTop_contx
  Menu, MemosActions, Add, Rename, RenameMemo_contx
  Menu, MemosActions, Add, Delete, DeleteMemo_contx
  Menu, MemosActions, Add
  Menu, MemosActions, Add,To File, Save_Memo_To_File
  
  Hotkey("^s",1,"ApplyMemosChangesHK",1,"i)^\s*\Q" glb[ "memosTitle" ] "\E\s*$")
  Gui, Show,,% glb[ "memosTitle" ]
  MemoToAdd =	
  return

  Open_MemoSyntaxHelp:
    SyntaxHelp()
    return

  SendMemoEmail:
    Gui, 8:Default
    Gui +OwnDialogs
    LV_GetText(MemoName, SelectedRowNumber)
    if !GetMemoText(memoText, MemoName)
      return
    if (memoText = "")
    {
      DTP("Memo empty!",1000)
      return
    }
    else
    {
      MailEscape(memoText)
      mail_string := "mailto:?subject=" . MemoName "&body=" . memoText
      Run,% mail_string,,UseErrorLevel
      if errorlevel
        MsgBox,16,Cannot open e-mail client,You probably have no default e-mail client installed
      mail_string =
    }
    return

  ShowMemoOnTop_contx:
    Gui, 8:Default
    LV_GetText(MemoName, SelectedRowNumber)
    ShowMemoOnTop(MemoName)
    return

  8GuiContextMenu:
    Gui, 8:Default
    if (A_GuiControl = "MemosList" && LV_GetCount() && LV_GetNext() && AllowContx)
    {
      LV_Modify(A_EventInfo,"Focus Select Vis")
      AllowContx := 0
      Menu, MemosActions, Show
    }
    return

  ApplyMemosChanges:
    MemosSaveChanges()
    return


  Save_Memo_To_File:
    Gui, 8:Default
    Gui, +OwnDialogs
    if !LV_GetNext()
    {
      DTP("Choose a memo!")
      return
    }
    LV_GetText(MemoName,LV_GetNext())
    CopyMemoToFile(MemoName)
  return

  MemoCaseChange:
    Gui, 8:Default
    GuiControlGet, CaseDDL,,CaseDDL
    GuiControlGet, MemoPreview,,MemoPreview
    if (CaseDDL == "Upper")
      StringUpper, MemoPreview, MemoPreview
    if (CaseDDL == "Lower")
      StringLower, MemoPreview, MemoPreview
    if (CaseDDL == "Title")
      StringUpper, MemoPreview, MemoPreview, T
    if (CaseDDL == "Sentence")
    {
      StringLower, MemoPreview, MemoPreview		
      MemoPreview := RegExReplace(MemoPreview, "`a)(\.\s*.|^\s*.|`n\s*.)", "$U0")
    }
    GuiControl,,MemoPreview,%MemoPreview%
    GuiControl,,CaseDDL,|Upper|Lower|Sentence|Title
    GuiControl, Enable, SaveMemosButton
  return

  addMemo:
    gui, 8:default
    if !FileExist( glb[ "memosDir" ] )
      FileCreateDir,% glb[ "memosDir" ]
    MemoName := GetNewMemoName("new_Memo")
    GuiControl, Focus, MemosList
    LV_Modify(LV_Add("", MemoName),"Focus Select Vis") ;adding and selecting new memo
    FileOpen( glb[ "memosDir" ] . "\" . MemoName . ".mmo","w").Close()
    return

  DeleteMemo_contx: ;deleting memo from context menu
    Gui, 8:Default
    Gui, +OwnDialogs
    RowNumber := LV_GetNext()
    RowsCount := LV_GetCount()
    LV_GetText(MemoName, RowNumber)
    if qcOpt["memos_DelConf"]
    {
      MsgBox, 36, Delete Memo?, Delete "%MemoName%"?
      IfMsgBox, NO
        Return
    }
    LV_Delete(RowNumber)
    FileDelete,% glb[ "memosDir" ] "\" MemoName ".mmo"
    GuiControl,, MemoPreview
    GuiControl,, memoname_gui
    LV_Modify(RowNumber := RowNumber == 1 ? 1 : (RowNumber := RowsCount == RowNumber ? RowNumber-1 : RowNumber),"Select Vis")
    if (LV_GetCount() = 0)
    {
      GuiControlSet("MemoPreview|CaseDDL|SendMemoE|mmo_MemoEncrypt_but|mmo_MemoDecrypt_but","","Disable",8,0)
      GuiControl,,MemoPreview
    }
    RowsCount := RowNumber := ""
    return

  RenameMemo_contx: ;renaming memo from context menu
    Gui, 8:Default
    SendMessage( memoHwnd, LVM_EDITLABELW := 0x1000 + 118, LV_GetNext()-1, 0 )
    return

  MemoPreviewChanged:
    if AllowApplyButtonEnabling
      GuiControl, Enable, SaveMemosButton
    return


  8GuiClose:
  8GuiEscape:
    Gui, 8:Default
    Gui, +OwnDialogs
    MemoCheckState()
    Gui, 8:Destroy
    Menu, MemosMenuBar, Delete
    Menu, MemosActions, Delete
    Menu, ChCase, Delete
    memo_edit_hwnd =
    QCFreeMem()
    MemosAddMenu( qcMainMenu, 1 )
    MemoMenu_MColor := MemoMenu_TColor := ""
    Hotkey("^s",0,"ApplyMemosChangesHK",1,"i)^\s*\Q" glb[ "memosTitle" ] "\E\s*$")
    return
    
  OnMemoSelect:
    Gui, 8:Default
    Gui, +OwnDialogs
    if (A_GuiEvent == "I" && InStr(ErrorLevel, "s", 1))
    {
      prevMemoRow := A_EventInfo
    }
    ;puts selected memo's content to the edit control
    else if (A_GuiEvent == "I" && InStr(ErrorLevel, "S", 1))
    {
      AllowContx := 1
      MemoCheckState(prevMemoRow)
      if memo_Old_Name	;in case if memo was not successfully renamed before switching to another
      {
        LV_Modify(last_renamed_memo, "", memo_Old_Name)
        DTP("Please use ""Enter"" to confirm memo renaming!")
        last_renamed_memo =
        memo_Old_Name =
      }
      AllowApplyButtonEnabling = 0
      GuiControlGet, state, Enabled, MemoPreview
      if !state
        GuiControlSet("MemoPreview|CaseDDL|SendMemoE|mmo_MemoEncrypt_but|mmo_MemoDecrypt_but","","Enable",8,0)	;Enabling edit control in case it was disabled (happens only when memos list empty)
      Free(state)
      GuiControl, Disable, SaveMemosButton			;disabling button "Apply Changes"
      SelectedRowNumber := A_EventInfo				;putting currently selected row number into global variable
      LV_GetText(MemoName, A_EventInfo)				;getting selected memo name
      GuiControl,,memoname_gui,%MemoName%				;puts selected memo name above edit control
      GuiControl,,MemoPreview							;emptying edit control
      GetMemoText( Memo, MemoName, 0 )		;reading content of selected memo	
      if (Memo = "")
      {
        AllowApplyButtonEnabling = 1
        return
      }
      MemoToCtrl(Memo,"MemoPreview")
      GuiControl, Focus, MemosList
      Sleep 50
      AllowApplyButtonEnabling = 1
    }
    else if (A_GuiEvent == "K") ;if button pressed, support for deleting memos
    {
      if A_EventInfo in 110,46 ;if "Del" pressed 
      {
        RowNumber := LV_GetNext()
        RowsCount := LV_GetCount()
        LV_GetText(MemoName, RowNumber)
        if qcOpt["memos_DelConf"]
        {
          MsgBox, 36, Delete Memo?, Delete "%MemoName%"?
          IfMsgBox, NO
              Return
        }
        LV_Delete(RowNumber)
        FileDelete,% glb[ "memosDir" ] "\" MemoName ".mmo"
        GuiControl,, MemoPreview
        GuiControl,, memoname_gui
        LV_Modify(RowNumber := RowNumber == 1 ? 1 : (RowNumber := RowsCount == RowNumber ? RowNumber-1 : RowNumber),"Select Vis")
        if (LV_GetCount() = 0)
        {
          GuiControlSet("MemoPreview|CaseDDL|SendMemoE|mmo_MemoEncrypt_but|mmo_MemoDecrypt_but","","Disable",8,0)
          GuiControl,,MemoPreview
        }
        RowsCount := RowNumber := ""
      }
      else if (A_EventInfo = 38 && LV_GetNext()=1 && AllowJumpList = 1) 				;if "Up" pressed while on the top of list
        LV_Modify(LV_GetCount(),"Select Focus Vis") 								;select last item from list
      else if (A_EventInfo = 40 && LV_GetNext()=LV_GetCount() && AllowJumpList = 1) 	;if "Down" pressed while on the last item from list
        LV_Modify(1,"Select Focus Vis")												;select item on the top of list
      else if (LV_GetNext() = LV_GetCount() || LV_GetNext() = 1)
        AllowJumpList := 1
      else
        AllowJumpList := 0
    }
    else if (A_GuiEvent == "E") ;support for editing memos name
      last_renamed_memo := A_EventInfo, LV_GetText(memo_Old_Name, last_renamed_memo)
    else if (A_GuiEvent == "e")
    {
      LV_GetText(memo_New_Name, last_renamed_memo)
      if (memo_New_Name == memo_Old_Name)
      {}
      else If (StrLen(memo_New_Name) > 190)
      {
        DTP("New memo name is too long! (max 190 chars)")
        LV_Modify(last_renamed_memo, "Select Vis", memo_Old_Name)			
      }
      else if RegExMatch(memo_New_Name,"[^0-9a-zA-Z!@#$%\^&()_\-+= ]+|^&|^\s*$")
      {
        DTP("Wrong Name!")
        LV_Modify(last_renamed_memo, "Select Vis", memo_Old_Name)
      }
      else If IsMemoExist(memo_New_Name)
      {
        DTP("This Memo already exists!")
        LV_Modify(last_renamed_memo, "Select Vis", memo_Old_Name)				
      }
      else
      {
        FileMove,% glb[ "memosDir" ] "\" memo_Old_Name ".mmo",% glb[ "memosDir" ] "\" memo_New_Name ".mmo",1
        if ErrorLevel
        {
          DTP("Could not rename memo!")
          LV_Modify(last_renamed_memo, "Select Vis", memo_Old_Name)
        }
        GuiControl,,memoname_gui,%memo_New_Name%
      }
      memo_Old_Name =
      last_renamed_memo =
    }
    else if (A_GuiEvent == "DoubleClick")
    {
      if LV_GetNext()
      {
        SendMessage( memoHwnd, LVM_EDITLABELW := 0x1000 + 118, A_EventInfo-1, 0 )
        last_renamed_memo := A_EventInfo, LV_GetText(memo_Old_Name, last_renamed_memo)
      }
      else
        GoSub, addMemo
    }
  return
    
  CryptThatShit:
    ProcessMemoEncrypt(A_GuiControl)
    return
}

IsMemoExist(memo_name)
{
  Loop,% glb[ "memosDir" ] "\" memo_name ".mmo"
      return 1
  return 0
}

ShowMemoOnTop(memo_Name)
{
  global
  if !GetMemoText(Memo_Text,memo_Name)
    return
  if (memo_Text == "")
  {
    DTP("Memo empty!")
    return
  }
  if (memoontop_gui == "" || memoontop_gui == 98)
    memoontop_gui := 30
  Else
    memoontop_gui++
  if (memoontop_gui == 77)
    memoontop_gui++
  
  Gui, %memoontop_gui%:+LastFoundExist
  IfWinExist
  {
    DTP("Existed Memo-On-Top replaced due to limits...",3000)
    Gui, %memoontop_gui%:Destroy
  }
  
  Gui, %memoontop_gui%:Default
  QCSetGuiFont( memoontop_gui )
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  Gui, Margin, 5, 5
  Gui,Add,Edit,xm ym -Theme W250 H250 +Multi vOnTopMemo%memoontop_gui% HWND%memoontop_gui%_edit_hwnd gOTM_Changed
  
  OTM_e_name = OnTopMemo%memoontop_gui%
  MemoToCtrl(Memo_Text,OTM_e_name,memoontop_gui)
  OTM_e_name =
  OTM_%memoontop_gui%_name := memo_Name
  ;~ GuiControl,+ReadOnly, OnTopMemo%memoontop_gui%
  Gui,Add,Button,xm y+5 w80 h20 vOTM_Save_But%memoontop_gui% gsave_OTM_Changes Hidden,Save
  Gui,Add,Button,x+5 w100 h20 vOTM_SaveEncrypt%memoontop_gui% gsave_OTM_Changes Hidden,Encrypt && Save
  
  ;creating menu bar for current gui

  Menu, %memoontop_gui%MenuBar, Delete
  Menu, %memoontop_gui%Tools, Add, Change Font, changefont
  Menu, %memoontop_gui%Tools, Add, Change BG Color, change_color
  Menu, %memoontop_gui%Tools, Add, Change Text Color, change_color
  Menu, %memoontop_gui%Tools, Add, Set Random Colors, change_color
  Menu, %memoontop_gui%Tools, Add
  Menu, %memoontop_gui%Tools, Add, Save current settings, savecurrentsettings
  Menu, %memoontop_gui%Tools, Add
  Menu, %memoontop_gui%Tools, Add, Always On Top, changeontoppness
  Menu, %memoontop_gui%Tools, Check, Always On Top
  Menu, %memoontop_gui%Tools, Add, Edit, edit_memo
  Menu, %memoontop_gui%MenuBar, Add, -<>-, :%memoontop_gui%Tools

  Gui, Menu, %memoontop_gui%MenuBar	
  
  ChoosedBGColor%memoontop_gui% := qcOpt[ "OTM_bg_default_color" ]
  if ChoosedBGColor%memoontop_gui% is not Integer
    ChoosedBGColor%memoontop_gui% := "0xE0E0E0"
  ChoosedTextColor%memoontop_gui% := qcOpt[ "OTM_t_default_color" ]
  if ChoosedTextColor%memoontop_gui% is not Integer
    ChoosedTextColor%memoontop_gui% := 0	
  
  CColor(%memoontop_gui%_edit_hwnd,ChoosedBGColor%memoontop_gui%,ChoosedTextColor%memoontop_gui%)								;setting default colors
  
  OTM_%memoontop_gui%_font := qcOpt[ "OTM_default_font" ]
  FONTobj2ahk( qcOpt[ "OTM_default_font" ], fontname, styles )
  if ( fontname || styles )
  {
    gui, font,% styles,% fontname
    GuiControl, Font, OnTopMemo%memoontop_gui%
  }	
  Gui, +LabelOnTopMemo +Resize MinSize200x200 +AlwaysOnTop +ToolWindow ;-SysMenu
  GUi, +LastFoundExist
  WinGet, %memoontop_gui%hwnd, ID
  WinSet, Redraw,,% "ahk_id " %memoontop_gui%hwnd
  Gui,Show,, %memo_Name%
  return
  
  OTM_Changed:
    Gui, %A_Gui%:Default
    GuiControlGet,state,Visible,OTM_Save_But%A_Gui%
    if !state
    {
      WinGetPos, X, Y, W, H,% "AHK_ID " %memoontop_gui%_edit_hwnd
      GuiControl, MoveDraw, OnTopMemo%A_Gui%,% "H" . (H-15)
      GuiControl, Show, OTM_Save_But%A_Gui%
      GuiControl, Show, OTM_SaveEncrypt%A_Gui%
    }
    else
    {
      GuiControl,MoveDraw,OnTopMemo%A_Gui%
    }
    return
  
  save_OTM_Changes:
    guinum := A_Gui
    Gui, %guinum%:Default
    ctrlname = OnTopMemo%guinum%
    if instr(A_GuiControl,"OTM_SaveEncrypt")
      r := SaveMemoToFile(OTM_%guinum%_name,ctrlname,guinum,1)
    else
      r := SaveMemoToFile(OTM_%guinum%_name,ctrlname,guinum)
    if !r
      return
    Gui, %guinum%:Default
    WinGetPos, X, Y, W, H,% "AHK_ID " %guinum%_edit_hwnd
    GuiControl, MoveDraw, OnTopMemo%guinum%,% "H" . (H+15)
    GuiControl, Hide, OTM_Save_But%guinum%
    GuiControl, Hide, OTM_SaveEncrypt%guinum%
    GuiControl, Focus,OTM_Save_But%guinum%
    return
  
  change_color:
    CC_Gui := A_Gui
    if (A_ThisMenuItem == "Change BG Color")
      ChoosedColor := "0x" ChoosedBGColor%A_Gui%			;set default color for color dialog to current
    else if (A_ThisMenuItem == "Change Text Color")
      ChoosedColor := "0x" ChoosedTextColor%A_Gui%		;set default color for color dialog to current
    else if (A_ThisMenuItem == "Set Random Colors")
    {
      CColor(%CC_Gui%_edit_hwnd, ChoosedBGColor%CC_Gui% := RandColor(), ChoosedTextColor%CC_Gui% := RandColor())
      WinSet, Redraw,,% "ahk_id " %CC_Gui%hwnd
      return
    }
    else return
    if Dlg_Color(ChoosedColor, %A_Gui%hwnd)
    {
      if (A_ThisMenuItem == "Change BG Color")
        CColor(%A_Gui%_edit_hwnd, ChoosedBGColor%A_Gui% := ChoosedColor, ChoosedTextColor%A_Gui%)
      if (A_ThisMenuItem == "Change Text Color")
        CColor(%A_Gui%_edit_hwnd, ChoosedBGColor%A_Gui%, ChoosedTextColor%A_Gui% := ChoosedColor)
      WinSet, Redraw,,% "ahk_id " %A_Gui%hwnd
      ChoosedColor =
    }
    return
  
  edit_memo:
    ThisGui := A_Gui
    gui, %ThisGui%:default
    Gui %ThisGui%:+LastFoundExist
    WinSet, AlwaysOnTop, Off
    Menu, %ThisGui%Tools, Uncheck, Always On Top
    Memos_Change_GUI()				;opening memos gui\
    WinWait,% glb[ "memosTitle" ],,3		;waiting till gui appear
    gui, 8:default
    WinGetTitle, MemoName,% "ahk_id " %ThisGui%hwnd
    Loop,% LV_GetCount()
    {
      LV_GetText(TempMemoName, A_Index)
      if (TempMemoName = MemoName)
      {
        LV_Modify(A_Index,"Select Focus Vis") ;selecting memo for edit	
        break
      }
    }
    TempMemoName := MemoName := ""
    WinSet, Top,,% glb[ "memosTitle" ]						;putting memos gui to foreground
    return
  
  OnTopMemoClose:
  Gui, %A_Gui%:Destroy
  Menu, %A_Gui%MenuBar, Delete
  ChoosedBGColor%A_Gui% =
  ChoosedTextColor%A_Gui% = 
  %A_Gui%_edit_hwnd = 
  OnTopMemo%A_Gui% =
  %A_GUI%hwnd =
  memoontop_cb%A_GUI% =
  return
  
  OnTopMemoSize:
  Gui, %A_Gui%:Default
  GuiControlGet,save_vis,Visible,OTM_Save_But%A_Gui%
  GuiControl, MoveDraw, OnTopMemo%A_Gui%,% "W" . (A_GuiWidth-10) . A_Space . "H" . (A_GuiHeight-(save_vis ? 25 : 10))
  GuiControl, MoveDraw, OTM_Save_But%A_Gui%,% "Y" . (A_GuiHeight-20)
  GuiControl, MoveDraw, OTM_SaveEncrypt%A_Gui%,% "Y" . (A_GuiHeight-20)
  return
  
  changefont:
  Gui, %A_GUI%:Default
  if( ret := Dlg_Font( OTM_%A_GUI%_font, false, %A_GUI%hwnd) )
  {
    OTM_%A_GUI%_font := ret
    FONTobj2ahk( ret, fontname, styles )
    gui, font,% styles,% fontname
    GuiControl, Font, OnTopMemo%A_Gui%
  }
  return
  
  changeontoppness:
  Gui, %A_GUI%:Default
  Gui, +LastFoundExist
  Menu, %A_Gui%Tools, ToggleCheck, Always On Top
  WinSet, AlwaysOnTop, Toggle
  return
    
  savecurrentsettings:
    qcOpt[ "OTM_bg_default_color" ] := ChoosedBGColor%A_Gui%
    qcOpt[ "OTM_t_default_color" ] := ChoosedTextColor%A_Gui%
    qcOpt[ "OTM_default_font" ] := OTM_%A_GUI%_font
    qcconf.Save()
    return
}

GetNewMemoName(mmo_Name)
{
  loop,% glb[ "memosDir" ] "\" mmo_Name ".mmo"
    mmo_Name := GetNewMemoName( NameGetNext(mmo_Name) )
  return mmo_Name
}

GetMemoPreview( memoNum )
{
  memo_name := qcMemos[ memoNum ]
  IfNotExist,% glb[ "memosDir" ] "\" memo_name ".mmo"
    memo_preview .= "File Not Found!"

  f := FileOpen( glb[ "memosDir" ] . "\" . memo_name . ".mmo","r","CP0")
  if IsObject(f)
    loop, 5
      memo_preview .= f.ReadLine()
  f.Close()
  if (memo_preview = "")
    memo_preview := "Empty!"
  else
    memo_preview .= "..."
  return memo_preview
}

MemoToCtrl(MemoText,CtrlName,Gui = "") 
{	
  if (Gui = "")
    Gui := A_Gui
  GuiControlSet(CtrlName,MemoText,"",Gui)
  GuiControl,%Gui%: Focus, %CtrlName%
  return
}

MemoToClip( MemoName )
{
  if !GetMemoText( mTextC, MemoName )
    return
  if (mTextC == "")
    {
      DTP("Memo empty!")
      return
    }
  WinClip.Clear()
  WinClip.SetText( mTextC )
  DTP( "Memo copied to clipboard:`n" MemoName, 3000 )
  return
}

MemoToWindow( MemoName, win_hwnd )
{
  if !GetMemoText( MemoText, MemoName )
    return
  if (MemoText == "")
  {
    DTP("Memo empty!")
    return
  }
  WinActivate, ahk_id %win_hwnd%
  WinWaitActive, ahk_id %win_hwnd%, , 1
  if !WinClip.Paste( MemoText, qcOpt[ "gen_paste_method" ] )
  {
    DTP("Could not send to the window.`nPlease try again.")
    Return
  }
  return
}

CopyMemoToFile(mName)		;this function is for copying memo to external txt
{
  if !GetMemoText(memo, mName)
    return
  FileSelectFile, OUT_FILE, s16, %mName%.txt
  If Errorlevel
    Return
  
  f := FileOpen(OUT_FILE,"w","CP0")
  if IsObject(f)
    f.Write(memo)
  f.Close()
  return
}

GetMemoText( ByRef mText, mName, EvalMetaSyntax = 1 )
{
  mText := ""
  mText := FileOpen( glb[ "memosDir" ] . "\" . mName . ".mmo","r","CP0").Read()
  
  StringReplace,mText,mText,`n,`r`n,1
  if EvalMetaSyntax
  {
    if GetKeyState( "CTRL", "P" )
      if !( mText := MemoCrypt( mText, 0 ) )
        return 0
    mText := EvalMetaData( mText )
  }
  return 1
}

MemosSaveChanges(row = "")
{
  Gui, 8:Default
  GuiControlGet, SaveMemosButton, Enabled, SaveMemosButton
  if !SaveMemosButton
    return
  LV_GetText( MemoName, row = "" ? LV_GetNext() : row )
  SaveMemoToFile(MemoName)
  GuiControl, Disable, SaveMemosButton
}

MemoCheckState(row = "")
{
  Gui, 8:Default
  GuiControlGet, state, Enabled, SaveMemosButton
  if state
  {
    MsgBox,68,Saving Memo,Last memo changes were not saved.`nDo you want to save them?
    IfMsgBox,Yes
      MemosSaveChanges(row)
  }
  return
}

SaveMemoToFile(mName,CtrlName = "",GuiNum = "",encrypt = "")			;this function is saving memo's changes back to file
{
  if (!CtrlName || !GuiNum)
    mText := GuiControlGet("MemoPreview",8)
  else
    mText := GuiControlGet(CtrlName,GuiNum)
  if (encrypt && mText != "")					;used to encrypt memo from OTM window
  {
    mText := MemoCrypt(mText,1,GuiNum)
    if !mText
      return 0
  }
  f := FileOpen( glb[ "memosDir" ] . "\" . mName . ".mmo","w")
  if IsObject(f)
    f.Write(mText)
  f.Close()	
  return 1
}