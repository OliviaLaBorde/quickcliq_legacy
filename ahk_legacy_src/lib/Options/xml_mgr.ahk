class XMLManager extends qc_base
{
  __New( qcmPath = "" )
  {
    if qcmPath
    {
      xdoc := XMLCreateObj()
      xdoc.load( qcmPath )
      err := xdoc.parseError
      if err.errorCode
      {
        QMsgBoxP( { title : "Error parsing QCM"
                  , msg : "Error occured while reading QCM file:`nPos: " err.filepos "`nReason: " err.reason
                  ,buttons : "Exit", pic : "!" } )
        ExitApp
      }
      xdoc := xdoc.documentElement
      this.xdoc := xdoc
      this.topmenu := xdoc.selectSingleNode( "/qc_/menu" )
      this.opts := xdoc.selectSingleNode( "/qc_/settings" )
      if ( !this.topmenu || !this.opts )
      {
        QMsgBoxP( { title : "Error parsing QCM"
                  , msg : "Error occured while reading QCM file:`nNo required nodes found."
                  ,buttons : "Exit", pic : "!" } )
        ExitApp
      }
      this.xmlpath := qcmPath
    }
    else
    {
      xdoc := QCCheckXMLconf()
      this.xdoc := xdoc
      this.lastID := xdoc.selectSingleNode( "/qc_/lastID" )
      this.topmenu := xdoc.selectSingleNode( "/qc_/menu" )
      this.opts := xdoc.selectSingleNode( "/qc_/settings" )
      this.wins := xdoc.selectSingleNode( "/qc_/wins" )
      this.xmlpath := glb[ "xmlConfPath" ]
    }
  }
  
  GetMenuNode()
  {
    return this.topmenu
  }
  
  GetOptNode()
  {
    return this.opts
  }
  
  GetWinsNode()
  {
    return this.wins
  }
  
  IsSeparator( item )
  {
    if ( item := this.ItemResolve( item ) )
      return item.getAttribute( "issep" ) ? True : False
  }
  
  IsMenu( item )
  {
    if ( item := this.ItemResolve( item ) )
      if ( item.selectSingleNode( "item" ) || item.nodeName = "menu" )
        return 1
    return 0
  }
  
  ItemResolve( item )
  {
    if IsInteger( item )
      return this.GetNodeByID( item )
    else if InStr(  ComObjType( item, "Name"), "IXMLDOM" )
      return item
    else
      ShowExc( "non-valid item passed: " item )
  }
  
  GetMenuItems( xmlMenu )
  {
    return xmlMenu.selectNodes( "item" )
  }
  
  ItemSetCmd( itemID, commands )
  {
    if !( item := this.ItemResolve( itemID ) )
      return 0
    item.selectNodes( "command" ).removeAll()   ;first - deleting all commands from this node
    relPath := qcOpt[ "gen_CmdRelPath" ]
    if ( commands != "" )
      for i,cmd in StrSplit( commands, glb[ "optMTDivider" ], A_Space A_Tab )
      {
        if relPath
          cmd := QCPathMakeRelative( cmd )
        cmdNode := this.NewNode( "command" )
        cmdNode.text := cmd
        item.appendChild( cmdNode )
      }
    return 1
  }

  GetItemCmdByID( itemID )
  {
    if ( item := this.ItemResolve( itemID ) )
      return this.GetItemCmdString( item )
    return
  }
  
  GetItemCmdString( xmlItem )
  {
    cmds := ""
    if xmlItem.hasChildNodes()
      for cmd in xmlItem.selectNodes( "command" )
        cmds .= ( ( A_Index = 1 ) ? "" : glb[ "optMTDivider" ] ) cmd.text
    return cmds
  }

  GetItemsWithAttr( attrName, attrVal )
  {
    query = //item[ @%attrName% = "%attrVal%"]
    return this.GetMenuNode().selectNodes( query )
  }

  ItemSetAttr( itemID, attrName, value, doNotResolve = 0 )
  {
    item := doNotResolve ? itemID : this.ItemResolve( itemID )
    if !item
      return 0
    if !attrName
      ShowExc( "Empty attribute name passed" )
    attrName := StringLower( attrName )
    if( attrName = "icon" && qcOpt[ "gen_IconRelPath" ] )
      value := IconGetRelative( value )
    if ( value = "" )   ;removing attribute
      item.removeAttribute( attrName )
    else
      item.setAttribute( attrName, value )
    return 1
  }
  
  ItemGetAttr( itemID, attrName )
  {
    if ( item := this.ItemResolve( itemID ) )
    {
      attrName := StringLower( attrName )
      if ( attrName = "" )  ;getting item's commands
        ShowExc( "Empty attribute name passed" )
      else                  ;getting attribute value
        return item.getAttribute( attrName )
    }
    return ""
  }
  
  ItemDel( itemID )
  {
    if ( item := this.ItemResolve( itemID ) )
        return item.parentNode.removeChild( item )
    return ""
  }
  
  SetOpt( name, value )
  {
    name := StringLower( name )
    query = opt[ @name = "%name%" ]
    if ( node := this.opts.selectSingleNode( query ) )
      option := node
    else
    {
      option := this.NewNode( "opt" )
      option.setAttribute( "name", name )
      this.GetOptNode().appendChild( option )
    }
    if IsObject( value )
    {
      option.selectNodes( "value" ).removeAll()
      for k,v in value
      {
        node := this.NewNode( "value" )
        node.text := v
        option.appendChild( node )
      }
    }
    else
      option.setAttribute( "value", value )
  }
  
  GetOpt( name )
  {
    name := StringLower( name )
    query = opt[ @name = "%name%" ]
    if ( option := this.opts.selectSingleNode( query ) )
    {
      if option.hasChildNodes()
      {
        ret_opt := object()
        for val in option.selectNodes( "value" )
          ret_opt.insert( val.text )
      }
      else
        ret_opt := option.getAttribute( "value" )
      return { val : ret_opt, attrExist : 1 }
    }
    return { val : "", attrExist : 0 }
  }
  
  DelOpt( name )
  {
    name := StringLower( name )
    query = opt[ @name = "%name%" ]
    if ( option := this.opts.selectSingleNode( query ) )
      return this.opts.removeChild( option )
  }
  
  GetNodeByID( id )
  {
    if ( id = 0 )
      return this.GetMenuNode()
    query = //item[ @ID = "%id%"]
    return this.xdoc.selectSingleNode( query )
  }
  
  Save()
  {
    return SaveXml( this.xdoc, this.xmlpath )
  }
  
  Backup()
  {
    FileCopy,% this.xmlpath ".bak",% this.xmlpath ".bak2", 1
    FileCopy,% this.xmlpath,% this.xmlpath ".bak", 1
    return
  }
  
  NextID()
  {
    IDNode := this.xdoc.selectSingleNode( "/qc_/lastID" )
    IDNode.text := IDNode.text + 1
    return IDNode.text
  }
  
  GetItemsCount( xmlMenu )
  {
    return xmlMenu.selectNodes( "item" ).length
  }
  
  NewNode( name )
  {
    if ( name = "" )
      throw Exception( "Empty node name passed`n" CallStack() )
    if !( newNode := this.xdoc.createElement( name ) )
      throw Exception( "Could not create new node with name: " name "`n" CallStack() )
    return newNode
  }
  
  CreateItemNode( parentNode, beforeNode = 0 )
  {
    IsXmlElement( parentNode )
    itemNode := this.NewNode( "item" )
    itemNode.setAttribute( "ID", this.NextID() )
    if !beforeNode
      return parentNode.appendChild( itemNode )
    else
      return parentNode.insertBefore( itemNode, beforeNode )
  }
  
  GetItemPath( item )
  {
    if ( item := this.ItemResolve( item ) )
      while ( item.nodeName != "menu" )
      {
        path :=  "/" item.getAttribute( "name" ) path
        item := item.parentNode
      }
    return path
  }
}
