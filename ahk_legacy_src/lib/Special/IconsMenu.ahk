IconsMenu_AddUser( oMenu, ico_fol )
{
  num := 0
  Loop,%ico_fol%\*,2,0	;getting folders only
  {
    subFolMenu := qcPum.CreateMenu( { iconssize : 32 } )
    IconsMenu_AddUser( subFolMenu, A_LoopFileFullPath )
    oMenu.Add( { name : A_LoopFileName
                , submenu : subFolMenu, noicons : 1
                , break : mod( num, 8 ) ? 0 : 1 } )
    num++
  }
  num := 5
  Loop,%ico_fol%\*.*,0,0	;getting files only
  {
    if A_LoopFileExt not in ico,png,jpeg,bmp,jpg,gif,cur
      continue
    oMenu.Add( { icon : A_LoopFileFullPath, uid : "IconsMenu_ico"
                ,cmd : A_LoopFileFullPath, notext : 1
                ,break : mod( num, 5 ) ? 0 : 1
                , name : A_LoopFileName } )
    num++
  }
  return
}

;######## IconsMenu
; Function Creates menu with icons to choose in main gui
Gui_Main_IconsMenu( hWin, oldIco, x="", y="" )
{
  static iconsMenu, oFolMod
  if( IsDirModified( glb[ "qcUserIconsPath" ], oFolMod ) || !iconsMenu.IsMenu() )
  {
    iconsMenu.Destroy()
    iconsMenu := qcPum.CreateMenu( { noicons : 1 } )
    IconsMenu_AddStandard( iconsMenu )
    userIconsMenu := qcPum.CreateMenu( { iconssize : 32 } )
    IconsMenu_AddUser( userIconsMenu, glb[ "qcUserIconsPath" ] )
    if !userIconsMenu.Count()
      userIconsMenu.Add( { name : "How can i add my own icons here?", uid : "IconsMenu", cmd : "HowToHint" } )
    iconsMenu.Add( { name : "My Icons", submenu : userIconsMenu } )
  }
  if ( x="" || y="" )
    MouseGetPos, X,Y
  if ( item := iconsMenu.Show( x, y ) )
    new_ico := IconsMenu_Handler( item, hWin, oldIco )
  Return new_ico
}

IconsMenu_AddStandard( oMenu )
{
  oMenu.Add( { name : "Browse...", uid : "IconsMenu", cmd : "Browse" } )
  oMenu.Add()
  if A_OSVersion in WIN_XP,WIN_2003
    sysIcons := "shell32,moricons,pifmgr,compstui,mmcndmgr,netshell,wmploc,wpdshext"
  else
    sysIcons := "shell32,moricons,pifmgr,compstui,DDORes,imageres,mmcndmgr,netshell,pnidui,wmploc,wpdshext"
  for i,val in StrSplit( sysIcons, ",", A_SPace A_Tab )
    oMenu.Add( { name : val "...", uid : "IconsMenu_dll", cmd : val ".dll" } )
  oMenu.Add()
  oMenu.Add( { name : "Remove", uid : "IconsMenu", cmd : "Remove" } )
  
  icosSub := qcPUM.CreateMenu( { iconssize : 32, notext : 1 } )
  oMenu.Add( { name : glb[ "appName" ], break : 1, submenu : icosSub } )
  
  iEnum := glb[ "icoSuspOn" ] "|" glb[ "icoSuspOff" ] "|" glb[ "icoMainEditor" ] "|"
      . glb[ "icoClips" ] "|" glb[ "icoWins" ] "|" glb[ "icoMemos" ] "|" glb[ "icoFolMenu" ] "|"
      . glb[ "icoRecent" ] "|" glb[ "icoHelpMe" ] "|" glb[ "icoSuspend" ] "|" glb[ "icoRemoteFol" ] "|"
      . glb[ "icoSysItem" ] "|" glb[ "icoFolder" ] "|" glb[ "icoEmail" ] "|" glb[ "icoURL" ]
  
  for i,val in StrSplit( iEnum, "|", A_SPace A_Tab )
    icosSub.Add( { icon : val, uid : "IconsMenu_ico", cmd : val, break : mod( i-1, 5 ) ? 0 : 1 } )
  return
}

IconsMenu_Handler( oItem, hWin, oldIco )
{
  uid := oItem.uid
  if !InStr( uid, "IconsMenu" )
    ShowExc( "Wrong item passed" )
  if ( uid = "IconsMenu_Ico" )
    return oItem.cmd
  else if ( uid = "IconsMenu_dll" )
  {
    if IconPickDlg( hWin, sIconPath := oItem.cmd, nIndex := 0 )
      return sIconPath ":" nIndex
  }
  else if ( uid = "IconsMenu" )
  {
    if ( oItem.cmd = "Browse" )
    {
      sIconPath := IconGetPath( oldIco )
      nIndex := IconGetIndex( oldIco )
      if IconPickDlg( hWin, sIconPath, nIndex )
        return sIconPath ":" nIndex
      return 0
    }
    if ( oItem.cmd = "Remove" )
      return -1
    if ( oItem.cmd = "HowToHint" )
    {
      QMsgBoxP( { title : "How to add your own icons", msg : "You can choose your favorite icons from this menu.`nJust add them into the folder:`n<" glb[ "appName" ] " dir>\" glb[ "qcUserIconsPath" ] "`nAny subfolders will be recursed."
      , pos : 1, modal : 1, pic : "i" }, 1 )
      return 0
    }
  }
  return 0
}