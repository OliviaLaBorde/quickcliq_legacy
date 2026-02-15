;############################### SET ITEM PROPERTIES
QC_ItemSet( item, params )
{
	static params_list := {	name:0,issep:0,icon:0,bold:0
												,bgcolor:0,tcolor:0,mbgcolor:0,mtcolor:0,hotkey:0}	;list of possible parameters for menu item
	if !isObject( params )
		throw Exception( "Wrong parameter: " params "`n" CallStack() )
	item := qcconf.ItemResolve( item )
	for key, value in params
		if params_list.HasKey( key )
			qcconf.ItemSetAttr( item, key, value, 1 )
	if params.HasKey( "cmd" )
		qcconf.ItemSetCmd( item, params.cmd )
}
;############################### ADD XML ITEM
QC_AddXMLItem( params )
{
	Gui, 1:Default
	if !IsObject( params )
		throw Exception( "Not an object passed`n" CallStack() )
	menuNode := params.menuNode ? params.menuNode
								: params.menuID ? qcconf.GetNodeByID( params.menuID )	;any menu
								: qcconf.GetNodeByID( 0 )	;top menu
	beforeItemNode := params.afterNode ? params.afterNode.nextSibling
										: params.afterID ?  qcconf.GetNodeByID( params.afterID ).nextSibling
										: 0							; will add to the end of menu
										;~ : menuNode.firstChild		;item will be added to the top of the list
	newItemNode := qcconf.CreateItemNode( menuNode, beforeItemNode )
	QC_ItemSet( newItemNode, params )
	return newItemNode
}
;############################### MOVE ITEM
GUI_Main_TV_Move( id, tid, pid = "" )	;tid can be target id, after which moved item will be placed (0 for top), or U or D letter for move
{
	if !id
		return
	Gui,1:Default
	GuiControl,Focus,% qcGUI[ "main_tv" ]
	GuiControl, -Redraw,% qcGui[ "main_tv" ]
	if ( pid = "" )
		pid := TV_GetParent( id )
	if tid in U,D	;in case we move item with arrows
	{
		dir := tid
		tid :=  dir = "U" ? TV_GetPrev( id )
				: dir = "D" ? TV_GetNext( id ) : ""
		if !tid		;means item at the beginning or at the end of menu
			return
		if ( dir = "D" )								;getting item before which moved one should be
			tid := TV_GetNext( tid )
	}
	else if !IsInteger( tid )	;can be integer if passed from DragnDrop
		throw Exception( "invalid tid: " tid "`n" CallStack() )
	; XML CHANGES
	itemNode := qcconf.GetNodeByID( qcTVItems[ id ] )
	itemNode := itemNode.parentNode.removeChild( itemNode )
	parentNode := qcconf.GetNodeByID( qcTVItems[ pid ] )
	if ( tid && ( beforeNode := qcconf.GetNodeByID( qcTVItems[ tid ] ) ) )
		parentNode.insertBefore( itemNode, beforeNode )
	else
		parentNode.appendChild( itemNode )
	; TV CHANGES
	isAutorun := qcTVAutorunItems[ id ]
	hasHotkey := qcTVHKItems[ id ]
	props := QC_TVDelProps( id )
	tid_prev := TV_GetPrev( tid )
	prevID := tid ? ( tid_prev ? tid_prev : "First" ) : 0	;determining item after which moved one will be inserted
	newTVID := QC_TVAdd( props.name, PID, prevID " " props.options, itemNode.getAttribute( "ID" ) )
	qcTVAutorunItems[ newTVID ] := isAutorun
	qcTVHKItems[ newTVID ] := hasHotkey
	if props.hasChilds
		QC_BuildTV( newTVID, itemNode, False )
	sleep 1							; for some reason next line require small sleep to be successful :/
	TV_Modify( newTVID, "Select Vis" )
	if ( TV_GetParent( newTVID ) = PID )
		QC_ArrangeTVColors( PID )
	GuiControl, +Redraw,% qcGui[ "main_tv" ]

	return newTVID
}

TVGetIDbyUID( in_uid )
{
	for tvid,uid in qcTVItems
		if( uid = in_uid )
			return tvid
}

; this functions opens QCEditor and selects target item inside it
QCEditItem( item, fActivate = True )
{
  if IsObject( item )
    item_uid := item.uid
	else
		item_uid := item
  QCMainGui( fActivate )
  Gui,1:Default
	tvid := TVGetIDbyUID( item_uid )
	if( tvid )
	{
		if fActivate
			WinWaitActive,% "ahk_id " qcGui[ "main" ],,3
		TV_Modify( tvid, "Select Vis" )
		return
	}
  DTP( "Shortcut not found!" )
  return
}

GUI_Main_TV_Event()
{
  static lastItemID
  if glb[ "TVMenuBuildState" ]
    return
  guiEvent := A_GuiEvent
  eventInfo := A_EventInfo
  Gui,1:Default
  if (guiEvent == "D")
    TVDragDrop(eventInfo)
  if (guiEvent == "K")
  {
    GetKeyState, CtrlH, Ctrl, P
    GetKeyState, UpH, Up, P
    GetKeyState, DownH, Down, P
    GetKeyState, SH, S, P
    GetKeyState, ZH, Z, P
    GetKeyState, XH, X, P
    GetKeyState, DelH, Del, P
    if (CtrlH == "D" && UpH == "D")
      GUI_Main_TV_Move( TV_GetSelection(), "U" )
    if (CtrlH == "D" && DownH == "D")
      GUI_Main_TV_Move( TV_GetSelection(), "D" )
    if (CtrlH = "D" && SH == "D")
      GUI_Main_TV_Add( "sep" )
    if (CtrlH = "D" && ZH == "D")
      GUI_Main_TV_Add( "item" )
    if (CtrlH = "D" && XH == "D")
      GUI_Main_TV_Add( "menu" )
    if (CtrlH != "D" && DelH == "D")
      GUI_Main_TV_Del()
    if ( eventInfo = 93 ) ;context menu call
    {
      if GetKeyState( "SHIFT", "P" )
        eventInfo := 0
      SetTimer, MG_ShowProps, -30
    }
  }
  else if guiEvent in S,RightClick
  {
    if isEmpty( eventInfo )
      return
    if ( guiEvent = "RightClick" )
    {
      if GetKeyState( "SHIFT", "P" )
        eventInfo := 0
      SetTimer, MG_ShowProps, -30
    }
    Gui_Main_LV_Event( "switch", "" )	;this saves shortcut target in case user switch item while command still being edited
    if ( ( !eventInfo || guiEvent = "RightClick" ) && lastItemID != eventInfo )
      SendMessage( qcGui[ "main_tv" ], 0x110B, 0x9, eventInfo )	;selects item
    SendMessage( qcGui[ "main_tv" ], 0x110B, 0x8, eventInfo )		; Show a focus independent selection over item; TVM_SELECTITEM := 0x110B,	TVGN_DROPHILITE := 0x8
    if ( lastItemID != eventInfo )
      Gui_Main_UpdControls( eventInfo )
    lastItemID := eventInfo
    HideFocus(1)						;removes focus border from selected item so it could look pretty
  }
  else if ( guiEvent == "e" && qcTVItems[ eventInfo ] ) ; second check is for case when user deletes items which is being edited
  {
    TV_GetText(ItemNewName, eventInfo)
    qcconf.ItemSetAttr( qcTVItems[ eventInfo ], "name", ItemNewName )
    Gui_Main_UpdControls( eventInfo )
  }
  else if (guiEvent=="DoubleClick")
	{
    if !TV_GetChild( eventInfo )
      SendMessage( qcGui[ "main_tv" ], TVM_EDITLABELW := 0x1100 + 65, 0, eventInfo )
	}
	else if ( guiEvent ~= "\+|\-" ) ;item expanded/collapsed
		GUI_Main_TV_Redraw()
  return
}