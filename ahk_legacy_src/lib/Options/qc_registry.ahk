;######################## Adding context option to explorer
Context_Reg( Toggle, init = False ) 
{
	fErrors := 0
	cmd = "%A_ScriptFullPath%" -a "`%1"
	cmdDirBg = "%A_ScriptFullPath%" -a "`%V"
	iconPath = "%A_ScriptFullPath%"
	if ( Toggle = 1 )
	{
		RegRead, dirText, HKEY_CLASSES_ROOT, Directory\shell\QC
		RegRead, dirBgText, HKEY_CLASSES_ROOT, Directory\Background\shell\QC
		RegRead, filesText, HKEY_CLASSES_ROOT, *\shell\QC
		if ( dirText != glb[ "qcctxname" ] || dirBgText != glb[ "qcctxname" ] || filesText != glb[ "qcctxname" ] )
			fErrors := 1
		RegRead, dirCmd, HKEY_CLASSES_ROOT, Directory\shell\QC\command
		RegRead, dirBgCmd, HKEY_CLASSES_ROOT, Directory\Background\shell\QC\command
		RegRead, filesCmd, HKEY_CLASSES_ROOT, *\shell\QC\command
		if ( dirCmd != cmd || dirBgCmd != cmdDirBg || filesCmd != cmd )
			fErrors := 1
		if fErrors	;reset all registry settings
		{
			if( !A_IsAdmin && A_IsCompiled )
			{
				msg := ( init ? "Your " glb[ "appName" ] " settings are incorrect."
							. "`n`nIt could happen if you moved " glb[ "appName" ] ".exe to another place or changed it's name."
							. "`n`nTo fix this issue, " glb[ "appName" ] " requires admin privileges."
						: glb[ "appName" ] " requires admin privileges for this action." ) "`n`nDo you want to proceed?"
				ret := QMsgBoxP( { title : "Run as Admin?"
							, msg : msg, pos : "GUI_OPT", modal : 1, pic : "?"
							, buttons : "Yes|No" }, "GUI_OPT" )
				if( ret != "Yes" )
					return 0
				API_ShellExecute(A_ScriptFullPath,"-ctxreg 1", A_ScriptDir,"RUNAS")
				Return 1
			}
			RegDelete, HKEY_CLASSES_ROOT, Directory\shell\QC
			RegDelete, HKEY_CLASSES_ROOT, Directory\Background\shell\QC
			RegDelete, HKEY_CLASSES_ROOT, *\shell\QC
			
			RegWrite, REG_SZ, HKEY_CLASSES_ROOT, Directory\shell\QC,,% glb[ "qcctxname" ]
			RegWrite, REG_EXPAND_SZ, HKEY_CLASSES_ROOT, Directory\shell\QC,Icon,% iconPath
			RegWrite, REG_SZ, HKEY_CLASSES_ROOT, Directory\shell\QC\command,,% cmd
			
			RegWrite, REG_SZ, HKEY_CLASSES_ROOT, Directory\Background\shell\QC,,% glb[ "qcctxname" ]
			RegWrite, REG_EXPAND_SZ, HKEY_CLASSES_ROOT, Directory\Background\shell\QC,Icon,% iconPath
			RegWrite, REG_SZ, HKEY_CLASSES_ROOT, Directory\Background\shell\QC\command,,% cmdDirBg
			
			RegWrite, REG_SZ, HKEY_CLASSES_ROOT, *\shell\QC,,% glb[ "qcctxname" ]
			RegWrite, REG_EXPAND_SZ, HKEY_CLASSES_ROOT, *\shell\QC,Icon,% iconPath
			RegWrite, REG_SZ, HKEY_CLASSES_ROOT, *\shell\QC\command,,% cmd
		}
	}
	else	;deleting settings
	{
		RegRead, ComName, HKEY_CLASSES_ROOT, Directory\shell\QC
		RegRead, ComName1, HKEY_CLASSES_ROOT, Directory\Background\shell\QC
		RegRead, ComName2, HKEY_CLASSES_ROOT, *\shell\QC
		if ( ComName != "" || ComName1 != "" || ComName2 != "" )
		{
			if ( !A_IsAdmin && A_IsCompiled )
			{
				MsgBox, 52, Run As Admin?,% glb[ "appName" ] " requires admin privileges for this action.`nDo you want to proceed?"
				IfMsgBox, No
					Return 0
				API_ShellExecute(A_ScriptFullPath,"-ctxreg 0", A_ScriptDir,"RUNAS")
				Return 1
			}
			RegDelete, HKEY_CLASSES_ROOT, Directory\shell\QC
			RegDelete, HKEY_CLASSES_ROOT, Directory\Background\shell\QC
			RegDelete, HKEY_CLASSES_ROOT, *\shell\QC
		}
	}
	return 1
}

CheckStartupShortcut( mode = "" )
{
	mode := ( mode != "" ) ? mode : qcOpt[ "gen_RunOnStartup" ]
	appname := glb[ "appName" ]
	subKey := "Software\Microsoft\Windows\CurrentVersion\Run"
	if ( mode = 1 )
	{
		expCmd = "%A_ScriptFullPath%" -startup
		RegRead, cmd, HKCU,% subKey, % glb[ "appName" ]
		if ( cmd != expCmd )
			RegWrite, REG_SZ,HKCU,% subKey,% glb[ "appName" ],% expCmd
	}
	else if ( mode = 0 )
		RegDelete,HKCU,% subKey,% glb[ "appName" ]
	return
}