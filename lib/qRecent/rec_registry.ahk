GetWindowsRecentState()
{
	if A_OSVersion in WIN_2003,WIN_XP,WIN_2000
	{
		RegRead, val, HKCU, Software\Microsoft\Windows\CurrentVersion\Policies\Explorer,NoRecentDocsHistory
		if (val = 1)
			state := 0
		else
			state := 1
	}
	else
	{
		RegRead, val, HKCU, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced,Start_TrackDocs
		if (val = 0)
			state := 0
		else
			state := 1
	}
	return state
}

EnableWindowsRecent(SID = "")
{
	if !A_ISAdmin
	{
		MsgBox, 52, Run As Admin?,% "In order to enable Windows Recent Items we will need to write to the registry.`nFor this to happen " glb[ "appName" ] " will need to be run with admin rights.`nWould you like to proceed and run with Admin rights?"
		IfMsgBox, Yes
		{
			API_ShellExecute(A_ScriptFullPath,"-rcnwinrec " . GetUserSid(), A_ScriptDir,"RUNAS")
			return 1
		}
		Return 0
	}
	
	if A_OSVersion in WIN_2003,WIN_XP,WIN_2000
	{
		if (SID = "")
			RegWrite, REG_DWORD, HKCU, Software\Microsoft\Windows\CurrentVersion\Policies\Explorer,NoRecentDocsHistory, 0
		else
			RegWriteToSID(SID,"Software\Microsoft\Windows\CurrentVersion\Policies\Explorer","REG_DWORD","NoRecentDocsHistory",0)
	}		
	else
	{
		if (SID = "")
			RegWrite, REG_DWORD, HKCU, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced,Start_TrackDocs, 1
		else
			RegWriteToSID(SID,"Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced","REG_DWORD","Start_TrackDocs",1)
	}
	return 1
}

GetUserSid()
{
	Loop, HKCU, Software\Microsoft\Protected Storage System Provider, 2, 1
		SID := A_LoopRegName
	return SID
}

RegWriteToSID(SID,Key,ValueType,ValueName="",Value="")
{
	RegWrite,%ValueType%,HKU,%SID%\%Key%,%ValueName%,%Value%
	if errorlevel
		return 0
	else
		return 1
}