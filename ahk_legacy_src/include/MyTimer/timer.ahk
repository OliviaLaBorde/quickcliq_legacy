; time should be 0 or OFF to disable timer
SetTimer( funcName, time = "" )
{
    static st_timers := object(), st_cb := object()
    if !IsFunc( funcName )
        throw Exception( "Non existent function used for timer: " funcName, -1 )
    if st_timers.HasKey( funcName )
    {
        if ( time = "" )    ;just return parameters of active timer
            return st_timers[ funcName ]
        if ( time = "nOFF" && !( st_timers[ funcName ].delay < 0 ) )
            return
        DllCall( "KillTimer", "ptr", 0, "uint", st_timers[ funcName ].tID )
        st_timers.Delete( funcName )
    }
    if time is integer
        if ( time != 0 )
        {
            address := st_cb.hasKey( funcName ) ? st_cb[ funcName ] : ( st_cb[ funcName ] := RegisterCallback( funcName, "", 4 ) )
            timerID := DllCall( "SetTimer", "ptr", 0, "UInt", 0, "Uint", abs(time), "ptr", address )
            st_timers[ funcName ] := { tID : timerID, delay : time }
        }
    return
}

TimerGetParams( params )
{
	if IsObject( params )
		return params
	hwnd := NumGet( params + 0, 0, "Ptr" )
	msg := NumGet( params + 0, A_PtrSize, "UInt" )
	timerID := NumGet( params + 0, 4 + A_PtrSize, "UInt" )
	time := NumGet( params + 0, 8 + A_PtrSize, "UInt" )
	return [ hwnd, msg, timerID, time ]
}