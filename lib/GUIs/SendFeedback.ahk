SendFeedback( initMsg = "", atGui = "" )
{
  global
  local uname,uemail
  static shname, shemail
  if IsWindow( qcGui[ "fb_form" ] )
  {
    WinActivate,% "ahk_id " qcGui[ "fb_form" ]
    return
  }
  Gui, 20:New, +ToolWindow +hwndhwnd +OwnDialogs, Send Feedback
  qcGui[ "fb_form" ] := hwnd
  QCSetGuiFont( 20 )
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  Gui, Add, Link,W320 +Wrap gSendMailAdmin,Have something to say or ask about? Just send us a note through this form or email to <a href="mail">support@apathysoftworks.com</a>
  
  shname := (uname := qcOpt[ "fb_UserName" ] ) ? 0 : 1
  shemail := (uemail := qcOpt[ "fb_UserEmail" ] ) ? 0 : 1
  Gui, Add, Edit,% "xm y+10 R1 W140 cBlue vSenderName -Multi HWNDhSenderName",% uname ? uname : ""
  Gui, Add, Edit,% "Section x+20 yp R1 W160 cBlue vSenderEMail -Multi HWNDhSenderEMail",% uemail ? uemail : ""
  tmail := "Your Email", tname := "Your Name"
  SendMessage( hSenderName, 0x1500 + 1, 0, &tname )
  SendMessage( hSenderEMail, 0x1500 + 1, 0, &tmail )
  Gui, Add, Text,xm y+10,Your Message:
  Gui, Add, Edit,xm W320 H150 vFeedbackText +Multi,% initMsg
  Gui, Add, Button,% "xm y+10 W" glb[ "defButW" ] " H" glb[ "defButH" ] " gFeedBackTransmit", Send
  Gui, -0x10000 -0x20000
  GuiControl, Focus, FeedbackText
  
  if( atGui != "" )
  {
    Gui %atGui%:+LastFoundExist
    WinGetPos, X, Y, W, H,% "AHK_ID " WinExist()
    Gui, show,% "x" . round(x+w/6) . " y" . round(y+h/10) . " AutoSize"
  }
  else
    Gui, show
  return
  
  20GuiEscape:
  20GuiClose:
    Gui, 20:Destroy
    return
  
  SendMailAdmin:
    if( ErrorLevel != "mail" )
      return
    uac := isUAC()
    qcver := glb[ "ver" ]
    qcarch := glb[ "qcArch" ]
    msg =
    (LTrim
    -----Please Keep This Info in Your Message-----
    OS:			%A_OSVersion%
    IsUAC:		%uac%
    QC Version:	%qcver%%qcarch%
    IsAdmin:	%A_ISAdmin%
    -----------------------------------------------
    
    )
    subj := glb[ "appName" ] " feedback"
    Run,% "mailto:support@apathysoftworks.com?body=" MailEscape(msg) "&subject=" MailEscape( subj ),, UseErrorLevel
    msg =
    return
  
  SaveFeedbackUserInfo:
    qcOpt[ "fb_UserEmail" ] := GuiControlGet("SenderEmail",20)
    qcOpt[ "fb_UserName" ] := GuiControlGet("SenderName",20)
    return
  
  FeedBackTransmit:
    Gui, Submit, nohide		
    if (FeedbackText = "")
    {
      QMsgBoxP( { title : "It's empty, man!"
          , msg : "Please! You won't send us blank message, do you?"
          , pic : "!", modal : 1, pos : 20 }, 20 )
      return
    }
    procs := GetWin32Proc()
    procList := procs.Count " processes:`n"
    for id,proc in procs.list
      procList .= proc.name "`n"
    FeedbackText := "User Name:  " SenderName "`nUser Email: " SenderEMail "`nOS:         " A_OSVersion "`nUAC:        " isUAC() "`nQC Version: " glb[ "ver" ] glb[ "qcArch" ] "`nAdmin:      " A_ISAdmin "`nUse Time:   " GetUseTime() "`n`nMessage:`n" FeedbackText "`n`n" procList
    GoSub, SaveFeedbackUserInfo
    if SendMail( "support@apathysoftworks.com","QC Feedback",FeedbackText,glb[ "xmlConfPath" ] )
      GoSub, 20GuiClose
    return
}


SendMail(sTo,sSubject="",sBody="",sAttach="",sCC="",sBCC="")
{
  fCOMErr := ComObjError( 1 )
  SplashWait(1,"Delivering...",20,0,5)
  ;read about "TO" field - http://msdn.microsoft.com/en-us/library/aa487617%28v=EXCHG.65%29.aspx
  ;can add multiple attachments, the delimiter is |
  sFrom     	 := "QC_fb <" glb[ "feedBackMail" ] ">"
  sUsername	 := glb[ "feedBackMail" ]
  sPassword	 := glb[ "feedBackMailPwd" ]

  sServer  	 := "mail.apathysoftworks.com" 	; specify your SMTP server
  nPort    	 := 587 				; 25
  bSSL     	 := 0 					; true = 1
  nSend  	 := 2  				    ; cdoSendUsingPort = 2
  nAuth    	 := 1   				; cdoBasic = 1

  pmsg   		 := ComObjCreate("CDO.Message")
  pmsg.From    := sFrom
  pmsg.To      := sTo
  pmsg.BCC     := sBCC   ; Blind Carbon Copy, Invisable for all, same syntax as CC
  pmsg.CC      := sCC
  pmsg.Subject := sSubject
  ;You can use either Text or HTML body like
  pmsg.TextBody := sBody
  ;OR
  ;pmsg.HtmlBody := "<html><head><title>Hello</title></head><body><h2>Hello</h2><br /><p>Testing!</p></body></html>"
  fields := Object()
  fields.smtpserver   		:= sServer ; specify your SMTP server
  fields.smtpserverport     	:= nPort ; 25
  fields.smtpusessl     		:= bSSL ; False
  fields.sendusing     		:= nSend   ; cdoSendUsingPort
  fields.smtpauthenticate     := nAuth   ; cdoBasic
  fields.sendusername 		:= sUsername
  fields.sendpassword 		:= sPassword
  fields.smtpconnectiontimeout := 20
  schema := "http://schemas.microsoft.com/cdo/configuration/"

  pfld :=   pmsg.Configuration.Fields

  For field,value in fields
     pfld.Item(schema . field) := value
  pfld.Update()
  Loop, Parse, sAttach, |, %A_Space%%A_Tab%
    pmsg.AddAttachment(A_LoopField)
  sleep 100
  try
    pmsg.Send()
  catch oEx
  {
    if RegExMatch( oEx.Message, "imO)Description:\s*(.*?)\s*$", match )
      err := match[1]
  }
  e := GetLastError()
  ComObjError( fCOMErr )
  if ( err || e )
  {
    SplashWait( -1,"",20,0,5 )
    msg := "Message send failed. Error:`n" errorFormat( e ) "`n" err
    ret := QMsgBoxP( { title : "Send failed"
                , msg : msg, buttons : "OK|Copy"
                , pos : 20, modal : 1 }, 20 )
    if( ret = "Copy" )
    {
      WinClip.Clear()
      WinClip.SetText( msg )
    }
    return 0
  }
  SplashWait(1,"Successfull",20,0,5)
  Sleep 1000
  SplashWait( 0, "", 20, 0, 5 )
  return 1
}