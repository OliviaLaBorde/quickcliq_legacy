AddExtras( objMenu )
{
  If ( ( qcOpt[ "clips_on" ] && qcOpt[ "clips_sub" ] ) 
    || ( qcOpt[ "wins_on" ] && qcOpt[ "wins_sub" ] ) 
    || ( qcOpt[ "Memos_On" ] && qcOpt[ "memos_sub" ] )
    || ( qcOpt[ "recent_on" ] && qcOpt[ "recent_sub" ] ) )
    objMenu.add() ;separator
  
  ClipsAddMenu( objMenu )
  WinsAddMenu( objMenu )
  MemosAddMenu( objMenu )
  RecentAddMenu( objMenu )
  return
}