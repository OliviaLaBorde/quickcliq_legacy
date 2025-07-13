/*
   Function:   CColor
            Set text and background color for some Gui controls.
            Supported types: Edit, Text, ListBox, ComboBox, DropDownList, CheckBox, RadioButton, ListView, TreeView, RichEdit
   
   Parameters:   
      Hwnd      -  Handle of the control.
      Background  -  Background color. HTML color name or 6-digit RGB value. Optional.
      Foreground  -  Foreground color. HTML color name or 6-digit RGB value. Optional.
    
   Remarks:
      You need to redraw the window for changes to take effect. For some controls, it may be needed to explicitelly specify
      foreground color ("cRed") when creating control, otherwise text will stay black.

      On tha first call for a specific control class the function registers itself as message handler for WM_CTLCOLOR
      message of appropriate class.

      Buttons are always drawn with the default system colors. Drawing buttons requires several different brushes-face, highlight and shadow
      but the WM_CTLCOLORBTN message allows only one brush to be returned. To provide a custom appearance for push buttons, use an owner-drawn button.

   About:
      o Version 1.0 by majkinetor.
      o Original code by (de)nick, See: <http://www.autohotkey.com/forum/topic238864.html>.
      o Licenced under BSD <http://creativecommons.org/licenses/BSD/>.
 */
CColor(Hwnd, Background="", Foreground="") {
   return CColor_(Background, Foreground, "", Hwnd+0)
}

CColor_(Wp, Lp, Msg, Hwnd) {
   static
   static dColors := {}
   static WM_CTLCOLOREDIT=0x0133, WM_CTLCOLORLISTBOX=0x134, WM_CTLCOLORSTATIC=0x0138
        ,LVM_SETBKCOLOR=0x1001, LVM_SETTEXTCOLOR=0x1024, LVM_SETTEXTBKCOLOR=0x1026, TVM_SETTEXTCOLOR=0x111E, TVM_SETBKCOLOR=0x111D
        ,BS_CHECKBOX=2, BS_RADIOBUTTON=8, ES_READONLY=0x800, CLR_NONE=-1
        ,CLASSES := "Button,ComboBox,Edit,ListBox,Static,RICHEDIT50W,SysListView32,SysTreeView32"

   If (Msg = "") {
      if !adrSetTextColor
         adrSetTextColor   := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandleW", "Wstr", "Gdi32.dll","UPtr"), "AStr", "SetTextColor","UPtr")
         ,adrSetBkColor   := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandleW", "Wstr", "Gdi32.dll","UPtr"), "AStr", "SetBkColor","UPtr")
         ,adrSetBkMode   := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandleW", "Wstr", "Gdi32.dll","UPtr"), "AStr", "SetBkMode","UPtr")
   
      ;Set the colors (RGB -> BGR)
      BG := !Wp ? "" : RGBtoBGR( Wp )
      FG := !Lp ? "" : RGBtoBGR( Lp )
		
      ;Activate message handling with OnMessage() on the first call for a class
      WinGetClass, class, ahk_id %Hwnd%
      If class not in %CLASSES%
         return A_ThisFunc "> Unsupported control class: " class

      ControlGet, style, Style, , , ahk_id %Hwnd%
      if (class = "Edit") && (Style & ES_READONLY)
         class := "Static"
   
      if (class = "Button")
         if (style & BS_RADIOBUTTON) || (style & BS_CHECKBOX)
             class := "Static"
         else return A_ThisFunc "> Unsupported control class: " class
      
      if (class = "ComboBox") {
;~ typedef struct tagCOMBOBOXINFO {
  ;~ DWORD cbSize;          0    uint
  ;~ RECT  rcItem;          4    4*uint
  ;~ RECT  rcButton;        20    4*uint
  ;~ DWORD stateButton;     36    uint
  ;~ HWND  hwndCombo;       40    ptr
  ;~ HWND  hwndItem;        40+ptr    ptr
  ;~ HWND  hwndList;        40+2ptr    ptr
;~ } COMBOBOXINFO           40+3ptr
         cbSize := 40 + A_PtrSize*3
         VarSetCapacity(CBBINFO, cbSize, 0)
         NumPut(cbSize, CBBINFO)
         DllCall("GetComboBoxInfo", "Ptr", Hwnd, "Ptr", &CBBINFO)
         hwnd := NumGet(CBBINFO, cbSize-A_PtrSize)      ;hwndList
         dColors[ hwnd "BG" ] := BG
         dColors[ hwnd "FG" ] := FG
         dColors[ hwnd ] := BG ? DllCall("CreateSolidBrush", "UInt", BG) : -1

         IfEqual, CTLCOLORLISTBOX,,SetEnv, CTLCOLORLISTBOX, % OnMessage(WM_CTLCOLORLISTBOX, A_ThisFunc)

         hw := NumGet(CBBINFO,cbSize-A_PtrSize*2)
         If hw   ;hwndEdit
            Hwnd := hw, class := "Edit"
      }

      if class in SysListView32,SysTreeView32
      {
         m := class="SysListView32" ? "LVM" : "TVM"
         SendMessage, %m%_SETBKCOLOR, ,BG, ,ahk_id %Hwnd%
         SendMessage, %m%_SETTEXTCOLOR, ,FG, ,ahk_id %Hwnd%
         SendMessage, %m%_SETTEXTBKCOLOR, ,CLR_NONE, ,ahk_id %Hwnd%
         return
      }

      if (class = "RICHEDIT50W")
         return f := "RichEdit_SetBgColor", %f%(Hwnd, -BG)

      if (!CTLCOLOR%Class%)
         CTLCOLOR%Class% := OnMessage(WM_CTLCOLOR%Class%, A_ThisFunc)

	  dColors[ hwnd ] := BG ? DllCall("CreateSolidBrush", "UInt", BG) : CLR_NONE
      dColors[ hwnd "BG" ] := BG
      dColors[ hwnd "FG" ] := FG
	  
      return dColors[ hwnd ]
   }
 
 ; Message handler
   critical               ;its OK, always in new thread.
   Hwnd := Lp + 0, hDC := Wp + 0
   If (dColors[ hwnd ]) {
      DllCall(adrSetBkMode, "Ptr", hDC, "int", 1)
      if (dColors[ hwnd "FG" ])
         DllCall(adrSetTextColor, "Ptr", hDC, "UInt", dColors[ hwnd "FG" ])
      if (dColors[ hwnd "BG" ])
         DllCall(adrSetBkColor, "Ptr", hDC, "UInt", dColors[ hwnd "BG" ])
      return (dColors[ hwnd ])
   }
}