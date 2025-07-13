CopyCmd( cmd, win_hwnd )
{
  RegExMatch(cmd,"i)^[*^]*\s*(?=.*$)",match_out)
  isChooseFile := instr(match_out,"*") ? 1 : 0
  isDeleteSource := instr(match_out,"^") ? 1 : 0
  RegExMatch(cmd,"i)^[*^]*\s*\K.*$",dirs)
  if (dirs == "") 
  {
    FileSelectFolder, destDir,,3,copyto: Select Destination Folder
    dirs := destDir
  }
  dirs := StrRemoveChars(dirs,"""")
  fol := strsplit(dirs,"|",A_Space A_Tab)
  if !fol.MaxIndex()
  {
    err := "No destination folders specified"
    goto, copyto_finita
  }
  if isChooseFile
  {
    FileSelectFile,out_files,M,,copyto: Choose Files to Copy,*.*
    if !out_files
      return
    files_list := strsplit(out_files,"`n",A_Space A_Tab)
    SplashWait(1,"Copying...","",1,2)
    for i,path in files_list
    {
      if (i = 1)
      {
        init_fol := path . "\"
        continue
      }
      for j,fol_path in fol
        MoveFile(init_fol . path,path,fol_path)
      if isDeleteSource
        FileDelete,% init_fol . path
    }
    SplashWait(1,"Done","",1,2,1500)
    return
  }
  WinGet, proc, processName, % "ahk_id " win_hwnd
  if !proc {
    DTP("Failure!`nPlease try again",3000)
    return
  }
  WinGetClass, class, ahk_id %win_hwnd%
  if (proc != "explorer.exe") {
    err := "Unsupported window! Must be Explorer!"
    err_type := "wrong_proccess"
    goto, copyto_finita
  }
  else if (class ~= "(Cabinet|Explore)WClass") {
    for i,window in ShellGetWindows()
      if (window.hwnd==win_hwnd)
        sel := window.Document.SelectedItems
    if !isObject(sel) {
      err := "Unsupported window!"
      err_type := "no_sel_obj"
      goto, copyto_finita
    }
    if (sel.Count = 0) {
      err := "No selected items in the window!"
      goto, copyto_finita
    }
    SplashWait(1,"Copying...","",1,2)
    for item in sel
    {
      path := item.Path
      name := item.Name
      for i,p in fol
        MoveFile(path,name,p)
      if isDeleteSource
        FileDelete,% path
    }
  }
  else if (class ~= "Progman|WorkerW") {
    if !( files := GetDesktopSelection( -1 ) ) {
      err := "No selected files!"
      err_type := "desk_class"
      goto, copyto_finita
    }
    SplashWait(1,"Copying...","",1,2)
    for i,path in StrSplit( files,"`n",A_Space A_Tab "`r") 
    {
      SplitPath,path,out_name
      for j,fol_path in fol
        MoveFile(path,out_name,fol_path)
      if isDeleteSource
        FileDelete,% path
    }
  }
  else
  {
    err := "Unsupported window!"
    err_type := "unsupp_class"
    goto, copyto_finita
  }

copyto_finita:
  if err
  {
    for i,f in fol
      fol_list .= f . "`n"
    err_info =
    (LTrim
    type: %err_type%
    
    hWin: %win_hwnd%
    proc: %proc%
    class: %class%
    folders:
    %fol_list%
    )
    if A_IsCompiled
      DTP(err "`n" err_type)
    else
      msgbox,48,Error copying files,% err "`n" err_info
  }
  else
    SplashWait(1,"Done","",1,2,1500)
  return
}

;## NOT USED
Explorer_GetSelection(hwnd="") {
    WinGet, process, processName, % "ahk_id " hwnd := hwnd? hwnd:WinExist("A")
    WinGetClass class, ahk_id %hwnd%
    if (process = "explorer.exe")
        if (class ~= "Progman|WorkerW") {
      return ""
            ControlGet, files, List, Selected Col1, SysListView321, ahk_class %class%
            Loop, Parse, files, `n, `r
                ToReturn .= A_Desktop "\" A_LoopField "`n"
        } else if (class ~= "(Cabinet|Explore)WClass") {
            for i,window in ShellGetWindows()
                if (window.hwnd==hwnd)
                    sel := window.Document.SelectedItems
            for item in sel
                ToReturn .= item.path "`n"
        }
    return Trim(ToReturn,"`n")
}

GetDesktopSelection(hwnd)
{
  static files
  if ( hwnd = -1 )
    return files
  WinGetClass, class, ahk_id %hwnd%
  ControlGet, sl_hwnd, hwnd,,SysListView321,ahk_id %hwnd%
  if !( class ~= "Progman|WorkerW" && SendMessage( sl_hwnd, 0x1000 + 50, 0, 0 ) )  ;LVM_GETSELECTEDCOUNT    (LVM_FIRST + 50)
    files =
  else
  {
    WinClip.Snap( data )
    WinClip.Copy( glb[ "copyTO" ], qcOpt[ "gen_copy_method" ] )
    files := WinClip.GetFiles()
    WinClip.Restore( data )
  }
  return files
}

MoveFile(src_file,name,dest_fol)
{
  if !FileExist(dest_fol)
    FileCreateDir,% dest_fol
  if instr(FileExist(dest_fol),"D")
  {
    if instr(FileExist(src_file),"D")
      FileCopyDir,% src_file,% dest_fol "\" name, 1
    else
      FileCopy,% src_file,% dest_fol "\" name, 1
  }
  return
}