MG_AddEditLV() 
{
	static ie_static_var, SwitchViewButton, ctrl_Main_LV
out_target:= out_name := ""

Gui, 1:Default

Menu, Main_Menu_CmdChange, Add, File,IE_File
Menu, Main_Menu_CmdChange, Add, Folder,IE_Folder
Menu, Main_Menu_CmdChange, Add, Folder Menu,IE_FMenu
Menu, Main_Menu_CmdChange, Add, Folder Switch,IE_FSwitch
Menu, Main_Menu_CmdChange, Add, System Shortcut,IE_System
Menu, Main_Menu_CmdChange, Add, From Process,IE_FromProcess
Menu, Main_Menu_CmdChange, Add, From Recent,IE_FromRecent
Menu, Main_Menu_CmdChange, Add, EMail,IE_Email
Menu, Main_Menu_CmdChange, Add, URL,IE_Url
Menu, Main_Menu_CmdChange, Add, Special,IE_Spc

Menu, IE_Contx_Menu, Add, + Insert,IE_InsertBlank
Menu, IE_Contx_Menu, Add, + Add,IE_AddBlank
Menu, IE_Contx_Menu, Add 
Menu, IE_Contx_Menu, Add, Set, :Main_Menu_CmdChange
Menu, IE_Contx_Menu, Add 
Menu, IE_Contx_Menu, Add, Path: Make Relative, IEPathMakeRel
Menu, IE_Contx_Menu, Add, Path: Make Full, IEPathMakeFull
Menu, IE_Contx_Menu, Add
Menu, IE_Contx_Menu, Add, Delete,Delete_LV_Item
Menu, IE_Contx_Menu, Add
Menu, IE_Contx_Menu, Add, Clear List,IE_ClrList

Menu, IE_Contx_Menu_LV, Add,+ Add,IE_AddBlank
Menu, IE_Contx_Menu_LV, Add,
Menu, IE_Contx_Menu_LV, Add, Clear List,IE_ClrList

qcGui[ "main_tbbot_IL" ] := IL_CreateNew(16, 16, 7, 1 )
;adding icons to the toolbar IL
loop,% glb[ "icoIECnt" ]
{
	ico := glb[ "iconListPath" ] . glb[ "icoIEInd" ]+(A_Index-1)
	IL_AddIcon( qcGui[ "main_tbbot_IL" ], IconExtract( ico,16 ) )
}
qcGui[ "main_tbbot" ] := Toolbar_Add( qcGui[ "main" ], "Gui_Main_TBBot_Handler","FLAT LIST TOOLTIPS", qcGui[ "main_tbbot_IL" ], "x10 y325" )
;DO NOT change IDs since they are hardly linked with events
btns = 
	(LTrim
	Add New Command,1,,,1
	-
	Move Command Down,3,,,3
	Move Command Up,4,,,8
	Set Command,5,,WHOLEDROPDOWN,4
	-
	Run Selected Command,6,,,5
	Run All,7,,,6
	-
	Delete,8,,,7
	)
Toolbar_Insert( qcGui[ "main_tbbot" ], btns )
Toolbar_AutoSize( qcGui[ "main_tbbot" ], 1 )

Gui,Add,Button,x460 y325 w25 h25 hwndhandle gSwitchCmdView vSwitchViewButton +0x00000040	;BS_ICON
qcGui[ "main_svBut" ] := handle

Gui, Add, ListView,x10 y380 w470 h100 vctrl_Main_LV gIE_ListEvent hwndhandle -ReadOnly -Hdr AltSubmit Grid +0x8, targets	;LVS_SHOWSELALWAYS
qcGui[ "main_lv" ] := handle
Return

IEPathMakeRel:
IEPathMakeFull:
	Gui, 1:Default
	Gui, +OwnDialogs
	row := 0
	update := 0
	loop, % LV_GetCount( "S" )
	{
		row := LV_GetNext( row )
		LV_GetText( cmd, row )
		if instr( A_ThisLabel, "Rel" )
			new_cmd := QCPathMakeRelative( cmd )
		else
			if !qcOpt[ "gen_CmdRelPath" ]
				new_cmd := QCPathMakeFull( cmd )
			else {
				msg := "This command is disabled while option 'Always save commands relative path' is in effect"
				msgbox,48,Command currently disabled,% msg
				return
			}
		LV_Modify( row, "", new_cmd )
		if !( new_cmd == cmd )
			update := 1
	}
	if update
		Gui_Main_SyncFrom( "LV" )
	return

SwitchCmdView:
	GUI_Main_ToggleView()
	return

IE_ClrList:
	Gui, 1:Default
	LV_Delete()
	Gui_Main_SyncFrom( "LV" )
	return

IE_Spc:
	GUI_Special_Show( 1 )
	return

IE_File:
IE_Folder:
IE_FSwitch:
IE_FMenu:
IE_Url:
IE_Email:
IE_System:
IE_FromProcess:
IE_FromRecent:
	ie_static_var := A_ThisLabel
	SetTimer,IE_ChangeTargetTimer,-1
	return
IE_ChangeTargetTimer:
	LV_GetText( selected_target, LV_GetNext() )
	GUI_Main_ChangeCmd( ie_static_var, selected_target )
	return

IE_Show_Contx_Menu:
	Menu,IE_Contx_Menu, Show
	return
IE_Show_Contx_Menu_LV:
	Menu, IE_Contx_Menu_LV, Show
	return

IE_ListEvent:
	Gui_Main_LV_Event( A_GuiEvent, A_EventInfo )
	Return

Delete_LV_Item:
	GUI_Main_LV_Del()
	return
	
IE_InsertBlank:
	GUI_Main_LV_AddNew( True )
	return

IE_AddBlank:
	if qcOpt[ "main_cmd_LVView" ]
		GUI_Main_LV_AddNew()
	else
		GUI_Main_ED_Set( (( cmd := GUI_Main_ED_Get() ) ? cmd " " glb[ "optMTDivider" ] " " : "" ) . "command" )
	return
}

Gui_Main_LV_Event( event, evInfo )
{
	static lastTVitem
	Gui, 1:Default
	If ( event = "RightClick" || ( event = "K" && evInfo = 93 ) ) ;context menu call
	{
		if LV_GetNext()
			SetTimer,IE_Show_Contx_Menu,-20
		else
			SetTimer,IE_Show_Contx_Menu_LV,-20
	}
	else If ( event = "K")
	{
		If GetKeyState("Del", "P")
			GUI_Main_LV_Del()
	}
	else If ( event = "DoubleClick")
	{
		if LV_GetNext()
		{
			SendMessage( qcGui[ "main_lv" ], LVM_EDITLABELW := 0x1000 + 118, evInfo-1, 0 )
			lastTVitem := TV_GetSelection()
		}
		else
			SetTimer,IE_AddBlank,-1
	}
	else if ( event == "E")
		lastTVitem := TV_GetSelection()
	else if ( event == "e")
	{
		if ( lastTVitem = TV_GetSelection() )
			Gui_Main_SyncFrom( "LV" )
		free( lastTVitem )
	}
	else if ( event == "I" && InStr( ErrorLevel, "S" ) )	;item is selected
		Gui_Main_TBBot_BtnsUpdate()
	else if ( event = "switch" && lastTVitem )
	{
		Gui_Main_SyncFrom( "LV", lastTVitem )
		free( lastTVitem )
	}
}

Gui_Main_TBBot_SetState( mode )
{
	static s_mode
	if ( s_mode = mode )
		return
	s_mode := mode
	ControlSetState( qcGui[ "main_tbbot" ], mode )
	return
}

Gui_Main_TBBot_BtnsUpdate()
{
	static s_mode
	Gui, 1:Default
	; LV - listView active and item selected
	; LV0 - listview active and no item selected
	; ED - edit control active
	mode := qcOpt[ "main_cmd_LVView" ] ? ( LV_GetNext() ? "LV" : "LV0" ) : "ED"
	if ( s_mode = mode )
		return
	s_mode := mode
	
	TB_Enable( qcGui[ "main_tbbot" ],"3|8|5", s_mode = "LV" ? 1 : 0)
	TB_Enable( qcGui[ "main_tbbot" ],"4|7", s_mode ~= "^(ED|LV)$" ? 1 : 0)
	return
}

GUI_Main_ToggleView()
{
	return Gui_Main_SetView( qcOpt[ "main_cmd_LVView" ] := !qcOpt[ "main_cmd_LVView" ] )
}
Gui_Main_SetView( mode )
{
	static hIco_LV, hIco_Line
	if !hIco_LV
		hIco_LV := IconExtract( glb[ "icoCMDIn" ], 16 )
	if !hIco_Line
		hIco_Line := IconExtract( glb[ "icoCMDOut" ], 16 )
	
	GuiControlSet( qcGui[ "main_ed" ],"",mode ? "Hide" : "Show", 1, 0 )
	GuiControlSet( qcGui[ "main_lv" ],"",mode ? "Show" : "Hide", 1, 0 )
	Icon2Button( qcGui[ "main_svBut" ], mode ? hIco_LV : hIco_Line )
	Gui_Main_TBBot_BtnsUpdate()
	return mode
}

GUI_Main_ChangeCmd( tg_type, current_cmd = "" )
{
	Gui, 1:Default
	Gui, +OwnDialogs
	fIsFMenuCheck := InStr( tg_type, "FMenu" ) && LV_GetCount() > 1
	;let user know that setting FolderMenu shortcut may cause troubles
	if fIsFMenuCheck
		if( "No" = QMsgBoxP( { title : "Folder menu shortcut", msg : "Setting this type of shortcut will remove all other commands from the list.`nAre you sure?", pic : "!", buttons : "Yes|No", modal : 1, pos : 1 }, "1" ) )
			return
	o_out := GUI_Main_ChooseCmd( { gui : 1, type : tg_type, cur_cmd : current_cmd } )
	if ( o_out.cmd != "" && !( o_out.cmd == current_cmd ) )
	{
		;removing all commands if this is Folder Menu shortcut
		if( fIsFMenuCheck && qcOpt[ "main_cmd_LVView" ] )
			LV_Delete(),LV_Add("Select Vis Focus")
		if qcOpt[ "main_cmd_LVView" ]
			GUI_Main_LV_SetList( o_out.cmd, True, True )
		else
			GUI_Main_ED_Set( o_out.cmd, True )
	}
	else
		return
	;if this is only command in LV or if edit line is current view
	if  ( ( qcOpt[ "main_cmd_LVView" ] && LV_GetCount() = 1 ) || !qcOpt[ "main_cmd_LVView" ] )
	{
		selItem := TV_GetSelection()
		TV_GetText( current_name, selItem )
		if ( o_out.Icon && IconInd := TV_IL.Add( o_out.Icon ) )
		{
			TV_Modify( selItem, "Select Vis Icon" . IconInd)
			qcconf.ItemSetAttr( qcTVItems[ selItem ], "icon", o_out.Icon )
			Gui_Main_TlbProp_SetIcon( selItem )
		}
		If ( !( o_out.name == current_name ) && o_out.name != "" )
		{
			qcconf.ItemSetAttr( qcTVItems[ selItem ], "name", o_out.name )
			TV_Modify( selItem, "", o_out.name )
		}
	}
	return
}

GUI_Main_LV_Del()
{
	Gui 1:Default
	row_num := LV_GetNext()
	if !row_num
		return
	loop % LV_GetCount("Selected")
		LV_Delete(LV_GetNext())
	rows_count := LV_GetCount()
	if (row_num = rows_count+1)
		LV_Modify(row_num-1,"Select Focus")
	else
		LV_Modify(row_num,"Select Focus")
	GuiControl, Focus,% qcGui[ "main_lv" ]
	Gui_Main_SyncFrom( "LV" )
	return
}

GUI_Main_LV_AddNew( isIns = False )
{
	Gui, 1:Default
	name := "new command"
	if isIns
		num := LV_Insert( LV_GetNext()+1, "Focus Select", name )
	else
		num := LV_Add( "Focus Select", name )
	GuiControl, Focus,% qcGui[ "main_lv" ]
	LV_Modify( 0, "-Select -Focus" ) ;deselect all items
	LV_Modify( num, "Select Focus" )
	SendMessage( qcGui[ "main_lv" ], LVM_EDITLABELW := 0x1000 + 118, num-1, 0 )
	return
}

GUI_Main_LV_SetList( cmds, sync = True, replace = False )
{
	gui,1:Default
	GuiControl, -Redraw,% qcGui[ "main_lv" ]
	if !replace
		LV_Delete()
	if ( cmds != "" )
	{
		if replace
			LV_Delete( start_row := next_row := LV_GetNext() )
		for i,v in StrSplit( cmds, glb[ "optMTDivider" ], A_Tab A_Space "`n`r" )
			if v
				r := replace ? LV_Insert( next_row++, "", v) : LV_Add("", v )
		LV_Modify( replace ? start_row : 1, "Focus Select Vis" )
	}
	GuiControl, +Redraw,% qcGui[ "main_lv" ]
	if sync
		Gui_Main_SyncFrom( "LV" )
	return
}

GUI_Main_LV_GetList()
{
	gui,1:Default
	ControlGet, LV_targets, List,,,% "ahk_id " qcGui[ "main_lv" ]
	StringReplace, Edit_targets, LV_targets,`n,% " " glb[ "optMTDivider" ] " " ,1
	return Edit_targets
}

GUI_Main_ED_Set( cmd, sync = True )
{
	TG_ASaveStop(1)
	GuiControlSet( qcGui[ "main_ed" ], cmd, "", 1 )
	TG_ASaveStop(0)
	if sync
		Gui_Main_SyncFrom( "ED" )
	return
}

GUI_Main_ED_Get()
{
	return GuiControlGet( qcGui[ "main_ed" ], 1 )
}

GUI_Main_LV_Move( GUI, Way ) { ;UP & Whatever
	gui, %GUI%:Default
	s := LV_GetNext()
	IfEqual, s, 0, return
	e := s + LV_GetCount("Selected")-1
	if LV_GetNext(e+1) {
         MsgBox, 16, Error, You can only move a solid block selection.
		 return
	}
	l := LV_GetCount(), cols := LV_GetCount("Column")
	if (way="UP") {
		IfEqual, s, 1, return

		LV_Insert(++e), s--
		loop, %cols%
			LV_GetText(txt, s, A_Index), LV_Modify( e, "col" A_Index, txt )
		LV_Delete(s)
	} else {
		IfEqual, e, %l%, return

 		LV_Insert(s), e+=2
		loop, %cols%
			LV_GetText(txt, e, A_Index), LV_Modify( s, "col" A_Index, txt )
		LV_Delete(e)
	}
	LV_Modify(LV_GetNext(), "Focus")
}


;~ GUI_Main_ChooseCmd( type, byRef target, byRef name, ByRef ico, cur_target = "", P_GUI = 1 )
GUI_Main_ChooseCmd( o_in )
{
	if !IsObject( o_in )
		Exception( "Non-object passed: " o_in "`n" CallStack() )
	if !o_in.gui
		Exception( "no parent gui passed`n" CallStack() )
	if !( type := o_in.type )
		Exception( "no cmd type passed`n" CallStack() )
	o_out := object()
	Gui,% o_in.gui ":+OwnDialogs"
	
	;getting f_p - file path and d_p - dir path for using in the dialogs. It just looks cool
	if ( o_in.cur_cmd != "" )
	{
		f_p := o_in.cur_cmd
		f_p := PathRemoveArgs( f_p )
		if ( substr( f_p, 0 ) = "^" )
			StringTrimRight,f_p,f_p,1
		f_p := PathUnquoteSpaces( f_p )
		if instr( FileExist(f_p), "D" )
			d_p := f_p
		else
			SplitPath,f_p,,d_p
		if !FileExist( f_p )
			f_p =
	}
	;--------------------------------------------
	
	if instr( type,"File" )
	{
		FileSelectFile, target,,%f_p%, Select File
		if target
		{
			o_out.icon := IconFromExt("",target)
			SplitPath,target,,,,name
			o_out.name := name
			o_out.cmd := PathQuoteSpaces( target )
		}
	}
	else if instr(type,"Folder")
	{
		FileSelectFolder, target,*%d_p%, 3, Select Folder
		if target
		{
			o_out.icon := RegExMatch(target,"^\\.*") ? glb[ "icoRemoteFol" ] : glb[ "icoFolder" ]
			SplitPath,target,,dir,,name
			o_out.name := name ? name : dir
			o_out.cmd := PathQuoteSpaces( target )
		}
	}
	else if instr(type,"FMenu")
	{
		FileSelectFolder, target,*%d_p%, 3, Select Folder
		if target
		{
			SplitPath,target,,dir,,name
			o_out.name := ( name ? name : dir ) . "*"
			o_out.cmd := PathQuoteSpaces( target )
			o_out.icon := glb[ "icoFolMenu" ]
		}
	}
	else if instr( type,"FSwitch" )
	{
		FileSelectFolder, target,*%d_p%, 3, Select Folder
		if target
		{
			SplitPath,target,,dir,,name
			o_out.name := ( name ? name : dir ) . "^"
			o_out.cmd := PathQuoteSpaces( target ) . "^"
			o_out.icon := glb[ "icoFolder" ]
		}
	}
	else If instr(type,"System")
	{
		System_Shortcut_Gui( o_in.gui, target, name )
		o_out.name := name
		o_out.cmd := target
		if target
			o_out.icon := glb[ "icoSysItem" ]
	}
	else if instr(type,"Email")
	{
		if ( o_out.cmd := AddMail( o_in.cur_cmd, o_in.gui ) )
			o_out.icon := glb[ "icoEmail" ]
	}
	else if instr( type,"Url" )
	{
		InputBox, target, Enter an URL, Please enter an URL,, 300, 120
		if target
		{		
			o_out.cmd := RegExMatch( target, "i)^\s*(www|http|ftp)" ) ? target : "http://" . target
			o_out.icon := glb[ "icoURL" ]
		}
	}
	else if instr( type,"FromProcess" )
	{
		oParams := object()
		hwnd := GUIAddItemFromProcList( oParams )
		while( IsWindow( hwnd ) )
			sleep, 500
		o_out.name := oParams.name
		o_out.cmd := oParams.cmd
		o_out.icon := IconFromExt("",oParams.iconPath)
	}
	else if instr( type, "FromRecent" )
	{
		oParams := object()
		hwnd := GUIAddItemFromRecent( oParams )
		while( IsWindow( hwnd ) )
			sleep, 500
		o_out.name := oParams.name
		o_out.cmd := oParams.cmd
		if PathIsDir(oParams.iconPath)
			o_out.icon := glb[ "icoFolder" ]
		else
			o_out.icon := IconFromExt("",oParams.iconPath)
	}
	Gui,% o_in.gui ":Default"
	return o_out
}