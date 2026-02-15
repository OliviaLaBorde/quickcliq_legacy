;############################### GET RANDOM TEXT
GetRandomAphorism()
{
	afos := StrSplit( GetAfos(), "@", A_Space A_Tab "`n`t" )
	Random,,A_Hour . A_Min . A_Sec . A_MSec
	Random, ind, 1,% afos.MaxIndex()
	parts := StrSplit( afos[ ind ], "&", A_Space A_Tab "`n`t" )
	glb[ "afo_cur" ] := RegExReplace( parts[1], "^.", "$U0")
	glb[ "afo_cur_details" ] := RegExReplace( parts[2], "^.", "$U0")
	return A_Tab glb[ "afo_cur" ]
}

GetAfos()
{
	APHORISM =
	(LTrim
	    Success is a journey not a destination. The doing is often more important than the outcome & Arthur Ashe @
	    If at first you don't succeed, try, try again. Then quit. There's no use being a damn fool about it & W.C. Fields @
		Memento Mori, Memento Vivere & Remember about death, Remember about live @
		Cogito ergo sum & I doubt, therefore I think, therefore I am @
		Amicus Plato, sed magis amica veritas & Plato is my friend, but truth is a better friend @
		Q.E.D. & quod erat demonstrandum - which means "that which was to be demonstrated" @
		Natura non facit saltus & nature does not make jumps @ aut viam inveniam aut faciam & I'll Either Find a Way or Make One  @
		adde parvum parvo magnus acervus erit & Add a little to a little and there will be a great heap @
		crede quod habes, et habes & Believe that you have it, and you have it @
		dulce bellum inexpertis & War is sweet to those who have not experienced it @
		legum servi sumus ut liberi esse possimus & We are slaves of the laws in order that we may be free @
		beneficium accipere libertatem est vendere & To accept a favour is to sell freedom @
		deficit omne quod nasciture & Everything that is born passes away @
		certum est quia impossible est &  It is certain because it is impossible @
		cave quid dicis, quando, et cui & beware what you say, when, and to whom @
		amare et sapere vix deo conceditur & even a god finds it hard to love and be wise at the same time @
		One single grateful thought raised to heaven is the most perfect prayer & G. E. Lessing @
		Poets have been mysteriously silent on the subject of cheese & G. K. Chesterton @
		If there were no God, there would be no Atheists & G. K. Chesterton @
		There is no wisdom without love & N. Sri Ram @
		Anything you fully do is an alone journey & Natalie Goldberg @
		The greatest thing you'll ever learn is just to love and be loved in return & Nat King Cole @
		Eyes that see do not grow old & Nicaraguan Proverb @
		Nothing is easy to the unwilling & Nikki Giovanni @
		The joy of a spirit is the measure of its power & Ninon de Lenclos @
		Life is an adventure in forgiveness & Norman Cousins @
		You can tell the ideals of a nation by its advertisements & Norman Douglas @
		Any fool can criticize, condemn, and complain - and most fools do & Dale Carnegie @
		The best way to live is by not knowing what will happen to you at the end of the day... & Donald Barthelme @
		Change, when it comes, cracks everything open & Dorothy Allison @
		If my hands are fully occupied in holding on to something, I can neither give nor receive & Dorothee Solle @
		This being human is a guest house. Every morning a new arrival & Rumi @
		Do you love me because I'm beautiful, or am I beautiful because you love me? & Oscar Hammerstein @
		Believe in the importance of love... & Believe in the importance of love for it is the strength an beauty that brings music to our souls.@
		Don’t frown because you never know who might be falling in love with your smile.@
		I have learned not to worry about love; But to honor its coming with all my heart. & Alice Walker @
		I love you, not for what you are, but for what I am when I am with you. & Ray Croft @
		If there is anything better than to be loved it is loving. @
		If you judge people, you have no time to love them. & Mother Teresa @
		Let love be the sweet elixir that awakens your spirit and moves your soul to dance. @
		Don't be afraid your life will end; be afraid that it will never begin. & Grace Hansen @
		Each morning when I open my eyes... & ...I say to myself: I, not events, have the power to make me happy or unhappy today. 
I can choose which it shall be. Yesterday is dead, tomorrow hasn't arrived yet. 
I have just one day, today, and I'm going to be happy in it.
-Groucho Marx @
		I postpone death by living, by suffering, by error, by risking, by giving, by losing. & Anaias Nin @
		The most common way people give up their power is by thinking they don't have any. & Alice Walker @
		Time is a dressmaker specializing in alterations. & Faith Baldwin @
		Buy land. They've stopped making it. & Mark Twain @
		Clothes make the man. Naked people have little or no influence on society. & Mark Twain @
		For some strange reason, no matter where I go, the place is always called "here" & Ashleigh Brilliant @
		All, everything that I understand, I understand only because I love. & Leo Tolstoy
		@ The more closely you look at one thing, the less closely can you see something else. & Heisenberg @
		On the other hand, you have different fingers & Jack Handy @
		我慢 & Gaman - enduring the seemingly unbearable with patience and dignity.`nAlso means endurance, patience, tolerance, perseverance, self-control (Japanese) @
		May your life on this Earth be a happy one... May the sun be warm and may the sky be blue... & part of "Irish Blessing" @
		Fame usually comes to those who are thinking about something else. & Wendell Holmes @
		Optimism is the faith that leads to achievement. & Helen Keller @
		Success comes in cans, failure in can'ts. & Unknown @
		We grow great by dreams. All big men are dreamers. & Woodrow T. Wilson @
		Oh man! There is no planet, sun or star that could hold you, if you but knew what you are.& Ralph Waldo Emerson @
		Act as if what you do makes a difference. It does. & William James @
		If you’re going to doubt something, doubt your own limits. & Don Ward @
		When you live on a round planet, there's no choosing sides. & Wayne Dyer @
		An honest answer is the sign of true friendship. & Proverb @
		Life is 10`% what happens to you and 90`% how you react to it. & Charles Swindoll @
		Every day brings a choice: to practice stress or to practice peace. & Joan Borysenko @
		Beware of the half truth. You may have gotten hold of the wrong half. & Unknown @
		Put your future in good hands - your own. & Unknown @
		Hare Krishna Hare Krishna, Krishna Krishna Hare Hare & Hare Krishna Hare Krishna, Krishna Krishna Hare Hare`nHare Rama Hare Rama, Rama Rama Hare Hare @
		Criticism is something you can easily avoid by saying nothing, doing nothing, and being nothing. & Aristotle @
		The real measure of your wealth is how much you'd be worth if you lost all your money. & Unknown @
		Politics is the entertainment branch of industry. & Unknown
	)
	return APHORISM
}

SendAfoForm()
{
	global
	local tlp,afo, MailBody
	Gui,1:+Disabled
	Gui,21:Default
	QCSetGuiFont( 21 )
	if qcOpt[ "gen_noTheme" ]
		Gui,-Theme
	SB_Changed := 0
	Gui,+owner1
	Gui,Add,Text,w300 +Wrap cNavy,% "Use this form to send us a new aphorism you think should be included in " glb[ "appName" ] ". Try it to be short and meaningful :)"
	Gui,Add,Text,w300 +Wrap,Aphorizm:
	Gui,Add,Edit,w300 vtAfo R2 Limit150 +Wrap -VScroll -WantReturn gShowAfoPreview
	Gui,Add,Text,w300 +Wrap,Tooltip (Optional - author/traslation to english/etc...):
	Gui,Add,Edit,w300 vtAfoToolt r3 +Multi +Wrap
	Gui,Add,Button,w70 gSendNewAfoB,Send
	Gui,1:+LastFoundExist
	WinGetPos, X, Y, W, H,% "ahk_id " WinExist()
	Gui,Show,% "x" . round(x+(w/2)-150) . " y" . round(y+(h/2)-120),Send Afo
	return
	
	ShowAfoPreview:
		Gui, 1:Default
		SB_SetText(A_Tab . GuiControlGet("tAfo",21))
		SB_Changed := 1
		return
	
	AfoSended:
	21GuiClose:
	21GuiEscape:
		Gui,1:-Disabled
		Gui,21:Destroy
		if SB_Changed
		{
			Gui, 1:Default
			SB_SetText( GetRandomAphorism() )
		}
		return
		
	SendNewAfoB:
		If (GuiControlget("tAfo",21) = "")
		{
			DTP("Cannot send empty Afo!")
			return
		}
		afo := GuiControlget("tAfo",21)
		tlp := GuiControlget("tAfoToolt",21)
		MailBody := "Use Time:   " GetUseTime() "`n`nAfo:`n" b64Encode( afo, strlen(afo)*2 ) "`n`nTooltip:`n" tlp
		SendMail("pavel@apathysoftworks.com","QC new Afo: " . afo,MailBody)
		GoSub, AfoSended
		return
}