;
; AutoHotkey Version: 1.x
; Language:       English
; Platform:       Win9x/NT
; Author:         A.N.Other <myemail@nowhere.com>
;
; Script Function:
;	Template script (you can customize this template by editing "ShellNew\Template.ahk" in your Windows folder)
;

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

str := "KLJDlsakldHJkljsdhakljhsLKDHSKLAJHd8u87	u p8hPOJSDPOKIJAOFSKH"
"".base.base := StringExtensions
msgbox % str.lower()
msgbox % str.lower() "`n" str.upper() "`n" str[5]
return

class StringExtensions
{
	__Get( prop )
	{
		StringMid, sub, this, prop, 1
		return sub
	}
	
	lower()
	{
		StringLower, new_string, this
		return new_string
	}
	upper()
	{
		StringUpper, new_string, this
		return new_string
	}
}
; http://www.autohotkey.com/community/viewtopic.php?t=50660
class StringLib {
    static init := ("".base.base := StringLib)
    static __Set := Func("StringLib_Set")
    Left(count=1) {
       return, SubStr(this, 1, count)
    }
    Right(count=1) {
       StringRight, out, this, count
       return, out
    }
    TrimL(count="") {
        if count.is_Str
            out := count? LTrim(this, count):LTrim(this)
        else
            StringTrimLeft, out, this, count
        return, out
    }
    TrimR(count="") {
        if count.is_Str
            return, count? RTrim(this, count):RTrim(this)
        else
            StringTrimRight, out, this, count
        return, out
    }
    Count(count) {
        StringReplace, this, this, %count%, , UseErrorLevel
        return, ErrorLevel
    }
    Replace(find, replace="") {
       StringReplace, out, this, %find%, %replace%, A
       return, out
    }
    GSub(needle, replace="") {
        return, RegExReplace(this, needle, replace)
    }
    Times(times) {
        VarSetCapacity(out, times)
        Loop, %times%
            out .= this
        return, out
    }
    Split(delim="", omit="") {
        out := object()
        if (SubStr(delim, 1, 2) = "R)") {
            this := this.Replace(omit), pos := 0, n:=start:=1
            if ((needle:=SubStr(delim, 3))="")
                return, this.Split(needle)
            while, pos := RegExMatch(this, needle, match, start)
                out[n++] := SubStr(this, start, pos-start), start := pos+StrLen(match)
            out[n] := SubStr(this, start)
        } else 
            Loop, Parse, this, %delim%, %omit%
                out[A_Index] := A_LoopField 
        return, out 
    } 
    RemoveLines(lines) {
        VarSetCapacity(out, n:=StrLen(this))
        Loop, Parse, this, `n, `r 
            if A_Index not in %lines%
                out .= A_LoopField "`n" 
        return, SubStr(out, 1, -1)
    }
    KeepLines(lines) {
        VarSetCapacity(out, n:=StrLen(this))
        Loop, Parse, this, `n, `r 
            if A_Index in %lines%
                out .= A_LoopField "`n" 
        return, SubStr(out, 1, -1)
    }
    __Call( p* )
    {
        msgbox % p[0] "`n" p[1] "`n" p[2] "`n" p[3]
        return 0
    }
    __Get(key, key2="") {
        if (key = "is_int") {
            if this is integer
                out := true
            else, 
                out := false
        } else if (key = "upper")
            StringUpper, out, this
        else if (key = "lower")
            StringLower, out, this
        else if (key = "capitalize")
            out := SubStr(this, 1, 1).upper . SubStr(this, 2).lower
        else if (key = "reverse") or (key = "rev")
            DllCall("msvcrt\_" (A_IsUnicode? "wcs":"str") "rev", "UInt",&this, "CDecl"), out:=this
        else if (key = "length") or (key = "len")
            out := StrLen(this)
        else if (key = "isEmpty")
            out := StrLen(this)? False:True
        else if key.is_int and key2.is_int
            out := SubStr(this, key, key2)
        else if key.is_int and key2=""
            out := SubStr(this, key, 1)
        else if (key = "toHex") {
            format := A_FormatInteger
            SetFormat, IntegerFast, Hex
            out := "" this+0 ""
            SetFormat, IntegerFast, %format%
        } else if (key = "toDec") {
            format := A_FormatInteger
            SetFormat, IntegerFast, Dec
            out := "" this+0 ""
            SetFormat, IntegerFast, %format%
        } else if (key = "is_str") {
            Format := A_FormatInteger
            SetFormat, IntegerFast, Hex
            out := SubStr(this:=this, 1, 2)="0x"? False:True
            SetFormat, IntegerFast, %Format%
        }
        return, out
    }
}
StringLib_Set(byref this, key, value){
   StringReplace, this, this, %key%, %value%, all
}