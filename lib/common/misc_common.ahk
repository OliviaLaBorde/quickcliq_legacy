VerCompare(num1,num2)
{
	if RegExMatch(num2,".*?(?=b\d+\s*$)", match )
	{
		num1 := RegExReplace(num1,"[^0-9]")
		num2 := RegExReplace(match,"[^0-9]")
		res := num1 >= num2
	}
	else {
		num1 := RegExReplace(num1,"[^0-9]")
		num2 :=	RegExReplace(num2,"[^0-9]")
		res := num1 > num2
	}
	return res
}

toInt( var )
{
  if IsInteger( var )
    return var
  else
    return 0
}

saveToFile( filePath, content, encoding = "" )
{
  f := FileOpen( filePath, "w", isEmpty( encoding ) ? A_FileEncoding : encoding )
  if !IsObject( f )
  {
    QMsgBoxP( { title : "Could not open file"
                , msg : "Could not open file for writing:`n" filePath "`n`nError:`n" ErrorFormat( A_LastError )
                , pic : "x" } )
    return 0
  }
  f.write( content )
  f.close()
  return 1
}

ObjGetItems( obj, indentSize = 0 )
{
  static objAddr  
  if !IsObject( obj )
    return ""
  if !indentSize
    objAddr := Object()
  if ObjHasKey( objAddr, &obj )
    return "obj at " &obj " (listed)"
  objAddr[ &obj ] := 1
  plan .= "obj at <" &obj ">"
  cnt := 0
  for key,value in obj
    ++cnt
  plan .= " " cnt "`n"
  try
    for key,value in obj
    {
      if IsObject( key )
        key := "object"
      if IsObject( value )
        value := ObjGetItems( value, indentSize + 2 )
      plan .= Indent( indentSize ) key " :`t" value "`n"
    }
  catch Ex
    plan .= Indent( indentSize ) Ex.message "`n"
  return plan
}

ObjGetRef( objPtr )
{
  if !IsInteger( objPtr )
    return -1
  ObjAddRef( objPtr )
  return ObjRelease( objPtr )
}

Indent( count, useTabs = False )
{
  indent := useTabs ? A_Tab : A_Space
  loop, % count
    string .= indent
  return string
}

IsInteger( var )
{
  if var is integer
    return True
  else 
    return False
}

max( var1, var2 )
{
  return var1>var2?var1:var2
}

isEmpty( var )
{
  return ( var = "" ? True : False )
}

SplashWait( mode, sptext = "",nGui = 1, OnTop = 1, SplashIndex = 7, DisableAfter=0 ) 
{
  static static_index,static_gui
  static_index := SplashIndex
  static_gui := nGui
  if (mode = 1)
  {
    if !sptext
      sptext := "Please Wait..."
    if nGui
    {
      Gui, %nGui%:Default
      Gui, +OwnDialogs
      Gui, +Disabled
      Gui, +LastFoundExist
      WinGetPos, X, Y, W, H,% "AHK_ID " WinExist()
    }
    si_pos := (x ? (" x" . (x+w/2-w/4)) : "") . (Y ? (" y" . (y+h/2-15)) : "") . " w" . (w ? w/2 : 250) . " h40"
    SplashImage,%SplashIndex%:,% "FS10 B CW405871 CTWhite " (OnTop ? "" : "A") . si_pos,% sptext
  }
  else if (mode = 0)
    SetTimer,DSI,-5
  else if ( mode = -1 )
    gosub, DSI
  if DisableAfter
    SetTimer,DSI,% "-" DisableAfter
  return
  
  DSI:
    if static_gui
      Gui, %static_gui%:-Disabled
    SplashImage, %static_index%: Off
    static_gui =
    static_index =
    return
}

DTP( tlp="",to=1500 )
{
  if tlp
  {
    Tooltip % tlp
    SetTimer,DTP,% "-" to
  }
  else
    SetTimer,DTP,% "-" to
  return
  
  DTP:
    ToolTip
    return
}

Free(byRef var)
{
  VarSetCapacity(var,0)
  return
}

range( num )
{
  arr := Array()
  if ( !num || ( num is not Integer ) )
    return arr
  loop,% num
    arr.insert( A_Index-1 )
  return arr
}

RemoveDubls( objArray ) {
  while True
  {
    nodubls := 1
    tempArr := Object()
    for i,val in objArray
    {
      if tempArr.haskey( val )
      {
        nodubls := 0
        objArray.Delete( i )
        break
      }
      tempArr[ val ] := 1
    }
    if nodubls
      break
  }
  return objArray
}

Arr2Str( obj, joiner )
{
  for i,v in obj
    ret .= ( ret ? joiner : "" ) v
  return ret
}

RGBtoBGR( bgr_clr )
{
  return ( bgr_clr & 0xFF0000 ) >> 16 | ( bgr_clr & 0x00FF00 ) | ( bgr_clr & 0x0000FF ) << 16
}