GetSysFont( ByRef LOGFONT )
{
  VarSetCapacity( LOGFONT, 92, 0 )
  return DllCall("SystemParametersInfoW", "Uint", 0x001F, "UInt", 92, "Ptr", &LOGFONT, "UInt", 0 ) ? &LOGFONT : 0
}

CreateFontIndirect( pLOGFONT )
{
  return DllCall("CreateFontIndirectW", "Ptr", pLOGFONT )
}

Dlg_Font( objParams, Effects=true, hGui=0 ) 
{

   Flags := 0x3 | 0x040 | 0x00010000 | 0x00000400  | ( Effects ? 0x100 : 0 )  
   ;CF_EFFECTS = 0x100
   ;CF_INITTOLOGFONTSTRUCT = 0x40
   ;CF_INACTIVEFONTS = 0x02000000
   ;CF_SCRIPTSONLY = 0x00000400 
   ;CF_FORCEFONTEXIST = 0x00010000
  
  if !IsObject( objParams )
    fRetString := True

  obj2LOGFONT( objParams, LOGFONT )
  ;convert from rgb
  clr := RGBtoBGR( clr )
  
;~ typedef struct {
  ;~ DWORD        lStructSize;	0			uint
  ;~ HWND         hwndOwner;	ptr			ptr
  ;~ HDC          hDC;			2ptr		ptr
  ;~ LPLOGFONT    lpLogFont;	3ptr		ptr
  ;~ INT          iPointSize;	4ptr		uint
  ;~ DWORD        Flags;		4 + 4ptr	uint
  ;~ COLORREF     rgbColors;	8 + 4ptr	uint
  ;~ LPARAM       lCustData;	8 +5ptr		ptr
  ;~ LPCFHOOKPROC lpfnHook;		8 +6ptr		ptr
  ;~ LPCTSTR      lpTemplateName;	8+7ptr 	ptr
  ;~ HINSTANCE    hInstance;	8+8ptr		ptr
  ;~ LPTSTR       lpszStyle;	8+9ptr		ptr
  ;~ WORD         nFontType;	8+10ptr		ushort
  ;~ INT          nSizeMin;		8+11ptr		uint
  ;~ INT          nSizeMax;		12+11ptr	uint
;~ } CHOOSEFONT, *LPCHOOSEFONT;	16+11ptr

  size := 16 + 11*A_PtrSize
  VarSetCapacity( CHOOSEFONT, size, 0)
  NumPut( size,		CHOOSEFONT, 0)		; DWORD lStructSize
  NumPut( hGui,    CHOOSEFONT, A_PtrSize,"UPtr")		; HWND hwndOwner (makes dialog "modal").
  NumPut( &LOGFONT,CHOOSEFONT, 3*A_PtrSize,"UPtr")	; LPLOGFONT lpLogFont
  NumPut( Flags, CHOOSEFONT, 4 + 4*A_PtrSize,"Uint")
  NumPut( clr,	 CHOOSEFONT, 8 + 4*A_PtrSize,"Uint")

  if !DllCall( "comdlg32\ChooseFontW", "Ptr", &CHOOSEFONT )
    return false
  clr := ToHex( RGBtoBGR( NumGet(CHOOSEFONT, 8 + 4*A_PtrSize) ) )
  
  if fRetString
    return Dict2Str( LOGFONT2obj( LOGFONT ) )
  return LOGFONT2obj( LOGFONT )
}

;~ typedef struct tagLOGFONT {
  ;~ LONG  lfHeight;					0		uint
  ;~ LONG  lfWidth;						4		uint
  ;~ LONG  lfEscapement;				8		uint
  ;~ LONG  lfOrientation;				12		uint
  ;~ LONG  lfWeight;					16		uint
  ;~ BYTE  lfItalic;					20		b
  ;~ BYTE  lfUnderline;					21		b
  ;~ BYTE  lfStrikeOut;					22		b
  ;~ BYTE  lfCharSet;					23		b
  ;~ BYTE  lfOutPrecision;				24		b
  ;~ BYTE  lfClipPrecision;				25		b
  ;~ BYTE  lfQuality;					26		b
  ;~ BYTE  lfPitchAndFamily;			27		b
  ;~ TCHAR lfFaceName[LF_FACESIZE];		28		32
;~ } LOGFONT, *PLOGFONT;				92
obj2LOGFONT( obj, ByRef LOGFONT, init = True )
{
  if !IsObject( obj )
    obj := Str2Dict( obj )
  if ( VarSetCapacity( LOGFONT ) != 92 )
    VarSetCapacity( LOGFONT, 92, 0 )
  if ObjHasKey( obj, "height" )
  {
    NumPut( -MulDiv( abs(obj["height"]), GetDeviceCaps(), 72 )
          , LOGFONT, 0, "Int" )
  }
  if ObjHasKey( obj, "width" )
    NumPut( obj["width"], LOGFONT, 4, "UInt" )
  if ObjHasKey( obj, "Escapement" )
    NumPut( obj["Escapement"], LOGFONT, 8, "UInt" )
  if ObjHasKey( obj, "Orientation" )
    NumPut( obj["Orientation"], LOGFONT, 12, "UInt" )
  if ObjHasKey( obj, "Weight" )
    NumPut( obj["Weight"], LOGFONT, 16, "UInt" )
  if ObjHasKey( obj, "Italic" )
    NumPut( obj["Italic"], LOGFONT, 20, "UChar" )
  if ObjHasKey( obj, "Underline" )
    NumPut( obj["Underline"], LOGFONT, 21, "UChar" )
  if ObjHasKey( obj, "strike" )
    NumPut( obj["strike"], LOGFONT, 22, "UChar" )
  if ObjHasKey( obj, "OutPrecision" )
    NumPut( obj["OutPrecision"], LOGFONT, 24, "UChar" )
  if ObjHasKey( obj, "ClipPrecision" )
    NumPut( obj["ClipPrecision"], LOGFONT, 25, "UChar" )
  if ObjHasKey( obj, "PitchAndFamily" )
    NumPut( obj["PitchAndFamily"], LOGFONT, 27, "UChar" )
  if ObjHasKey( obj, "CharSet" )
    NumPut( obj["CharSet"], LOGFONT, 23, "UChar" )
  if ObjHasKey( obj, "Quality" )
    NumPut( obj["Quality"], LOGFONT, 26, "UChar" )
  if ObjHasKey( obj, "name" )
    StrPut( obj["name"], &LOGFONT + 28, 32, "UTF-16" )
}

LOGFONT2obj( ByRef LOGFONT )
{
  if ( VarSetCapacity( LOGFONT ) != 92 )
    return 0
  obj := object()
  obj["height"] := abs( MulDiv( abs( NumGet( LOGFONT, 0, "Int" ) )
                      , 72, GetDeviceCaps() ) )
  obj["width"] := NumGet( LOGFONT, 4, "Int" )
  obj["Escapement"] := NumGet( LOGFONT, 8, "Int" )
  obj["Orientation"] := NumGet( LOGFONT, 12, "Int" )
  obj["Weight"] := NumGet( LOGFONT, 16, "Int" )
  obj["italic"] := NumGet( LOGFONT, 20, "UChar" )
  obj["underline"] := NumGet( LOGFONT, 21, "UChar" )
  obj["strike"] := NumGet( LOGFONT, 22, "UChar" )
  obj["CharSet"] := NumGet( LOGFONT, 23, "UChar" )
  obj["OutPrecision"] := NumGet( LOGFONT, 24, "UChar" )
  obj["ClipPrecision"] := NumGet( LOGFONT, 25, "UChar" )
  obj["Quality"] := NumGet( LOGFONT, 26, "UChar" )
  obj["PitchAndFamily"] := NumGet( LOGFONT, 27, "UChar" )
  obj["name"] := StrGet( &LOGFONT + 28, 32, "UTF-16" )
  return obj
}

Dict2Str( obj, delim = "|", separ = ":" ) {
  fstr := ""
  for key,val in obj
    fstr .= ( fstr ? delim : "" ) key separ val
  return fstr
}

Str2Dict( fstr, delim = "|", separ = ":" ) {
  obj := object()
  for i,pair in StrSplit( fstr, delim, A_Space A_Tab )
  {
    ar := StrSplit( pair, separ, A_Space A_Tab )
    obj[ ar[1] ] := ar[2]
  }
  return obj
}

FONTahk2obj( fontname, styles )
{
  obj := object()
  if fontname
    obj["name"] := fontname
  if RegExMatch( styles, "iO)\bs(\d+)\b", resl )
    obj["height"] := resl[ 1 ]
  if RegExMatch( styles, "iO)\bw(\d+)\b", resl )
    obj["weight"] := resl[ 1 ]
  if RegExMatch( styles, "iO)\bq(\d)\b", resl )
    obj["quality"] := resl[ 1 ]
  if RegExMatch( styles, "iO)\bunderline\b", resl )
    obj["underline"] := 1
  if RegExMatch( styles, "iO)\bstrike\b", resl )
    obj["strike"] := 1
  if RegExMatch( styles, "iO)\sitalic\b", resl )
    obj["italic"] := 1
  if RegExMatch( styles, "iO)\bbold\b", resl )
    obj["weight"] := 700
  return
}

FONTobj2ahk( obj, byref fontname, byref styles )
{
  fontname := styles := ""
  if !IsObject( obj )
    obj := Str2Dict( obj )
  if obj["name"]
    fontname := obj["name"]
  styles := "norm "
  if obj["weight"]
    styles .= " w" obj["weight"]
  if obj["italic"]
    styles .= " italic"
  if obj["strike"]
    styles .= " strike"
  if obj["underline"]
    styles .= " underline" 
  if obj["quality"]
    styles .= " q" obj["quality"]
  if obj["height"]
    styles .= " s" abs(obj["height"])
  return
}

GetSysFontObj()
{
  GetSysFont( LOGFONT )
  return LOGFONT2obj( LOGFONT )
}

; use deleteObject on returned font
ControlSetFont( chwnd, font )
{
  if IsInteger( font )
    hFont := font
  else if IsObject( font )
  {
    obj2LOGFONT( font, LOGFONT )
    hFont := CreateFontIndirect( &LOGFONT )
  }
  else if font
  {
    obj2LOGFONT( Str2Dict( font ), LOGFONT )
    hFont := CreateFontIndirect( &LOGFONT )
  }
  else
    hFont := 0
  SendMessage( chwnd, 0x0030, hFont, 1 )
  return hFont
}

GuiSetFont(Control_Name,FontOptions="",FontName="",Gui="")
{
  if (Gui = "")
    Gui := A_Gui
  Gui,%Gui%:Default
  Gui, Font,% FontOptions,% FontName
  Loop, Parse, Control_Name, |, %A_Tab%%A_Space%
    GuiControl, Font,% A_Loopfield
  Gui, Font, norm
  return
}

QCGetFontSets()
{
  if qcOpt[ "aprns_mainfont" ]
    obj := Str2Dict( qcOpt[ "aprns_mainfont" ] )
  else
    obj := GetSysFontObj()
  if IsInteger( qcOpt[ "aprns_fontqlty" ] )
    obj[ "quality" ] := qcOpt[ "aprns_fontqlty" ]
  return obj
}

QCTVSetFont()
{
  obj := object()
  if qcOpt[ "main_tv_glFont" ]
    obj := QCGetFontSets()
  else
    obj.name := glb[ "QC_GUI_FONT" ]
  size := qcOpt[ "main_tv_fontSize" ]
  if !IsInteger( size )
    size := 10
  obj[ "height" ] := size
  FONTobj2ahk( obj, fontname, styles )
  GuiSetFont( qcGui[ "main_tv" ], styles, fontname, 1 )
  return
}

QCSetGuiFont( guiname )
{
  Gui,%guiname%:Default
  Gui, Font,norm s10 q6,% glb[ "QC_GUI_FONT" ]
  return
}