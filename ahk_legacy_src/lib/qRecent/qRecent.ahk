RecentAddMenu( objMenu )
{
  RecentHotkeys( 0 )
  if !qcOpt[ "recent_on" ]
  {
    RecentTrackersUpdate()
    qcRecentMenu.Destroy()
    return
  }
  recentMenuParams := { iconssize : toInt( 16 )
            ,tcolor    : NodeGetColor( "mtcolor", qcconf.GetMenuNode() )
            ,bgcolor   : NodeGetColor( "mbgcolor", qcconf.GetMenuNode() )
            ,textoffset: glb[ "menuIconsOffset" ]
            ,noicons   : qcOpt[ "aprns_lightMenu" ]
            ,nocolors  : qcOpt[ "aprns_lightMenu" ]
            ,notext    : 0
            ,ymargin   : 3 + toInt( qcOpt[ "aprns_heightAdjust" ] ) }
  
  ;just updating the settings of the menu if it already exist, avoid loosing recent items
  qcRecentMenu := qcPUM.CreateMenu( recentMenuParams )
  qcRecentMenu.Add()
  qcRecentMenu.Add( { name : "Clear List", uid : "Recent_Clear" } )
  Recent_Items( "restore" )
  
  RecentTrackersUpdate()
  
  if qcOpt[ "recent_sub" ]
  {
    objMenu.Add( { name : glb[ "recentName" ]
                , icon : glb[ "icoRecent" ]
                , uid : glb[ "recentItemID" ]
                , submenu : qcRecentMenu
                , break : IsNewCol( objMenu, glb[ "mItemsNum" ] ) } )
  }
  RecentHotkeys( 1 )
  return
}

FoldersTracker( state )
{
  SetTimer( "CheckActiveFolders", state ? glb[ "RecentFolTrackInterval" ] : "OFF" )
  return
}

WindowsRecentTracker( state )
{
  SetTimer( "CheckWindowsRecent", state ? glb[ "RecentWinRecTrackInterval" ] : "OFF" )
  return
}

CheckWindowsRecent( p* )
{
  static lastRecentItemTime
; a very first call of this function = just update static var
  if !lastRecentItemTime        
  {
    Loop, % GetWinRecentFolder() . "\*.lnk", 0, 0
      if ( A_LoopFileTimeModified > lastRecentItemTime )
        lastRecentItemTime := A_LoopFileTimeModified
    return
  }
; /////////////////////
  mostRecent := 0
  Loop, % GetWinRecentFolder() . "\*.lnk", 0, 0
  {
    if ( A_LoopFileTimeModified > lastRecentItemTime )    ;if any new shortcut appeared in the folder
    {
      FileGetShortcut, %A_LoopFileFullPath%, f_target
      SplitPath, f_target, f_name
      RecentAdd( f_name, IconGetAssociated( f_target ), f_target )
      if ( A_LoopFileTimeModified > mostRecent )
        mostRecent := A_LoopFileTimeModified
    }
  }
  if mostRecent
    lastRecentItemTime := mostRecent
  return
}

CheckActiveFolders( p* )
{
  static winList = object()
  tempList := object()
  for i,win in ShellGetWindows()
    try
      tempList[ win.HWND ] := { name: win.LocationName, url : win.LocationURL }
    catch
      continue
  
  for hwnd,props in winList
    if !tempList.HasKey( hwnd )
      RecentAdd( props[ "name" ], "shell32.dll:3", props[ "url" ] )
  
  winList := tempList
  return
}

RecentProcDelNotify( state )
{
  static s_state, winmgmts, deleteSink
  if ( s_state && state )   ;only one delete notification should be active
    return
  if state
  {
    winmgmts := WMIObj()
    deleteSink := ComObjCreate("WbemScripting.SWbemSink")
    ComObjConnect( deleteSink,"ProcessDelete_" )
    winmgmts.ExecNotificationQueryAsync( deleteSink, "SELECT * FROM __InstanceDeletionEvent WITHIN " . glb[ "RecentProcTrackInterval" ] . " WHERE TargetInstance ISA 'Win32_Process'" )
    s_state := 1
  }
  else
    winmgmts := deleteSink := "", s_state := 0
  return
}

; Called when a process terminates:
ProcessDelete_OnObjectReady( objWbemObject, objWbemAsyncContext ) 
{
  static IgnoredProcList := "SearchFilterHost.exe,SearchProtocolHost.exe,svchost.exe,dllhost.exe"
  
  proc := objWbemObject.TargetInstance
  ;http://msdn.microsoft.com/en-us/library/aa394372.aspx
  proc_cmd := proc.CommandLine
  proc_name := proc.Name
  proc_exe := proc.ExecutablePath
  
  if (proc_exe = "" || proc_cmd = "" || InStr(proc_cmd,"Windows\Servicing") || instr(IgnoredProcList,proc_name))
    return
  RecentAdd( proc_name, IconGetAssociated(proc_exe), proc_cmd )
  return
}