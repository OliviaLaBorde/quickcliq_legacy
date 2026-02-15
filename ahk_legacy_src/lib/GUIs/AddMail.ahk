AddMail(mail_to_parse = "", Parent_Gui = 1)	{

	global Adresses,CopyAdresses,HCAdresses,Subject,MailBody
	
	Gui, %Parent_Gui%:+Disabled
	Gui, 5:Default
	QCSetGuiFont( 5 )
	Gui, +owner%Parent_Gui%
	if qcOpt[ "gen_noTheme" ]
		Gui,-Theme
	ParseEmail(mail_to_parse,to,cc,bcc,subj,bdy)
	Gui, add, text,, To: (separate addresses by comma "`,")
	Gui, add, edit, R2 W280 vAdresses -WantReturn  Limit90,% to
	Gui, add, text,, CC:
	Gui, add, edit, R2 W280 vCopyAdresses -WantReturn  Limit90,% cc
	Gui, add, text,, BCC:
	Gui, add, edit, R2 W280 vHCAdresses -WantReturn  Limit90,% bcc
	Gui, add, text,, Subject:
	Gui, add, edit, R1 W280 vSubject Limit80,% subj
	Gui, add, text,, Message:
	Gui, add, edit, R5 W280 vMailBody Limit200,% bdy
	Gui, add, Button, Xm gSendMail W70 H20, Ok
	Gui, add, Button, X+35 gClearEMailFields W70 H20, Clear
	Gui, add, Button, X+35 gEmailGuiClose W70 H20, Cancel
	Gui, -0x10000 -0x20000
	Gui %Parent_Gui%:+LastFoundExist
	parent_hwnd := 
	WinGetPos, X, Y, W, H,% "AHK_ID " WinExist()
	Gui, show,% "x" . round(x+w/2-200) . " y" . round(y+h/2-200) . " W300", E-mail compose
	Loop
	{
		GuiControlGet,MailBody ,,MailBody
		if ErrorLevel
			break
		sleep 100
	}
	return Target
	
	;############################### SEND MAIL
	SendMail:
	Gui, 5:Default
	Gui, submit, nohide

	MailEscape(Adresses)
	MailEscape(HCAdresses)
	MailEscape(CopyAdresses)
	MailEscape(Subject)
	MailEscape(MailBody)

	if (Adresses = "")
		MailStr := "mailto:?"
	else
		MailStr := "mailto:" . Adresses . "?"
	if (CopyAdresses != "")
		MailStr := MailStr . "cc=" . CopyAdresses . "&"
	if (HCAdresses != "")
		MailStr := MailStr . "bcc=" . HCAdresses . "&"
	if (Subject != "")
		MailStr := MailStr . "subject=" . Subject . "&"
	if (MailBody != "")
		MailStr := MailStr . "body=" . MailBody
	Target := MailStr

	Gui, %Parent_Gui%:-Disabled
	Gui, 5:Destroy
	Gui %Parent_Gui%:+LastFoundExist
	MailStr = 
	IfWinExist
		WinActivate
	Return

	ClearEMailFields:
		GuiControl,,Adresses
		GuiControl,,CopyAdresses
		GuiControl,,HCAdresses
		GuiControl,,Subject
		GuiControl,,MailBody
		return

	;###############################
	EmailGuiClose:
	5GuiClose:
	5GuiEscape:
	Gui, %Parent_Gui%:-Disabled
	Gui, 5:Destroy
	Gui, %Parent_Gui%:+LastFoundExist
	WinActivate
	return	
}

ParseEmail( email, byref to, byref cc, byref bcc, byref subj, byref body )
{	
	to := cc := bcc := subj := body := ""
	if ( email = "" || instr( email, glb[ "optMTDivider" ] ) )
		return
	If RegExMatch(email,"^\s*mailto:.*?\?(cc=.*?&|)(bcc=.*?&|)(subject=.*?&|)(body=.*?|)\s*$")
	{
		if RegExMatch(email,"(?<=mailto:).*?(?=\?)",_to)
			to := MailDescape(_to)
		if RegExMatch(email,"(?<=cc=).*?(?=&)",_cc)
			cc := MailDescape(_cc)
		if RegExMatch(email,"(?<=bcc=).*?(?=&)",_bcc)
			bcc := MailDescape(_bcc)
		if RegExMatch(email,"(?<=subject=).*?(?=&)",_subj)
			subj := MailDescape(_subj)
		if RegExMatch(email,"(?<=body=).*",_body)
			body := MailDescape(_body)
	}
}