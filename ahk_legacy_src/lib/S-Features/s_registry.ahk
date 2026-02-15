SMenu_SetRegistry( state, startupCheck = False )			;checking if reg values for .qcm files are valid, otherwise fixing them
{
  if !state
  {
    if !A_ISAdmin
    {
      MsgBox, 52, Run As Admin?,% glb[ "appName" ] " requires admin privileges for this action.`nDo you want to proceed?"
      IfMsgBox, Yes
      {
        API_ShellExecute(A_ScriptFullPath,"-smreg 0", A_ScriptDir,"RUNAS")	
        return 1
      }
      else
        return 0
    }	
    RegDelete( "HKCR", ".qcm" )
    RegDelete( "HKCR", glb[ "smenuRegName" ] )
    DllCall("Shell32.dll\SHChangeNotify","Int",0x8000000,"UInt",0)
    return 1
  }
  else
  {
    iconPath = "%A_ScriptFullPath%"
    cmdUpd = "%A_ScriptFullPath%" -smupd "`%1" 
    cmdRun = "%A_ScriptFullPath%" -sm "`%1"
    typeName := glb[ "appName" ] " Menu"
    
    if ( RegRead( "HKCR", glb[ "smenuRegName" ] "\shell\Update" ) 						!= glb[ "smenuUpdName" ] )
      || ( RegRead( "HKCR", glb[ "smenuRegName" ] "\shell\Update", "Icon" ) 		!= iconPath )
      || ( RegRead( "HKCR", glb[ "smenuRegName" ] "\shell\Update\command" ) != cmdUpd )
      || ( RegRead( "HKCR", ".qcm" ) 																			!= glb[ "smenuRegName" ] )
      || ( RegRead( "HKCR", glb[ "smenuRegName" ] ) 												!= typeName )
      || ( RegRead( "HKCR", glb[ "smenuRegName" ], "NeverShowExt" ) 				!= 1 )
      || ( RegRead( "HKCR", glb[ "smenuRegName" ] "\DefaultIcon" ) 					!= iconPath )
      || ( RegRead( "HKCR", glb[ "smenuRegName" ] "\Shell\Open\Command" ) 	!= cmdRun )
      hasErrors := True
    
    if hasErrors
    {
      if !A_IsAdmin
      {
        if startupCheck
          MsgBox, 52,% glb[ "appName"],% "S-Menu settings is not properly set.`n" glb[ "appName" ] " requires admin privileges to fix this.`nDo you want to proceed?"
        else
          MsgBox, 52, Run As Admin?,% glb[ "appName" ] " requires admin privileges for this action.`nDo you want to proceed?"
        IfMsgBox, Yes
        {
          API_ShellExecute(A_ScriptFullPath,"-smreg 1", A_ScriptDir,"RUNAS")
          return 1
        }
        else
          Return 0
      }
      RegDelete( "HKCR", ".qcm" )
      RegDelete( "HKCR", glb[ "smenuRegName" ] )
      RegWrite( "REG_SZ", "HKCR", glb[ "smenuRegName" ] "\shell\Update","", glb[ "smenuUpdName" ] )
      RegWrite( "REG_EXPAND_SZ", "HKCR", glb[ "smenuRegName" ] "\shell\Update","Icon", iconPath )
      RegWrite( "REG_SZ", "HKCR", glb[ "smenuRegName" ] "\shell\Update\command","", cmdUpd )
      RegWrite( "REG_SZ", "HKCR", ".qcm","", glb[ "smenuRegName" ] )
      RegWrite( "REG_SZ", "HKCR", glb[ "smenuRegName" ],"", typeName )
      RegWrite( "REG_SZ", "HKCR", glb[ "smenuRegName" ],"NeverShowExt", 1 )
      RegWrite( "REG_SZ", "HKCR", glb[ "smenuRegName" ] "\DefaultIcon","", iconPath )
      RegWrite( "REG_SZ", "HKCR", glb[ "smenuRegName" ] "\Shell\Open\Command","", cmdRun )
      DllCall("Shell32.dll\SHChangeNotify","Int",0x8000000,"UInt",0)
    }
  }
  return 1
}