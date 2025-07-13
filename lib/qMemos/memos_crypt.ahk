ProcessMemoEncrypt(cmd)
{
  Gui, 8:Default
  Gui +OwnDialogs
  text := GuiControlGet("MemoPreview",8)
  if (text == "")
    return
  if InStr( cmd, "MemoEncrypt" )
    ret_txt := MemoCrypt(text,1,8)
  else if InStr( cmd, "MemoDecrypt" )
    ret_txt := MemoCrypt(text,0,8)
  if (ret_txt = "")
  {
    Free(text)
    return
  }
  MemoToCtrl(ret_txt,"MemoPreview",8)
  GuiControlSet("SaveMemosButton","","Enable",8,0)
  Free(ret_txt), Free(text)
  return
}

MemoCrypt( data, flag, pgui="", promtadd="" )
{
  Global Crypt
  if pgui
  {
    Gui,%pgui%:Default
    Gui,%pgui%:+OwnDialogs
  }
  if (flag == 1)	;encrypt
  {
    promt =
    (LTrim
    Enter password to encrypt Memo.
    It will not be stored anywhere, so make sure you are remember it in order to decrypt it later.
    The password may be empty
    )
    promt .= promtadd
    if !GetPassword( password, promt, pgui )
      return ""
    if !b64 := Crypt.Encrypt.StrEncrypt( data, password, 7, 3 )	;aes 256 + sha
    {
      Free(password)
      return
    }
    Free(password)
    return Trim( b64, " `t`n`r" )
  }
  else if (flag == 0)	;decrypt
  {
    promt =
    (LTrim
    Enter password to decrypt Memo.
    )
    promt .= promtadd
    data := Trim( data, " `t`n`r" )
    if ( data == "" || RegExMatch( data,"[^A-Za-Z0-9\+/=]" ) || mod( StrLen(data),4 ) )
    {
      DTP( "Wrong data for decrypting memo!" )
      return ""
    }
    if !GetPassword(password,promt,pgui)
      return ""
    ret_str := Crypt.Encrypt.StrDecrypt( data, password, 7, 3 ) ;aes 256 + sha
    if ( ret_str = "" )
      MsgBox, 8240, Wrong Password, You have either entered a wrong password or data is not encrypted.
    else
      return ret_str
  }
  return ""
}

GetPassword(ByRef pwd, promt = "",pgui = "")
{
  global global_keep_crypt_pwd,global_crypt_pwd
  global pwde,bok,bcncl,spgui,state,PwdSessSave

  if (global_keep_crypt_pwd = "")
    global_keep_crypt_pwd := 0
  
  Gui,11:+LastFoundExist
  ifWinExist
  {
    WinActivate
    return 0
  }
  QCSetGuiFont( 11 )
  Gui,11:Default
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  if pgui
  {
    spgui := pgui
    Gui,+owner%pgui% +ToolWindow 
    Gui,%pgui%:+Disabled
  }
  else
    spgui := ""
  if (promt = "")
    promt := "Enter password:"
  Gui,Add,Text,w250,% promt
  Gui,Add,Edit,vpwde w250 y+10 Password,% global_crypt_pwd
  Gui,add,Checkbox,% "vPwdSessSave gPwdSessGL w250 +wrap Checked" . global_keep_crypt_pwd,Keep password during current session
  Gui,Add,Button,vbok gconfirmpwd Default w50,OK
  Gui,Add,Button,vbcncl gcancelpwd x+150 w50,Cancel
  Gui, -SysMenu
  Gui,Show,,Password Required
  GuiControl,Focus,pwde
  Loop
  {
    GuiControlGet,pwde ,,pwde
    if ErrorLevel
      break
    else
      pwd := pwde
    sleep 100
  }
  return state
  
  PwdSessGL:
    global_keep_crypt_pwd := GuiControlGet("PwdSessSave",11)
    return
  
  confirmpwd:
    state := 1
    goto, PwdGuiClose
    return
  
  11GuiClose:
  11GuiEscape:
  cancelpwd:
    state := 0
    goto, PwdGuiClose
    return
  
  PwdGuiClose:
    if spgui
    {
      Gui,%spgui%:-Disabled
      Free(spgui)
    }
    if global_keep_crypt_pwd
      global_crypt_pwd := GuiControlGet("pwde",11)
    else
      free(global_crypt_pwd)
    Gui,Destroy
    return
}