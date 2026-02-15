XMLMakePretty( oXmlDoc )
{
  rdr := ComObjCreate( "Msxml2.SAXXMLReader.6.0" )
  wrt := ComObjCreate( "Msxml2.MXXMLWriter.6.0" )
  wrt.indent := True
  rdr.contentHandler 	:= wrt
  rdr.dtdHandler 		:= wrt
  rdr.errorHandler 	:= wrt
  rdr.putProperty( "http://xml.org/sax/properties/lexical-handler", wrt )
  rdr.putProperty( "http://xml.org/sax/properties/declaration-handler", wrt )
  rdr.parse( oXmlDoc )
  return wrt.output
}

GetNextID( xmldoc )
{
  IDNode := xmldoc.selectSingleNode( "/qc_/lastID" )
  IDNode.text := IDNode.text + 1
  return IDNode.text
}

IsXmlElement( obj )
{
  if !InStr(  ComObjType( obj, "Name"), "IXMLDOM" )
    ShowExc( "Non-Xml parameter: " obj )
}

SaveXml( oXmlDoc, filepath )
{
  if( xml := XMLMakePretty( oXmlDoc ) )
  {
    if ComObjCreate( "Msxml2.DOMDocument.6.0" ).loadXML( xml )
      return saveToFile( filepath, xml, "UTF-16" )
  }
  return 0
}

XMLCreateObj()
{
  try
    xmldoc := ComObjCreate( "Msxml2.DOMDocument.6.0" )
  catch oEx
  {
    QMsgBoxP( { title : "MSXML 6.0 required"
                , msg : glb[ "appName" ] " requires MSXML 6.0 to be installed.`nYou may use following links to download the distributive:`n"
                  . "<a href=""http://download.microsoft.com/download/2/e/0/2e01308a-e17f-4bf9-bf48-161356cf9c81/msxml6.msi"">MSXML 6.0 32-bit</a>`n"
                  . "<a href=""http://download.microsoft.com/download/2/e/0/2e01308a-e17f-4bf9-bf48-161356cf9c81/msxml6_x64.msi"">MSXML 6.0 64-bit</a>`n"
                  . "<a href=""http://www.microsoft.com/en-us/download/details.aspx?id=3988"">Browse</a>", pic : "!" } )
    ExitApp
  }
  xmldoc.setProperty( "MultipleErrorMessages", True )
  xmldoc.setProperty( "NewParser", True )
  xmldoc.setProperty( "SelectionLanguage", "XPath" )
  return xmldoc
}

XMLParseError( oXmlError )
{
  if !IsObject( oXmlError )
    return False
  return "reason: " oXmlError.reason "`n"
              . "errorCode: " oXmlError.errorCode "`n"
              . "line: "  oXmlError.line "`n"
              . "srcText: "  oXmlError.srcText "`n"
              . "url: "  oXmlError.url
}