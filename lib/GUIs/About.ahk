;################ ABOUT #########################
ABOUT()
{	
	static about_ok_button
	If IsWindow( qcGui[ "about" ] )
	{
		WinActivate,% "ahk_id " qcGui[ "about" ]
		return
	}
	Gui, 6:Default
	QCSetGuiFont( 6 )
	Gui, +Owner1
	Gui, 1:+Disabled
	Gui, -SysMenu +hwndhAboutGUI
	qcGui[ "about" ] := hAboutGUI
	if qcOpt[ "gen_noTheme" ]
		Gui,-Theme
	
	pGDIToken := Gdip_Startup()
	Gui, Add, Picture, x1 y1 w367 h61 0xE hwndhdrHWND
	GdipHeader( hdrHWND, 0xff283199, glb[ "appName" ] )
	Gdip_Shutdown(pGDIToken)
	qcver := "v" glb[ "ver" ] " " glb[ "qcArch" ]
	qcweb := glb[ "urlQCHome" ]
	aphome := glb[ "urlApathyHome" ]
	appname := glb[ "appName" ]
	ahk_ver := A_IsCompiled ? "" : "( ahk " A_AhkVersion " )"
	info = 
	( LTrim
	%appname% %qcver% %ahk_ver%
	
	Official Apathy Softworks web site:
	<a href="%aphome%">%aphome%</a>
	
	Official %appname% web page:
	<a href="%qcweb%">%qcweb%</a>
	
	E-Mail:
	<a href="mail">support@apathysoftworks.com</a>
	)
	Gui, Add, Link, xm y+5 w350 +Multi +Wrap gg_about_mail,% info
	Gui, Add, Text, xm y+10,License:
	Gui,Add,Edit,xm y+5 w350 R10 +Multi +ReadOnly,
	(
This application developed under "Apathy Softworks" trademark and completely free for both personal and commercial use.

This product, %appname%, as distributed by ApathySoftworks.com, may be used free of charge by individuals, non-profit organizations, commercial organizations, and government agencies, on single or multiple computers/systems for non-commercial and/or commercial uses.

This product may be copied and/or distributed free of charge.

Distribution of %appname% with any 3rd party application or plug-in is prohibited without prior permission from the %appname% developer, Apathy Softworks.

As this product is free, there is no warranty for the product, to the extent permitted by applicable law. Unless otherwise stated, the product is provided "as is" without warranty of any kind, either expressed or implied, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose. The entire risk as to the quality and performance of the program is with you. Should the program prove defective, you assume the cost of all necessary servicing, repair or correction.

In no event unless required by applicable law or agreed to in writing will any copyright holder, or any other party who may redistribute the program as permitted below, be liable to anyone for damages, including any general, special, incidental or consequential damages arising out of the use or inability to use the program, including but not limited to loss of data or data being rendered inaccurate or losses sustained by you or third parties or a failure of the program to operate with any other programs, even if such holder or other party had previously been advised of the possibility of such damages.
	)
	Gui,Add,text,y+5,© 2010-2015 by Apathy Softworks. All rights reserved.
	Gui, Add, Button, x132 y+10 w100 h30 gcloseaboutbox vabout_ok_button, Ok
	GuiControl,Focus,about_ok_button
	WinGetPos, X, Y, W, H,% "AHK_ID " qcGui[ "main" ]
	pos := "x" . round(x+w/2-184) . " y" . round(y+h/2-230) . " w369"
	Gui, Show,% pos,% "About " glb[ "appName" ]
	Return
	
	g_about_mail:
		if( ErrorLevel = "mail" )
			Run,mailto:support@apathysoftworks.com,,UseErrorLevel
		return
	
	closeaboutbox:
		Gui, 1:-Disabled
		Gui, Destroy
		WinActivate,% "ahk_id " qcGui[ "main" ]
		return
}

/*
centaur
century
chiller
*/

GdipHeader(hwnd, Background=0x00000000, Text="", TextOptions="x0p y15p s50p Center cffffffff r5 Bold", Font="Times New Roman")
{
	ControlGetPos,,,picW, picH,,ahk_id %hwnd%
	pBrushBack := Gdip_BrushCreateSolid(Background)
	pBitmap := Gdip_CreateBitmap(picW, picH)
	G := Gdip_GraphicsFromImage(pBitmap)
	Gdip_SetSmoothingMode(G, 4)
	Gdip_FillRoundedRectangle(G, pBrushBack, 0, 0, picW, picH,10)
	Gdip_TextToGraphics(G, Text, TextOptions, Font, picW, picH)
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	SetImage(hwnd, hBitmap)
	Gdip_DeleteBrush(pBrushBack)
	Gdip_DeleteGraphics(G)
	Gdip_DisposeImage(pBitmap)
	DeleteObject(hBitmap)
	Return
}
