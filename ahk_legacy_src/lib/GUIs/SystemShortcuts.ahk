
System_Shortcut_Gui(Parent_Gui = 1,ByRef out_target = "",ByRef out_name = "") 
{
  Global Shortcuts_Listbox, Shortcuts_Listview, SysShct_SrchED	;GUI controls must be global
  global butt_add,butt_runas,butt_run,butt_send_new_shcut, SysShct_Counter

  out_target := out_name := ""

  Menu, ShortcutGuiMenu, Delete
  Menu, ShortcutGuiMenu, Add, Add Selected, g_SysShct_AddSel

  Gui, %Parent_Gui%:+Disabled
  Gui, 23:Default
  QCSetGuiFont( 23 )
  Gui, +owner%Parent_Gui%
  Gui, +ToolWindow +LastFound
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  Gui,Add,Text,,Category
  Gui,Add,Text,x+60,Shortcuts
  Gui,Add,Text,x+330 w60 vSysShct_Counter
  Gui, add, Listbox,xm w100 h300 vShortcuts_Listbox gSysShct_UpdList Multi hwndhwnd
  qcGui[ "sysShct_lb" ] := hwnd
  Gui, add, listview, w450 hp yp x+5 vShortcuts_Listview gLV_list_Events AltSubmit Sort, Description|Command
  SysShctLoad()
  Gui,Add,Text,xm+60,Search
  Gui,Font,Bold
  Gui,Add,Edit,cMaroon R1 x115 yp-3 w450 vSysShct_SrchED gSysShct_Search +0x800000
  Gui,Font,Normal
  Gui, add, Button, w110 h30 xm vbutt_add gg_SysShct_AddSel, Add Selected
  Gui, add, Button, w70 h30 x+295 vbutt_run gTestSHcuts, Test
  Gui, add, Button, w70 h30 x+5 vbutt_runas gTestSHcuts, As Admin
  Gui %Parent_Gui%:+LastFoundExist
  parent_hwnd := WinExist()
  WinGetPos, X, Y, W, H, AHK_ID %parent_hwnd%
  Gui, show,% "x" . round(x+w/2-285) . " y" . round(y+h/2-200),% glb[ "sysTitle" ]

  GuiControl,Focus,SysShct_SrchED
  SetTimer,Check_Buttons_State,100
  sleep, 500
    Loop
    {
      GuiControlGet, Shortcuts_Listbox ,, Shortcuts_Listbox
      if ErrorLevel
        break
      sleep 100
    }
Return

Check_Buttons_State:					;main buttons will be disabled if no any item selected in LV
  Gui, 23:Default
  if LV_GetNext()
    state := 1
  else
    state := 0
  GuiControl,Enable%state%,butt_add
  GuiControl,Enable%state%,butt_run
  GuiControl,Enable%state%,butt_runas
  return

CloseSGui:
23GuiClose:
23GuiEscape:
  Gui, %Parent_Gui%:-Disabled
  Gui, 23:Destroy
  SetTimer,Check_Buttons_State,OFF
  ToolTip
  Gui, %Parent_Gui%:Default
  return

LV_list_Events:
  Gui, 23:Default
  if (A_GuiEvent = "DoubleClick")
    gosub, g_SysShct_AddSel
  else if (A_GuiEvent = "RightClick")
    SetTimer,Show_SHcutsContextMenu,-100
  return

Show_SHcutsContextMenu:
  Menu, ShortcutGuiMenu, Show
  return

g_SysShct_AddSel:
  obj := SysShct_AddSelected()
  out_name := obj.name
  out_target := obj.cmds
  GoTo, CloseSGui
  return

TestSHcuts:
  Gui, 23:Default
  Gui +OwnDialogs
  LV_GetText(RunString, LV_GetNext(), 2)
  LV_GetText(Name, LV_GetNext(), 1)
  err = 0
  if RegExMatch(RunString, "i)^\s*(win_casc|win_tasksw|win_tileh|win_min|win_unmin|win_togd|win_tilev)\s*$")
  {
    WinCmd(RunString)
    return
  }
  if (A_GuiControl = "butt_run")
  {
    Run,% RunString,,UseErrorLevel
    If errorlevel
      err := 1
  }
  else if (A_GuiControl = "butt_runas")
  {
    args := PathGetArgs( RunString )
    RunString := PathRemoveArgs( RunString )
    ret := API_ShellExecute(RunString,args, 0,"RUNAS")
    if (ret < 32)
      err := 1
  }
  If err
    MsgBox,16,Could not run target, It appears the command "%Name%" is not working.`nThis could be because of your account permissions`nor the command does not work in your current version of Windows.
  return


SysShct_Search:
  SetTimer,SysShct_UpdList,-250
  return

SysShct_UpdList:
  SysShctLoad( GuiControlGet( "SysShct_SrchED", 23 ) )
  return
}

SysShct_AddSelected()
{
  Gui, 23:Default
  cnt := LV_GetCount( "Selected" )
  if !cnt
    return
  row := 0
  Loop
  {
    row := LV_GetNext(row)
    if !row
      break
    LV_GetText( cmd, row, 2)
    LV_GetText( name, row, 1)
    list .= ( list ? glb[ "optMTDivider" ] : "" ) cmd
  }
  if( cnt > 1 )
    name = ""
  return { name : name, cmds : list }
}

SysShctLoad( searchQry = "" )
{
  Gui,23:Default
  if SendMessage( qcGui[ "sysShct_lb" ], 0x018B, 0, 0 )  ;LB_GETCOUNT
    oItems := Str2Dict( GuiControlGet( qcGui[ "sysShct_lb" ], 23 ) )
  list := SysShortcutsGetList( oItems )
  oQrs := StrSplit( searchQry, " ", A_Space A_Tab )
  if !oItems
  {
    for key,v in list
      lb_items .= ( lb_items ? "|" : "" ) key
    GuiControl,,% qcGui[ "sysShct_lb" ],% lb_items
    PostMessage, 0x185, 1, -1,,% "ahk_id " qcGui[ "sysShct_lb" ]  ; Select all categories. 0x185 is LB_SETSEL.
  }
  LV_Delete()
  for key,cmds in list
    if( oItems.HasKey( key ) || !oItems )
      for i,line in StrSplit( cmds, "`n", A_Space A_Tab )
      {
        L := StrSplit( line, "@", A_Space A_Tab )
        if oQrs.MaxIndex()
        {
          if SysShct_CmdHasQry( line, oQrs )
            LV_Add( "", L[1], L[2] )
        }
        else
          LV_Add( "", L[1], L[2] )
      }
  LV_ModifyCol( 2, "AutoHdr")
  LV_ModifyCol( 1, "AutoHdr")
  GuiControlSet( "SysShct_Counter", LV_GetCount() " found", "", 23 )
  return
}

SysShct_CmdHasQry( cmd, oQueries )
{
  for i,qry in oQueries
    if( qry != "@" )
      if !InStr( cmd, qry )
        return False
  return True
}

SysShortcutsGetList( oItems )
{
  l := object()
  s = 
  (LTrim
    Add Hardware Wizard@hdwwiz.cpl
    Add/Remove Programs@appwiz.cpl
    Administrative Tools@control admintools
    Certificate Manager@certmgr.msc
    Character Map@charmap
    Check Disk Utility@cmd /k chkdsk
    Component Services@dcomcnfg
    Component Services@comexp.msc
    Computer Management@compmgmt.msc
    Computer Management@compmgmtlauncher
    Control Panel@control
    Date and Time Properties@timedate.cpl
    Device Manager@devmgmt.msc
    Device Manager@hdwwiz.cpl
    Direct X Troubleshooter@dxdiag
    Disk Cleanup Utility@cleanmgr
    Disk Management@diskmgmt.msc
    Display Properties@desk.cpl
    Fonts@control fonts
    Fonts Folder@fonts
    Game Controllers@joy.cpl
    Group Policy Editor@gpedit.msc
    Internet Properties@inetcpl.cpl
    Keyboard Properties@control keyboard
    Local Users and Groups@lusrmgr.msc
    Mouse Properties@main.cpl
    Performance Monitor@perfmon.msc
    Power Configuration@powercfg.cpl
    Printers and Faxes@control printers
    Private Character Editor@eudcedit
    Regional Settings@intl.cpl
    Scheduled Tasks@control schedtasks
    Security Center@wscui.cpl
    Services@services.msc
    Shared Folders@fsmgmt.msc
    Sounds and Audio@mmsys.cpl
    SQL Client Configuration@cliconfg
    System Information@msinfo32
    System Properties@sysdm.cpl
    Utility Manager@utilman
    User Accounts@control userpasswords2
    Windows Firewall@firewall.cpl
    Windows System Security Tool@syskey
    Safely Remove Hardware Dialog Box@Rundll32 Shell32.dll,Control_RunDLL HotPlug.dll
    Windows - About@RunDll32.exe SHELL32.DLL,ShellAboutW
    Windows - About@winver
    Color Management@colorcpl
    Change Computer Performance Settings@systempropertiesperformance
    Change Data Execution Prevention Settings@systempropertiesdataexecutionprevention
    Change Printer Settings@printui
    Advanced User Accounts@netplwiz
    Action Center@wscui.cpl
    Default Location@locationnotifications
    Ease of Access Center@utilman
    Network Connections@ncpa.cpl
    Windows Fax and Scan@wfs
    Windows Features@optionalfeatures
    Windows Firewall with Advanced Security@wf.msc
    Windows Journal@journal
  )
  l[ "Control Panel" ] := s
  s =
  (LTrim
    Add New Programs Folder@Shell:AddNewProgramsFolder
    AppData@Shell:AppData
    Cache@Shell:Cache
    CD Burning@Shell:CD Burning
    My Computer@shell:MyComputerFolder
    Recycle Bin@shell:RecycleBinFolder
    Administrative Tools Folder@shell:Administrative Tools
    Change/Remove Programs@shell:ChangeRemoveProgramsFolder
    Network@shell:NetworkPlacesFolder
    User Profiles@shell:UserProfiles
    Profile Folder@shell:Profile
    Public Folder@shell:Public
    Common Administrative Tools@Shell:Common Administrative Tools
    Common AppData@Shell:Common AppData
    Common Desktop@Shell:Common Desktop
    Common Documents@Shell:Common Documents
    Common Programs@Shell:Common Programs
    Common Start Menu@Shell:Common Start Menu
    Common Startup@Shell:Common Startup
    Common Templates@Shell:Common Templates
    Common Downloads@Shell:CommonDownloads
    Common Music@Shell:CommonMusic
    Common Pictures@Shell:CommonPictures
    Common Video@Shell:CommonVideo
    Network Connections@Shell:ConnectionsFolder
    Contacts@Shell:Contacts
    Control Panel Folder@Shell:ControlPanelFolder
    Cookies@Shell:Cookies
    CredentialManager@Shell:CredentialManager
    CryptoKeys@Shell:CryptoKeys
    Default Gadgets@Shell:Default Gadgets
    Desktop@Shell:Desktop
    Downloads@Shell:Downloads
    DpapiKeys@Shell:DpapiKeys
    Favorites@Shell:Favorites
    Fonts@Shell:Fonts
    Gadgets@Shell:Gadgets
    Games@Shell:Games
    History@Shell:History
    Links@Shell:Links
    Local AppData@Shell:Local AppData
    Local AppDataLow@Shell:LocalAppDataLow
    My Music@Shell:My Music
    My Pictures@Shell:My Pictures
    My Video@Shell:My Video
    Printers and Faxes@control printers
    Quick Launch@shell:Quick Launch
  )
  l[ "System Folders" ] := s
  s =
  (LTrim
    Delete Temporary Internet Files@RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8
    Delete Cookies@RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 2
    Delete History@RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 1
    Delete Form Data@RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 16
    Delete Passwords@RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 32
    Delete All@RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255
    Delete All + files and settings stored by Add-ons@RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 4351
    Display Organize Favorites Dialog@RUNDLL32.EXE shdocvw.dll,DoOrganizeFavDlg
  )
  l[ "IE" ] := s
  s =
  (LTrim
    Hibernate@RunDll32.exe powrprof.dll,SetSuspendState
    Lock Screen@RunDll32.exe user32.dll,LockWorkStation
    Map Network Drive Wizard@Rundll32 Shell32.dll,SHHelpShortcuts_RunDLL Connect
    Logs You Out Of Windows@logoff
    Shutdown Computer@shutdown /s /d p:0:0 /t 0
    Shutdown (Force)@shutdown /p /d p:0:0
    Restart Computer@shutdown /r /d p:0:0 /t 0
    Restart (Force)@shutdown /r /f /d p:0:0 /t 0
    Clear The Clipboard (Vista/7)@cmd /C "echo off | clip"
    Date to the clipboard (Vista/7)@cmd /C Date /t | Clip
    Time to the clipboard (Vista/7)@cmd /C Time /t | Clip
    Date and time to the clipboard (Vista/7)@cmd /C cmd /C "date /t & time /t" | clip
    Turn Aero Transparency Off@rundll32.exe dwmApi #104
    Turn Aero Transparency On@rundll32.exe dwmApi #102
    Troubleshoot Using System Maintenance@msdt.exe -id MaintenanceDiagnostic
  )
  l[ "System Commands" ] := s
  s =
  (LTrim
    Calculator@calc
    Command Prompt@cmd
    Internet Explorer@iexplore
    Notepad@notepad
    Remote Desktop@mstsc
    Task Manager@taskmgr
    Windows Magnifier@magnify
    Windows Media Player@wmplayer
    Wordpad@write
    Registry Editor@regedit
    On Screen Keyboard@osk
    Paint@mspaint
    Sound Recorder (Vista/7)@soundrecorder
    Snipping Tool@SnippingTool
    ClearType Tuner@cttune
    Connect to a Network Projector@netproj
    Connect to a Projector@displayswitch
    Create A Shared Folder Wizard@shrpubw
    Create a System Repair Disc@recdisc
    Credential Backup and Restore Wizard@credwiz
    Backup and Restore@sdclt
    Authorization Manager@azman.msc
    Add a Device@devicepairingwizard
    Diagnostics Troubleshooting Wizard@msdt
    Digitizer Calibration Tool@tabcal
    Disk Defragmenter@dfrgui
    Display@dpiscaling
    Display Color Calibration@dccw
    Display Switch@displayswitch
    DPAPI Key Migration Wizard@dpapimig
    Driver Verifier Manager@verifier
    EFS REKEY Wizard@rekeywiz
    Encrypting File System Wizard@rekeywiz
    Event Viewer@eventvwr.msc
    Fax Cover Page Editor@fxscover
    File Signature Verification@sigverif
    Font Viewer@fontview
    Getting Started@gettingstarted
    IExpress Wizard@iexpress
    Infrared@irprops.cpl
    Install or Uninstall Display Languages@lusrmgr
    iSCSI Initiator Configuration Tool@iscsicpl
    Language Pack Installer@lpksetup
    Local Security Policy@secpol.msc
    Malicious Software Removal Tool@mrt
    Math Input Panel@mip1
    Microsoft Management Console@mmc
    NAP Client Configuration@napclcfg.msc
    Narrator@narrator
    New Scan Wizard@wiaacmgr
    ODBC Data Source Administrator@odbcad32
    ODBC Driver Configuration@odbcconf
    Pen and Touch@tabletpc.cpl
    People Near Me@collab.cpl
    Phone and Modem@telephon.cpl
    Phone Dialer@dialer
    Presentation Settings@presentationsettings
    Print Management@printmanagement.msc
    Printer Migration@printbrmui
    Problem Steps Recorder@psr
    Programs and Features@appwiz.cpl
    Remote Access Phonebook@rasphone
    Resource Monitor@resmon
    Resource Monitor@perfmon /res
    Resultant Set of Policy@rsop.msc
    SAM Lock Tool@syskey
    Securing the Windows Account Database@syskey
    Set Program Access and Computer Defaults@computerdefaults
    Sticky Notes@stikynot
    Sync Center@mobsync
    System Configuration@msconfig
    System Configuration Editor@sysedit
    System Properties (Advanced Tab)@systempropertiesadvanced
    System Properties (Computer Name Tab)@systempropertiescomputername
    System Properties (Hardware Tab)@systempropertieshardware
    System Properties (Remote Tab)@systempropertiesremote
    System Properties (System Protection Tab)@systempropertiesprotection
    System Restore@rstrui
    Tablet PC Input Panel@tabtip1
    Task Scheduler@taskschd.msc
    Trusted Platform Module (TPM) Management@tpm.msc
    User Account Control Settings@useraccountcontrolsettings
    Volume Mixer@sndvol
    Windows Activation Client@slui
    Windows Anytime Upgrade Results@windowsanytimeupgraderesults
    Windows CardSpace@infocardcpl.cpl
    Windows Disc Image Burning Tool@isoburn
    Windows DVD Maker@dvdmaker
    Windows Easy Transfer@migwiz
    Windows Media Player@dvdplay
    Windows Memory Diagnostic Scheduler@mdsched
    Windows Mobility Center@mblctr
    Windows PowerShell@powershell
    Windows PowerShell ISE@powershell_ise
    Windows Remote Assistance@msra
    Windows Script Host@wscript
    Windows Update@wuapp
    Windows Update Standalone Installer@wusa
    WMI Management@wmimgmt.msc
    Windows Management Instrumentation (WMI) Tester@wbemtest
    XPS Viewer@xpsrchvw
  )
  l[ "Utilities" ] := s
  s =
  (LTrim
    Tile Windows Horizontally@win_tileh
    Tile Windows Vertically@win_tilev
    Minimize: All Windows@win_min
    Minimize: Undo@win_unmin
    Toggle Desktop@win_togd
    Task Switcher (Vista+ only)@win_tasksw
    Cascade Windows@win_casc
  )
  l[ "Wins" ] := s
  s =
  (LTrim
    Action Center@explorer.exe shell:::{BB64F8A7-BEE7-4E1A-AB8D-7D8273F7FDB6}
    Add Network Location@explorer.exe shell:::{D4480A50-BA28-11d1-8E75-00C04FA31A86}
    Administrative Tools@explorer.exe shell:::{D20EA4E1-3957-11d2-A40B-0C5020524153}
    Advanced User Accounts@explorer.exe shell:::{7A9D77BD-5403-11d2-8785-2E0420524153}
    AutoPlay@explorer.exe shell:::{9C60DE1E-E5FC-40f4-A487-460851A8D915}
    Backup and Restore@explorer.exe shell:::{B98A2BEA-7D42-4558-8BD1-832F41BAC6FD}
    Biometric Devices@explorer.exe shell:::{0142e4d0-fb7a-11dc-ba4a-000ffe7ab428}
    BitLocker Drive Encryption@explorer.exe shell:::{D9EF8727-CAC2-4e60-809E-86F80A666C91}
    Bluetooth Devices@explorer.exe shell:::{28803F59-3A75-4058-995F-4EE5503B023C}
    Briefcase@explorer.exe shell:::{85BBD920-42AO-1069-A2E4-08002B30309D}
    Color Management@explorer.exe shell:::{B2C761C6-29BC-4f19-9251-E6195265BAF1}
    Computer@explorer.exe shell:::{20d04fe0-3aea-1069-a2d8-08002b30309d}
    Connect To@explorer.exe shell:::{38A98528-6CBF-4CA9-8DC0-B1E1D10F7B1B}
    Control Panel (Icons view)@explorer.exe shell:::{21EC2020-3AEA-1069-A2DD-08002B30309D}
    Control Panel (All Tasks)@explorer.exe shell:::{ED7BA470-8E54-465E-825C-99712043E01C}
    Control Panel (Category view)@explorer.exe shell:::{26EE0668-A00A-44D7-9371-BEB064C98683}
    Credential Manager@explorer.exe shell:::{1206F5F1-0569-412C-8FEC-3204630DFB70}
    Date and Time@explorer.exe shell:::{E2E7934B-DCE5-43C4-9576-7FE4F75E7480}
    Data Execution Prevention@systempropertiesdataexecutionprevention
    Default Location@explorer.exe shell:::{00C6D95F-329C-409a-81D7-C46C66EA7F33}
    Default Programs@explorer.exe shell:::{17cd9488-1228-4b2f-88ce-4298e93e0966}
    Default Programs@explorer.exe shell:::{E44E5D18-0652-4508-A4E2-8A090067BCB0}
    Desktop Gadgets@explorer.exe shell:::{37efd44d-ef8d-41b1-940d-96973a50e9e0}
    Desktop in Favorites@explorer.exe shell:::{04731B67-D933-450a-90E6-4ACD2E9408FE}
    Device Manager@explorer.exe shell:::{74246bfc-4c96-11d0-abef-0020af6b0b7a}
    Devices and Printers@explorer.exe shell:::{A8A91A66-3A7D-4424-8D24-04E180695C7A}
    Display (DPI)@explorer.exe shell:::{C555438B-3C23-4769-A71F-B6D3D9B6053A}
    Ease of Access Center@explorer.exe shell:::{D555645E-D4F8-4c29-A827-D93C859C4F2A}
    E-mail (default program)@explorer.exe shell:::{2559a1f5-21d7-11d4-bdaf-00c04f60b9f0}
    Favorites@explorer.exe shell:::{323CA680-C24D-4099-B94D-446DD2D7249E}
    Flip 3D@explorer.exe shell:::{3080F90E-D7AD-11D9-BD98-0000947B0257}
    Folder Options@explorer.exe shell:::{6DFD7C5C-2451-11d3-A299-00C04F8EF6AF}
    Font Settings@explorer.exe shell:::{93412589-74D4-4E4E-AD0E-E0CB621440FD}
    Fonts@explorer.exe shell:::{BD84B380-8CA2-1069-AB1D-08000948534}
    Gadgets@explorer.exe shell:::{37efd44d-ef8d-41b1-940d-96973a50e9e0}
    Game Controllers@explorer.exe shell:::{259EF4B1-E6C9-4176-B574-481532C9BCE8}
    Games Explorer@explorer.exe shell:::{ED228FDF-9EA8-4870-83b1-96b02CFE0D52}
    Get Programs@explorer.exe shell:::{15eae92e-f17a-4431-9f28-805e482dafd4}
    Getting Started@explorer.exe shell:::{CB1B7F8C-C50A-4176-B604-9E24DEE8D4D1}
    Help and Support@explorer.exe shell:::{2559a1f1-21d7-11d4-bdaf-00c04f60b9f0}
    HomeGroup@explorer.exe shell:::{67CA7650-96E6-4FDD-BB43-A8E774F73A57}
    Indexing Options@explorer.exe shell:::{87D66A43-7B11-4A28-9811-C86EE395ACF7}
    Infared@explorer.exe shell:::{A0275511-0E86-4ECA-97C2-ECD8F1221D08}
    Installed Updates@explorer.exe shell:::{d450a8a1-9568-45c7-9c0e-b4f9fb4537bd}
    Internet Options@explorer.exe shell:::{A3DD4F92-658A-410F-84FD-6FBBBEF2FFFE}
    iSCCI Initiator@explorer.exe shell:::{A304259D-52B8-4526-8B1A-A1D6CECC8243}
    Keyboard Properties@explorer.exe shell:::{725BE8F7-668E-4C7B-8F90-46BDB0936430}
    Libraries@explorer.exe shell:::{031E4825-7B94-4dc3-B131-E946B44C8DD5}
    Location@explorer.exe shell:::{00C6D95F-329C-409a-81D7-C46C66EA7F33}
    Location and Other Sensors@explorer.exe shell:::{E9950154-C418-419e-A90A-20C5287AE24B}
    Manage Wireless Networks@explorer.exe shell:::{1fa9085f-25a2-489b-85d4-86326eedcd87}
    Mobility Center@explorer.exe shell:::{5ea4f148-308c-46d7-98a9-49041b1dd468}
    Mouse Properties@explorer.exe shell:::{6C8EEC18-8D75-41B2-A177-8831D59D2D50}
    My Documents@explorer.exe shell:::{450d8fba-ad25-11d0-98a8-0800361b1103}
    Network@explorer.exe shell:::{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}
    Network and Sharing Center@explorer.exe shell:::{8E908FC9-BECC-40f6-915B-F4CA0E70D03D}
    Network Center Notification area pop-up@explorer.exe shell:::{38A98528-6CBF-4CA9-8DC0-B1E1D10F7B1B}
    Network Connections@explorer.exe shell:::{7007ACC7-3202-11D1-AAD2-00805FC1270E}
    Network Connections@explorer.exe shell:::{992CFFA0-F557-101A-88EC-00DD010CCC48}
    Network Map@explorer.exe shell:::{E7DE9B1A-7533-4556-9484-B26FB486475E}
    Network Neighborhood@explorer.exe shell:::{208D2C60-3AEA-1069-A2D7-O8002B30309D}
    Network (WorkGroup) Places@explorer.exe shell:::{208D2C60-3AEA-1069-A2D7-08002B30309D}
    Notification Area Icons@explorer.exe shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}
    NVIDIA Control Panel (if driver installed)@explorer.exe shell:::{0bbca823-e77d-419e-9a44-5adec2c8eeb0}
    Offline Files Folder@explorer.exe shell:::{AFDB1F70-2A4C-11d2-9039-00C04F8EEB3E}
    Parental Controls@explorer.exe shell:::{96AE8D84-A250-4520-95A5-A47A7E3C548B}
    Pen and Touch@explorer.exe shell:::{F82DF8F7-8B9F-442E-A48C-818EA735FF9B}
    People Near Me@explorer.exe shell:::{5224F545-A443-4859-BA23-7B5A95BDC8EF}
    Performance Information and Tools@explorer.exe shell:::{78F3955E-3B90-4184-BD14-5397C15F1EFC}
    Personalization@explorer.exe shell:::{ED834ED6-4B5A-4bfe-8F11-A626DCB6A921}
    Phone & Modem Location Information@explorer.exe shell:::{40419485-C444-4567-851A-2DD7BFA1684D}
    Power Options@explorer.exe shell:::{025A5937-A6BE-4686-A844-36FE4BEC8B6D}
    Printers@explorer.exe shell:::{2227A280-3AEA-1069-A2DE-08002B30309D}
    Printers@explorer.exe shell:::{863aa9fd-42df-457b-8e4d-0de1b8015c60}
    Problem Reports (Action Center)@explorer.exe shell:::{BB64F8A7-BEE7-4E1A-AB8D-7D8273F7FDB6}
    Programs and Features@explorer.exe shell:::{7b81be6a-ce2b-4676-a29e-eb907a5126c5}
    Public folder@explorer.exe shell:::{4336a54d-038b-4685-ab02-99bb52d3fb8b}
    Recent Places@explorer.exe shell:::{22877a6d-37a1-461a-91b0-dbda5aaebc99}
    Recovery (System Restore)@explorer.exe shell:::{9FE63AFD-59CF-4419-9775-ABCC3849F861}
    Recycle Bin@explorer.exe shell:::{645FF040-5081-101B-9F08-00AA002F954E}
    Region and Language@explorer.exe shell:::{62d8ed13-c9d0-4ce8-a914-47dd628fb1b0}
    RemoteApp and Desktop Connections@explorer.exe shell:::{241D7C96-F8BF-4F85-B01F-E2B043341A4B}
    Run@explorer.exe shell:::{2559a1f3-21d7-11d4-bdaf-00c04f60b9f0}
    Search@explorer.exe shell:::{2559a1f0-21d7-11d4-bdaf-00c04f60b9f0}
    Set Program Access and Defaults@explorer.exe shell:::{2559a1f7-21d7-11d4-bdaf-00c04f60b9f0}
    Show Desktop@explorer.exe shell:::{3080F90D-D7AD-11D9-BD98-0000947B0257}
    Sound@explorer.exe shell:::{F2DDFC82-8F12-4CDD-B7DC-D4FE1425AA4D}
    Speech Recognition@explorer.exe shell:::{58E3C745-D971-4081-9034-86E34B30836A}
    Sync Center@explorer.exe shell:::{9C73F5E5-7AE7-4E32-A8E8-8D23B85255BF}
    System@explorer.exe shell:::{BB06C0E4-D293-4f75-8A90-CB05B6477EEE}
    System Icons@explorer.exe shell:::{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9} 
    Tablet PC Settings@explorer.exe shell:::{80F3F1D5-FECA-45F3-BC32-752C152E456E}
    Taskbar and Start Menu@explorer.exe shell:::{0DF44EAA-FF21-4412-828E-260A8728E7F1}
    Text to Speech@explorer.exe shell:::{D17D1D6D-CC3F-4815-8FE3-607E7D5D10B3}
    Time and Date@explorer.exe shell:::{E2E7934B-DCE5-43C4-9576-7FE4F75E7480}
    Troubleshooting@explorer.exe shell:::{C58C4893-3BE0-4B45-ABB5-A63E4B8C8651}
    User Accounts@explorer.exe shell:::{60632754-c523-4b62-b45c-4172da012619}
    User Folder@explorer.exe shell:::{59031a47-3f72-44a7-89c5-5595fe6b30ee}
    User Pinned@explorer.exe shell:::{1f3427c8-5c10-4210-aa03-2ee45287d668}
    Web Browser (default)@explorer.exe shell:::{871C5380-42A0-1069-A2EA-08002B30309D}
    Windows Anytime Upgrade@explorer.exe shell:::{BE122A0E-4503-11DA-8BDE-F66BAD1E3F3A}
    Windows Cardspace@explorer.exe shell:::{78CB147A-98EA-4AA6-B0DF-C8681F69341C}
    Windows Defender@explorer.exe shell:::{D8559EB9-20C0-410E-BEDA-7ED416AECC2A}
    Windows Features@explorer.exe shell:::{67718415-c450-4f3c-bf8a-b487642dc39b}
    WEI@explorer.exe shell:::{78F3955E-3B90-4184-BD14-5397C15F1EFC}
    Windows Firewall@explorer.exe shell:::{4026492F-2F69-46B8-B9BF-5654FC07E423}
    Windows Mobility Center@explorer.exe shell:::{5ea4f148-308c-46d7-98a9-49041b1dd468}
    Windows SideShow@explorer.exe shell:::{E95A4861-D57A-4be1-AD0F-35267E261739}
    Windows Update@explorer.exe shell:::{36eef7db-88ad-4e81-ad49-0e313f0c35f8}
  )
  l[ "Shell" ] := s
  list := object()
  for key,strc in l
    if( oItems.HasKey( key ) || !oItems )
      list[ key ] := strc
  return list
}