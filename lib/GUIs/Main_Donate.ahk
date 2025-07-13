GUIDonation()
{
  if !WinExist( "ahk_id " qcGui[ "main_donate_gui" ] )
  {
    GuiCreateNew( "GUI_DONATE_GUI", "main_donate_gui", "Do you like " glb[ "appName" ] "?", qcGui[ "main" ] )
    appName := glb[ "appName" ]
    msg =
    (Ltrim
    Hello!
    It seems you are using %appName% for a few days now.
    If you like it and appreciate our work, please consider a small <a href="http://apathysoftworks.com/donate">donation</a>
      
    If you think it lack some important feature, <a href="mailto:support@apathysoftworks.com?subject=%appName% feature request">e-mail to us</a> so we could improve and make it more useful for you
    )
    Gui,Add,Link,xm w300,% msg
    Gui,Add,Button,gGUI_DONATE_DONATE_BUT,Donate
    Gui,Add,Button,x+5 gGUI_DONATE_DONATE_LATER,Later
    Gui,Add,Button,x+120 gGUI_DONATE_DONATE_ALREADY_DID,I already did
    Gui,-sysmenu
  }
  GuiShowChildWindow( qcGui[ "main_donate_gui" ], qcGui[ "main" ] )
  ControlFocus,Button1,% "ahk_id " qcGui[ "main_donate_gui" ]
  return qcGui[ "main_donate_gui" ]
  
  GUI_DONATE_DONATE_LATER:
  GUI_DONATE_GUIGuiClose:
  GUI_DONATE_GUIGuiEscape:
    GuiDestroyChild( qcGui[ "main_donate_gui" ], qcGui[ "main" ] )
    return
    
  GUI_DONATE_DONATE_BUT:
    Run, http://apathysoftworks.com/donate
    gosub, GUI_DONATE_GUIGuiClose
    return
    
  GUI_DONATE_DONATE_ALREADY_DID:
    qcOpt["gen_donated"] := 1
    ClHide( qcGui[ "main_donate_but" ] )
    gosub, GUI_DONATE_GUIGuiClose
    QMsgBoxP( { "title"		: "Thank you"
              , "msg" 		: "Thank you, a generous man!"
              ,"nocaption": 1, "pos" : qcGui[ "main" ], "pic" : "i"
              ,"buttons" : "OK" }, qcGui[ "main" ] )
    return
}