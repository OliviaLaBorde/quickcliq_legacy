/*
 Function:		Color
				(See Dlg_color.png)

 Parameters: 
				Color	- Initial color and output in RGB format.
				hGui	- Optional handle to parents Gui. Affects dialog position.
  
 Returns:	
				False if user canceled the dialog or if error occurred	
 */ 
Dlg_Color(ByRef Color, hGui=0){ 
  ;covert from rgb
    clr := ((Color & 0xFF) << 16) + (Color & 0xFF00) + ((Color >> 16) & 0xFF)

;~ typedef struct {
  ;~ DWORD        lStructSize;		0		uint	ptr
  ;~ HWND         hwndOwner;		ptr		ptr		ptr
  ;~ HWND         hInstance;		2ptr	ptr		ptr
  ;~ COLORREF     rgbResult;		3ptr	uint	ptr
  ;~ COLORREF     *lpCustColors;	4ptr	ptr		ptr
  ;~ DWORD        Flags;			5ptr	uint	uint
  ;~ LPARAM       lCustData;		6ptr	ptr		ptr
  ;~ LPCCHOOKPROC lpfnHook;			7ptr	ptr		ptr
  ;~ LPCTSTR      lpTemplateName;	8ptr	ptr		ptr
;~ } CHOOSECOLOR, *LPCHOOSECOLOR;	9ptr

    VarSetCapacity(CHOOSECOLOR, 9*A_PtrSize, 0), VarSetCapacity(CUSTOM, 64, 0)
     NumPut(9*A_PtrSize,		CHOOSECOLOR, 0,"Uint")      ; DWORD lStructSize 
     NumPut(hGui,		CHOOSECOLOR, A_PtrSize,"UPtr")      ; HWND hwndOwner (makes dialog "modal"). 
     NumPut(clr,		CHOOSECOLOR, 3*A_PtrSize,"Uint")     ; clr.rgbResult 
     NumPut(&CUSTOM,	CHOOSECOLOR, 4*A_PtrSize,"UPtr")     ; COLORREF *lpCustColors
     NumPut(0x00000103,CHOOSECOLOR, 5*A_PtrSize,"Uint")     ; Flag: CC_ANYCOLOR || CC_RGBINIT || CC_FULLOPEN

    nRC := DllCall("comdlg32\ChooseColorW", "Ptr", &CHOOSECOLOR)  ; Display the dialog. 
    if (errorlevel <> 0) || (nRC = 0)
       return  false 

    clr := NumGet(CHOOSECOLOR, 3*A_PtrSize,"Uint") 
    
    oldFormat := A_FormatInteger 
    SetFormat, integer, hex  ; Show RGB color extracted below in hex format. 

 ;convert to rgb 
    Color := (clr & 0xff00) + ((clr & 0xff0000) >> 16) + ((clr & 0xff) << 16) 
    StringTrimLeft, Color, Color, 2 
    loop, % 6-strlen(Color) 
		Color=0%Color% 
    Color=0x%Color% 
    SetFormat, integer, %oldFormat% 
	return true
}