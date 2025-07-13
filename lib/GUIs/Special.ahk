GUI_Special_Show(gui_in = "")
{
	global 
	static pgui
	if gui_in
	{
		pgui := gui_in
		gui,%pgui%:+Disabled
		gui,27:+owner%pgui%
	}
	else
		pgui =
	Gui,27:Default
	QCSetGuiFont( 27 )
	if qcOpt[ "gen_noTheme" ]
		Gui,-Theme
	Gui,Add,Edit,+ReadOnly +Wrap +Multi vedit_v, % Spc_Tg_Descr()
	GuiControl,Focus, edit_v
	Gui, +ToolWindow +Resize MinSize300x350
	if pgui 
	{
		Gui %pgui%:+LastFoundExist
		WinGetPos, X, Y, W, H,% "AHK_ID " WinExist()
		Gui, show,% "x" . round(x+w/2-190) . " y" . round(y+h/2-240) . "w350 h400", Special Targets Description
	}
	else
		gui, show,w350 h400,Special Targets Description
	return
	
	27GuiClose:
	27GuiEscape:
		if pgui
			gui,%pgui%:-Disabled
		Gui,27:Destroy
		return
		
	27GUISize:
		EditWidth := A_GuiWidth - 20
		EditHeight := A_GuiHeight - 10
		GuiControl, MoveDraw, edit_v, w%EditWidth% h%EditHeight%
		return
}

Spc_Tg_Descr()
{
	string = 
	(LTrim %
	Here is description of special commands you can use in shortcut's targets. All commands are not case sensitive.
	-------
	Comments
	
	Anything included inside {! ... !} will be treated as comments and removed before command execution
	Example:
	cmd {! this is comment !} /K dir
	
	-------
	%env_name%
	- it is possible to use windows environmental variables by enclosing them by percents
	Example:
	%TEMP%
	%WINDIR%\System32\
	
	-------
	RUNAS <file>
	 - run <file> under administrative privilegies or with UAC elevation
	 
	Example:
	RUNAS "cmd"
	RUNAS "C:\Program Files\SomeProgram\Application.exe"
	
	-------
	RUN_MIN <file>
	RUN_MAX <file>
	 - run application maximized or minimized. Depending on application it may not work.
	 
	Example:
	RUN_MIN "cmd"
	RUN_MAX "cmd"
	
	-------
	CHK
	- shows the list of custom hotkeys.
	
	-------
	W<num>
	 - waits for <num> seconds before continue. The <num> can be an integer (1,3,13) or float (1.5,2.5,0.5) number.
	Use in multi-target shortcut. Useful when you need to wait sometime before executing next command.
	
	Example:
	cmd /C netstat -a >C:\netstat.txt {N} W1 {N} C:\netstat.txt
	cmd /C chkdsk >D:\chkdsk_log.txt {N} W15 {N}D:\chkdsk_log.txt
	
	-------
	REP<num> <target>
	- repeat <target> <num> times. REP can be used with RUNAS. <num> should be an integer (1,2,5). Delay between each run can be defined in options.
	
	Example:
	REP5 cmd
	- open five cmd windows
	REP3 RUNAS "C:\Utils\SomeApp.exe"
	- run SomeApp three times with administrative rights
	
	-------
	COPYTO<flags> [<dir1>|<dir2>|<dir3>...]
	- copies files/folders selected inside explorer window (target window must be active when opening menu) to the destination folders - dir1,dir2,dir3,etc... delimited with "|" symbol. If destination folder doesn't exist, it will be created.
	If no destination folders specified, you will be asked about one each time this command started.
	
	Possible flags:
	* - "Choose Files" dialog will appear and ask you to choose needed files instead of copying selected ones
	^ - will delete source files/folders after copying
	
	Examples:
	
	copyto D:\ | C:\ | C:\MyFolder
	- copy selected files to those three folders
	
	copyto^ C:\Program Files | C:\BackUp
	- copy selected files to the "C:\Program Files" and "C:\BackUp" and delete them from the first place
	
	copyto*^ D:\Store | D:\SomeDir
	- show "Choose Files" dialog, then copy selected files to this folders and delete source
	
	copyto
	- ask about destination folder and copy selected files there
	
	-------
	Clipboard usage in commands
	
	Example:
	cmd {clip} {clip0} {clip1} {clip2} ...
	where {clip} and {clip0} will be replaced by current Windows clipboard content,
	{clip1-9} by corresponding Clips content if you have them enabled ( otherwise - just removed )
	)
	return string
}