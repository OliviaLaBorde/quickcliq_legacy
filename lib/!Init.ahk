IfNotExist,% glb[ "qcDataPath" ]
  FileCreateDir,% glb[ "qcDataPath" ]
FileInstall , .\qc_icons.icl,% glb[ "qcDataPath" ] "\qc_icons.icl", 1
;----------------------------------------------------------
;Super-global variables/constants/objects
glb[ "hIcoNone" ] := IconExtract( glb[ "icoNone" ], 24 )
global qcExec := new ExecCommand( 8 )
global qcconf
global oGuiTooltip  := new GuiTooltip()
global qcOpt          := new QC_Options()
global qcPUM        := new PUM()
global qcCustomHotkeys := object()
global qcMemos := object()  ;stores a memos names
global qcGui := object() ;stored gui handles
global qcClips := object()  ;stored clips
global qcTVItems := object() ;maps TV items IDs to QC items IDs, like { TVItem_ID : QCItem_ID }
global qcTVAutorunItems := object() ;contains those TV Items IDs which has an autorun property
global qcTVHKItems := object() ;contains TV items with defined hotkey
loop 9
  qcClips[ A_Index ] := new WinClip
qcClips[ 0 ] := WinClip
;TreeView Icon List
global TV_IL    ;main gui TreeView ImageList
global TV_CL    ;main gui TreeView color list
global qcHotkeyList := object() ;list of all currently active hotkeys
global f_QC_DEBUG := FALSE

;~ PUM menus
global qcMainMenu
global qcClipsMenu
global qcWinsMenu
global qcRecentMenu
global qcMemosMenu

QC_Init()
{
  QCLoadLibs()
  SetDebugPrivilege()
  ParseArguments()
  qcconf := new XMLManager()    ;should be defined after arguments parsing because SMenu may be used
  if glb[ "firstRun" ]
    GUI_FirstRun_Show()
  Menu, tray, UseErrorLevel
  SplitPath,A_ScriptFullPath,,,,,adrive
  DriveGet, adlabel, Label,% adrive
  DriveGet, atype, Type,% adrive
  trayTip := glb[ "appName" ] " " glb[ "ver" ] "`nRunning on " adrive " (" adlabel ") " atype
  Menu, tray, Tip,% trayTip
  Menu, Tray, Click, 1
  Menu, Tray, Icon,,,1				;disabling changing to "S" icon
  Menu, Tray,% qcOpt[ "gen_trayIcon" ] ? "Icon" : "NoIcon"
  if !A_IsCompiled		;if not compiled instance runned, - add debug hotkeys
  {
    Hotkey("!r",1,"Restart","","",True)
    Hotkey("!h",1,"Listhotkeys","","",True)
  }
  if A_IsCompiled
    SetTimer( "SilentUpdate", -120000 )     ;autoupdate check
  GWE_SetWinGroup()
  QCMenuRebuild( "main" )                             ;building the menu here
  CheckStartupShortcut()
  OnMessage( 0x004A, "IPCProcessMsg")

  if ( qcOpt[ "gen_smenusOn" ] = 1 && A_IsCompiled )
    SMenu_SetRegistry( True, True )                               ;checking SMenu registry settings
  
  if qcOpt[ "gen_ContextQC" ]
    Context_Reg( 1, True )
  
  qcver := glb[ "ver" ]
    
  if ( qcOpt[ "clips_on" ] && qcOpt[ "clips_SaveOnExit" ] )
    RestoreClips()
  
  if glb[ "firstRun" ]
    FirstRun_OpenMenuMsg()

  hPipe := CreateNamedPipe( glb[ "mainPipeName" ], glb[ "pipeTimeout" ] )
  glb[ "hMainPipe" ] := hPipe
  if (hPipe == 0 && glb[ "fFirstInstance" ])
    QMsgBoxP( { title : "Could not open pipe"
              , msg : "Could not open pipe: " pipeName "`nErrorLevel: " ErrorLevel "`nFormat: " ErrorFormat(GetLastError())
              , pic : "x" } )
              
  if( glb[ "fStartup" ] )
    SetTimer, QCRunStartupItems, -1000
  return
}

ParseArguments()
{
  glb[ "fExitNoNotify" ] := 1
  params := sysargs[0]
  param1 := sysargs[1]
  param2 := sysargs[2]
  if ( params = 0 || ( params = 1 && param1 = "-startup" ) )
  {
    PID := DllCall("GetCurrentProcessId")
    Process, Exist, %A_ScriptName%
    if (PID != ErrorLevel && ErrorLevel != 0)
    {
      appname := glb[ "appName"]
      omsg = 
      ( LTrim
      You have an instance of %appname% already running. If going to continue, consider following side-effects:
      
      1. Hotkeys/Gestures will work only on last instance started unless they are different
      
      2. Adding new shortcut through file's context menu will create one window for each instance running
      
      3. S-Menus will be running through the last instance where "Enable S-Menus" option checked
      )
      ans := QMsgBoxP( { title : appname " already running", msg : omsg, pic : "!", buttons : "Continue|Exit" } )
      if( ans != "Continue" )
        ExitApp
      else
        glb[ "fFirstInstance" ] := 0
    }
    glb[ "fExitNoNotify" ] := 0
    if ( param1 = "-startup" )
      glb[ "fStartup" ] := 1
  }
  else if ( params = 1 )
  {
    If( param1 = "-getprocs" )
    {
      if !A_IsAdmin
      {
        QMsgBoxP( { title : "Failed to start with Admin rights"
              , msg : glb[ "appName" ] " failed to run under Admin rights"
              , pic : "x" } )
        ExitApp
      }
    }
    ret := param1 = "-getprocs" ? ProcList_toPipe() 
                    : WrongArgsPassed()
    ExitApp
  }
  else if ( params = 2 )
  {
    If param1 in -smreg,-rcnwinrec,-ctxreg
    {
      if !A_IsAdmin
      {
        MsgBox, 16, Failed to start with Admin rights,% glb[ "appName" ] " could not run under Admin rights"
        ExitApp
      }
    }
    ret :=      param1 = "-smreg" ? SMenu_SetRegistry( param2 )
              : param1 = "-smupd" ? SMenu_UpdateMenu( param2 )
              : param1 = "-rcnwinrec" ? EnableWindowsRecent( param2 )
              : param1 = "-ctxreg" ? Context_Reg( param2 )
              : param1 = "-a" ? Gui_AddSh_SendMsg( param2 )
              : param1 = "-sm" ? SMenu_Run( param2 )
              : WrongArgsPassed()
    If param1 in -smreg,-rcnwinrec,-ctxreg
      MsgBox,% ret ? 64 : 16,% ret ? "Success" : "Fail" ,% ret ? "Setting has been successfully changed" : "Failed to change setting:`n" param1 " " param2
    ExitApp
  }
  else
    WrongArgsPassed()
  return
}

WrongArgsPassed()
{
  for i,v in sysargs
    params .= v "`n"
  Msgbox % "Wrong set of parameters passed:`n" params
  ExitApp
}