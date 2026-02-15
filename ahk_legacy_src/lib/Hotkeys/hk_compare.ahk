HotkeysCompare( atGui = "", showErrMsg = 1 )
{
  gestures_log := ""
  hotkeys_log := ""
  G := object()
  H := object()
  ident := "     "
  ;getting gestures
  G[1] := { hk : qcOpt[ "main_gesture" ], descr : "MainMenu" }
  G[2] := { hk : qcOpt[ "clips_on" ] ? qcOpt[ "clips_gesture" ] : ""
          , descr : "ClipsMenu" }
  G[3] := { hk : qcOpt[ "wins_on" ] ? qcOpt[ "wins_gesture" ] : ""
          , descr : "WindowsMenu" }
  G[4] := { hk : qcOpt[ "Memos_On" ] ? qcOpt[ "Memos_Gesture" ] : ""
          , descr : "MemosMenu" }
  G[5] := { hk : qcOpt[ "recent_on" ] ? qcOpt[ "Recent_Gesture" ] : ""
          , descr : "RecentMenu" }
  ;getting hotkeys
  H[1] := { hk : qcOpt[ "clips_on" ] ? qcOpt[ "clips_hotkey" ] : ""
          , descr : "ClipsMenu" }
  H[2] := { hk : qcOpt[ "main_hotkey" ], descr : "MainMenu" }
  H[3] := { hk : qcOpt[ "wins_on" ] ? qcOpt[ "wins_hotkey" ] : ""
          , descr : "WindowsMenu" }
  H[4] := { hk : qcOpt[ "wins_on" ] ? qcOpt[ "wins_wndHideHkey" ] : ""
          , descr : "HideWindow" }
  H[5] := { hk : qcOpt[ "Memos_On" ] ? qcOpt[ "Memos_Hotkey" ] : ""
          , descr : "MemosMenu" }
  H[6] := { hk : qcOpt[ "recent_on" ] ? qcOpt[ "Recent_Hotkey" ] : ""
          , descr : "RecentMenu" }
  
  nodes := qcconf.GetMenuNode().selectNodes( ".//item[ @hotkey != '' ]" )	;getting nodes with non-empty hotkey attr
    while ( node := nodes.nextNode )
    H.insert( { hk : node.getAttribute( "hotkey" ), descr : qcconf.GetItemPath( node ) } )
  Loop, 9
  {
    H.Insert( { hk : qcOpt[ "Clips_CopyHK" ] A_Index, descr : "Clips_Add: " . HotkeyToString( qcOpt[ "Clips_CopyHK" ] A_Index ) } )
    H.Insert( { hk : qcOpt[ "Clips_AppendHK" ] A_Index, descr : "Clips_Append: " . HotkeyToString( qcOpt[ "Clips_AppendHK" ] A_Index ) } )
    H.Insert( { hk : qcOpt[ "Clips_PasteHK" ] A_Index, descr : "Clips_Paste: " . HotkeyToString( qcOpt[ "Clips_PasteHK" ] A_Index ) } )
  }
  
  for i,props in G
  {
    if ( "" == ( hk := props.hk ) )
      continue
    descr := props.descr
    j := i
    While !( ++j > G.MaxIndex() )
    {
      if ( "" == ( hk_next := G[ j ].hk ) )
        continue
      if ( hk = hk_next )
        gestures_log .= "`n'" descr "' gesture is the same as '" G[ j ].descr "':`n" ident hk
    }
  }
  
  for i,props in H
  {
    if ( "" == ( hk := props.hk ) )
      continue
    descr := props.descr
    j := i
    While !( ++j > H.MaxIndex() )
    {
      if ( "" == ( hk_next := H[ j ].hk ) )
        continue
      if ( hk = hk_next )
        hotkeys_log .= "`n'" descr "' hotkey is the same as for '" H[ j ].descr "':`n" ident HotkeyToString( hk )
    }
  }
  
  if gestures_log
    output .= "Gestures errors:" gestures_log "`n`n`"
  if hotkeys_log
    output .= "Hotkeys errors:" hotkeys_log
  if ( output && showErrMsg )
    QMsgBoxP( { title : "Using of similar hotkeys"
          , msg : "Some of your hotkeys/mouse gestures are the same:`n`n" output
          , butons : "OK", pic : "!", modal : 1
          , pos : atGui, editbox : 1, rsz : 1 }, atGui )
  return output
}