glb[ "ver" ] := "2.1.0"
glb[ "startTime" ] := A_NOW
glb[ "MAX_PATH" ] := (260+1)*2
glb[ "appName" ] := "Quick Cliq"
glb[ "BlankIcoNum" ] := 20000
glb[ "separator" ] := "-------------<"
glb[ "qcctxname" ] := "=> " glb[ "appName" ]
glb[ "smenuRegName" ] := "QuickCliq_S_Menu"
glb[ "smenuUpdName" ] := "Update S-Menu"
glb[ "menuIconsOffset" ] := 8
glb[ "optMTDivider" ] := "{N}" 
glb[ "optRecentMax" ] := 30
glb[ "optRecentMin" ] := 2
glb[ "afoDelay" ] := 30000
glb[ "qcArch" ] := A_PtrSize = 8 ? "x64" : "x32"
glb[ "RecentProcTrackInterval" ] := 3
glb[ "RecentFolTrackInterval" ] := 5000
glb[ "RecentWinRecTrackInterval" ] := 8000
glb[ "CtxMaxCmdLen" ] := 33
glb[ "firstRun" ] := False
glb[ "QC_PID" ] := GetCurrentProcessID()
glb[ "QC_GUI_FONT" ] := "Times New Roman"
glb[ "l_hkeys_on" ] := "Hotkeys: Turn ON"
glb[ "l_hkeys_off" ] := "Hotkeys: Turn OFF"
glb[ "l_gstrs_on" ] := "Gestures: Turn ON"
glb[ "l_gstrs_off" ] := "Gestures: Turn OFF"
glb[ "mainPipeName" ] := "\\.\pipe\quickcliq"
glb[ "mainPipeBufSize" ] := 1024*1024*5
glb[ "pipeTimeout" ] := 5000
glb[ "fFirstInstance" ] := 1
glb[ "pumParams" ] := { onrun : "MenuRunCommand"
                      , onselect : "MenuOnSelect"
                      , onuninit : "MenuOnUninit"
                      , oninit : "MenuOnInit"
                      , onmbutton : "MenuOnMButton"
                      , onrbutton : "MenuOnRButton"
                      , onshow : "MenuOnSwitch"
                      , onclose : "MenuOnSwitch" }

glb[ "copyTO" ] := 1
glb[ "clipsName" ] := "Clips"
glb[ "clipsItemID" ] := "ClipsMenu"
glb[ "clipsTitle" ] := "Clips View"
glb[ "winsName" ] := "Wins"
glb[ "winsItemID" ] := "WinsMenu"
glb[ "memosName" ] := "Memos"
glb[ "memosItemID" ] := "MemosMenu"
glb[ "memosTitle" ] := "Memos"
glb[ "recentName" ] := "Recent"
glb[ "recentItemID" ] := "RecentMenu"
glb[ "sysTitle" ] := "System Shortcuts"
glb[ "propsTitle" ] := "Item Properties"

;config
glb[ "qcDataPath" ] := A_ScriptDir . "\Data"
glb[ "qcUserIconsPath" ] := "Data\user_icons"
glb[ "xmlConfPath" ] := glb[ "qcDataPath" ] "\qc_conf.xml"
glb[ "memosDir" ] := glb[ "qcDataPath" ] "\memos"
glb[ "clipsDir" ] := glb[ "qcDataPath" ] "\Clips"

;previous version conf
glb[ "settingsPath" ] := glb[ "qcDataPath" ] "\settings.ini"
glb[ "itemsPath" ] := glb[ "qcDataPath" ] "\menu_items.ini"

;Icons
glb[ "iconListPath" ] := "Data\qc_icons.icl:"
icl := glb[ "iconListPath" ]
glb[ "icoQC" ] := icl . "0"
glb[ "icoSuspOn" ] := icl . "10"
glb[ "icoSuspOff" ] := icl . "9"
glb[ "icoMainEditor" ] := icl . "6"
glb[ "icoClips" ] := icl . "1"
glb[ "icoWins" ] := icl . "8"
glb[ "icoMemos" ] := icl . "7"
glb[ "icoFolMenu" ] := icl . "4"
glb[ "icoNone" ] := icl . "16"
glb[ "icoRecent" ] := icl . "11"
glb[ "icoHelpMe" ] := icl . "5"
glb[ "icoSuspend" ] := icl . "13"
glb[ "icoRemoteFol" ] := icl . "12"
glb[ "icoSysItem" ] := icl . "14"
glb[ "icoFolder" ] := icl . "3"
glb[ "icoEmail" ] := icl . "2"
glb[ "icoURL" ] := icl . "15"
glb[ "icoPropsInd" ] := 16
glb[ "icoPropsCnt" ] := 8
glb[ "icoIEInd" ] := glb[ "icoPropsInd" ] + glb[ "icoPropsCnt" ]
glb[ "icoIECnt" ] := 8
glb[ "icoPropsHotkey" ] := icl . ( glb[ "icoPropsInd" ] + 2 )
glb[ "icoMainInd" ] := glb[ "icoIEInd" ] + glb[ "icoIECnt" ]
glb[ "icoMainCnt" ] := 10
glb[ "icoCMDOut" ] := icl . ( glb[ "icoMainInd" ] + glb[ "icoMainCnt" ] )
glb[ "icoCMDIn" ] := icl . ( glb[ "icoMainInd" ] + glb[ "icoMainCnt" ] + 1 )
glb[ "icoGWESrch" ] := icl . ( glb[ "icoMainInd" ] + glb[ "icoMainCnt" ] + 2 )
free( icl )
;clips icons
glb[ "icoClipData" ] := "shell32.dll:166"
glb[ "icoClipClearAll" ] := "shell32.dll:31"
;some extras
glb[ "icoTLBprop_autorun" ] := "shell32.dll:24"
glb[ "hIcoTLBprop_autorun" ] := IconExtract( glb[ "icoTLBprop_autorun" ], 16 )
glb[ "icoProcList_uacBut" ] :=  ( A_OSVersion = "WIN_VISTA" ) ? "imageres.dll:72" 
                                : ( A_OSVersion ~= "WIN_XP|WIN_2003" ) ? "shell32.dll:44"
                                : "imageres.dll:73"
glb[ "icoRecentList_refrBut" ] := A_OSVersion ~= "WIN_XP|WIN_2003" ? "mmcndmgr.dll:46" : "shell32.dll:238"
glb[ "hIcoPropsHotkey16" ] := IconExtract( glb[ "icoPropsHotkey" ], 16 )

; URLs
glb[ "urlWebHelp" ] := "http://apathysoftworks.com/help_files/qc/"
glb[ "urlNews" ] := "http://apathysoftworks.com/category/stuff"
glb[ "urlFacebook" ] := "http://www.facebook.com/pages/Apathy-Softworks/109468265754240"
glb[ "urlTwitter" ] := "http://twitter.com/DeoWhite/apathy-softworks"
glb[ "urlDonate" ] := "http://apathysoftworks.com/donate"
glb[ "urlQCHome" ] := "http://apathysoftworks.com/software/quickcliq"
glb[ "urlApathyHome" ] := "http://apathysoftworks.com"
glb[ "urlChangelog" ] := "http://apathysoftworks.com/QC/qc_update/changelog.txt"
glb[ "pathChangelog" ] := A_Temp "\changelog.txt"
glb[ "urlLastVer" ] := "http://apathysoftworks.com/QC/qc_update/last_ver.txt"
glb[ "pathLastVer" ] := A_Temp "\app_last_ver.txt"
glb[ "urlUpdater" ] := "http://apathysoftworks.com/QC/qc_update/QC_updater.exe"
glb[ "pathUpdater" ] := A_Temp "\QC_updater.exe"
glb[ "pathVerChLog" ] := A_Temp "\QC_ver_changelog.txt"

;def
glb[ "defTColor" ] := 0x000000
glb[ "defBgColor" ] := 0xf1f1f1
glb[ "defButW" ] := 70
glb[ "defButH" ] := 25
glb[ "defOptBoxW" ] := 400
glb[ "defOptBoxH" ] := 435
glb[ "defOptLVW" ] := 150
glb[ "defOptBoxPos" ] := "x" floor(160*A_ScreenDPI/96) " y0"
/*
Used gui names:
GUI_OPT - options,
1 - main gui,
2 - options,
GUI_OPT_DEF_HKS - ChangeDefaultHotkeys
4 - add shortcut,
5 - add mail,
6 - about
7 - help gui
8 - for On-Top-Memos
9 - for Custom Hotkeys gui
10 - Custom Hotkeys Edit Hotkey
11 - GetPassword GUI
12 - props gui
20 - for FeedBack
21 - Send new Afo
22 - view clip
23 - System Shortcut Gui
24 - Win Transparency
25 - 
26 - 
27 - Special Targets description
29 - change log
30-98 - used for memo-on-top
PUM_MENU_GUI -  used by pum_menu
GUI_OPT_GEST_WIN_EXCL - gui for gesture exclusions

Splashes:
2 - for copyto command
3 - update check
5 - feedback delivering
7 - common
*/