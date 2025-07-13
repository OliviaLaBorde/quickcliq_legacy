SafeArrayGetDim( pComArr )
{
  return DllCall( "OleAut32\SafeArrayGetDim", "Ptr", pComArr )
}

SafeArrayGetUBound( pComArr, Dims )
{
  DllCall( "OleAut32\SafeArrayGetUBound", "Ptr", pComArr, "Uint", Dims, "Uint*", uBound )
  return uBound
}

SafeArrayGetLBound( pComArr, Dims )
{
  DllCall( "OleAut32\SafeArrayGetLBound", "Ptr", pComArr, "Uint", Dims, "Uint*", lBound )
  return lBound
}

SafeArrayAccessData( pComArr )
{
  DllCall( "OleAut32\SafeArrayAccessData", "Ptr", pComArr, "Ptr*", pData )
  return pData
}

SafeArrayUnaccessData( pComArr )
{
  return DllCall( "OleAut32\SafeArrayUnaccessData", "Ptr", pComArr )
}

DwnFile( url, filePath )
{
  ret := { rcode : 0 }
  FileDelete,% filePath
  webReq := ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
  webReq.SetTimeouts( 5000, 15000, 15000, 15000 )
  webReq.Open( "GET", url )
  try
    webReq.Send()
  catch oEx
  {
    ret[ "rcode" ] := 1
    ret[ "err" ] := oEx.message ( oEx.Extra ? "`n" oEx.Extra : "" )
  }
  if !ret[ "rcode" ]
  {
    vtBody := webReq.ResponseBody
    vtType := ComObjType( vtBody )
    vtPtr := ComObjValue(vtBody)
    if( vtType == 0x11 | 0x2000 && 1 == SafeArrayGetDim( vtPtr ) )
    {
      UpperBounds := SafeArrayGetUBound( vtPtr, 1 )
      LowerBounds := SafeArrayGetLBound( vtPtr, 1 )
      bLen := UpperBounds - LowerBounds + 1
      ret[ "BytesLd" ] := bLen
      pData := SafeArrayAccessData( vtPtr )
      objFile := FileOpen( filePath, "w", "CP0" )
      if !IsObject( objFile )
      {
        ret[ "rcode" ] := 1
        ret[ "err" ] := "Could not open file:`n" filePath
      }
      else
        ret[ "BytesWr" ] := objFile.RawWrite( pData+0, bLen )
      SafeArrayUnaccessData( vtPtr )
    }
    else
    {
      ret[ "rcode" ] := 1
      ret[ "err" ] := "Wrong return type"
    }
  }
  try
  {
    ret[ "status" ] := webReq.Status
    ret[ "statusText" ] := webReq.StatusText
    if( webReq.Status != 200 )
    {
      ret[ "rcode" ] := 1
      ret[ "err" ] .= webReq.Status ? ( ret[ "err" ] ? "`n" : "" ) "HTTP status: " webReq.Status "`n" webReq.StatusText : ""
    }
  }
  return ret
}