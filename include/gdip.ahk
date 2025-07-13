Gdip_Startup()
{
	static hmodule
	if ( !hmodule || !DllCall( "GetModuleHandleW", "Wstr", "gdiplus", "UPtr" ) )
        hmodule := DllCall( "LoadLibraryW", "Wstr", "gdiplus", "UPtr" )
	
	VarSetCapacity(GdiplusStartupInput , 3*A_PtrSize, 0), NumPut(1,GdiplusStartupInput ,0,"UInt") ; GdiplusVersion = 1
	DllCall("gdiplus\GdiplusStartup", "Ptr*", pToken, "Ptr", &GdiplusStartupInput, "Ptr", 0)
	return pToken
}

Gdip_Shutdown(pToken)
{
	DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
	return 0
}

Gdip_CreateBitmap(Width, Height, Format=0x26200A)
{
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", 0, "int", Format, "Ptr", 0, "Ptr*", pBitmap)
    Return pBitmap
}

Gdip_GraphicsFromImage(pBitmap)
{
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", pGraphics)
    return pGraphics
}

Gdip_SetSmoothingMode(pGraphics, SmoothingMode)
{
   return DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "int", SmoothingMode)
}

Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
{
   return DllCall("gdiplus\GdipFillRectangle", "Ptr", pGraphics, "Ptr", pBrush
   , "float", x, "float", y, "float", w, "float", h)
}

Gdip_FillRoundedRectangle(pGraphics, pBrush, x, y, w, h, r)
{
	Region := Gdip_GetClipRegion(pGraphics)
	Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
	Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
	Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
	Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
	E := Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
	Gdip_SetClipRegion(pGraphics, Region, 0)
	Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
	Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
	Gdip_FillEllipse(pGraphics, pBrush, x, y, 2*r, 2*r)
	Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y, 2*r, 2*r)
	Gdip_FillEllipse(pGraphics, pBrush, x, y+h-(2*r), 2*r, 2*r)
	Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
	Gdip_SetClipRegion(pGraphics, Region, 0)
	Gdip_DeleteRegion(Region)
	return E
}

Gdip_SetClipRegion(pGraphics, Region, CombineMode=0)
{
	return DllCall("gdiplus\GdipSetClipRegion", "Ptr", pGraphics, "Ptr", Region, "uint", CombineMode)
}

Gdip_CreateRegion()
{
	DllCall("gdiplus\GdipCreateRegion", "Ptr*", Region)
	return Region
}

Gdip_GetClipRegion(pGraphics)
{
	Region := Gdip_CreateRegion()
	DllCall("gdiplus\GdipGetClip", "Ptr" pGraphics, "Ptr*", Region)
	return Region
}

Gdip_SetClipRect(pGraphics, x, y, w, h, CombineMode=0)
{
   return DllCall("gdiplus\GdipSetClipRect", "Ptr", pGraphics, "float", x, "float", y, "float", w, "float", h, "int", CombineMode)
}

Gdip_FillEllipse(pGraphics, pBrush, x, y, w, h)
{
	return DllCall("gdiplus\GdipFillEllipse", "Ptr", pGraphics, "Ptr", pBrush, "float", x, "float", y, "float", w, "float", h)
}

Gdip_DeleteRegion(Region)
{
	return DllCall("gdiplus\GdipDeleteRegion", "Ptr", Region)
}

Gdip_TextToGraphics(pGraphics, Text, Options, Font="Arial", Width="", Height="", Measure=0)
{
	IWidth := Width, IHeight:= Height
	
	RegExMatch(Options, "i)X([\-\d\.]+)(p*)", xpos)
	RegExMatch(Options, "i)Y([\-\d\.]+)(p*)", ypos)
	RegExMatch(Options, "i)W([\-\d\.]+)(p*)", Width)
	RegExMatch(Options, "i)H([\-\d\.]+)(p*)", Height)
	RegExMatch(Options, "i)C(?!(entre|enter))([a-f\d]+)", Colour)
	RegExMatch(Options, "i)Top|Up|Bottom|Down|vCentre|vCenter", vPos)
	RegExMatch(Options, "i)NoWrap", NoWrap)
	RegExMatch(Options, "i)R(\d)", Rendering)
	RegExMatch(Options, "i)S(\d+)(p*)", Size)

	if !Gdip_DeleteBrush(Gdip_CloneBrush(Colour2))
		PassBrush := 1, pBrush := Colour2
	
	if !(IWidth && IHeight) && (xpos2 || ypos2 || Width2 || Height2 || Size2)
		return -1

	Style := 0, Styles := "Regular|Bold|Italic|BoldItalic|Underline|Strikeout"
	Loop, Parse, Styles, |
	{
		if RegExMatch(Options, "\b" A_loopField)
		Style |= (A_LoopField != "StrikeOut") ? (A_Index-1) : 8
	}
  
	Align := 0, Alignments := "Near|Left|Centre|Center|Far|Right"
	Loop, Parse, Alignments, |
	{
		if RegExMatch(Options, "\b" A_loopField)
			Align |= A_Index//2.1      ; 0|0|1|1|2|2
	}

	xpos := (xpos1 != "") ? xpos2 ? IWidth*(xpos1/100) : xpos1 : 0
	ypos := (ypos1 != "") ? ypos2 ? IHeight*(ypos1/100) : ypos1 : 0
	Width := Width1 ? Width2 ? IWidth*(Width1/100) : Width1 : IWidth
	Height := Height1 ? Height2 ? IHeight*(Height1/100) : Height1 : IHeight
	if !PassBrush
		Colour := "0x" (Colour2 ? Colour2 : "ff000000")
	Rendering := ((Rendering1 >= 0) && (Rendering1 <= 5)) ? Rendering1 : 4
	Size := (Size1 > 0) ? Size2 ? IHeight*(Size1/100) : Size1 : 12

	hFamily := Gdip_FontFamilyCreate(Font)
	hFont := Gdip_FontCreate(hFamily, Size, Style)
	FormatStyle := NoWrap ? 0x4000 | 0x1000 : 0x4000
	hFormat := Gdip_StringFormatCreate(FormatStyle)
	pBrush := PassBrush ? pBrush : Gdip_BrushCreateSolid(Colour)
	if !(hFamily && hFont && hFormat && pBrush && pGraphics)
		return !pGraphics ? -2 : !hFamily ? -3 : !hFont ? -4 : !hFormat ? -5 : !pBrush ? -6 : 0
   
	CreateRectF(RC, xpos, ypos, Width, Height)
	Gdip_SetStringFormatAlign(hFormat, Align)
	Gdip_SetTextRenderingHint(pGraphics, Rendering)
	ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)

	if vPos
	{
		StringSplit, ReturnRC, ReturnRC, |
		
		if (vPos = "vCentre") || (vPos = "vCenter")
			ypos += (Height-ReturnRC4)//2
		else if (vPos = "Top") || (vPos = "Up")
			ypos := 0
		else if (vPos = "Bottom") || (vPos = "Down")
			ypos := Height-ReturnRC4
		
		CreateRectF(RC, xpos, ypos, Width, ReturnRC4)
		ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)
	}

	if !Measure
		E := Gdip_DrawString(pGraphics, Text, hFont, hFormat, pBrush, RC)

	if !PassBrush
		Gdip_DeleteBrush(pBrush)
	Gdip_DeleteStringFormat(hFormat)   
	Gdip_DeleteFont(hFont)
	Gdip_DeleteFontFamily(hFamily)
	return E ? E : ReturnRC
}

Gdip_DrawString(pGraphics, sString, hFont, hFormat, pBrush, ByRef RectF)
{
	if !A_IsUnicode
	{
		nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "Ptr", &sString, "int", -1, "Ptr", 0, "int", 0)
		VarSetCapacity(wString, nSize*2)
		DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "Ptr", &sString, "int", -1, "Ptr", &wString, "int", nSize)
		return DllCall("gdiplus\GdipDrawString", "Ptr", pGraphics
		, "Ptr", &wString, "int", -1, "Ptr", hFont, "Ptr", &RectF, "Ptr", hFormat, "Ptr", pBrush)
	}
	else
	{
		return DllCall("gdiplus\GdipDrawString", "Ptr", pGraphics
		, "Ptr", &sString, "int", -1, "Ptr", hFont, "Ptr", &RectF, "Ptr", hFormat, "Ptr", pBrush)
	}	
}

Gdip_MeasureString(pGraphics, sString, hFont, hFormat, ByRef RectF)
{
	VarSetCapacity(RC, 16)
	if !A_IsUnicode
	{
		nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "Ptr", &sString, "int", -1, "Ptr", 0, "int", 0)
		VarSetCapacity(wString, nSize*2)   
		DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "Ptr", &sString, "int", -1, "Ptr", &wString, "int", nSize)
		DllCall("gdiplus\GdipMeasureString", "Ptr", pGraphics
		, "Ptr", &wString, "int", -1, "Ptr", hFont, "Ptr", &RectF, "Ptr", hFormat, "Ptr", &RC, "uint*", Chars, "uint*", Lines)
	}
	else
	{
		DllCall("gdiplus\GdipMeasureString", "Ptr", pGraphics
		, "Ptr", &sString, "int", -1, "Ptr", hFont, "Ptr", &RectF, "Ptr", hFormat, "Ptr", &RC, "uint*", Chars, "uint*", Lines)
	}
	return &RC ? NumGet(RC, 0, "float") "|" NumGet(RC, 4, "float") "|" NumGet(RC, 8, "float") "|" NumGet(RC, 12, "float") "|" Chars "|" Lines : 0
}

Gdip_SetTextRenderingHint(pGraphics, RenderingHint)
{
	return DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", pGraphics, "int", RenderingHint)
}

Gdip_SetStringFormatAlign(hFormat, Align)
{
   return DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", hFormat, "int", Align)
}

CreateRectF(ByRef RectF, x, y, w, h)
{
   VarSetCapacity(RectF, 16)
   NumPut(x, RectF, 0, "float"), NumPut(y, RectF, 4, "float"), NumPut(w, RectF, 8, "float"), NumPut(h, RectF, 12, "float")
}

/* StringFormatFlagsDirectionRightToLeft    = 0x00000001,
StringFormatFlagsDirectionVertical       = 0x00000002,
StringFormatFlagsNoFitBlackBox           = 0x00000004,
StringFormatFlagsDisplayFormatControl    = 0x00000020,
StringFormatFlagsNoFontFallback          = 0x00000400,
StringFormatFlagsMeasureTrailingSpaces   = 0x00000800,
StringFormatFlagsNoWrap                  = 0x00001000,
StringFormatFlagsLineLimit               = 0x00002000,
StringFormatFlagsNoClip                  = 0x00004000 
 */
Gdip_StringFormatCreate(Format=0, Lang=0)
{
   DllCall("gdiplus\GdipCreateStringFormat", "int", Format, "int", Lang, "Ptr*", hFormat)
   return hFormat
}

Gdip_FontCreate(hFamily, Size, Style=0)
{
   DllCall("gdiplus\GdipCreateFont", "Ptr", hFamily, "float", Size, "int", Style, "int", 0, "Ptr*", hFont)
   return hFont
}

Gdip_FontFamilyCreate(Font)
{
	if !A_IsUnicode
	{
		nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "Ptr", &Font, "int", -1, "Ptr", 0, "int", 0)
		VarSetCapacity(wFont, nSize*2)
		DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, "Ptr", &Font, "int", -1, "Ptr", &wFont, "int", nSize)
		DllCall("gdiplus\GdipCreateFontFamilyFromName", "Ptr", &wFont, "Ptr", 0, "Ptr*", hFamily)
	}
	else
		DllCall("gdiplus\GdipCreateFontFamilyFromName", "Ptr", &Font, "Ptr", 0, "Ptr*", hFamily)
	return hFamily
}

Gdip_CreateHBITMAPFromBitmap(pBitmap, Background=0xffffffff)
{
	DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hbm, "int", Background)
	return hbm
}

SetImage(hwnd, hBitmap)
{
	SendMessage, 0x172, 0x0, hBitmap,, ahk_id %hwnd%
	E := ErrorLevel
	DeleteObject(E)
	return E
}

DeleteObject( hObj )
{
  return DllCall( "DeleteObject", "Ptr", hObj )
}

SelectObject( hDC, hObj )
{
  return DllCall( "SelectObject", "Ptr", hDC, "Ptr", hObj )
}

GetDC( hwnd = 0 )
{
  return DllCall( "GetDC", "Ptr", hwnd )
}

GetTextExtentPoint32( hDC, string )
{
  VarSetCapacity( pSize, 8, 0 )
  DllCall( "GetTextExtentPoint32W", "Ptr", hDC, "Ptr", &string, "UInt", StrLen( string ), "Ptr", &pSize )
  size := object()
  size[ "cx" ] := NumGet( &pSize, 0, "UInt" )
  size[ "cy" ] := NumGet( &pSize, 4, "UInt" )
  return size
}

ExcludeClipRect( hDC, left, top, right, bottom )
{
  return DllCall( "ExcludeClipRect"
          , "Ptr", hDC
          , "Int", left
          , "Int", top
          , "Int", right
          , "Int", bottom )
}

SetBkColor( hDC, clr )
{
  return DllCall( "SetBkColor", "Ptr", hDC, "UInt", clr )
}

FrameRect( hDC, pRect, clr )
{
  ret := DllCall( "FrameRect"
                , "Ptr", hDC
                , "Ptr", pRECT
                , "Ptr", hBrush := CreateSolidBrush( clr ) )
  DeleteObject( hBrush )
  return ret
}

InflateRect( pRECT, x, y )
{
  return DllCall( "InflateRect", "Ptr", pRECT, "int", x, "int", y )
}

DrawEdge( hDC, pRECT )
{
  return DllCall( "DrawEdge"
                , "Ptr", hDC
                , "Ptr", pRECT
                , "UInt", (0x0002 | 0x0004)
                , "UInt", 0x0002 )
}

SetTextColor( hDC, clr )
{
  return DllCall( "SetTextColor", "Ptr", hDC, "UInt", clr )
}

DeleteDC( hDC )
{
  return DllCall( "DeleteDC", "Ptr", hDC )
}

ReleaseDC( hDC, hWnd = 0 )
{
  return DllCall( "ReleaseDC", "Ptr", hWnd, "Ptr", hDC )
}

BitBlt( hdcDest, nXDest, nYDest, nWidth, nHeight, hdcSrc, nXSrc, nYSrc, dwRop )
{
  return DllCall( "BitBlt"
                , "Ptr", hdcDest
                , "UInt",nXDest
        , "UInt",nYDest
        , "UInt",nWidth
        , "UInt",nHeight
        , "Ptr", hdcSrc
        , "UInt",nXSrc
        , "UInt",nYSrc
        , "UInt",dwRop )
}

FillRect( hDC, pRECT, Clr )
{
  ret := DllCall( "FillRect", "Ptr", hDC, "Ptr", pRECT, "Ptr", hBrush := CreateSolidBrush( Clr ) )
  DeleteObject( hBrush )
  return ret
}

CreateCompatibleDC( hDC )
{
  return DllCall( "CreateCompatibleDC", "Ptr", hDC )
}

CreateCompatibleBitmap( hDC, w, h )
{
  return DllCall( "CreateCompatibleBitmap", "Ptr", hDC, "UInt", w, "Uint", h )
}

SetRect( ByRef rect, left, top, right, bottom )
{
  VarSetCapacity( rect, 16, 0 )
  return DllCall( "SetRect", "Ptr", &rect, "UInt", left, "UInt", top, "UInt", right, "UInt", bottom )
}

DrawFrameControl( hDC, pRECT, uType, uState )
{
  return DllCall( "DrawFrameControl", "Ptr", hDC, "Ptr", pRECT, "UInt", uType, "UInt", uState )
}

GetSysColorBrush( nIndex )
{
  return DllCall( "GetSysColorBrush", "UInt", nIndex )
}

CreateSolidBrush( clr )
{
  return DllCall( "CreateSolidBrush", "Uint", clr )
}

CreatePen( width, color, style=0 )  ;0 means solid
{
  return DllCall( "CreatePen", "int", style, "int", width, "UInt", color, "UPtr" )
}

GetObject( hObj,ByRef buf )
{
  if bufSize := DllCall( "GetObject", "Ptr", hObj, "UInt", 0, "Ptr", 0 )
  {
    VarSetCapacity( buf, bufSize, 0 )
    DllCall( "GetObject", "Ptr", hObj, "UInt", bufSize, "Ptr", &buf )
  }
  else
    return 0
  return 1
}

PatBlt( hDC, clr, rect )
{
  hBrush := CreateSolidBrush( clr )
  hOldBrush := SelectObject( hDC, hBrush )
  if IsObject( rect )
    x := rect.left, y := rect.top, w := rect.right - rect.left, h := rect.bottom - rect.top
  else if IsInteger( rect )
  {
    x := NumGet( rect+0, 0, "UInt" )
    y := NumGet( rect+0, 4, "UInt" )
    w := NumGet( rect+0, 8, "UInt" ) - x
    h := NumGet( rect+0, 12, "UInt" ) - y
  }
  else
    return 0
  ret := DllCall( "PatBlt", "Ptr", hDC, "int", x, "int", y, "int", w, "int", h, "Uint", 0x005A0049 )
  SelectObject( hDC, hOldBrush )
  DeleteObject( hBrush )
  return ret
}

Polyline( hDC, arrPOINT )
{
  if !IsObject( arrPOINT )
    return 0
  points_num := arrPOINT.MaxIndex()
  VarSetCapacity( sPOINTS, 8*points_num, 0 )
  for i,point in arrPOINT
  {
    NumPut( point.x, sPOINTS, 4*( A_Index*2 - 2 ), "UInt" )
    NumPut( point.y, sPOINTS, 4*( A_Index*2 - 1 ), "UInt" )
  }
  return DllCall( "Polyline", "Ptr", hDC, "Ptr", &sPOINTS, "Int", points_num )
}

DrawText( hDC, text, pRect, flags )
{
  return DllCall( "DrawTextExW"
                  ,"Ptr", hDC
                  , "wstr", text
                  , "Uint", -1
                  , "Ptr", pRect
                  , "Uint", flags
                  , "Ptr", 0 )
}

;#####################################################################################

; Function				CreateDIBSection
; Description			The CreateDIBSection function creates a DIB (Device Independent Bitmap) that applications can write to directly
;
; w						width of the bitmap to create
; h						height of the bitmap to create
; hdc					a handle to the device context to use the palette from
; bpp					bits per pixel (32 = ARGB)
; ppvBits				A pointer to a variable that receives a pointer to the location of the DIB bit values
;
; return				returns a DIB. A gdi bitmap
;
; notes					ppvBits will receive the location of the pixels in the DIB

CreateDIBSection(w, h, hdc="", bpp=32, ByRef ppvBits=0)
{
	hdc2 := hdc ? hdc : GetDC()
	VarSetCapacity(bi, 40, 0)
	NumPut(w, bi, 4, "UInt" ), NumPut(h, bi, 8, "UInt" ), NumPut(40, bi, 0, "UInt" ), NumPut(1, bi, 12, "ushort"), NumPut(0, bi, 16, "UInt" ), NumPut(bpp, bi, 14, "ushort")
	hbm := DllCall("CreateDIBSection", "Ptr" , hdc2, "Ptr" , &bi, "uint" , 0, "Ptr*", ppvBits, "Ptr" , 0, "uint" , 0)

	if !hdc
		ReleaseDC(hdc2)
	return hbm
}

;#####################################################################################

; Function				Gdip_GraphicsFromHDC
; Description			This function gets the graphics from the handle to a device context
;
; hdc					This is the handle to the device context
;
; return				returns a pointer to the graphics of a bitmap
;
; notes					You can draw a bitmap into the graphics of another bitmap

Gdip_GraphicsFromHDC( hdc )
{
    DllCall("gdiplus\GdipCreateFromHDC", "Ptr", hdc, "Ptr*", pGraphics)
    return pGraphics
}

GdipCreateFontFromLogfont( hdc, logfont )
{
	DllCall( "gdiplus\GdipCreateFontFromLogfont", "ptr", hdc, "ptr", &logfont, "ptr*", hFont )
	return hFont
}

GdipCreateFontFromDC( hdc )
{
	DllCall( "gdiplus\GdipCreateFontFromDC", "ptr", hdc, "ptr*", hFont )
	return hFont
}

CreatePointF(ByRef PointF, x, y)
{
   VarSetCapacity(PointF, 8)
   NumPut(x, PointF, 0, "float"), NumPut(y, PointF, 4, "float")     
}

/*   
DashStyleSolid        = 0,
DashStyleDash         = 1,
DashStyleDot          = 2,
DashStyleDashDot      = 3,
DashStyleDashDotDot   = 4,
DashStyleCustom       = 5  
*/
GdipSetPenDashStyle( pPen, dashstyle )
{
	return DllCall( "gdiplus\GdipSetPenDashStyle", "ptr", pPen, "UInt", dashstyle )
}

;#####################################################################################

; Function				Gdip_DrawRectangle
; Description			This function uses a pen to draw the outline of a rectangle into the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pPen					Pointer to a pen
; x						x-coordinate of the top left of the rectangle
; y						y-coordinate of the top left of the rectangle
; w						width of the rectanlge
; h						height of the rectangle
;
; return				status enumeration. 0 = success
;
; notes					as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width

Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
{
   return DllCall("gdiplus\GdipDrawRectangle", "ptr", pGraphics, "ptr", pPen, "float", x, "float", y, "float", w, "float", h)
}

;#####################################################################################

; Function				Gdip_DrawRoundedRectangle
; Description			This function uses a pen to draw the outline of a rounded rectangle into the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pPen					Pointer to a pen
; x						x-coordinate of the top left of the rounded rectangle
; y						y-coordinate of the top left of the rounded rectangle
; w						width of the rectanlge
; h						height of the rectangle
; r						radius of the rounded corners
;
; return				status enumeration. 0 = success
;
; notes					as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width

Gdip_DrawRoundedRectangle(pGraphics, pPen, x, y, w, h, r)
{
	Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
	Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
	Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
	Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
	E := Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
	Gdip_ResetClip(pGraphics)
	Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
	Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
	Gdip_DrawEllipse(pGraphics, pPen, x, y, 2*r, 2*r)
	Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y, 2*r, 2*r)
	Gdip_DrawEllipse(pGraphics, pPen, x, y+h-(2*r), 2*r, 2*r)
	Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
	Gdip_ResetClip(pGraphics)
	return E
}

;#####################################################################################

; Function				Gdip_DrawEllipse
; Description			This function uses a pen to draw the outline of an ellipse into the Graphics of a bitmap
;
; pGraphics				Pointer to the Graphics of a bitmap
; pPen					Pointer to a pen
; x						x-coordinate of the top left of the rectangle the ellipse will be drawn into
; y						y-coordinate of the top left of the rectangle the ellipse will be drawn into
; w						width of the ellipse
; h						height of the ellipse
;
; return				status enumeration. 0 = success
;
; notes					as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width

Gdip_DrawEllipse(pGraphics, pPen, x, y, w, h)
{
   return DllCall("gdiplus\GdipDrawEllipse", "ptr", pGraphics, "ptr", pPen, "float", x, "float", y, "float", w, "float", h)
}

Gdip_ResetClip(pGraphics)
{
   return DllCall("gdiplus\GdipResetClip", "ptr", pGraphics)
}

;#####################################################################################
; Create resources
;#####################################################################################

Gdip_CreatePen(ARGB, w)
{
   DllCall("gdiplus\GdipCreatePen1", "int", ARGB, "float", w, "int", 2, "Ptr*", pPen)
   return pPen
}

;#####################################################################################

Gdip_CreatePenFromBrush(pBrush, w)
{
	DllCall("gdiplus\GdipCreatePen2", "Ptr", pBrush, "float", w, "int", 2, "Ptr*", pPen)
	return pPen
}

;#####################################################################################

Gdip_BrushCreateSolid(ARGB=0xff000000)
{
	DllCall("gdiplus\GdipCreateSolidFill", "int", ARGB, "Ptr*", pBrush)
	return pBrush
}

;#####################################################################################

; HatchStyleHorizontal = 0
; HatchStyleVertical = 1
; HatchStyleForwardDiagonal = 2
; HatchStyleBackwardDiagonal = 3
; HatchStyleCross = 4
; HatchStyleDiagonalCross = 5
; HatchStyle05Percent = 6
; HatchStyle10Percent = 7
; HatchStyle20Percent = 8
; HatchStyle25Percent = 9
; HatchStyle30Percent = 10
; HatchStyle40Percent = 11
; HatchStyle50Percent = 12
; HatchStyle60Percent = 13
; HatchStyle70Percent = 14
; HatchStyle75Percent = 15
; HatchStyle80Percent = 16
; HatchStyle90Percent = 17
; HatchStyleLightDownwardDiagonal = 18
; HatchStyleLightUpwardDiagonal = 19
; HatchStyleDarkDownwardDiagonal = 20
; HatchStyleDarkUpwardDiagonal = 21
; HatchStyleWideDownwardDiagonal = 22
; HatchStyleWideUpwardDiagonal = 23
; HatchStyleLightVertical = 24
; HatchStyleLightHorizontal = 25
; HatchStyleNarrowVertical = 26
; HatchStyleNarrowHorizontal = 27
; HatchStyleDarkVertical = 28
; HatchStyleDarkHorizontal = 29
; HatchStyleDashedDownwardDiagonal = 30
; HatchStyleDashedUpwardDiagonal = 31
; HatchStyleDashedHorizontal = 32
; HatchStyleDashedVertical = 33
; HatchStyleSmallConfetti = 34
; HatchStyleLargeConfetti = 35
; HatchStyleZigZag = 36
; HatchStyleWave = 37
; HatchStyleDiagonalBrick = 38
; HatchStyleHorizontalBrick = 39
; HatchStyleWeave = 40
; HatchStylePlaid = 41
; HatchStyleDivot = 42
; HatchStyleDottedGrid = 43
; HatchStyleDottedDiamond = 44
; HatchStyleShingle = 45
; HatchStyleTrellis = 46
; HatchStyleSphere = 47
; HatchStyleSmallGrid = 48
; HatchStyleSmallCheckerBoard = 49
; HatchStyleLargeCheckerBoard = 50
; HatchStyleOutlinedDiamond = 51
; HatchStyleSolidDiamond = 52
; HatchStyleTotal = 53
Gdip_BrushCreateHatch(ARGBfront, ARGBback, HatchStyle=0)
{
	DllCall("gdiplus\GdipCreateHatchBrush", "int", HatchStyle, "int", ARGBfront, "int", ARGBback, "Ptr*", pBrush)
	return pBrush
}

;#####################################################################################

Gdip_CreateTextureBrush(pBitmap, WrapMode=1, x=0, y=0, w="", h="")
{
	if !(w && h)
		DllCall("gdiplus\GdipCreateTexture", "Ptr", pBitmap, "int", WrapMode, "Ptr*", pBrush)
	else
		DllCall("gdiplus\GdipCreateTexture2", "Ptr", pBitmap, "int", WrapMode, "float", x, "float", y, "float", w, "float", h, "Ptr*", pBrush)
	return pBrush
}

;#####################################################################################

; WrapModeTile = 0
; WrapModeTileFlipX = 1
; WrapModeTileFlipY = 2
; WrapModeTileFlipXY = 3
; WrapModeClamp = 4
Gdip_CreateLineBrush(x1, y1, x2, y2, ARGB1, ARGB2, WrapMode=1)
{
	CreatePointF(PointF1, x1, y1), CreatePointF(PointF2, x2, y2)
	DllCall("gdiplus\GdipCreateLineBrush", "Ptr", &PointF1, "Ptr", &PointF2, "int", ARGB1, "int", ARGB2, "int", WrapMode, "Ptr*", LGpBrush)
	return LGpBrush
}

;#####################################################################################

; LinearGradientModeHorizontal = 0
; LinearGradientModeVertical = 1
; LinearGradientModeForwardDiagonal = 2
; LinearGradientModeBackwardDiagonal = 3
Gdip_CreateLineBrushFromRect(x, y, w, h, ARGB1, ARGB2, LinearGradientMode=1, WrapMode=1)
{
	CreateRectF(RectF, x, y, w, h)
	DllCall("gdiplus\GdipCreateLineBrushFromRect", "Ptr", &RectF, "int", ARGB1, "int", ARGB2, "int", LinearGradientMode, "int", WrapMode, "Ptr*", LGpBrush)
	return LGpBrush
}

;#####################################################################################

Gdip_CloneBrush(pBrush)
{
	DllCall("gdiplus\GdipCloneBrush", "Ptr", pBrush, "Ptr*", pBrushClone)
	return pBrushClone
}

;#####################################################################################
; Delete resources
;#####################################################################################

Gdip_DeletePen(pPen)
{
   return DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
}

;#####################################################################################

Gdip_DeleteBrush(pBrush)
{
   return DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)
}

;#####################################################################################

Gdip_DisposeImage(pBitmap)
{
   return DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
}

;#####################################################################################

Gdip_DeleteGraphics(pGraphics)
{
   return DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
}

;#####################################################################################

Gdip_DisposeImageAttributes(ImageAttr)
{
	return DllCall("gdiplus\GdipDisposeImageAttributes", "Ptr", ImageAttr)
}

;#####################################################################################

Gdip_DeleteFont(hFont)
{
   return DllCall("gdiplus\GdipDeleteFont", "Ptr", hFont)
}

;#####################################################################################

Gdip_DeleteStringFormat(hFormat)
{
   return DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", hFormat)
}

;#####################################################################################

Gdip_DeleteFontFamily(hFamily)
{
   return DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", hFamily)
}

;#####################################################################################

Gdip_DeleteMatrix(Matrix)
{
   return DllCall("gdiplus\GdipDeleteMatrix", "Ptr", Matrix)
}

;~ https://msdn.microsoft.com/en-us/library/windows/desktop/dd162480%28v=vs.85%29.aspx
Gdip_DrawArrow( hDC, x,y, width, height, clr, type = "left" )
{
	bmWidth := width
	bmHeight := height
	bmY := y
	bmX := x
	
	;drawing arrow in the colors we need
	arrowDC := CreateCompatibleDC( hDC )
	fillDC := CreateCompatibleDC( hDC )
	arrowBM := CreateCompatibleBitmap( hDC, bmWidth, bmHeight )
	fillBM := CreateCompatibleBitmap( hDC, bmWidth, bmHeight )
	oldArrowBitmap := SelectObject( arrowDC, arrowBM )
	oldFillBitmap := SelectObject( fillDC, fillBM )
	;Set the offscreen arrow rect
	SetRect( tmpArrowR, 0, 0, bmWidth, bmHeight )
	;Draw the frame control arrow (The OS draws this as a black on
	;                            white bitmap mask)
	DrawFrameControl( arrowDC, &tmpArrowR, 2, type == "left" ? 0 : 4 )
	FillRect( fillDC, &tmpArrowR, clr )
	;Blit the items in a masking fashion
	BitBlt( hDC, bmX, bmY, bmWidth, bmHeight, fillDC, 0, 0, 0x00660046 )
	BitBlt( hDC, bmX, bmY, bmWidth, bmHeight, arrowDC, 0, 0, 0x008800C6 )
	BitBlt( hDC, bmX, bmY, bmWidth, bmHeight, fillDC, 0, 0, 0x00660046 )
	
	SelectObject( arrowDC, oldArrowBitmap )
	SelectObject( fillDC, oldFillBitmap )
	DeleteObject( arrowBM )
	DeleteObject( fillBM )
	DeleteDC( arrowDC )
	DeleteDC( fillDC )
	return 0
}