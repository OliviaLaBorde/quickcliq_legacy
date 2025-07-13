SilentUpdate( p* )
{
  SetTimer( A_ThisFunc, "nOff" )
  if qcOpt[ "gen_autoUpd" ]
    Program_Update( "", True )
  return
}

Program_Update( GuiNum = "", isSilent = False )
{
  SetTimer( "SilentUpdate", "Off" )

  if !isSilent
  {
    Gui, %GuiNum%:+OwnDialogs
    SplashWait(1,"Please Wait...",GuiNum,0,3)
  }
  qBox := new QMsgBox( { title : "Update failed"
          , msg : "Could not retrieve update information due to following error:`n"
            . "<ERR>`n`nPlease check your internet connection and try again later.`nOr visit our site:`n"
            . "<a href=""www.apathysoftworks.com"" >www.apathysoftworks.com</a>"
          , pos : 1, modal : 1 } )
  sleep 100
  if ( ret := DwnFile( glb[ "urlLastVer" ], glb[ "pathLastVer" ] ) ).rcode
  {
    if !isSilent
    {
      SplashWait( -1,"",GuiNum,0,3)
      qBox.msg := RegExReplace( qBox.msg, "<ERR>", ret.err )
      qBox.Show( 1 )
    }
    return
  }
  
  last_ver := FileOpen( glb[ "pathLastVer" ], "r", "CP0" ).Read()
  last_ver := RegExReplace( last_ver, "[^\db\.]" )
  if !VerCompare( last_ver, glb[ "ver" ] )
  {
    if !isSilent
    {
      SplashWait( -1,"",GuiNum,0,3)
      QMsgBoxP( { title : "You running the latest version"
            , msg : "You are already running the most recent version of " glb["appName"] "."
            , pos : 1, modal : 1 }, 1 )
    }
    OnMessage(0x7779, "")
    return
  }
  clog_url := "http://apathysoftworks.com/QC/qc_update/" last_ver "/changelog.txt"
  if ( ret := DwnFile( clog_url, glb[ "pathVerChLog" ] ) ).rcode
    chLog := "Changelog unavailable " ( ret.statusText ? "( " ret.statusText " )" : "" )
  else
    chLog := FileOpen( glb[ "pathVerChLog" ], "r", "UTF-8" ).Read()
  SplashWait( -1,"",GuiNum,0,3)
  ans := QMsgBoxP( { title : "New " glb[ "appName" ] " version available"
            , msg : "A new " last_ver " version found`n`n" chLog "`n`nDo you wish to update now?"
            , buttons : "Yes|No", editbox : 1, editbox_h : 200 } )
  if( ans != "Yes" )
    return
  SplashWait( 1,"Please wait...",GuiNum,0,3)
  if ( ret := DwnFile( glb[ "urlUpdater" ], glb[ "pathUpdater" ] ) ).rcode
  {
    SplashWait( -1,"",GuiNum,0,3)
    qBox.msg := RegExReplace( qBox.msg, "<ERR>", ret.err )
    qBox.Show( 1 )
    return
  }
  SplashWait( -1,"",GuiNum,0,3)
  PID := DllCall("GetCurrentProcessId")
  OnMessage(0x7779, "ExitQC")
  spath = "%A_ScriptFullPath%"
  args := PID " " spath " " glb[ "ver" ] " " last_ver " " glb[ "qcArch" ]
  retval := API_ShellExecute( glb[ "pathUpdater" ], args, A_ScriptDir )
  if( retval < 32 )
  {
    SplashWait( -1,"",GuiNum,0,3)
    QMsgBoxP( { title : "Failed to run updater"
              , msg : "Could not open " glb["appName"] " updater:`n" glb[ "pathUpdater" ] "`nError: " GetShellExecuteError( retval ) "`nPlease try again or visit our site:`n"
                . "<a href=""www.apathysoftworks.com"" >www.apathysoftworks.com</a>" } )
  }
  return
}