QCCheckXMLconf()
{
  if !FileExist( glb[ "xmlConfPath" ] )
  {
    if ( FileExist( glb[ "settingsPath" ] ) || FileExist( glb[ "itemsPath" ] ) )
    {
      appname := glb[ "appName" ]
      msg = 
      (LTrim
        %appname%'s settings format has been changed starting with version 2.0.
        A few other breaking changes has also been made.
        
        Please, READ the following before you proceed.
        
        1. Upon conversion all your menu configuration will be saved, as well as hotkeys/gestures settings.
        But you will need to manually recheck all other options beside this.
        
        2. Your previous "ini" configuration will not be changed, so you still may use it with old %appname% version if you wish.
        
        3. A few changes to memos encryption system has been made.
        Please, convert all your encrypted Memos using old %appname% of version 1.3.7 before proceed.
        
        4. Saved Clips from %appname% 1.3.7 not compatible with new version. Just recreate those you need.
        
        Press "Exit" if you need to make changes before proceed.
        
        By pressing "Convert" button your menu configuration will be converted to the new format.
        By pressing "Blank" button you'll start with empty menu and default settings.
        In either case your former configuration will not be changed, so you may still use %appname% 1.3.7 later
        If you want this dialog display later, just delete .\Data\qc_conf.xml file
      )
      ans := QMsgBoxP( { title : glb[ "appName" ] " critical changes", msg : msg
                , buttons : "Convert|Blank|Exit", pic : "i", ontop : 1
                , editbox : 1, editbox_h : 250, editbox_w : 350
                , rsz : 1 } )
      if ( ans = "Exit" || !ans )
        ExitApp
    }
    else
      glb[ "firstRun" ] := True
    xmldoc := XMLCreateNewQCConf( ans = "Convert" ? 1 : 0 )
    SaveXml( xmldoc, glb[ "xmlConfPath" ] )
  }
  else
  {
    xmldoc := XMLCreateObj()
    xmldoc.load( glb[ "xmlConfPath" ] )
    err := xmldoc.parseError
    if err.errorCode
      errDescr := err.reason
                  . ( err.srcText ? "`n" err.srcText : "" )
                  . "`nLine: " err.line ", Pos: " err.linepos
    else
    {
      mainNode := xmldoc.documentElement
      errDescr := mainNode.nodeName != "qc_" ? "wrong main Node name: " mainNode.nodeName
              : !mainNode.selectSingleNode( "lastID" ) ? "no 'lastID' node"
              : !mainNode.selectSingleNode( "menu" ) ? "no 'menu' node"
              : !mainNode.selectSingleNode( "settings" ) ? "no 'settings' node"
              : !mainNode.selectSingleNode( "wins" ) ? "no 'wins' node"
              : 0
    }
    if errDescr
    {
      bkName := glb[ "xmlConfPath" ] ".bak"
      IfExist,% bkName
      {
        btns := "Send|Blank|Restore|Exit"
        bkMsg := "`nPress 'Restore' to restore latest backup.`n"
      }
      else
        btns := "Send|Blank|Exit"
      msg =
      ( LTrim
      Error occured while reading XML file:
      Reason:
      %errDescr%
      
      If you can't understand what the problem is, - send this message and your qc_conf.xml file to support@apathysoftworks.com so we could help you.
      %bkMsg%
      WARNING! Choosing 'Blank' will erase your current settings.
      )
      a := QMsgBoxP( { title : "Error parsing XML", msg : msg
                , buttons : btns, pic : "!" } )
      if ( a = "Exit" || !a )
        ExitApp
      if( a = "Send" )
      {
        body := "XML parse error:`n" errDescr "`n---`nPlease attach qc_conf.xml to this e-mail"
        subject := glb[ "appName" ] " XML parse error"
        Run,% "mailto:support@apathysoftworks.com?body=" MailEscape(body) "&subject=" MailEscape( subject ),, UseErrorLevel
        ExitApp
      }
      if( a = "Restore" )
      {
        FileCopy,% glb[ "xmlConfPath" ] ".bak",% glb[ "xmlConfPath" ], 1
        QCRestart()
      }
      xmldoc := XMLCreateNewQCConf( 0 )
      SaveXml( xmldoc, glb[ "xmlConfPath" ] )
    }
  }
  return xmldoc
}

XMLCreateNewQCConf( convertOldFormat = 1 )
{
  xmldoc := XMLCreateObj()
  mainNode := xmldoc.appendChild( xmldoc.createElement( "qc_" ) )
  mainNode.appendChild( xmldoc.createElement( "lastID" ) ).text := 0
  menuNode := mainNode.appendChild( xmldoc.createElement( "menu" ) )
  menuNode.setAttribute( "ID", "0" )
  menuNode.setAttribute( "name", "main" )
  setsNode := mainNode.appendChild( xmldoc.createElement( "settings" ) )
  winsNode := mainNode.appendChild( xmldoc.createElement( "wins" ) )
  if ( convertOldFormat )
  {
    if FileExist( glb[ "itemsPath" ] )
      XMLBuildMenu( glb[ "itemsPath" ], menuNode, "main" )
    else
      QMsgBoxP( { title : "Missing File", msg : "Could not locate file:`n" glb[ "itemsPath" ], pic : "!" } )
    if FileExist( glb[ "settingsPath" ] )
      XMLBuildSets( glb[ "settingsPath" ], setsNode )
    else
      QMsgBoxP( { title : "Missing File", msg : "Could not locate file:`n" glb[ "settingsPath" ], pic : "!" } )
  }
  return xmldoc
}

XMLBuildMenu( filename, menuNode, section )
{
  ini := filename
  ind := 0
  xmldoc := menuNode.ownerDocument
  if ( section = "main" )
  {
    IniRead, mc,% ini,% section,% "MenuColor"
    IniRead, tc,% ini,% section,% "TextColor"
    if ( mc != "error" )
      menuNode.setAttribute( "mbgcolor", "0x" mc )
    if ( tc != "error" )
      menuNode.setAttribute( "mtcolor", "0x" tc )
  }
  loop
  {
    Bold := 0, isMenu := 0, icon := "", hotkey := ""
    IniRead, name,% ini,% section,% ind
    if ( name = "error" )
      break
    If InStr( name, "#B#" )
    {
      StringReplace, name, name, #B# 
      Bold := True
    }
    If InStr( name, "#M#" )
    {
      StringReplace, name, name, #M# 
      isMenu := True
    }
    IniRead, val,% ini,% section,% ind "#ICON"
    if ( val != "error" && val != "" )
      icon := val
    IniRead, val,% ini,% section,% ind "#HOTKEY"
    if ( val != "error" && val != "" )
      hotkey := val
    item := xmldoc.createElement( "item" )
    item.setAttribute( "ID", GetNextID( xmldoc ) )
    item.setAttribute( "name", name )
    if RegExMatch( name,"^#[0-9]*$" )
      item.setAttribute( "issep", 1 )
    if Bold
      item.setAttribute( "bold", 1 )
    if icon
      item.setAttribute( "icon", icon )
    if hotkey
      item.setAttribute( "hotkey", hotkey )
    menuNode.appendChild( item )
    if isMenu
    {
      menuSection := section "#" GetItemId( name )
      IniRead, mc,% ini,% menuSection,% "MenuColor"
      IniRead, tc,% ini,% menuSection,% "TextColor"
      if ( mc != "error" )
        item.setAttribute( "mbgcolor", "0x" mc )
      if ( tc != "error" )
        item.setAttribute( "mtcolor", "0x" tc )
      XMLBuildMenu( ini, item, menuSection )
    }
    else
    {
      IniRead, targets,% ini, Targets,% section "#" GetItemId( name )
      if ( targets != "error" )
        for i,cmd in StrSplit(targets,"{N}",A_Space A_Tab)
        {
          cmdNode := xmldoc.createElement( "command" )
          cmdNode.text := cmd
          item.appendChild( cmdNode )
        }
    }
    ind++
  }
  return
}

XMLBuildSets( filename, menuNode )
{
  otsets := { "settings_ct" : "settings_ct"
             ,"clipxgesture" : "clips_gesture"
             ,"clipxhotkey" : "clips_hotkey"
             ,"hotkeystring" : "main_hotkey"
             ,"maingesture" : "main_gesture"
             ,"memos_hotkey" : "memos_hotkey"
             ,"memos_gesture" : "memos_gesture"
             ,"win_hide_gesture" : "wins_gesture"
             ,"win_hide_show_hotkey" : "wins_hotkey"
             ,"hide_optionalhotkey" : "wins_wndhidehkey"
             ,"recent_gesture" : "recent_gesture"
             ,"recent_hotkey" : "recent_hotkey"
             ,"tgnotify" : "gest_tempnotify"
             ,"gesture_disable_time" : "gest_time"
             ,"globalgesturebutton" : "gest_curbut"
             ,"gesturesglobalstate" : "gest_glbon"
             ,"hotkeysglobalstate" : "hkey_glbon"
             ,"gesture_clipx_enabled" : "clips_geston"
             ,"gesture_main_enabled" : "main_geston"
             ,"recent_gesture_state" : "recent_geston"
             ,"gesture_memos_enabled" : "memos_geston"
             ,"gesture_wh_enabled" : "wins_geston" }
  ini := filename
  xmldoc := menuNode.ownerDocument
  IniRead, settings,% ini, Options
  for i,option in StrSplit( settings, "`n", A_Space A_Tab "`r" )
  {
    if RegExMatch( option, "^(.*?)=(.*?)$", match )
    {
      if ObjHasKey( oTSets, match1 )
        match1 := oTSets[ match1 ]
      else
        continue
      option := xmldoc.createElement( "opt" )
      option.setAttribute( "name", match1 )
      option.setAttribute( "value", match2 )
      menuNode.appendChild( option )
    }
  }
}

GetItemId( InputID )	{
  InputID := RegExReplace(InputID, "[ =]","")	;removing spaces, =
  return InputID
}