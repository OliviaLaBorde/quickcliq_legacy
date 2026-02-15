GUIAddItemFromProcList( byRef oTarget )
{
  static proc_list_uac_but, hUACIco
  if !WinExist( "ahk_id " qcGui[ "main_proc_list" ] )
  {
    GuiCreateNew( "GUI_PROC_LIST", "main_proc_list", "Process List", qcGui[ "main" ] )
    Gui,Add,ListView,h600 w650 hwndhwnd gGUI_PROC_LIST_LVHandle AltSubmit Grid +0x8 -Multi,Name|ID|Executable|Cmd|Service Name ;LVS_SHOWSELALWAYS
    qcGui[ "procList_lv" ] := hwnd
    Gui,Add,Text,xm,Command Line
    Gui,Add,Edit,W500 xp+100 hwndhwnd
    qcGui[ "procList_cmdEdit" ] := hwnd
    Gui,Add,Text,xm,Executable
    Gui,Add,Edit,W500 xp+100 hwndhwnd
    qcGui[ "procList_execEdit" ] := hwnd
    if( !A_IsAdmin && glb[ "fFirstInstance" ] )
    {
      Gui,Add,Button,% "x+7 yp-25 w40 h40 vproc_list_uac_but hwndhwnd gGUI_PROC_LIST_UACGetProcs +0x00000040" ;BS_ICON
      qcGui[ "procList_uacBut" ] := hwnd
      if !hUACIco
        hUACIco := IconExtract( glb[ "icoProcList_uacBut" ], 32 )
      Icon2Button( qcGui[ "procList_uacBut" ], hUACIco )
    }
    
    Menu, GUI_PROC_LIST_ProcMenu, Add, Add cmd line,GUI_PROC_LIST_AddCmd
    Menu, GUI_PROC_LIST_ProcMenu, Default, Add cmd line
    Menu, GUI_PROC_LIST_ProcMenu, Add, Add executable path,GUI_PROC_LIST_ExecPath
  }
  GuiShowChildWindow( qcGui[ "main_proc_list" ], qcGui[ "main" ] )
  ProcList_AddProcs()
  return qcGui[ "main_proc_list" ]
  
  GUI_PROC_LISTGuiClose:
  GUI_PROC_LISTGuiEscape:
  GUI_PROC_LISTStop:
    GuiDestroyChild( qcGui[ "main_proc_list" ], qcGui[ "main" ] )
    return
    
  GUI_PROC_LIST_AddCmd:
  GUI_PROC_LIST_ExecPath:
    Gui,GUI_PROC_LIST:Default
    rowNum := LV_GetNext()
    if !rowNum
      return
    LV_GetText( cmdName, rowNum, 1 )
    LV_GetText( execPath, rowNum, 3 )
    LV_GetText( cmdLine, rowNum, 4 )
    if ( isEmpty( execPath ) && isEmpty( cmdLine ) )
      return
    oTarget.name := cmdName
    oTarget.iconPath := execPath != "" ? execPath : cmdLine
    if instr( A_ThisLabel, "AddCmd" )
      oTarget.cmd := cmdLine != "" ? cmdLine : execPath
    else
      oTarget.cmd := execPath != "" ? execPath : cmdLine
    SetTimer,GUI_PROC_LISTStop,-20
    return
    
  GUI_PROC_LIST_UACGetProcs:
    Gui,GUI_PROC_LIST:Default
    dRet := API_ShellExecuteEx(A_ScriptFullPath,"-getprocs", A_ScriptDir,"RUNAS")
    if dRet["err"]
    {
      QMsgBoxP( { title : "Failed to start " glb[ "appName" ] " with admin rights"
              , msg : "Failed to start " glb[ "appName" ] " with admin rights:`n" dRet["err"]
              , pic : "x" } )
      return
    }
    hProc := dRet["hProc"]
    ;it may connect or may not, but must be called
    ;returns immediately because of FILE_FLAG_OVERLAPPED when creating the pipe
    ;for us it does not matter if and when the pipe connected because we wait for process exit anyway
    ConnectNamedPipe( glb[ "hMainPipe" ] )
    tcnt := glb[ "pipeTimeout" ]/500
    while( ( GetExitCodeProcess( hProc ) == 259 ) && tcnt != 0 ) ;STILL_ACTIVE
      sleep 500,tcnt--
    if ( tcnt == 10 )
    {
      QMsgBoxP( { title : "Failed to wait " glb[ "appName" ] " exit"
              , msg : glb[ "appName" ] " didn't respond in " glb[ "pipeTimeout" ]/1000 " sec"
              , pic : "x" } )
      return
    }
    ; we'll most probably get an error here if there is any problems with pipe on client side
    procsCSV := PipeRead( glb[ "hMainPipe" ], glb[ "mainPipeBufSize" ] )
    if !procsCSV
    {
      QMsgBoxP( { title : "Could not read from pipe"
              , msg : "Failed to read data from pipe: ErrLevel " ErrorLevel ", format: " ErrorFormat(GetLastError())
              , pic : "x" } )
      return
    }
    ;must be called to free client side handle (and allow following connections)
    DisconnectNamedPipe( glb[ "hMainPipe" ] )
    ProcList_ParseCSV( procsCSV )
    return
    
  GUI_PROC_LIST_ShowCtxMenu:
    Menu, GUI_PROC_LIST_ProcMenu, Show
    return
    
  GUI_PROC_LIST_LVHandle:
    Gui,GUI_PROC_LIST:Default
    event := A_GuiEvent
    ev_info := A_EventInfo
    If ( event = "RightClick" || ( event = "K" && ev_info = 93 ) )
    {
      if LV_GetNext()
        SetTimer,GUI_PROC_LIST_ShowCtxMenu,-20
    }
    else If ( event = "DoubleClick" || ( event = "K" && ev_info = 32 ))
    {
      if LV_GetNext()
        SetTimer,GUI_PROC_LIST_AddCmd,-1
    }
    else if ( event ~= "Normal|I" )
    {
      LV_GetText( cmdLine, ev_info, 4 )
      LV_GetText( execPath, ev_info, 3 )
      GuiControlSet( qcGui[ "procList_cmdEdit" ],cmdLine,"",qcGui[ "main_proc_list" ] )
      GuiControlSet( qcGui[ "procList_execEdit" ],execPath,"",qcGui[ "main_proc_list" ] )
    }
    return
}

ProcList_toPipe()
{
  hPipe := PipeOpen( glb[ "mainPipeName" ], glb[ "pipeTimeout" ] )
  if( !hPipe )
  {
    QMsgBoxP( { title : "Could not open pipe"
              , msg : "Failed to open pipe: ErrLevel " ErrorLevel ", format: " ErrorFormat(GetLastError())
              , pic : "x" } )
    return
  }
  sData := ""
  svcList := GetWin32Svc().list
  for id,proc in GetWin32Proc().list
    sData .= proc.name ";" id ";" proc.exec ";" (proc.cmd ? proc.cmd : svcList[id].cmd)
            . ";" svcList[id].name "`n"
  ret := PipeWrite( hPipe, sData )
  if ret
    QMsgBoxP( { title : "Could not write to pipe"
              , msg : ret
              , pic : "x" } )
  CloseHandle( hPipe )
  return
}

ProcList_ParseCSV( sCSV )
{
  Gui,GUI_PROC_LIST:Default
  if( sCSV = "" )
    return
  LV_Delete()
  GuiControl, -Redraw,% qcGui[ "procList_lv" ]
  for i,line in StrSplit( sCSV, "`n", A_Tab A_Space )
  {
    if ( line = "" )
      continue
    lineArr := StrSplit( line, ";", A_Tab A_Space )
    if( lineArr[1] = "System" )
      continue
    LV_Add( "", lineArr[1]  ;name
              , lineArr[2]  ;ID
              , lineArr[3]  ;Executable
              , lineArr[4]  ;CMD
              , lineArr[5]) ;Service Name
  }
  LV_ModifyCol( 1, "Sort" )
  GuiControl, +Redraw,% qcGui[ "procList_lv" ]
  return
}

ProcList_AddProcs()
{
  Gui, GUI_PROC_LIST:Default
  GuiControl, -Redraw,% qcGui[ "procList_lv" ]
  LV_Delete()
  svcList := GetWin32Svc().list
  for id,proc in GetWin32Proc().list
  {
    cmd := proc.cmd
    exect := proc.exec
    name := proc.name
    if( name = "System" )
      continue
    svcName := svcList[id].name
    if !cmd
      cmd := svcList[id].cmd
    LV_Add( "", name, id, exect, cmd, svcName )
  }
  LV_ModifyCol()
  LV_ModifyCol(1,90) ;name
  LV_ModifyCol(5,90) ;service name
  LV_ModifyCol(3,170) ;exec
  LV_ModifyCol(4,170) ;cmd
  LV_ModifyCol(2, "Integer" )
  LV_ModifyCol( 1, "Sort" )
  GuiControl, +Redraw,% qcGui[ "procList_lv" ]
  return 0
}