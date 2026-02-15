class GuiTooltip
{
	lastHWND := ""
	lastGuiCtrl := ""
	tooltipDelay := 600
	
	opt_RunOnStartup_TT := "Run " glb[ "appName" ] " when Windows starts up"
	opt_ContextQC_TT := "Add an option to the Windows Explorer context menu for each file/folder`nallowing you to quickly add a shortcut for it"
	opt_heightAdjust_TT := "Increases space between items in menu"
	opt_IconsTlp_TT := "Is checked, - item's name will be shown when you hold mouse cursor above it"
	opt_lightMenu_TT := "If checked, remove icons/colors from the menu"
	opt_mnem_method_TT := "Option determines what will happen when item selected in the menu`nby pressing corresponding key button:`nrun - the first matching item in the menu will be executed`nselect - the next matching item will only be selected`nallowing you to scroll through all such items in the menu"
	addMemo_TT := "Add new Memo"
	UpperCase_TT := "Upper Case"
	LowerCase_TT := "Lower Case"
	SentenceCase_TT := "Sentence Case"
	TitleCase_TT := "Title Case"
	opt_TForm_TT := "Each subsequent menu will be shown athwart to the previous one`nBest usage with 'Show Icons Only' option"
	opt_gest_glbOn_TT := "Currently suspended.`nYou can reenable them through 'Suspend' menu or " glb[ "appName" ] " tray menu"
	opt_hkey_glbOn_TT := this.opt_gest_glbOn_TT
	ToFileButtonClipX_TT := "Save current clip to file as plain text`nCTRL + Click - to save in original format"
	ClearButtonClipX_TT := "Clear current Clip"
	NotepadOpen_TT := "View clip in notepad"
	opt_autoUpd_TT := "Will check for updates automatically on each " glb[ "appName" ] " start after 2 minutes of run time"
	SortTypeChoice_TT := "Sort items inside selected menu"
	opt_smenusOn_TT := "The S-Menu feature allows you to save a submenu you have created as a separate menu`nthat can run outside of " glb[ "appName" ] ". The Submenu is saved as a file which is associated with " glb[ "appName" ] "."
	opt_editorItem_TT := "If checked, 'Open Editor' item will be shown in the menu."
	opt_trayIcon_TT := "If checked, tray icon will be shown"
	opt_transp_TT := "Transparency level of menu`n0 - fully transparent`n255 - opaque"
	opt_cmdDelay_TT := "Delay between running each command for a shortcut which has more than one`nRange 0-10000 milliseconds"
	opt_gest_time_TT := "Sets the number of seconds Mouse Gestures will be Suspended`nHold Control and click the Suspend Gestures menu item to suspend mouse gestures for this amount of time"
	opt_gest_curBut_TT := "Select which mouse button you wish to use to activate gesture.`nYou may select optional modifier keys as well."
	Memo_Encrypt_TT := "Keep current memo encrypted on the disk"
	opt_gest_tempNotify_TT := "Notify when gestures are temporarily disabled/restored"
	SaveMemosButton_TT := "Save changes you made to memo`nCTRL+S"
	SendMemoE_TT := "E-Mail this memo"
	ontopControl_TT := "Make this window Always-On-Top"
	opt_suspendSub_TT := "If checked, 'Suspend' menu will be shown in the main menu"
	opt_helpSub_TT := "If checked, 'Help' will be shown in the menu"
	opt_clips_SaveOnExit_TT := "Save clips to files on " glb[ "appName" ] " exit and restore on startup"
	opt_iconsOnly_TT := "Show only icons without text"
	opt_colBar_TT := "Show vertical line between columns"
	opt_noTheme_TT := "Make windows looking in classic style`nMay solve problems with font/colors"
	PwdSessSave_TT := glb[ "appName" ] " will keep your password until exit"
	SwitchViewButton_TT := "Switch between single/multi-line view of shortcut commands"
	opt_IconRelPath_TT := "If enabled, " glb[ "appName" ] " will always try to save relative path to icons`nUseful for portable use"
	opt_CmdRelPath_TT := "If enabled, " glb[ "appName" ] " will always try to save relative path of shortcut's commands`nUseful for portable use"
	opt_fm_extractExe_TT := "If enabled, may significantly reduce`nspeed at which menu builds."
	opt_fm_showicons_TT := "If disabled, Folder Menu will not extract/show any icons"
	opt_fm_iconssize_TT := "Allow set different icons size for folder menus.`nIf 'global' specified - will be used value choosen under 'Appearance' tab"
	hkey_changer_hint_TT := "All hotkeys are disabled to prevent`nexisting ones from interference.`nClose this window to restore them."
	proc_list_uac_but_TT := "Get process list with Admin rights"
	
	__Get( aName )
	{
		if ( aName = "AfoSB_TT" )
			return glb[ "afo_cur_details" ]
		return ""
	}
	
	Show( hwnd, controlName )
	{
		static obj
		this.lastHWND := hwnd
		this.lastGuiCtrl := controlName
		this._SetText()
		obj := this
		SetTimer, ShowTooltip, -1
		return
		
		ShowTooltip:
			obj._ShowTlp()
			return
	}
	
	_SetText()
	{
		this.tlp_text := this[ this.lastGuiCtrl "_TT" ]
	}
	
	_GetText()
	{
		return this.tlp_text
	}
	
	_CleanTlp()
	{
		this.tlp_text := ""
		tooltip,,,, 9
	}
	
	UpdateTlp( new_text )
	{
		this.tlp_text := new_text
		if this.tlp_shown
			Tooltip,% this._GetText(),,,9
	}
	
	_ShowTlp()
	{
		localHWND := this.lastHWND
		if ( this._GetText() = "" )
			return
		Loop
		{
			this.tlp_shown := 0
			MouseGetPos,Xcur,Ycur,,hwndname,2
			if ( hwndname != localHWND )
				break
			curtime = %A_Sec%%A_MSec%
			Loop
			{
				MouseGetPos,X,Y
				sleep 50
				if (Xcur != X || Ycur != Y)
				{
					tooltip,,,, 9
					break
				}
				if (((A_Sec . A_MSec) - curtime)> this.tooltipDelay && !this.tlp_shown) ;tooltip_delay is a delay before showing tooltip
				{
					curtime = %A_Sec%%A_MSec%
					Tooltip,% this._GetText(),,,9
					this.tlp_shown := 1
				}
			}
		}
		this._CleanTlp()
		return
	}
}

ShowTooltip(p_w, p_l, p_m, p_hw)
{
  GuiControlGet,name,% WinGetParent( p_hw ) ":Name",% p_hw
  if name
    oGuiTooltip.Show( p_hw, name )
	return
}

ShowCtrlTlp( msg, hCtrl )
{
  tooltip % msg
  Loop
  {
    MouseGetPos,,,,hw,2
    if( hw != hCtrl )
      break
    sleep 500
  }
  tooltip
  return
}