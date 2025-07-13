WinsAddMenu( objMenu ) 
{
  qcWinsMenu.Destroy()
  WinsHotkeys( 0 )
  If !qcOpt[ "wins_on" ]
    return
  winsMenuParams := { iconssize : toInt( qcOpt[ "aprns_iconsSize" ] )
                    ,tcolor    : NodeGetColor( "mtcolor", qcconf.GetMenuNode() )
                    ,bgcolor   : NodeGetColor( "mbgcolor", qcconf.GetMenuNode() )
                    ,textoffset: glb[ "menuIconsOffset" ]
                    ,noicons   : 1
                    ,nocolors  : qcOpt[ "aprns_lightMenu" ]
                    ,notext    : 0
                    ,ymargin   : 3 + toInt( qcOpt[ "aprns_heightAdjust" ] ) }
  
  qcWinsMenu := qcPUM.CreateMenu( winsMenuParams )
  
  oldSet := A_DetectHiddenWindows
  DetectHiddenWindows, On
  iter := qcconf.wins.selectNodes( "./win[ @type = ""hidden"" ]" )
  iter.reset()
  loop, % iter.length
  {
    if !( nextNode := iter.nextNode() )
      break
    winHWND := nextNode.getAttribute( "hwnd" )
    onTop := nextNode.getAttribute( "istopmost" )
    If IsWindow( winHWND )
      qcWinsMenu.Add( { name : WinGetTitle( winHWND )
                      , noicons : 0, icon : WinGetIcon( winHWND, qcOpt[ "aprns_iconsSize" ] )
                      , uid : "wins_" winHWND+0
                      , WinsTopmost : onTop }
                      , 0 )
    else
      qcconf.wins.removeChild( nextNode )
  }
  DetectHiddenWindows,% oldSet
  
  qcWinsMenu.Add()
  qcWinsMenu.Add( { name : "Hide current window", uid : "wins_HideAWin" } )
  qcWinsMenu.Add( { name : "Unhide all windows", uid : "wins_UnHideAll" } )
  qcWinsMenu.Add()
  qcWinsMenu.Add( { name : "Change window", uid : "wins_ModWin" } )
  qcWinsMenu.Add()
  qcWinsMenu.Add( { name : "Toggle Desktop", uid : "wins_ToggleDesktop" } )
  qcWinsMenu.Add( { name : "Tile Horizontally", uid : "wins_TileH" } )
  qcWinsMenu.Add( { name : "Tile Vertically", uid : "wins_TileV" } )
  qcWinsMenu.Add( { name : "Cascade windows", uid : "wins_Cascade" } )

  If qcOpt[ "wins_sub" ]
  {
    objMenu.Add( { name : glb[ "winsName" ]
                , icon : glb[ "icoWins" ]
                , uid : glb[ "winsItemID" ]
                , submenu : qcWinsMenu
                , break : IsNewCol( objMenu, glb[ "mItemsNum" ] ) } )
  }
  WinsHotkeys( 1 )
  Return
}

WinsHideWindow( winHWND )
{
  if ( glb[ "allowWinsHide" ] == 0 ) ;it may be just empty string on first run
    goto, winsHideCleanUp
  glb[ "allowWinsHide" ] := 0
  
  cls := WinGetClass( winHWND )
  If ( cls ~= "^(Shell_TrayWnd|Progman|WorkerW)$" 
      || !isWindow( winHWND )
      || glb[ "QC_PID" ] = WinGetProcID( winHWND ) ) ;taskbar & desktop, QC own windows
  {
    DTP( "Sorry, you cannot hide this window!" )
    goto, winsHideCleanUp
  }
  
  onTop := IsWinTopmost( winHWND )
  if ( winNode := qcconf.NewNode( "win" ) )
  {
    winNode.setAttribute( "type", "hidden" )
    winNode.setAttribute( "hwnd", winHWND+0 )
    winNode.setAttribute( "class", cls )
    winNode.setAttribute( "istopmost", onTop )
    qcconf.wins.appendChild( winNode )
  }
  
  qcWinsMenu.Add( { name : WinGetTitle( winHWND )
                  , icon : WinGetIcon( winHWND, qcOpt[ "aprns_iconsSize" ] )
                  , noicons : 0
                  , uid : "wins_" winHWND+0
                  , WinsTopmost : onTop }
                  , 0 ) ;qcWinsMenu.Count() - 11 )
    
  if qcOpt[ "wins_fade" ]
    WinFade( winHWND )
  WinHide( winHWND )
  qcconf.Save()
  SendInput, !{escape}
winsHideCleanUp:
  glb[ "allowWinsHide" ] := 1
  return
}

WinsUnhide( winHWND, isTopMost )
{
  glb[ "allowWinsHide" ] := 0
  WinsPreview( 0, True )
  if IsWindow( winHWND )
  {
    If ( !IsWindowVisible( winHWND ) && qcOpt[ "wins_fade" ] )  ;check for case when previwe active
      doFade := 1
    WinShow( winHWND )
    WinActivate( winHWND )
    if doFade
      WinUnFade( winHWND )
    WinSetTrans( winHWND, 255 )
    WinSet, AlwaysOnTop,% isTopMost ? "ON" : "OFF", ahk_id %winHWND%
  }
  Else
    DTP( "Window does not exist!" )
  
  WinsRemove( winHWND )
  qcconf.Save()
  glb[ "allowWinsHide" ] := 1
  return
}

WinsRemove( hwnd )
{
  hwnd += 0
  query = win[ @hwnd = "%hwnd%" and @type = "hidden" ]
  if ( winNode := qcconf.wins.selectSingleNode( query ) )
    qcconf.wins.removeChild( winNode )
  qcPUM.GetItemByUID( "wins_" hwnd ).Destroy()
}

WinsShowAll()
{
  iter := qcconf.wins.selectNodes( "./win[ @type = ""hidden"" ]" )
  iter.reset()
  Loop,% iter.length
  {
    if !( nextNode := iter.nextNode() )
      break
    winHWND := nextNode.getAttribute( "hwnd" )
    onTop := nextNode.getAttribute( "istopmost" )
    if !IsWindow( winHWND )
      continue
    WinShow( winHWND )
    WinSetTrans( winHWND, 255 )
    WinActivate(winHWND)
    WinSet, AlwaysOnTop,% onTop ? "ON" : "OFF", ahk_id %winHWND%
    WinsRemove( winHWND )
  }
  qcconf.Save()
  Return
}

WinUnFade( Window_Handle )
{
    transparency := 0
    Loop, 10
    {
      transparency += 25.5
      WinSetTrans( Window_Handle, transparency )
      sleep, 30
    }
}

WinFade( Window_Handle )
{
    transparency := 255
    Loop, 10
    {
        transparency -= 25.5
        WinSetTrans( Window_Handle, transparency )
        sleep, 30
    }	
}

WinsPreview( hWin, ClearOnly = False )
{
  static s_hWin
  #WinActivateForce
  Gui,PUM_MENU_GUI:+LastFoundExist
  menuHWND := WinExist()
  if hWin
  {
    t_Value := A_DetectHiddenWindows
    DetectHiddenWindows, ON
    WinSet, Transparent,% qcOpt[ "wins_viewTransp" ], ahk_id %hWin%
    DllCall( "SetWindowPos", "Ptr", hWin, "ptr", menuHWND
                , "int", 0, "int", 0, "int", 0, "int", 0
                , "uint", 0x0010 | 0x0001 | 0x0002 | 0x0040 | 0x400 | 0x0200 )
    DetectHiddenWindows,% t_Value
    s_hWin := hWin
  }
  else if ClearOnly
    s_hWin := 0
  else if s_hWin
  {
    WinSet, Transparent, 0, ahk_id %s_hWin%
    WinHide, ahk_id %s_hWin%
    WinActivate, AHK_ID %menuHWND%
    s_hWin := 0
  }
  return
}