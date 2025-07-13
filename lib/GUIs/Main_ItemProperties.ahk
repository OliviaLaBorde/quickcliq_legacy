Gui_Main_TlbProp_ShowGUI( fShow = True )
{
	global somechbx, hPropsGui, props_item_label
	
	gui, 12:Default
	If !IsWindow(hPropsGui)
	{
		Gui,+owner1
		Gui,+Lastfound
		Gui,Add,text,vprops_item_label w260
		hPropsGui := WinExist()+0
		qcGui[ "main_props" ] := hPropsGui
		if qcOpt[ "gen_noTheme" ]
			Gui,-Theme
		qcGui[ "main_tlbprop_IL" ] := IL_CreateNew( 24, 24, 7, 1 )
		loop,% glb[ "icoPropsCnt" ]
		{
			ico := glb[ "iconListPath" ] . glb[ "icoPropsInd" ]+(A_Index-1)
			IL_AddIcon( qcGui[ "main_tlbprop_IL" ], IconExtract( ico, 32) )
		}
		IL_AddIcon( qcGui[ "main_tlbprop_IL" ], IconExtract( glb[ "icoTLBprop_autorun" ], 32) )
		qcGui[ "main_tlbprop" ] := Toolbar_Add( hPropsGui, "Gui_Main_TlbProp_Handler","FLAT LIST TOOLTIPS", qcGui[ "main_tlbprop_IL" ], "x5 y25")
		;DO NOT change IDs since they are hardly linked with events
		;caption,icon_num,state,style,id
		btns = 
		(LTrim
		Change Icon,1,,WHOLEDROPDOWN ,1
		-,,,,10
		Change Item Boldness,2,,CHECK ,2
		-,,,,11
		Hotkey: None,3,WRAP,SHOWTEXT,3
		Change Text Color,4,,WHOLEDROPDOWN ,4
		Change Background Color,5,,WHOLEDROPDOWN ,5
		Random Menu's Colors,6,,,6
		Sort Items in Menu,7,,WHOLEDROPDOWN ,7
		-,,,,9
		Create Separate Menu,8,,,8
		Run item on startup,9,,CHECK,12
		)
		Toolbar_Insert( qcGui[ "main_tlbprop" ], btns )
		Toolbar_AutoSize( qcGui[ "main_tlbprop" ], 2 )
		
		Gui,Add,Checkbox,x5 y100 w40 h25 vsomechbx +0x1000 gChangePropsGUIStyle,H	;PUSHLIKE
		PropsGuiChangeStyle()
	}
	if !fShow
		return
	MouseGetPos,X,Y
	GuiControl,Focus,somechbx
	if (PropsGuiChangeStyle(0) = 0)
		Gui,Show,w280 h130,% glb[ "propsTitle" ]
	else
		Gui,Show,x%x% y%y% w280 h130,% glb[ "propsTitle" ]
	SetTimer( "Gui_Main_Props_CheckActive", 50 )
	return
	
	ChangePropsGUIStyle:
		PropsGuiChangeStyle(-1)
		Gui,Show,w280 h130
		return
	
	12GuiClose:
	PropsGuiHide:
		gui,12:default
		SetTimer( "Gui_Main_Props_CheckActive", "OFF" )
		HideWindow(hPropsGui)
		return
}

; function checks if Props gui is active, otherwise - hiding it
Gui_Main_Props_CheckActive( p* )
{
	global hPropsGui
	Gui,1:+LastFoundExist
	IfWinActive
		if PropsGuiChangeStyle( 0 )
		{
			HideWindow( hPropsGui )
			SetTimer( A_ThisFunc, "OFF" )
		}
	return
}

/*
function PropsGuiChangeStyle
 - changes props GUI style
in_param: mode, possible values:
"" - gets option from ini and save it to static PropsHide var
-1 - invert current value of PropsHide and save it to ini
0 - just return PropsHide value
*/
PropsGuiChangeStyle(mode="")
{
	static PropsHide
	if (mode="")
		PropsHide := qcOpt[ "main_props_hidden" ], GuiControlSet("somechbx",PropsHide,"",12)
	else if ( mode = -1 )
		PropsHide := !PropsHide, qcOpt[ "main_props_hidden" ] := PropsHide
	else
		return PropsHide
	gui,12:default
	Gui,% (PropsHide ? "-" : "+") "Caption +ToolWindow +0x400000" ; +AlwaysOnTop"
	return
}