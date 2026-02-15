RemWINhk(hk)
{
	if Instr(hk,"#")
		StringReplace, hk, hk, #
	Return hk
}

IsWINhk(hk)
{
	if Instr(hk,"#")
		return 1
	else
		return 0
}

HotkeyToString( HotKS ) {
	if( HotKS = "" )
		return "None"
	StringReplace,HotKS, HotKS, +, Shift+
	StringReplace,HotKS, HotKS, #, WIN+
	StringReplace,HotKS, HotKS, ^, Ctrl+
	StringReplace,HotKS, HotKS, !, Alt+
	StringReplace,HotKS, HotKS, RButton, Right Mouse Button
	StringReplace,HotKS, HotKS, MButton, Middle Mouse Button
	StringReplace,HotKS, HotKS, XButton1, Mouse 3 button
	StringReplace,HotKS, HotKS, XButton2, Mouse 4 button
	return %HotKS%
}

HotkeyFromVK( vk_hotkey )
{
	hotkeys := Array()
	if RegExMatch(vk_hotkey,"i)vk\K[0-9A-F]+$",vk_code)
	{
		StringReplace,vk_hotkey,vk_hotkey,vk%vk_code%
		for i,hkl in KeyboardLayoutList()
		{
			VarSetCapacity(lpKeyState,256,0)	;fake with nulls, wont work without
			vk := "0x" vk_code
			charNum := DllCall("ToAsciiEx","UInt",vk,"UInt",0,"Ptr",&lpKeyState,"UShort*",char,"Uint",0,"Ptr",hkl,"Int")
			if charNum
				hotkeys.insert(vk_hotkey . chr(char))
		}
	}
	else
		hotkeys.insert(vk_hotkey)
	return hotkeys
}

HotkeyGetVK( hk )
{
	if !RegExMatch(hk,"^\s*(\^|!|\+|#)*\K\pL$",letter)
		return [hk]		;1-element array
	StringReplace, hk, hk, % letter,,1
	hkList := Array()
	for i,v in GetVKList(letter)
		hkList.insert(hk . "vk" . v)
	return hkList
}

KeyboardLayoutList()
{
	hkl_num := 20
	VarSetCapacity(hHkls,hkl_num*A_PtrSize,0)
	num := DllCall("GetKeyboardLayoutList","Uint",hkl_num,"Ptr",&hHkls)
	hkl_list := Array()
	loop,% num
		hkl_list.Insert(NumGet(hHkls,(A_index-1)*A_PtrSize,"UPtr"))
	free(hHkls)
	return hkl_list
}

GetVKList( letter )
{
	SetFormat, Integer, Hex
	vk_list := Array()
	for i, hkl in KeyboardLayoutList()
	{
		retVK := DllCall("VkKeyScanExW","UShort",Asc(letter),"Ptr",hkl,"Short")
		if (retVK = -1)
			continue
		vk := retVK & 0xFF
		StringTrimLeft,vk,vk,2
		if !instr(_list,"|" vk "|")
		{
			_list .= "|" vk "|"
			vk_list.insert(vk)
		}
	}
	SetFormat, Integer, D
	return vk_list
}