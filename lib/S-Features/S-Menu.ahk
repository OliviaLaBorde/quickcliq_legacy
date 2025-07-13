/*
Functions for creating S-menus
*/

SMenu_Copy( menu_ID, dest_file )
{
  static qcm_options := [ "aprns_IconsTlp", "aprns_iconsSize", "aprns_lightMenu", "aprns_heightAdjust"
                          , "aprns_iconsOnly", "aprns_colBar", "aprns_columns"
                          , "aprns_ColNum", "aprns_transp"
                          , "aprns_tform", "aprns_mainfont", "aprns_fontqlty" 
                          , "fm_show_open_item", "fm_extractexe", "fm_showicons"
                          , "fm_show_files_ext", "fm_iconssize", "fm_files_first"
                          , "fm_show_lnk", "fm_sort_type", "fm_sort_mode"
                          , "gen_cmddelay", "gen_mnem_method" ]    ;only this options will be copied to the target qcm
  xmlNode := qcconf.ItemResolve( menu_ID )
  if !qcconf.IsMenu( xmlNode )
    ShowExc( "The node is not menu`nID: " menu_ID )
  smNode := qcconf.NewNode( "qc_" )
  menuNode := qcconf.NewNode( "menu" )
  smNode.appendChild( menuNode )
  setsNode := qcconf.NewNode( "settings" )
  smNode.appendChild( setsNode )
  ;saving needed options into qcm
  qcOptNode := qcconf.GetOptNode()
  for i,optionName in qcm_options
    if ( optNode := qcOptNode.selectSingleNode( "opt[ @name='" optionName "' ]" ) )
      setsNode.appendChild( optNode.cloneNode( True ) )
  ; setting needed attributes to the top qcm menu
  menuNode.setAttribute( "ID", 0 )
  menuNode.setAttribute( "PRE_ID", xmlNode.getAttribute( "ID") )
  tc := NodeGetColor( "mtcolor", xmlNode, True )
  bgc := NodeGetColor( "mbgcolor", xmlNode, True )
  menuNode.setAttribute( "mtcolor", tc )
  menuNode.setAttribute( "mbgcolor", bgc )
  ; copying all nodes from the target node
  for node in xmlNode.selectNodes( "./item" )
    menuNode.appendChild( node.cloneNode( True ) )
  SaveXml( smNode, dest_file )
  return
}

; function to update existing S-Menu, syncing it with the current user settings
; ti checks if the item with ID = PRE_ID of the 'menu' node from QCM file exists and updates it by calling SMenu_Copy()
SMenu_UpdateMenu( qcmPath )
{
  IfNotExist,% qcmPath
  {
    QMsgBoxP( { title : "Error parsing QCM", msg : "File not found:`n" qcmPath,buttons : "Exit", pic : "!" } )
    return False
  }
  qcconf := new XMLManager() ;loading user's current settings
  xdoc := XMLCreateObj()
  xdoc.load( qcmPath )
  oXmlErr := xdoc.parseError
  ; errors checking
  if oXmlErr.errorCode                                                                                                                     ; error while parsing XML
    err := "XML parsing error.`n" XMLParseError( oXmlErr )
  else if !( ( xdoc := xdoc.documentElement ).nodeName = "qc_" )                                            ; root node name != qc_
    err := "Wrong root element name"
  else if !( menuNode := xdoc.selectSingleNode( "menu" ) )                                                      ; root node does not contain 'menu' node
    err := "'menu' node not found"
  else if IsEmpty( prevID := menuNode.getAttribute( "PRE_ID" ) )                                            ; 'menu' node does not contain PRE_ID attribute
    err := "No link to the menu found"
  else if !( prevNode := qcconf.ItemResolve( prevID ) )                                                              ; current config does not contain item with id = PRE_ID
    err := "No item with ID: " prevID " found."
  else if !qcconf.IsMenu( prevNode )                                                                                           ; item with needed ID found, but it is not a menu
    err := "Item with ID " prevID " is not a menu."
  else
    SMenu_Copy( prevID, qcmPath )                                                                                               ; all is ok, updating menu
  if err
  {
    err := "Could not update S-Menu. Error:`n" err
    QMsgBoxP( { title : "S-Menu update: Fail", msg : err,buttons : "Exit", pic : "!" } )
    return False
  }
  else
  {
    QMsgBoxP( { title : "S-Menu update: Success", msg : "S-Menu successfully updated!", pic : "i" } )
    return True
  }
}

SMenu_Run( qcm_file )
{
  glb[ "fSMenuRun" ] := 1
  qcconf := new XMLManager( qcm_file )
  RenewPUM()
  smMenu := QCMenuRebuild( qcconf.GetMenuNode() )
  MouseGetPos,x,y
  if ( item := smMenu.Show( x, y ) )
    loop
    {
      sleep 50
    } until ( qcExec.curThreads = 0 )
  return
}

Gui_Main_TVItem_CreateSMenu()
{
  Gui, 12:+OwnDialogs
  Gui, 1:+Disabled
  if ( qcOpt[ "gen_smenusOn" ] != 1 )
  {
    msg = 
    ( LTrim
        You must enable this feature before using it.
        
    S-Menu allows you create a file-looking separate menu anywhere on your desktop. It opens corresponding menu when you double click it.
    
    Enabling S-Menu will require few registry writings.
    Do you want to enable S-Menus now?
    )
    if ( "No" = QMsgBoxP( { title : "S-Menu disabled"
                ,msg : msg
                ,buttons : "Yes|No"
                ,pic : "?", modal : 1, pos : 12 }, 12 ) )
      {
        Gui, 1:-Disabled
        return
      }
    SMenu_SetRegistry( True )
    qcOpt[ "gen_smenusOn" ] := 1
  }
  Gui, 1:Default
  MID := TV_GetSelection()
  if !TV_GetChild( MID )
    return
  if MID
    TV_GetText(menuname, MID)
  else
    menuname := "Main Menu"
  FileSelectFile, dest_file, S18,% PathCleanup( menuname . ".qcm" ),Choose where to save menu,Quick Click Menu (*.qcm)
  if dest_file
  {
    SplitPath, dest_file,,,dest_Ext
    if (dest_Ext = "")
      dest_file .= ".qcm"
    SMenu_Copy( qcTVItems[ MID ], dest_file )
  }
  Gui, 1:-Disabled
  return
}