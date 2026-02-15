ChangeFolderTo( hWin, FolderPath="", Tooltips = 1 )	;window handle and item ID or path
{
	WinGetClass, WinClass, ahk_id %hWin%
	if WinClass in #32770,CabinetWClass
	{
		if ( Dir := QCGetDir( FolderPath ) )
		{
			if (WinClass = "#32770")
				OpenSaveFF( hWin,Dir )
			else if (WinClass = "CabinetWClass")
				ExplorerFF( hWin,Dir )		
		}
		else
		{
			if Tooltips
				DTP("Invalid dir!",1000)
			return 0
		}
	}
	else
	{
		if Tooltips
			DTP("Unsupported window!`nPlease try on explorer window",3000)
		return 0
	}
	return 1
}

OpenSaveFF( hWin, Dir )
{
	hMenu := WinExist("A")
	if !WaitMODKeysRelease()
		return
	ControlSetText,Edit1,%Dir%,ahk_id %hWin%
	ControlFocus,Edit1,ahk_id %hWin%
	ControlSend,Edit1,{Enter},ahk_id %hWin%
	ControlGetText,control_text,Edit1,ahk_id %hWin%
	if (control_text = Dir)
		ControlSetText,Edit1,,ahk_id %hWin%
	WinActivate,% "ahk_id " hMenu
	return
}

ExplorerFF(hWin,Dir) 
{
	hMenu := WinExist("A")
	if A_IsCompiled
		curState := ComObjError( 0 )
	win := GetExplorerItem(hWin)
	if win
		win.Navigate(Dir)
	if A_IsCompiled
		ComObjError( curState )
	WinActivate,% "ahk_id " hMenu
	return
}

GetExplorerItem(hwnd)
{
	for i,item in ShellGetWindows()
		if (item.HWND = hwnd)
			return item
	return 0
}

WaitMODKeysRelease()
{
	KeyWait,Alt,T1
		if ErrorLevel 
			Goto,Just_A_Fail
	KeyWait,Ctrl,T1
		if ErrorLevel 
			Goto,Just_A_Fail
	KeyWait,Shift,T1
		if ErrorLevel 
			Goto,Just_A_Fail
	KeyWait,RWin,T1
		if ErrorLevel 
			Goto,Just_A_Fail
	KeyWait,LWin,T1
		if ErrorLevel 
			Goto,Just_A_Fail
	return 1
	
Just_A_Fail:
	DTP("Couldn`'t switch folder`nMake sure your modifier keys (ctrl`,alt`,shift`,win)`nare released",6000)
	return 0
}