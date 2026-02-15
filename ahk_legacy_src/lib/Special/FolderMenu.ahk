FM_BuildMenu( menu )
{
  static fBuildState
  if fBuildState
    return
  fBuildState := True
  fm_dir := menu.FolderMenu
  ;~ ObjRemove( menu, "FolderMenu" )	;removing field to prevent building this menu second time
  SetTimer( "FM_BuildTlp", -1000 )	;show tooltip when FM menu building takes more than 1 sec
  if ( fm_dir := QCGetDir(  fm_dir ) )
  {
    menu.FM_Built := 1
    if menu.FM_Root
      menu.FM_BuildTime := A_Now
    fShIcons := qcOpt[ "fm_showicons" ]
    icoSize := qcOpt[ "fm_iconssize" ] = "global" ? qcOpt[ "aprns_iconsSize" ] 
                                          : qcOpt[ "fm_iconssize" ]
    menuParams := { iconssize : toInt( icoSize )
                  ,textoffset: glb[ "menuIconsOffset" ]
                  ,tcolor : menu.GetTColor()
                  ,bgcolor : menu.GetBGColor()
                  ,noicons   : !fShIcons
                  ,nocolors  : qcOpt[ "aprns_lightMenu" ]
                  ,notext    : 0
                  ,ymargin   : 3 + toInt( qcOpt[ "aprns_heightAdjust" ] )}
    if qcOpt[ "fm_show_open_item" ]
    {
      menu.Add( { name : ".."
              , icon : fShIcons ? FM_GetIcon( "folder", icoSize ) : 0
              , iconUseHandle : 1
              , uid : "FolderMenu_Item"
              , FM_Target : fm_dir } )
      menu.Add()
    }
    Loop,% fm_dir "\*", 1, 0
    {
      hasItems := 1
      break
    }
    if !hasItems
      menu.Add( "(empty)" )
    else
    {
      if qcOpt[ "fm_files_first" ] {
        FM_AddFiles( fm_dir, menu )
        FM_AddFolders( fm_dir, menu, menuParams )
      }
      else {
        FM_AddFolders( fm_dir, menu, menuParams )
        FM_AddFiles( fm_dir, menu )
      }
    }
  }
  SetTimer( "FM_BuildTlp", "OFF" )
  tooltip
  fBuildState := False
  return
}

FM_AddFolders( dirPath, oMenu, menuParams )
{
  fShIcons := qcOpt[ "fm_showicons" ]
  icoSize := qcOpt[ "fm_iconssize" ] = "global" ? qcOpt[ "aprns_iconsSize" ] 
                                            : qcOpt[ "fm_iconssize" ]
  sortt := qcOpt[ "fm_sort_type" ]
  sortm := qcOpt[ "fm_sort_mode" ]
  for i,file in GetFilesList( dirPath, "folders", sortt, sortm )
  {
    menuParams.FolderMenu := file.fpath
    oMenu.Add( { name : file.name
                , icon : fShIcons ? FM_GetIcon( "folder", icoSize ) : 0
                , submenu : qcPUM.CreateMenu( menuParams )
                , iconUseHandle : 1
                , uid : "FolderMenu_Item"
                , FM_Target : file.lpath } )
  }
  return
}

FM_AddFiles( dirPath, oMenu )
{
  fShExt := qcOpt[ "fm_show_files_ext" ]
  fShLnk := qcOpt[ "fm_show_lnk" ]
  fShIcons := qcOpt[ "fm_showicons" ]
  icoSize := qcOpt[ "fm_iconssize" ] = "global" ? qcOpt[ "aprns_iconsSize" ] 
                                        : qcOpt[ "fm_iconssize" ]
  sortt := qcOpt[ "fm_sort_type" ]
  sortm := qcOpt[ "fm_sort_mode" ]
  for i,file in GetFilesList( dirPath, "files", sortt, sortm )
  {
    oMenu.Add( { name : fShExt ? ( !fShLnk && file.ext = "lnk" ? PathRemoveExt( file.name )
                                  : file.name )
                      : PathRemoveExt( file.name )
                , icon : fShIcons ? FM_GetIcon( file.fpath, icoSize ) : 0
                , iconUseHandle : 1
                , uid : "FolderMenu_Item"
                , FM_Target : file.lpath } )
  }
  return
}

GetFilesList( path, ni, sort_type = "", sort_mode = "" )
{
  list := object()
  loop, % path "\*",% ni = "files" ? 0 : ni = "folders" ? 2 : 1, 0
    list.insert( { name : A_LoopFileName
                  , ext : A_LoopFileExt
                  , fpath : A_LoopFileFullPath
                  , lpath : A_LoopFileLongPath 
                  , dir : A_LoopFileDir
                  , modified : A_LoopFileTimeModified
                  , created : A_LoopFileTimeCreated
                  , accessed : A_LoopFileTimeAccessed
                  , attr : A_LoopFileAttrib 
                  , size : A_LoopFileSize } )
  if sort_type
  {
    fIsNumeric := True
    r_attrib := sort_type = "Name" ? ( "name", fIsNumeric := False )
                : sort_type = "Time Created" ? "created"
                : sort_type = "Time Modified" ? "modified"
                : sort_type = "Size" ? "size"
                : sort_type = "Type" ? ( "ext", fIsNumeric := False )
                : ""
    if( r_attrib ~= "Size|Type" && ni = "folders" )
      r_attrib := "Name"
    if r_attrib
    {
      for i,v in list
        sList .= i "\" v[ r_attrib ] "`n"
      Sort, sList,% "\ " 
      . ( !fIsNumeric ? "" : sort_mode = "Desc" ? " F FM_NumSortRev " : " F FM_NumSort " )
      . ( sort_mode = "Desc" ? " R " : ""  )
      tmpList := Object()
      for i,v in StrSplit( sList, "`n", A_Space A_Tab )
      {
        p := StrSplit( v, "\", A_Space A_Tab )
        tmpList.insert( list[ p[1] ] )
      }
      list := tmpList
    }
  }
  return list
}

FM_NumSort( p1, p2 )
{
  pn1 := Trim( StrSplit( p1, "\" )[2] )+0
  pn2 := Trim( StrSplit( p2, "\" )[2] )+0
  return pn1 > pn2 ? 1
        : pn1 = pn2 ? 0
        : -1
}

FM_NumSortRev( p1, p2 )
{
  pn1 := Trim( StrSplit( p1, "\" )[2] )+0
  pn2 := Trim( StrSplit( p2, "\" )[2] )+0
  return pn1 > pn2 ? -1
        : pn1 = pn2 ? 0
        : 1
}

FM_BuildTlp( p* )   ;show tooltip when FM menu building takes too long
{
  SetTimer( A_ThisFunc, "nOFF" )
  tooltip building...
}

FM_GetIcon( filePath, icoSize )
{
  static fm_icos := object()
  if ( filePath = "" )
    return 0
  if ( filePath = "deleteAll" )
  {
    for i,hIcon in fm_icos
      DestroyIcon( hIcon )
    fm_icos := object()
    return 0
  }
  if ( filePath = "folder" )
  {
    if !fm_icos[ "folder" ]
      fm_icos[ "folder" ] := IconExtract( glb[ "icoFolder" ], icoSize )
    icoHandle := fm_icos[ "folder" ]
  }
  else if ( fileExt := PathGetExt( filePath ) )
  {
    if ( fileExt = "lnk" )
    {
      PathShortcutGet( filePath, sTarget, sIcon, False )
      if( sIcon ) ;&& !sTarget )
        return sIcon
      else if ( ( fExt := PathGetExt( sTarget ) ) && !PathIsDir( sTarget ) )
        filePath := sTarget, fileExt := fExt
    }
    if fileExt not in lnk,ico,exe
    {
      if fm_icos.HasKey( fileExt )
        icoHandle := fm_icos[ fileExt ]
      else
      {
        hIcon := IconExtract( IconGetFromPath( filePath ), icoSize )
        if hIcon
          icoHandle := fm_icos[ fileExt ] := hIcon
      }
      if !icoHandle
      {
        hAssocIcon := IconGetAssociated( filePath )
        fm_icos[ fileExt ] := IconCopy( hAssocIcon, icoSize, 1, 0 )
        icoHandle := fm_icos[ fileExt ]
      }
    }
    else if ( fileExt = "exe" )
    {
      if qcOpt[ "fm_extractExe" ]
        icoHandle := IconExtract( filePath, icoSize )
      else
      {
        if !fm_icos[ "exe" ]
          fm_icos[ "exe" ] := IconExtract( "shell32.dll:2", icoSize )
        icoHandle := fm_icos[ "exe" ]
      }
    }
    else
      icoHandle := IconGetFromPath( filePath )
  }
  else
  {
    if !fm_icos[ "" ]
      fm_icos[ "" ] := IconExtract( "shell32.dll:0", icoSize )
    icoHandle := fm_icos[ "" ]
  }
  return icoHandle
}

FM_Reset( oMenu )
{
  oMenu.DestroyItems()
  oMenu.FM_Built := 0
  return
}

FM_CheckMenuTime( oMenu )
{
  if !( oMenu.FM_Root && oMenu.FM_Built && qcOpt[ "fm_refresh_on" ] )
    return
  fmTime := qcOpt[ "fm_refresh_time" ]
  if !IsInteger( fmTime )
    return
  lastTime := oMenu.FM_BuildTime
  curTime := A_Now
  EnvSub, curTime,% lastTime, Minutes
  if( curTime >= fmTime )
    FM_Reset( oMenu )
  return
}