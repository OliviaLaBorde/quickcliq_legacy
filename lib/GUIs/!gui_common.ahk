ControlSetState(ctrl_hwnd,state=1)
{
  Control,% state=1 ? "Enable" : "Disable",,, ahk_id %ctrl_hwnd%
  return state
}

ClCheck(ctrl_hwnd,state=1)
{
  Control,% state=1 ? "Check" : "UnCheck",,, ahk_id %ctrl_hwnd%
  return state
}

ClHide(ctrl_hwnd)
{
  Control,% "Hide",,, ahk_id %ctrl_hwnd%
  return state
}

ClShow(ctrl_hwnd)
{
  Control,% "Show",,, ahk_id %ctrl_hwnd%
  return state
}

ClIsVisible(ctrl_hwnd)
{
  ControlGet, f, Visible,,, ahk_id %ctrl_hwnd%
  return f
}

ClIsEnabled(ctrl_hwnd)
{
  ControlGet, f, Enabled,,, ahk_id %ctrl_hwnd%
  return f
}

ClIsChecked(ctrl_hwnd)
{
  ControlGet, f, Checked,,, ahk_id %ctrl_hwnd%
  return f
}

ControlGetFont( hCtrl )
{
  return SendMessage( hCtrl, 0x31, 0, 0 )	;WM_GETFONT
}

HideFocus(guiNum)
{
  Gui,%guiNum%:+LastFoundExist
  hwnd := WinExist()
  return SendMessage(hwnd,0x0127,0x10003,0)	;WM_CHANGEUISTATE with UIS_INITIALIZE + UISF_HIDEFOCUS
}

GuiControlSet(Control_Name,Value="",Options="",Gui_="",CanBeEmptyValue=1)	{	;if few controls, separate them with |
  if (Gui_ = "")
    Gui_ := A_Gui
  Loop, Parse, Control_Name, |, %A_Tab%%A_Space%
  {
    if (Value != "" || CanBeEmptyValue)
      GuiControl,%Gui_%:,%A_Loopfield%,%Value%
    if Options
    {
      GuiControl,% Gui_ ": " Options, %A_Loopfield%
      GuiControl,% Gui_ ": MoveDraw", %A_Loopfield%
    }
  }
  return
}

ControlGetPos( ctl, sGui = "" )
{
  if !IsInteger( ctl )
  {
    if sGui
      GuiControlGet, ctl, %sGui%:Hwnd, %ctl%
    else
      ShowExc( "Gui not specified for control: " ctl )
  }
  ControlGetPos, X, Y, W, H,, ahk_id %ctl%
  return { x : X, y : Y, w : W, h : H }
}

ControlGetClientPos( hwnd )
{
  GuiControlGet, p, Pos,% hwnd
  VarSetCapacity( RECT, 16, 0 )
  if ( pX < 0 || pY < 0 || pW <= 0 || pH <= 0 )
    return 0
  return { "x" : pX,"y" : pY, "w" : pW, "h" : pH }
}

ControlGet( c_hwnd )
{
  ControlGetText, value,,ahk_id %c_hwnd%
  return value
}

GuiControlGet(Control_Name,Gui="")	{
  if (Gui = "")
    Gui := A_Gui
  GuiControlGet,value,%Gui%:,%Control_Name%
  return value
}

GuiShowChildWindow( hGui, hParentGui, showMode = "show_close", sSizes = "" )
{
  if !IsWindowVisible( hParentGui )
  {
    Gui,% hGui ": Show",% ( sSizes != "" ? sSizes : "AutoSize" )
    return
  }
  WinGetPos, X, Y, W, H,% "AHK_ID " hParentGui
  if ( showMode = "show_close" )
    Gui,% hGui ": Show",% "x" . round( x + 60 ) 
                     . " y" . round( y + 60 )
                     . " " ( sSizes != "" ? sSizes : "AutoSize" )
  else if ( showMode = "show_far_right" )
    Gui,% hGui ": Show",% "x" . round( x + 240 ) 
                     . " y" . round( y + 60 )
                     . " " ( sSizes != "" ? sSizes : "AutoSize" )
}

GuiCreateNew( guiName, guiID, title, guiOwnerID = 0, fDisableOwner = True )
{
  Gui,% guiName ":NEW",% "+hwndhwnd -DPIScale " ( guiOwnerID ? "+owner" guiOwnerID : "" ),% title
  qcGui[ guiID ] := hwnd
  QCSetGuiFont( guiName )
  if( fDisableOwner && guiOwnerID && IsWindow( guiOwnerID ) )
    Gui, % guiOwnerID ":+Disabled"
  Gui, Margin, 10, 10
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  return hwnd
}

GuiDestroyChild( hChild, hParent )
{
  if IsWindow( hParent )
    Gui,% hParent ":-Disabled"
  Gui,% hChild ":Destroy"
  if( IsWindow( hParent ) && IsWindowVisible( hParent ) )
  {
    Gui,% hParent ":Default"
    WinActivate,% "ahk_id " hParent
  }
  return 0
}