#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#persistent
#Include timer.ahk

SetTimer( "TimerProc", -1000 ) ;returns unique ID of registered timer. You can use it later to stop timer, otherwise it will be called repeatedly
SetTimer,testt,-2000
return

testt:
	sleep 100
	tooltip hello
	return

!h::
	ListHotkeys
	return

TimerProc( p* )
{
	obj := SetTimer( A_ThisFunc )
	if ( isObject( obj ) && ( obj.delay < 0 ) )
		SetTimer( A_ThisFunc, "OFF" )
	;~ tooltip % obj.tID " : " obj.callback " : " obj.delay " : " p1
	pms := TimerGetParams( p )
	tooltip % pms[1] "`n" pms[2] "`n" pms[3] "`n" pms[4]
	return
}