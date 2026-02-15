;build main gui TreeView menu
QC_BuildTV( PID, xmlMenuNode = "", DoRedraw = True, topMenu = True )
{
  Gui, 1:Default
  if ( PID = 0 )
    FullRecreate := 1, xmlMenuNode := "main"
  if ( xmlMenuNode = -1 )
    xmlMenuNode := qcconf.GetNodeByID( qcTVItems[ PID ] )
  xmlMenuNode := CheckMenuNode( xmlMenuNode )
  if topMenu
  {
    glb[ "tvIconsSet" ] := object()
    SetTimer( "QC_TV_BuildIcons", "OFF" )
    if DoRedraw
      GuiControl, -Redraw,% qcGui[ "main_tv" ]
    glb[ "TVMenuBuildState" ] := 1	;set this flag to avoid items selection while menu is building
  }
  if FullRecreate
  {
    TV_Delete()
    qcTVItems := { 0 : 0 }	;means 0 itemTVID equals to 0 xml item ID, main menu
    qcTVAutorunItems := {}
    qcTVHKItems := {}
    TV_IL := new MIL()
    SendMessage( qcGui[ "main_tv" ], 0x1100 + 9, 0, TV_IL.Small() )			; TVM_SETIMAGELIST = 0x1100 + 9
  }
  else
    QC_TVCleanMenu( PID )
  Loop
  {
    xmlItemNode := ( A_Index = 1 ) ? xmlMenuNode.firstChild : xmlItemNode.nextSibling
    if !xmlItemNode
      break
    if ( xmlItemNode.nodeName != "item" )	;it may be a 'command' sometimes
      continue
    if xmlItemNode.getAttribute( "issep" )
      item_id := TV_Add( glb[ "separator" ], PID, "Icon" glb[ "BlankIcoNum" ] )
    else
    {
      name := xmlItemNode.getAttribute( "name" )
      icon := xmlItemNode.getAttribute( "icon" )
      isAutorun := xmlItemNode.getAttribute( "autorun" )
      hasHotkey := xmlItemNode.getAttribute( "hotkey" ) != "" ? 1 : 0
      Bold := xmlItemNode.getAttribute( "bold" ) ? " Bold " : ""
      sub := qcconf.IsMenu( xmlItemNode ) ? 1 : 0
      item_id := TV_Add( name, PID, Bold " Icon" glb[ "BlankIcoNum" ] )
      if icon
        glb[ "tvIconsSet" ].insert( { id : item_id, picon : icon } )
      if sub
        QC_BuildTV( item_id, xmlItemNode, False, False )
    }
    qcTVItems[ item_id ] := xmlItemNode.getAttribute( "ID" )
    if (isAutorun)
      qcTVAutorunItems[ item_id ] := 1
    if (hasHotkey)
      qcTVHKItems[ item_id ] := 1
  }
  if FullRecreate
  {
    QC_ArrangeTVColors()
    GUI_Main_TV_ToggleColors( qcOpt[ "main_tv_defColors" ] )
  }
  if topMenu
  {
    QC_ArrangeTVColors( PID )
    glb[ "TVMenuBuildState" ] := 0
    if DoRedraw
      GuiControl, +Redraw,% qcGui[ "main_tv" ]
    SetTimer( "QC_TV_BuildIcons", 10 )
  }
  return
}

; function which adds icons to TV 
QC_TV_BuildIcons( p* )
{
  SetTimer( A_ThisFunc, "OFF" )
  for i,par in glb[ "tvIconsSet" ]
  {
    if ( iicon := TV_IL.Add( par.picon ) )
      TV_Modify( par.id, "Icon" iicon )
    sleep -1 ;check message queue
  }
  glb[ "tvIconsSet" ] := object()
  return
}

QC_ArrangeTVColors( itemID=0, updateTV=False )
{
  sleep -1
  itemNode := qcconf.ItemResolve( qcTVItems[ itemID ] )
  if ( itemID = 0 )	;full menu recalculate
  {
    TV_CL := object()
    TV_CL[-1,"mtc"] := RGBtoBGR( glb[ "defTColor" ] )		;used for default colors when enabled options "Use Default List Colors"
    TV_CL[-1,"mbgc"] := RGBtoBGR( glb[ "defBgColor" ] )
  }
  else
  {
    TV_CL[ itemID, "tc"] := RGBtoBGR( NodeGetColor( "tcolor", itemNode ) )
    TV_CL[ itemID, "bgc"] := RGBtoBGR( NodeGetColor( "bgcolor", itemNode ) )
  }
  Gui, 1:Default
  childID := TV_GetChild( itemID )
  if ( childID || itemID = 0 )	;if item has childs or it is a top menu without items
  {
    TV_CL[ itemID, "mtc"] := RGBtoBGR( NodeGetColor( "mtcolor", itemNode, True ) )
    TV_CL[ itemID, "mbgc"] := RGBtoBGR( NodeGetColor( "mbgcolor", itemNode, True ) )
  }
  if childID	;setting color for all childs recursively
    loop 
    {
      QC_ArrangeTVColors( childID )
    } until !( childID := TV_GetNext( childID ) )
  if updateTV
    GUI_Main_TV_Redraw()
  return
}

GUI_Main_TV_Redraw()
{
  SetTimer( "TV_Redraw", 10 )
  return
}
TV_Redraw( p* )
{
  SetTimer( A_ThisFunc, "OFF" )
  GuiControl, -Redraw,% qcGui[ "main_tv" ]
  GuiControl, +Redraw,% qcGui[ "main_tv" ]
  ;probbly delete it later, it cause window to blink on redraw
  ;~ if IsWindowVisible( qcGui[ "main_tv" ] ) ; avoiding the case when QC editor closed very fast after opening
    ;~ GuiControl, MoveDraw,% qcGui[ "main_tv" ]
  return
}

GUI_Main_TV_CustomDraw( hNMTVCUSTOMDRAW )
{
  static CDDS_PREPAINT := 0x00000001
        ,CDRF_NOTIFYITEMDRAW := 0x00000020
        ,CDDS_ITEMPREPAINT := 0x00010001
        ,CDRF_NOTIFYPOSTPAINT := 0x00000010
        ,CDRF_DODEFAULT := 0
        ,CDRF_SKIPDEFAULT := 0x00000004
        ,CDDS_ITEMPOSTPAINT := 0x00010002
  critical
  tvcd := hNMTVCUSTOMDRAW
;~ typedef struct tagNMTVCUSTOMDRAW {

  ;~ NMHDR     hdr;					0
  ;~ DWORD     dwDrawStage;			3ptr
  ;~ HDC       hdc;					4ptr
  ;~ RECT      rc;					5ptr
  ;~ DWORD_PTR dwItemSpec;			16+5ptr
  ;~ UINT      uItemState;			16+6ptr
  ;~ LPARAM    lItemlParam;			16+7ptr

  ;~ COLORREF     clrText;			16+8ptr
  ;~ COLORREF     clrTextBk;		20+8ptr
;~ #if (_WIN32_IE >= 0x0400)
  ;~ int          iLevel;			24+8ptr
;~ #endif 
;~ } NMTVCUSTOMDRAW, *LPNMTVCUSTOMDRAW;
  dstage := NumGet(tvcd+0, 3*A_PtrSize, "UInt")
  if (dstage = CDDS_PREPAINT)
    return CDRF_NOTIFYITEMDRAW
  hdc := NumGet(tvcd+0, 4*A_PtrSize, "UPtr")
  itemID := NumGet(tvcd+0,5*A_PtrSize+16,"UPtr")
  itemState := NumGet(tvcd+0,6*A_PtrSize+16,"UInt")
  isSelected := itemState & 0x0001
  isAutorunItem := qcTVAutorunItems[ itemID ]
  hasHotkey := qcTVHKItems[ itemID ]
  pRECT := tvcd + 5*A_PtrSize
  top := NumGet( pRECT + 0, 4, "UInt" )
  right := NumGet( pRECT + 0, 8, "UInt" )
  bottom := NumGet( pRECT + 0, 12, "UInt" )
  Gui, 1:Default
  pid := TV_GetParent( itemID )
  tc := qcOpt[ "main_tv_defColors" ] ? TV_CL[ -1, "mtc" ] 	;if default TV colors setting is on
        : !IsEmpty( TV_CL[ itemID, "tc" ] ) ? TV_CL[ itemID, "tc" ]	;if item has specific color - set it
        : !IsEmpty( TV_CL[ pid, "mtc" ]	) ? TV_CL[ pid, "mtc" ] ;else - set color of the menu
        : TV_CL[ ppid := TV_GetParent( pid ), "mtc" ] ;happens when adding new menu (colors for current menu where not set yet)
  bgc := qcOpt[ "main_tv_defColors" ] ? TV_CL[ -1, "mbgc" ]
        : !IsEmpty( TV_CL[ itemID, "bgc" ] ) ? TV_CL[ itemID, "bgc" ]
        : !IsEmpty( TV_CL[ pid, "mbgc" ] ) ? TV_CL[ pid, "mbgc" ] 
        : TV_CL[ ppid, "mbgc" ] ;see comment above
  NumPut( tc, tvcd+0, 8*A_PtrSize+16, "UInt" )
  NumPut( bgc, tvcd+0, 8*A_PtrSize+20, "UInt" )
  if ( ( isSelected || isAutorunItem || hasHotkey ) && dstage = CDDS_ITEMPREPAINT )
    return CDRF_NOTIFYPOSTPAINT
  if ( dstage == CDDS_ITEMPOSTPAINT )
  {
    if (isSelected)
    {      
      ; drawing frame & arrow with contrast colors
      InflateRect( pRECT, 0, 0 )
      clr := bgc > 0xffffff/2 ? 0x000000 : 0xFFFFFF
      FrameRect( hdc, pRECT, clr )
      arrHeight := round((bottom-top)*0.8)
      arrY := top+(bottom-top-arrHeight)/2
      Gdip_DrawArrow( hdc, right-15,arrY, 15, arrHeight, clr, "right" )
    }
    if ( isAutorunItem )
    {
      icoY := top+(bottom-top-16)/2
      pumAPI.DrawIconEx( hdc, right-35, icoY, glb[ "hIcoTLBprop_autorun" ] )
    }
    if ( hasHotkey )
    {
      icoY := top+(bottom-top-16)/2
      pumAPI.DrawIconEx( hdc, right-55, icoY, glb[ "hIcoPropsHotkey16" ] )
    }
  }
  return CDRF_DODEFAULT
}

GUI_Main_TV_ToggleColors( state )
{
  TV_Bg_Color := state ? glb[ "defBgColor" ] : NodeGetColor( "mbgcolor", qcconf.GetMenuNode() )
  TV_T_Color := state ? glb[ "defTColor" ] : NodeGetColor( "mtcolor", qcconf.GetMenuNode() )
  Gui_Main_TV_SetColor( TV_Bg_Color, "mbg" )
  Gui_Main_TV_SetColor( TV_T_Color, "mt" )
  GUI_Main_TV_Redraw()
  return
}

Gui_Main_TV_SetColor( clr, colorType )
{
  if colorType not in mt,mbg
    ShowExc( "Second parameter must be 'mt' or 'mbg', passed: " colorType )
  clr := RGBtoBGR( clr )
  if ( colorType = "mbg" )
    SendMessage( qcGui[ "main_tv" ], 0x1100 + 29, 0, clr )			;Private Const TVM_SETBKCOLOR As Long = (TV_FIRST + 29)	
  else
    SendMessage( qcGui[ "main_tv" ], 0x1100 + 30, 0, clr )			;Private Const TVM_SETTEXTCOLOR As Long = (TV_FIRST + 30)		
    ,SendMessage( qcGui[ "main_tv" ], 0x1100 + 37, 0, clr )		;TVM_SETINSERTMARKCOLOR, color of insert mark when dragging = color of text
  return
}

QC_TVCleanMenu( menuID )
{
  return QC_TVDel( menuID, True )
}

/*
Deletes item with specified ID and returns it's properties
Will not delete Icon associated with item
*/
QC_TVDelProps( itemID )
{
  props := QC_TVItemGetProps( itemID )
  QC_TVDel( itemID )
  return props
}

QC_TVDel( itemID, leaveTop = False )
{
  Gui,1:Default
  if ( childID := TV_GetChild( itemID ) )	;if item is menu
    loop
      QC_TVDel( childID )
    until !( childID := TV_GetChild( itemID ) )
  if leaveTop	;do not delete item with passed ID
    return
  qcTVItems.Delete( itemID )
  qcTVAutorunItems.Delete( itemID )
  qcTVHKItems.Delete( itemID )
  TV_CL.Delete( itemID )
  TV_Delete( itemID )
  if !TV_GetChild( 0 )			;in case no items left in the menu
    Gui_Main_UpdControls( 0 )
  return
}

QC_TVAdd( name, PID, options, nitemUID )
{
  glb[ "TVMenuBuildState" ] := 1	;avoid item selection before it was added
  itemID := TV_Add( name, PID, options )
  qcTVItems[ itemID ] := nitemUID
  glb[ "TVMenuBuildState" ] := 0
  return itemID
}

QC_TVItemGetProps( itemID )
{
  gui,1:default
  if !itemID
    return {}
  props := object()
  TV_GetText( itemName, itemID )
  props.name := itemName
  props.hasChilds := TV_GetChild( itemID ) ? 1 : 0
  props.options := " icon" TV_GetIconIndex( qcGui[ "main_tv" ], itemID )+1
                    . ( TV_Get( itemID,"Bold" ) ? " Bold " : "" )
                    . ( TV_Get( itemID,"Expand" ) ? " Expand " : "" )
  return props
}
