WinsHotkeys( state )
{
  if ( err := Hotkey( qcOpt[ "wins_wndHideHkey" ], state, "WinsHideWindow" ) )
      QMsgBoxP( { title : "Wins hide hotkey error", msg : err, pic : "x" } )
  if ( err := Hotkey( qcOpt[ "wins_hotkey" ], state, "WinsMenu" ) )
    QMsgBoxP( { title : "Wins hotkey error", msg : err, pic : "x" } )
}