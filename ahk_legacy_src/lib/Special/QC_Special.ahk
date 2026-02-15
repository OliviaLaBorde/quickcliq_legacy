QCRemoveSpecials( cmd )
{
	prefix := postfix := ""
	if RegExMatch( cmd, "\^$", match )
		postfix .= match, cmd := RegExReplace( cmd, "\^$" )
	if RegExMatch( cmd, "i)^\s*REP[0-9]+\s+", match )
		prefix .= match, cmd := RegExReplace( cmd, "i)^\s*REP[0-9]+\s+" )
	if RegExMatch( cmd, "i)^\s*RUNAS\s+", match )
		prefix .= match, cmd := RegExReplace( cmd, "i)^\s*RUNAS\s+" )
	if RegExMatch( cmd, "i)^\s*copyto[*^]*\s*", match )
		prefix .= match, cmd := RegExReplace( cmd, "i)^\s*copyto[*^]*\s*" )
	if RegExMatch(cmd,"i)\s*RUN_MAX\s+.*", match)
		prefix .= match, cmd := RegExReplace( cmd, "i)\s*RUN_MAX\s+.*" )
	if RegExMatch(cmd,"i)\s*RUN_MIN\s+.*", match)
		prefix .= match, cmd := RegExReplace( cmd, "i)\s*RUN_MIN\s+.*" )
	return { "cmd" : cmd, "prefix" : prefix, "postfix" : postfix }
}

WinCmd(cmd) {
	oShell := ComObjCreate("Shell.Application")
	ret := cmd == "win_casc" ? oShell.CascadeWindows()
			: cmd == "win_tasksw" ? oShell.WindowSwitcher()
			: cmd == "win_tileh" ? oShell.TileHorizontally()
			: cmd == "win_min" ? oShell.MinimizeAll()
			: cmd == "win_unmin" ? oShell.UndoMinimizeALL()
			: cmd == "win_togd" ? oShell.ToggleDesktop()
			: cmd == "win_tilev" ? oShell.TileVertically()
	return
}