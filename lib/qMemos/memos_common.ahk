MemosHotkeys( state )
{
  if ( err := Hotkey( qcOpt[ "Memos_Hotkey" ], state, "MemosMenu" ) )
	QMsgBoxP( { title : "Memos hotkey error", msg : err, pic : "x" } )
  return
}