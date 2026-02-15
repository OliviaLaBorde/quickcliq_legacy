#SingleInstance OFF
#MaxThreadsPerHotkey 3
#MaxThreads 30
#NoEnv
#Persistent
#NoTrayIcon
#InstallKeybdHook
#InstallMouseHook
#MaxMem 100
;~ #Warn, All, StdOut 

if A_OSVersion in WIN_NT4,WIN_95,WIN_98,WIN_ME,WIN_2000
{
  MsgBox % "This programm requires Windows 2003/XP or later."
  ExitApp
}
;////////////////////////////   StartUp init
global DBG_SHOW_ERRORS := 0
global glb := Object()                     ; this is globals store of constants/states
global sysargs := Object()                 ; object contains all arguments passed to the programm
; getting parameters passed
loop,%0%
  sysargs[ A_Index ] := %A_Index%
sysargs[ 0 ] := sysargs.MaxIndex() ? sysargs.MaxIndex() : 0  ;first element contains whole number of parameters

SendMode Input                                 ; recommended mode for send commands
Thread, Interrupt, 0,0
SetTitleMatchMode,RegEx
SetBatchLines, -1                               ;better performance
SetWorkingDir, %A_ScriptDir%        ; ensures working dir is script dir
OnExit, ExitProcessing                      ; this sub will be called whenever QC exits
Process, priority,,H                        ; high priority for the script to avoid problems running applications under heavy CPU load
FileEncoding, UTF-16                        ; all files by default in UTF-16
ComObjError( 1 )                               ; switch to turn ON/OFF COM elements errors
CoordMode, Mouse, Screen           ; default coordinates for mouse and
CoordMode, Menu, Screen              ; menu commands are relative to screen
#Include %A_ScriptDir%\lib\!Includes.ahk
;//////////////////////////
;initialization
OnMessage( 0x200, "ShowTooltip" )
QC_Init()
return

; PUM debug view
;~ !d::
;~ QMsgBoxP( { "title"		: "Message"
            ;~ ,"editbox" : 1
            ;~ ,"editbox_w" : 1000
            ;~ ,"editbox_h" : 1000
            ;~ ,"msg" 		: qcPUM.PUMGetLog()
            ;~ ,"buttons" : "OK" } )
;~ return

GesturesSub:
  GestureProcessing( A_ThisHotkey )
  return

MainMenu:
ClipsMenu:
MemosMenu:
WinsMenu:
RecentMenu:
  MenuProcessing( A_ThisHotkey, A_ThisLabel )
  return

ClipsHotkeys: ;sub running on using clip-changing hotkeys
  ProcessClipsCommand( A_ThisHotkey )
  return
;sub for hotkey to hide active window (ctrl+space or custom one)
WinsHideWindow:
  WinsHideWindow( WinExist( "A" ) )
  Return

; Debug labels
restart:
QCRestart( False )
return
listhotkeys:
ListHotkeys
return

;Open/Show main gui
MainGui:
QCMainGui()
return

;################ ABOUT #########################
ABOUT:
About()
return
;################ EXIT ##########################
ExitProcessing:				;OnExit sub
EXIT:
  if glb[ "hMainPipe" ]
    CloseHandle( glb[ "hMainPipe" ] )
  If !glb[ "fExitNoNotify" ]
  {
    SaveUseTime()
    if( qcOpt[ "clips_SaveOnExit" ] && qcOpt[ "clips_on" ] )
      SaveClips()
    qcconf.Backup()
    qcconf.Save() ;may cause xml corruption?
    loop,20
    {
      sleep -1
      sleep 50
    }
  }
  if glb[ "fSMenuRun" ]
    qcconf.Save()
  ExitApp
  return

HotkeysSuspend:
  HotkeysSuspend()
  return

GesturesSuspend:
  GesturesSuspend()
  return

ApplyMemosChangesHK:
  MemosSaveChanges()
  return
  
MG_ShowProps:
  Gui_Main_TlbProp_ShowGUI()
  return
