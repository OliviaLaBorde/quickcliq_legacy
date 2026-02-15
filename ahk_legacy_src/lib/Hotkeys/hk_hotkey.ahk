MainMenuHotkeys( state, susp = 0 )
{
  if ( err := Hotkey( qcOpt[ "main_hotkey" ], state, "MainMenu" ) )
    if ( "Reset" = QMsgBoxP( { title : "Main Menu hotkey error"
              , msg : err "`nDo you want to reset it to default?"
              , buttons : "OK|Reset", pic : "x" } ) && state )
      if ( err := Hotkey( OptDefaults[ "main_hotkey" ], 1, "MainMenu" ) )
        QMsgBoxP( { title : "Main Menu hotkey error"
                  , msg : "Could not reset hotkey to default value`n" err
                  , buttons : "OK", pic : "x" } )
  MainMenuExHotkeys( state )
  return
}

MainMenuExHotkeys( state )
{
  if !state {
    Hotkey( "^RButton",state,"MainMenu")
    Hotkey( "^MButton",state,"MainMenu")
    Hotkey( "~LButton & RButton",state,"MainMenu")
  }
  else
  {
    if qcOpt[ "main_ctrlRbHkey" ]
      if ( err := Hotkey( "^RButton",state,"MainMenu") )
        QMsgBoxP( { title : "Main Menu hotkey error", msg : err, buttons : "OK", pic : "x" } )
    
    if qcOpt[ "main_ctrlMbHkey" ]
      if ( err := Hotkey( "^MButton",state,"MainMenu") )
        QMsgBoxP( { title : "Main Menu hotkey error", msg : err, buttons : "OK", pic : "x" } )

    if qcOpt[ "main_ctrlLRbHKey" ]
      if ( err := Hotkey( "~LButton & RButton",state,"MainMenu") )
        QMsgBoxP( { title : "Main Menu hotkey error", msg : err, buttons : "OK", pic : "x" } )
  }
}

SetHotkeys( state )
{
  if qcOpt[ "wins_on" ]
    WinsHotkeys( state )
  if qcOpt[ "clips_on" ]
    ClipsHotkeys( state )
  if qcOpt[ "Memos_On" ]
    MemosHotkeys( state )
  if qcOpt[ "recent_on" ]
    RecentHotkeys( state )
  
  MainMenuExHotkeys( state )
  SetCustomHotkeys( state )
  return
}

; ifWin = 1 for IfWinActive, 0 for IfWinNotActive
Hotkey( hkey, state, label="", IfWin="", title="", isPersistent = False )
{
  if (hkey = "")
    return
  if state not in 0,1
    return
  hk_list := HotkeyGetVK(hkey)
  if IfWin in 0,1
    Hotkey,% "IfWin" (IfWin ? "Active" : "NotActive"),% title
  if hk_list.MaxIndex()
    for i,hk in hk_list
    {
      qcHotkeyList[ hk ] := { orig : hkey
                            , label : label
                            , ifwin : IfWin
                            , iftitle : title 
                            , state : state
                            , persistent : isPersistent }
      if( ex := _SetHotkey( hk, state, label ) )
        error .= ( error ? "`n" : "") "Hotkey wasn't set: " . HotkeyToString( hkey )
                . ";`nCode: " . hk ";`nError: " . ex.message . ";`n"
    }
  else
    error .= (error ? "`n" : "") "Hotkey wasn't set: " . HotkeyToString( hkey ) . ";`nError: The required symbol was not found on your current keyboard layouts.`n"
  Hotkey,IfWinActive
  return error
}

_SetHotkey( hk, state, label = ""  )
{
  try
    HotKey,% hk,% label,% ( state = 0 ? "OFF" : "ON" )
  catch ex
    return ex
  return
}

HotkeySetAll( state )
{
  for hk, params in qcHotkeyList
  {
    if !params.state
      continue
    if params.persistent
      continue
    if( params.ifwin != "" )
      Hotkey,% "IfWin" ( params.ifwin ? "Active" : "NotActive"),% params.iftitle
    _SetHotkey( hk, state )
    Hotkey,IfWinActive
  }
}

; this code disables/enables gesture button if specified windows is active
SetGestureState( gestureState )
{
  static curGroup := 0
  ghk := GestureGetHK()
  if qcOpt[ "gest_win_excl_on" ]
    Hotkey( ghk, gestureState, "GesturesSub", "0","ahk_group " glb[ "gwe_group_name" ] )
  else
    Hotkey( ghk, gestureState, "GesturesSub", "0","ahk_group " glb[ "gwe_default_name" ] )
  return
}

GestureGetHK()
{
  return qcOpt[ "gest_butmods" ] qcOpt[ "gest_curbut" ]
}