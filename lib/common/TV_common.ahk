TV_GetIconIndex( hTV, itemID )
{
	;~ typedef struct tagTVITEMEX {
  ;~ UINT      mask;					uint		0
  ;~ HTREEITEM hItem;					ptr			ptr
  ;~ UINT      state;					uint		2ptr
  ;~ UINT      stateMask;				uint		4+2ptr
  ;~ LPTSTR    pszText;					ptr			8+2ptr
  ;~ int       cchTextMax;				uint		8+3ptr
  ;~ int       iImage;					uint		12+3ptr
  ;~ int       iSelectedImage;			uint		16+3ptr
  ;~ int       cChildren;				uint		20+3ptr
  ;~ LPARAM    lParam;					ptr(uint)	24+3ptr
  ;~ int       iIntegral;				uint		24+4ptr
;~ #if (_WIN32_IE >= 0x0600)		
  ;~ UINT      uStateEx;				uint		28+4ptr
  ;~ HWND      hwnd;					ptr			32+4ptr
  ;~ int       iExpandedImage;			uint		32+5ptr
;~ #endif 
;~ #if (NTDDI_VERSION >= NTDDI_WIN7)
  ;~ int       iReserved;				uint		36+5ptr
;~ #endif 
;~ } TVITEMEX, *LPTVITEMEX;
	
	size := 36 + 5*A_PtrSize
	VarSetCapacity(TVITEMEX,size,0)
	numput( 0x0002 | 0x0010, TVITEMEX, 0, "UInt" )	;TVIF_IMAGE | TVIF_HANDLE
	numput( itemID, TVITEMEX, A_PtrSize, "UPtr" )
	SendMessage( hTV, 0x1100 + 62, 0, &TVITEMEX )	;TVM_GETITEMW = (TV_FIRST + 62)
	icoIndex := numget( TVITEMEX, 12+3*A_PtrSize, "Uint" )
	return icoIndex
}