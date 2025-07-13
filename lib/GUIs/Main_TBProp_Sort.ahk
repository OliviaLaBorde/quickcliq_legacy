Gui_Main_TVItem_SortMenu( tbButtonPos )
{
	static s_menuCreated
	if !s_menuCreated
	{
		Menu, QCMenuSort, add, Alpha, QCSortAlpha
		Menu, QCMenuSort, add, Random, QCSortRandom
		Menu, QCMenuSort, add, Alpha Menus Top, QCSortMenusTop
		Menu, QCMenuSort, add, Alpha Menus Bot, QCSortMenusBot
		Menu, QCMenuSort, add, Alpha Rev, QCSortRev
		Menu, QCMenuSort, add, Alpha Rev Menus Top, QCSortMenusTopRev
		Menu, QCMenuSort, add, Alpha Rev Menus Bot, QCSortMenusBotRev
	}
	ControlGetPos,x,y,w,h,,% "ahk_id " qcGui[ "main_tlbprop" ]
	p := StrSplit(Toolbar_GetRect( qcGui[ "main_tlbprop" ], tbButtonPos ),A_Space)
	CoordMode,Menu,Relative
	Menu,QCMenuSort,Show,% x+p[1],% y+p[4]+p[2]
	return
	
	QCSortAlpha:
	QCSortRandom:
	QCSortMenusTop:
	QCSortMenusBot:
	QCSortRev:
	QCSortMenusTopRev:
	QCSortMenusBotRev:
		Gui,1:Default
		TVID := TV_GetSelection()
		if !TV_GetChild( TVID )
			return
		atl := A_ThisLabel
		sortType := atl = "QCSortAlpha" 			? "F QCSort_Alpha"
							: atl = "QCSortMenusTop" 		? "F QCSort_AlphaMTop"
							: atl = "QCSortMenusBot" 		? "F QCSort_AlphaMBot"
							: atl = "QCSortRev" 				? "F QCSort_AlphaRev"
							: atl = "QCSortMenusTopRev" ? "F QCSort_AlphaRevMTop"
							: atl = "QCSortMenusBotRev" ? "F QCSort_AlphaRevMBot"
							: "Random"
		
		TV_Modify( TVID, "Expand Select" )
		ids := GetMenuIDs( TVID )
		Sort, ids,% sortType
		SetMenuIDs( TVID, ids )
		QC_BuildTV( TVID, -1 )
		return
}

GetMenuIDs( menuID )
{
	xmlNode := qcconf.ItemResolve( qcTVItems[ menuID ] )
	for item in ( items := xmlNode.selectNodes( "item" ) )
		if !qcconf.IsSeparator( item )	;exclude separators from the list
			ids .= ( ids ? "`n" : "" ) item.getAttribute( "ID" )
	return ids
}

SetMenuIDs( menuID, ids )
{
	xmlNode := qcconf.ItemResolve( qcTVItems[ menuID ] )	;getting xml node from ID
	nodes := object()
	separs := object()
	ind := 0
	for node in ( nodesSelection := xmlNode.selectNodes( "item" ) )	;selecting all items from the node
	{
		if !qcconf.IsSeparator( node )
			nodes[ node.getAttribute( "ID" ) ] := node.cloneNode( True )	;saving nodes to array by ID
		else
			separs[ ind ] := node.cloneNode( True )	;saving separatos and their position(index)
		ind++
	}
	nodesSelection.removeAll()	;deleting all selected items
	;append nodes back in sorted order
	for i,id in StrSplit( ids, "`n", A_Space A_Tab "`r" )
		if id
			xmlNode.appendChild( nodes[ id ] )
	;inserting separators back to the same place where they was
	for i,node in separs
	{
		if ( beforeNode := xmlNode.selectSingleNode( "item[" i+1 "]" ) )
			xmlNode.insertBefore( node, beforeNode )
		else
			xmlNode.appendChild( node )
	}
}

QCSort_Alpha( item1, item2 )
{
	name1 := qcconf.ItemResolve( item1 ).getAttribute( "name" )
	name2 := qcconf.ItemResolve( item2 ).getAttribute( "name" )
	return name1 > name2 ? 1 : name1 = name2 ? 0 : -1
}

QCSort_AlphaMTop( item1, item2 )
{
	isMenu1 := qcconf.IsMenu( item1 )
	isMenu2 := qcconf.IsMenu( item2 )
	return isMenu1 && !isMenu2 ? -1 
				: !isMenu1 && isMenu2 ? 1 
				: QCSort_Alpha( item1, item2 )
}

QCSort_AlphaMBot( item1, item2 )
{
	isMenu1 := qcconf.IsMenu( item1 )
	isMenu2 := qcconf.IsMenu( item2 )
	return isMenu1 && !isMenu2 ? 1 
				: !isMenu1 && isMenu2 ? -1 
				: QCSort_Alpha( item1, item2 )
}

QCSort_AlphaRev( item1, item2 )
{
	name1 := qcconf.ItemResolve( item1 ).getAttribute( "name" )
	name2 := qcconf.ItemResolve( item2 ).getAttribute( "name" )
	return name1 > name2 ? -1 : name1 = name2 ? 0 : 1
}

QCSort_AlphaRevMTop( item1, item2 )
{
	isMenu1 := qcconf.IsMenu( item1 )
	isMenu2 := qcconf.IsMenu( item2 )
	return isMenu1 && !isMenu2 ? -1 
				: !isMenu1 && isMenu2 ? 1 
				: QCSort_AlphaRev( item1, item2 )
}

QCSort_AlphaRevMBot( item1, item2 )
{
	isMenu1 := qcconf.IsMenu( item1 )
	isMenu2 := qcconf.IsMenu( item2 )
	return isMenu1 && !isMenu2 ? 1 
				: !isMenu1 && isMenu2 ? -1 
				: QCSort_AlphaRev( item1, item2 )
}