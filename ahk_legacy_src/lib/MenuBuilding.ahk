QCMenuRebuild( xmlMenuNode, init = False )
{
  static fState
  if fState
    return
  fState := 1
  the_menu := MenuRebuild( xmlMenuNode, init )
  fState := 0
  return the_menu
}

NodeGetColor( type, xmlNode, recurse = False )
{
  IsXmlElement( xmlNode )
  color := xmlNode.getAttribute( type )
  if !IsInteger( color )
  {
    if ( xmlNode.nodeName = "menu" )
      color := InStr( type, "bgcolor" ) ? glb[ "defBgColor" ] : glb[ "defTColor" ]
    else if recurse
    {
      type := SubStr( type, 1, 1 ) = "m" ? type : "m" type  ;when recursed - getting mtcolor or mbgcolor
      return NodeGetColor( type, xmlNode.parentNode, True ) 
    }
  }
  return color
}

RenewPUM()
{
  pumParams := glb[ "pumParams" ]
  pumParams[ "debug" ] := f_QC_DEBUG
  pumParams[ "pumfont" ] := QCGetFontSets() 
  pumParams[ "mnemonicCmd" ] := qcOpt[ "gen_mnem_method" ]
  pumParams[ "selMethod" ] := qcOpt[ "aprns_frameSelMode" ] ? "frame" : "fill"
  pumParams[ "frameWidth" ] := qcOpt[ "aprns_frameWidth" ]
  qcPUM.SetParams( pumParams )
  qcPUM.Destroy()
  return
}

; init means this is main menu and we renew many things, as well as recreate hotkeys/gestures
MenuRebuild( xmlMenuNode, init = False, oParentMenu = 0 )
{
  if ( xmlMenuNode = "main" )
    init := True
  xmlMenuNode := CheckMenuNode( xmlMenuNode )
  if init
  {
    Recent_Items( "save" )
    RenewPUM()
    glb[ "HotKeysAllowed" ] := 0
    IsNewCol( 0 )
    HotkeySetAll( 0 )
    qcCustomHotkeys := object()
    qcHotkeyList := object()
  }

  menuBGColor := NodeGetColor( "mbgcolor", xmlMenuNode, True )
  menuTColor := NodeGetColor( "mtcolor", xmlMenuNode, True )
  menuParams := { iconssize : toInt( qcOpt[ "aprns_iconsSize" ] )
                ,tcolor    : menuTColor
                ,bgcolor   : menuBGColor
                ,textoffset : glb[ "menuIconsOffset" ]
                ,noicons   : qcOpt[ "aprns_lightMenu" ]
                ,nocolors  : qcOpt[ "aprns_lightMenu" ]
                ,notext    : qcOpt[ "aprns_iconsOnly" ] && !qcOpt[ "aprns_lightMenu" ]
                ,ymargin   : 3 + toInt( qcOpt[ "aprns_heightAdjust" ] ) }
  objMenu := qcPUM.CreateMenu( menuParams )
  if !objMenu.handle
    ShowExc( "Unable create a new menu" )
; ////////////////////// Adding items to menu
  if init
    menuItemsCount := qcconf.GetItemsCount( xmlMenuNode ) + QCGetExtraCount()
  else
    menuItemsCount := qcconf.GetItemsCount( xmlMenuNode )
  curItemsNum := 0
  Loop
  {
    xmlItemNode := ( A_Index = 1 ) ? xmlMenuNode.firstChild : xmlItemNode.nextSibling
    if !xmlItemNode
      break
    if ( xmlItemNode.nodeName != "item" )	;it may be a 'command' sometimes
      continue
    ItemID := xmlItemNode.getAttribute( "ID" )
    ItemIcon := xmlItemNode.getAttribute( "icon" )
    ItemHotkey := xmlItemNode.getAttribute( "hotkey" )
    ItemName := xmlItemNode.getAttribute( "name" )
    ItemIsBold := xmlItemNode.getAttribute( "bold" )
    ItemIsSep := xmlItemNode.getAttribute( "issep" )
    ItemSubmenu := qcconf.IsMenu( xmlItemNode ) ? MenuRebuild( xmlItemNode, False, objMenu ) : 0
    ItemTColor := xmlItemNode.getAttribute( "tcolor" )
    ItemBGColor := xmlItemNode.getAttribute( "bgcolor" )
    
    ;check for FolderMenu
    if ( substr(ItemName,0) = "*" && !ItemSubmenu )
    {
      icoSize := qcOpt[ "fm_iconssize" ] = "global" ? qcOpt[ "aprns_iconsSize" ] 
                                          : qcOpt[ "fm_iconssize" ]
      ItemSubmenu := qcPUM.CreateMenu( { iconssize : toInt( icoSize )
                                ,textoffset : glb[ "menuIconsOffset" ]
                                ,tcolor : menuTColor
                                ,bgcolor : menuBGColor
                                ,noicons   : !qcOpt[ "fm_showicons" ]
                                ,nocolors  : qcOpt[ "aprns_lightMenu" ]
                                ,notext    : 0
                                ,FolderMenu : qcconf.GetItemCmdByID( ItemID )
                                ,FM_Root : True
                                ,ymargin   : 3 + toInt( qcOpt[ "aprns_heightAdjust" ] )} )
    }
    
    ItemParams := { name  : ItemName
                  ,issep : ItemIsSep
                  ,icon  : ItemIcon
                  ,uid   : ItemID
                  ,bold  : ItemIsBold
                  ,submenu : ItemSubmenu
                  ,tcolor : ItemTColor
                  ,bgcolor : ItemBGColor
                  ,break : ItemIsSep ? 0 : IsNewCol( objMenu, menuItemsCount, oParentMenu ) }
    
    objItem := objMenu.Add( ItemParams )
    
    ;hotkey definition
    if ItemHotkey
      qcCustomHotkeys[ ItemHotkey ] := objItem.id
  }
; ///////////////////////////////////////////////////////////////////
  if init
  {
    glb[ "mItemsNum" ] := menuItemsCount
    AddExtras( objMenu )
    ;separator for optional items
    if ( qcOpt[ "gen_helpSub" ] || qcOpt[ "gen_suspendSub" ] )
      objMenu.Add()
    ;help item
    if qcOpt[ "gen_helpSub" ]
      objMenu.Add( { name  : "Quick Help", icon : glb[ "icoHelpMe" ], uid : "QuickHelp"
                    ,break : IsNewCol( objMenu, menuItemsCount )  } )
    ;suspend item
    if qcOpt[ "gen_suspendSub" ]
    {
      suspMenu := qcPUM.CreateMenu( { iconssize : toInt( qcOpt[ "aprns_iconsSize" ] )
                                    ,tcolor    : menuTColor
                                    ,bgcolor   : menuBGColor
                                    ,textoffset: glb[ "menuIconsOffset" ]
                                    ,nocolors  : qcOpt[ "aprns_lightMenu" ]
                                    ,noicons : qcOpt[ "aprns_lightMenu" ]
                                    ,notext : qcOpt[ "aprns_iconsOnly" ] && !qcOpt[ "aprns_lightMenu" ]
                                    ,ymargin   : 3 + toInt( qcOpt[ "aprns_heightAdjust" ] ) } )
      suspMenu.Add( { name : qcOpt[ "hkey_glbOn" ] ? glb[ "l_hkeys_off" ] : glb[ "l_hkeys_on" ]
                    ,icon : qcOpt[ "hkey_glbOn" ] ? glb[ "icoSuspOn" ] : glb[ "icoSuspOff" ]
                    ,uid : "HK_Susp" } )
      suspMenu.Add( { name : qcOpt[ "gest_glbOn" ] ? glb[ "l_gstrs_off" ] : glb[ "l_gstrs_on" ]
                    ,icon : qcOpt[ "gest_glbOn" ] ? glb[ "icoSuspOn" ] : glb[ "icoSuspOff" ]
                    ,uid : "GS_Susp" } )
      objMenu.Add( { name  : "Suspend", icon : glb[ "icoSuspend" ], uid : "Susp"
                    ,break : IsNewCol( objMenu, menuItemsCount )
                    ,submenu : suspMenu } )
    }
    
    if qcOpt[ "gen_editorItem" ]
    {
      objMenu.Add()
      objMenu.Add( { name  : "Open Editor", icon : glb[ "icoMainEditor" ], uid : "QCEditor"
                    ,break : IsNewCol( objMenu, menuItemsCount ) } )
    }
    ; hotkeys & gestures settings
    MainMenuHotkeys( 1 )
    SetCustomHotkeys( 1 )
    
    if !qcOpt[ "hkey_glbOn" ]
      SetHotkeys( 0 )

    ;############ TRAY MENU ###################
    Menu,tray, DeleteAll
    Menu, tray, NoStandard
    HotKeySq := HotkeyToString( qcOpt[ "main_hotkey" ] )
    Menu,tray, add,% "Open Editor",MainGui
    Menu,tray, add
    Menu,tray, add,Use %HotKeySq% to open menu, MainMenu
    Menu,tray,Default,Use %HotKeySq% to open menu
    Menu,tray, add
    Menu,tray, add,% qcOpt[ "hkey_glbOn" ] ? glb[ "l_hkeys_off" ] : glb[ "l_hkeys_on" ],HotkeysSuspend
    Menu,tray, add,% qcOpt[ "gest_glbOn" ] ? glb[ "l_gstrs_off" ] : glb[ "l_gstrs_on" ],GesturesSuspend
    Menu,tray, add
    Menu,tray, add,Exit
    ;###########################################
    if ( !qcOpt[ "clips_gestOn" ]
      && !qcOpt[ "main_gestOn" ]
      && !qcOpt[ "wins_gestOn" ]
      && !qcOpt[ "memos_gestOn" ]
      && !qcOpt[ "recent_gestOn" ] )
    {
      qcPUM.GetItemByUID( "GS_Susp" ).SetParams( { name : glb[ "l_gstrs_on" ], disabled : 1, icon : glb[ "icoSuspOff" ] } )
      Menu,tray,Rename,% qcOpt[ "gest_glbOn" ] ? glb[ "l_gstrs_off" ] : glb[ "l_gstrs_on" ],% glb[ "l_gstrs_on" ]
      Menu,tray,Disable,% glb[ "l_gstrs_on" ]
    }
    else if qcOpt[ "gest_glbOn" ]
      SetGestureState( 1 )
    glb[ "HotKeysAllowed" ] := 1
  }
  if init
    qcMainMenu := objMenu
  return objMenu
}

IsNewCol( oPumMenu, menuItemsCount = 0, oParent = 0 )
{
  static om := object(), tf := object()
  if( oPumMenu = 0 )
  {
    ;an object contains items count for each menu
    om := object()
    ;an object contains t-form mode ( 0 or 1 ) for each menu ( if the feature enabled )
    tf := object()
    return 0
  }
  hMenu := oPumMenu.handle
  div := 0
  ; if feature to present menu view like columns not enabled - quit
  if !qcOpt[ "aprns_columns" ]
    return 0
  if !ObjHasKey( om, hMenu )
    om[ hMenu ] := 0
  if qcOpt[ "aprns_col_mode" ]
  {
    ColNum := qcOpt[ "aprns_ColNum" ] > 0 ? qcOpt[ "aprns_ColNum" ] : 1
    if qcOpt[ "aprns_TForm" ]
    {
      if !ObjHasKey( tf, hMenu )
      {
        if ( oParent && ObjHasKey( tf, oParent.handle ) )
          tf[ hMenu ] := !tf[ oParent.handle ] ;changing t-form mode opposite to the parent menu
        else
          tf[ hMenu ] := 0
      }
      if tf[ hMenu ]    
        ColNum := ceil( menuItemsCount/ColNum )
    }
    if( ceil( menuItemsCount/ColNum ) <= om[ hMenu ] )
    {
      om[ hMenu ] := 0
      div := qcOpt[ "aprns_colBar" ] ? 2 : 1
    }
  }
  else
  {
    maxnum := qcOpt[ "aprns_numpercol" ] > 0 ? qcOpt[ "aprns_numpercol" ] : 1
    if ( om[ hMenu ] >= maxnum )
    {
      om[ hMenu ] := 0
      div := qcOpt[ "aprns_colBar" ] ? 2 : 1
    }
  }
  om[ hMenu ]++
  return div
}

;returns the count of additional items in the main menu based on options settings
QCGetExtraCount()
{
  cnt := 0
  if qcOpt[ "gen_helpSub" ]
    cnt++  
  if qcOpt[ "gen_suspendSub" ]
    cnt++
  if qcOpt[ "gen_editorItem" ]
    cnt++
  If ( qcOpt[ "clips_on" ] && qcOpt[ "clips_sub" ] ) 
    cnt++
  if ( qcOpt[ "wins_on" ] && qcOpt[ "wins_sub" ] ) 
    cnt++
  if ( qcOpt[ "Memos_On" ] && qcOpt[ "memos_sub" ] )
    cnt++
  if ( qcOpt[ "recent_on" ] && qcOpt[ "recent_sub" ] )
    cnt++
  return cnt
}