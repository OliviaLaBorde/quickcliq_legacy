RecentProcessActions( item )
{
  if ( item.uid = "Recent_Clear")
    ClearRecentItems()
  else if ( item.uid = "Recent_Cmd")
    RunCommand( { cmd : item.Recent_Cmd, nolog : 1 } )		;with option "DontLog"
  return
}

ClearRecentItems()
{
  loop, % qcRecentMenu.Count() - 2
    qcRecentMenu.GetItemByPos( 0 ).Destroy()
  return
}

RecentAdd( name, icon, cmd_line )
{
  if !qcRecentMenu.IsMenu()
    return
  if ( name = "" || cmd_line = "" )
    return
  menu_items := qcRecentMenu.Count()
  if ( menu_items = qcOpt[ "recent_maxItems" ] + 2 )
    qcRecentMenu.GetItemByPos( menu_items-3 ).Destroy()
  qcRecentMenu.Add( { name : name, icon : icon, uid : "Recent_Cmd", Recent_Cmd : cmd_line, Recent_CmdTime : A_Now }, 0 )
  return
}

RecentHotkeys( state )
{
  if ( err := Hotkey( qcOpt[ "Recent_Hotkey" ], state, "RecentMenu" ) )
    QMsgBoxP( { title : "Recent hotkey error", msg : err, pic : "x" } )
  return
}

RecentTrackersUpdate()
{
  rcs := qcOpt[ "recent_on" ]
  RecentProcDelNotify( rcs ? qcOpt[ "recent_logProcs" ] : 0 )
  FoldersTracker( rcs ? qcOpt[ "recent_logFolders" ] : 0 )
  WindowsRecentTracker( rcs ? qcOpt[ "recent_logWinRI" ] : 0 )
}

GetWinRecentFolder()
{
	RegRead, recent_folder, HKCU, Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders, Recent
	return recent_folder
}

Recent_Items( cmd )
{
  static recItems
  if( cmd = "save" )
  {
    recItems := object()
    for i,item in qcRecentMenu.GetItems()
    {
      if( item.uid = "Recent_Cmd" )
        recItems.insert( { name : item.name
                          , icon : item.icon
                          , uid : item.uid
                          , Recent_Cmd : item.Recent_Cmd
                          , Recent_CmdTime : item.Recent_CmdTime } )
    }
  }
  else if( cmd = "restore" )
  {
    for i,item in recItems
    {
      qcRecentMenu.Add( { name : item.name
                        , icon : item.icon
                        , uid : item.uid
                        , Recent_Cmd : item.Recent_Cmd
                        , Recent_CmdTime : item.Recent_CmdTime }, i-1 )
    }
  }
  return
}