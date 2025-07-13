#NoEnv
#Include QMsgBoxAPI.ahk
#Include QMsgBox.ahk

msg =
(
To prevent the user from interacting with the owner while one of its owned window is visible, disable the owner via Gui +Disabled. Later (when the time comes to cancel or destroy the owned window), re-enable the owner via Gui -Disabled. Do this prior to cancel/destroy so that the owner will be reactivated automatically.

Parent [v1.1.03+]: Use +Parent immediately followed by the name or number of an existing Gui or the HWND of any window or control to use it as the parent of this window. To convert the Gui back into a top-level window, use -Parent. Unlike +Owner, this option works even after the window is created.

)

gui,add,button,gsomelabel,push me!
gui,add,button,gsomelabel2,push me again!
gui,show
mb := new QMsgBox( { "msg" : msg
          , "buttons" : "OK!"
          , "editbox" : 1
          , "ontop" : 0
          , "nocaption" : 0
          , "nosysmenu" : 1
          , "center" 	  : 1
          , "modal"	  : 0
          , "title"	  : "whats up"
          , "pic"		  : "s" } )
return


GuiClose:
  ExitApp
  return

somelabel2:
  tooltip % QMsgBoxP( { title : "title", msg : msg, buttons : "Yes|No", pic : "i" ,rsz : 1 } )
  return

somelabel:
  tooltip % mb.Show()
  return