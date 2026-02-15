Gui_Main_TVItem_ChangeHotkey()
{
	Gui,1:Default
	itemID := TV_GetSelection()
	orig_hk := GetCustomHotkey( itemID )
	new_hk := CustomHotkey_EditGUI( orig_hk,12 "|" 1,"Set Hotkey" )
	if (new_hk == orig_hk)
		return
	
	SetCustomHotkey( itemID, new_hk )
	Gui_Main_TlbProp_SetHotkey( itemID )
	return
}

Gui_Main_TVItem_SetMenuRandColors()
{
	Gui, 1:Default
	ItemId := TV_GetSelection()
	if !TV_GetChild( ItemId )
		return
	Gui_Main_TVItem_SetColor( "mt", ItemID, tc := RandColor() )
	Gui_Main_TVItem_SetColor( "mbg", ItemID, bgc := RandColor() )
	if ( itemID = 0 && !qcOpt[ "main_tv_defColors" ] ) 
	{
		Gui_Main_TV_SetColor( tc,"mt" )
		Gui_Main_TV_SetColor( bgc,"mbg" )
	}
	QC_ArrangeTVColors( ItemID, True )
	return
}

Gui_Main_TVItem_ChangeColorMenu( colorType, tlbButtonPos )
{
	static menu_created, s_colorType
	s_colorType := colorType
	if !menu_created
	{
		Menu, TVItem_MenuColorsOpt_menu, add, Change Item Color, ItemColorChange
		Menu, TVItem_MenuColorsOpt_menu, add, Change Menu Color, MenuColorChange
		Menu, TVItem_MenuColorsOpt_menu, add, Reset Item Color, ItemColorReset
		Menu, TVItem_MenuColorsOpt_menu, add, Reset Menu Color, MenuColorReset
		
		Menu, TVItem_MenuColorsOpt_item, add, Change Item Color, ItemColorChange
		Menu, TVItem_MenuColorsOpt_item, add, Reset Item Color, ItemColorReset
		
		Menu, TVItem_MenuColorsOpt_topmenu, add, Change Menu Color, MenuColorChange
		Menu, TVItem_MenuColorsOpt_topmenu, add, Reset Menu Color, MenuColorReset
		menu_created := 1
	}
	; getting coordinates where to show menu
	ControlGetPos,x,y,w,h,,% "ahk_id " qcGui[ "main_tlbprop" ]
	p := StrSplit(Toolbar_GetRect( qcGui[ "main_tlbprop" ], tlbButtonPos ), " " )
	x += p[1], y += p[2]
	CoordMode,Menu,Relative
	Gui,1:Default
	menuID := TV_GetSelection()
	if ( menuID = 0 )																				;top menu selected
		Menu,TVItem_MenuColorsOpt_topmenu,Show,% X,% y+p[4]
	else if TV_GetChild( menuID )															;any menu selected
		Menu,TVItem_MenuColorsOpt_menu,Show,% X,% y+p[4]
	else																									;item selected
		Menu,TVItem_MenuColorsOpt_item,Show,% X,% y+p[4]
	return
	
	MenuColorChange:
		Gui_Main_TVItem_ChangeColor( "m" s_colorType )
		return
	ItemColorChange:
		Gui_Main_TVItem_ChangeColor( s_colorType )
		return
	ItemColorReset:
		Gui_Main_TVItem_ChangeColor( s_colorType, True )
		return
	MenuColorReset:
		Gui_Main_TVItem_ChangeColor( "m" s_colorType, True )
		return
}

Gui_Main_TVItem_ChangeColor( colorType, toDefault = False )
{
	global hPropsGui
	
	Gui, 1:Default
	if colorType not in t,bg,mt,mbg
		ShowExc( "wrong color type passed: " colorType )
	ItemID := TV_GetSelection()
	if toDefault
		Gui_Main_TVItem_SetColor( colorType, itemID, "" )
		,upd := 1
	else
	{
		curColor := Gui_Main_TVItem_GetColor( colorType, itemID )
		Gui, 1:+Disabled
		if Dlg_Color( curColor, hPropsGui )
			Gui_Main_TVItem_SetColor( colorType, itemID, curColor )
			,upd := 1
	}
	if upd
	{
		if ( ItemID = 0 && !qcOpt[ "main_tv_defColors" ] )			;if changing colors of topmost menu - change color of TV bg
		{
			newColor := NodeGetColor( colorType = "mt" ? "mtcolor" : "mbgcolor"
														, qcconf.GetMenuNode() )
			Gui_Main_TV_SetColor( newColor, colorType )
		}
		QC_ArrangeTVColors( ItemID, True )
	}
	Gui, 1:-Disabled
	return
}

Gui_Main_TVItem_GetIcon( itemID )
{
	return qcconf.ItemGetAttr( qcTVItems[ itemID ], "icon" )
}

Gui_Main_TVItem_SetIcon( itemID, icon )
{
	return qcconf.ItemSetAttr( qcTVItems[ itemID ], "icon", icon )
}

Gui_Main_TVItem_GetBold( itemID )
{
	return qcconf.ItemGetAttr( qcTVItems[ itemID ], "bold" )
}

Gui_Main_TVItem_SetBold( itemID, state )
{
	return qcconf.ItemSetAttr( qcTVItems[ itemID ], "bold", state )
}

Gui_Main_TVItem_GetAutorun( itemID )
{
	return qcconf.ItemGetAttr( qcTVItems[ itemID ], "autorun" )
}

Gui_Main_TVItem_SetAutorun( itemID, state )
{
	return qcconf.ItemSetAttr( qcTVItems[ itemID ], "autorun", state )
}

Gui_Main_TVItem_GetColor( colorType, itemID )
{
	return qcconf.ItemGetAttr( qcTVItems[ itemID ], TVItem_GetColorByType( colorType ) )
}

Gui_Main_TVItem_SetColor( colorType, itemID, newColor )
{
	return qcconf.ItemSetAttr( qcTVItems[ itemID ], TVItem_GetColorByType( colorType ), newColor )
}

TVItem_GetColorByType( colType )
{
	return colType = "t" ? "tcolor"
				: colType = "mt" ? "mtcolor"
				: colType = "mbg" ? "mbgcolor"
				: colType = "bg" ? "bgcolor" : ShowExc( "Wrong color type: " colType )
}

SetCustomHotkey( ID, hotkey ) {
	qcconf.ItemSetAttr( qcTVItems[ ID ], "hotkey", hotkey )
}

GetCustomHotkey( ID ) {
	return qcconf.ItemGetAttr( qcTVItems[ id ], "hotkey" )
}