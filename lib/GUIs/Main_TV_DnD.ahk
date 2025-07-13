DragnDrop_TrackWheel(wParam, lParam, msg, hwnd)
{
	DllCall("Comctl32\ImageList_DragShowNolock","Int",0)
	SendMessage( qcGui[ "main_tv" ], 0x111A, 0, 0 ) ; hide insertion mark
	SendMessage( qcGui[ "main_tv" ], 0x110B, 0x9, 0 )	;removing hilite
	SetTimer( "Dnd_RestoreImage", 50 )
}

Dnd_RestoreImage( p* )
{
	SetTimer( A_ThisFunc, "OFF" )
	DllCall("Comctl32\ImageList_DragShowNolock","Int",1 )
}

; function to create drag image list for TV item -
; it looks much better than one created with TVM_CREATEDRAGIMAGE
TV_CreateDragImage( hitem )
{
	Gui,1:Default
	VarSetCapacity( rect, 16, 0 )
	NumPut( hitem, rect, 0, "UPtr" )
	;getting item bounding rectangle
	SendMessage( qcGui[ "main_tv" ], 0x1100 + 4, True, &rect )	;TVM_GETITEMRECT         (TV_FIRST + 4)
	;getting width and height of the image
	TV_GetText( itemText, hitem )
	width := numget( rect, 8, "UInt" ) - numget( rect, 0, "UInt" ) + 16 + 4 + ceil( strLen( itemtext )*0.4 )	;16 pixels for icon and compensation for wider gdip font
	height := numget( rect, 12, "UInt" ) - numget( rect, 4, "UInt" ) + 4
	;getting DC and bitmap
	hDC := GetDC( qcGui[ "main_tv" ] )
	memDC := CreateCompatibleDC( hDC )
	hBitmap := CreateDIBSection(width, Height, hDC)
	ReleaseDC( hDC, qcGui[ "main_tv" ] )
	if !( memDC && hBitmap )
		goto, GetDragImage_cleanup
	hOldBitmap := SelectObject( memDC, hBitmap )
	;gdip functions
	token := Gdip_Startup()
	pGraphics := Gdip_GraphicsFromHDC( memDC )
	;colors gotten from TV are BGR, we need RGB
	tcolor := RGBtoBGR( SendMessage( qcGui[ "main_tv" ], 0x1100 + 32, 0, 0 ) )	;TVM_GETTEXTCOLOR 
	bkcolor := RGBtoBGR( SendMessage( qcGui[ "main_tv" ], 0x1100 + 31, 0, 0 ) ) ;TVM_GETBKCOLOR
	;filling background
	pBrush := Gdip_BrushCreateSolid( 0xFF000000 | bkcolor )
	Gdip_FillRectangle( pGraphics, pBrush, 0, 0, width, height )
	Gdip_DeleteBrush( pBrush )
	;drawing frame around image
	pPen := Gdip_CreatePen( 0xFF000000 | ( ~bkcolor & 0xFFFFFF ), 1 )
	GdipSetPenDashStyle( pPen, 2 )
	Gdip_DrawRectangle( pGraphics, pPen, 0, 0, width-1, height-1 )
	Gdip_DeletePen( pPen )
	;getting font
	if !( hFont := ControlGetFont( qcGui[ "main_tv" ] ) )
	{
		if !( hFont := CreateFontIndirect( GetSysFont( LOGFONT ) ) )
			goto, GetDragImage_cleanup
		delFont := True
	}
	;creating gdip font from logical font
	hOldFont := SelectObject( memDC, hFont )
	hGdipFont := GdipCreateFontFromDC( memDC )
	SelectObject( memDC, hOldFont )
	;drawing text into graphics
	hFormat := Gdip_StringFormatCreate( 0x4000 | 0x1000 )	;NoClip | NoWrap
	pBrush := Gdip_BrushCreateSolid( clr := 0xFF000000 | tcolor )
	CreateRectF( rect, 18, 2, width, height )
	Gdip_SetTextRenderingHint(pGraphics, 5 )
	Gdip_DrawString( pGraphics, itemText, hGdipFont, hFormat, pBrush, rect )
	Gdip_DeleteBrush( pBrush )
	Gdip_DeleteStringFormat( hFormat )
	Gdip_DeleteFont( hGdipFont )
	;drawing icon
	if ( hIcon := IL_GetIcon( TV_IL.Small(), TV_GetIconIndex( qcGui[ "main_tv" ], hitem ) ) )
		DrawIconEx( memDC, 2, 2, hIcon )
	DestroyIcon( hIcon )
	SelectObject( memDC, hOldBitmap )
	;creating drag image list
	if !( hIL := IL_CreateNew( width, height,0,1 ) )
		goto, GetDragImage_cleanup
	IL_AddBitmap( hIL, hBitmap )
GetDragImage_cleanup:
	Gdip_DeleteGraphics( pGraphics )
	if delFont
		DeleteObject( hFont )
	DeleteObject( hBitmap )
	DeleteDC( memDC )
	Gdip_Shutdown( token )
	return hIL
}

TVDragDrop( DraggedItemID )
{
	Gui,1:Default
	Gui, TreeView,% qcGui[ "main_tv" ]
	
	static TVGN_CARET := 0x9,	TVM_HITTEST := 0x1111,	TVM_SELECTITEM := 0x110B,	TVGN_DROPHILITE := 0x8
	,TVM_GETITEMHEIGHT := 0x111C,	TVM_SETINSERTMARK := 0x111A,	TVM_GETITEMRECT := 0x1104
	,TVM_SETINSERTMARKCOLOR := 0x1100 + 37	;TV_FIRST + 37
	,TVM_CREATEDRAGIMAGE := 0x1100 + 18	;TV_FIRST + 18
	,WM_MOUSEWHEEL := 0x20A
	OnMessage(WM_MOUSEWHEEL,"DragnDrop_TrackWheel")
	
	CoordMode, Mouse, Relative
	MouseGetPos,X,Y
	
	hImg_list := TV_CreateDragImage( DraggedItemID )	
	DllCall("Comctl32\ImageList_BeginDrag","Ptr",hImg_list,"Int",0,"Int",0,"Int",0)
	ControlGetPos,,TV_Y,,TV_height,,% "ahk_id " qcGui[ "main_tv" ]
	DllCall("Comctl32\ImageList_DragEnter","Ptr",qcGui[ "main_tv" ],"Int",X,"Int",Y-TV_Y)
	;~ DllCall("ShowCursor","Int",0)
	DllCall( "SetCapture","Ptr", qcGui[ "main" ] )
	height := SendMessage( qcGui[ "main_tv" ], TVM_GETITEMHEIGHT, 0, 0 )
	div := 3
	hlMode := TVGN_CARET
	While GetKeyState("LButton")
	{
		MouseGetPos,X,Y
		if (X != Xpre || Y != Ypre )
		{
			; Create the TVHITTESTINFO struct...
			VarSetCapacity( tvht, 16, 0 )
			NumPut( X, tvht, 0, "int" )
			NumPut( Y-TV_Y, tvht, 4, "int" )

			If ( hitTarget := SendMessage( qcGui[ "main_tv" ], TVM_HITTEST, 0, &tvht ) )
			{
				VarSetCapacity( rcitem, 16, 0 ), NumPut( hitTarget, rcitem )
				SendMessage( qcGui[ "main_tv" ], TVM_GETITEMRECT, 1, &rcitem )
				rcitem_top := NumGet( rcitem, 4, "int" )
				rcitem_bottom := NumGet( rcitem, 12, "int" )
				mark_pos := ( Y - TV_Y - rcitem_top ) <= ( height/div ) ? 0 : ( rcitem_bottom - Y + TV_Y ) <= ( height/div ) ? 1 : "OFF"
				if !( lastHitTarget = hitTarget && lastMarkPos = mark_pos )
					&& !( ( mark_pos = 1 && TV_GetNext( hitTarget ) == lastHitTarget )
							|| ( mark_pos = 0 && TV_GetPrev( hitTarget ) == lastHitTarget ) )
				{
					SendMessage( qcGui[ "main_tv" ], TVM_SETINSERTMARK, 0, 0 ) ; hide insertion mark
					DllCall("Comctl32\ImageList_DragShowNolock","Int",0)
					if mark_pos in 0,1
					{
						SendMessage( qcGui[ "main_tv" ], TVM_SETINSERTMARK, mark_pos, hitTarget ) ; mark_pos = 0 - before,= 1 - after the item	
						SendMessage( qcGui[ "main_tv" ], TVM_SELECTITEM, hlMode, 0 )
					}
					else
						SendMessage( qcGui[ "main_tv" ], TVM_SELECTITEM, hlMode, hitTarget )
					DllCall("Comctl32\ImageList_DragShowNolock","Int",1)
				}
				lastHitTarget := hitTarget
				lastMarkPos := mark_pos
			}
			else
			{
				SendMessage( qcGui[ "main_tv" ], TVM_SETINSERTMARK, 0, 0 ) ; hide insertion mark
				SendMessage( qcGui[ "main_tv" ], TVM_SELECTITEM, hlMode, 0 )	;removing hilite
			}
			sleep 5	;helps avoid redrawing issues
			DllCall("Comctl32\ImageList_DragMove","Int",X,"Int",Y-TV_Y+height)
			Xpre := X
			Ypre := Y
		}
		;following code is for menus auto-expanding
		if ( TV_GetChild( hitTarget ) && hover_target == hitTarget && mark_pos = "off")
		{
			hover_time++
			if (hover_time = 20 && !TV_Get( hitTarget, "Expand" ) )				;consider delay time before expanding menu = hover_time*50 milliseconds, so now it 1000 msec
			{
				DllCall("Comctl32\ImageList_DragShowNolock","Int",0)
				sleep 50
				TV_Modify(hitTarget,"Expand")
				sleep 50
				DllCall("Comctl32\ImageList_DragShowNolock","Int",1)
			}
		}
		else if ( TV_GetChild( hitTarget ) && mark_pos = "off" )
		{
			hover_target := hitTarget
			hover_time =
		}
		else
		{
			hover_time =
			hover_target =
		}
		sleep 50
	}
	; Remove the drop-target highlighting and insertion mark
	SendMessage( qcGui[ "main_tv" ], TVM_SELECTITEM, hlMode, 0 )
	SendMessage( qcGui[ "main_tv" ], TVM_SETINSERTMARK, 0, 0 )
	DllCall("ReleaseCapture")
	DllCall("Comctl32\ImageList_DragLeave","Ptr",qcGui[ "main_tv" ] )
	DllCall("Comctl32\ImageList_EndDrag")
	DllCall("Comctl32\ImageList_Destroy","Ptr",hImg_list)
	;~ DllCall("SetClassLong", "Ptr",qcGui[ "main_tv" ], "int", -12, "int",  TV_oldcursor)
	;~ DllCall("DestroyCursor","Ptr",newcursor)

	;~ If hDroppedTargetID := SendMessage( qcGui[ "main_tv" ], TVM_HITTEST, 0, &tvht )
	If hitTarget
	{
		; Only do stuff if the droptarget is different from the drag item
		If ( DraggedItemID != hitTarget )
		   If !TV_NodeIsDescendant( hitTarget, DraggedItemID )
			  if TV_Get_DragnDropIDs( hitTarget, mark_pos, pPID, beforeID )
				GUI_Main_TV_Move( DraggedItemID, beforeID, pPID )     
	}
	else
		TV_Modify( DraggedItemID )
	OnMessage( WM_MOUSEWHEEL,"" )
	return
}

TV_Get_DragnDropIDs( id, mark, ByRef pid, ByRef beforeID )	;tPID is a parent ID where the dragged item should be placed, PreID is ID of item AFTER which we will place dragged item
{
	Gui, 1:Default
	if ( mark = "OFF" )	;if we going to drop item into the menu with tID
	{
		if qcconf.ItemResolve( qcTVItems[ id ] ).getAttribute( "issep" )
		{
			DTP( "Sorry! You cannot drop an item on separator!", 2000 )
			return 0
		}
		pid := id							;the menu's ID
		beforeID := TV_GetChild( pid )							;means the item will be added on the first position in the menu
	}
	else if ( mark = 1 )					;if we going to drop item after tID
	{
		pid := TV_GetParent( id )
		beforeID := TV_GetNext( id )
	}
	else if ( mark = 0 )					;if we going to drop item before tID
	{
		pid := TV_GetParent( id )
		beforeID := id
	}
	return 1
}

TV_NodeIsDescendant( node, parent )
{
	nextParent := node
	while ( nextParent := TV_GetParent( nextParent ) )
		if ( nextParent = parent )
			return 1
	return 0
}