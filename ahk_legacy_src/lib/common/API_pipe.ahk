CreateNamedPipe( pipeName, timeout )
{
  h := DllCall( "CreateNamedPipeW", "WStr", pipeName      ;lpName
                                  ;dwOpenMode - PIPE_ACCESS_DUPLEX | FILE_FLAG_FIRST_PIPE_INSTANCE | FILE_FLAG_OVERLAPPED
                                 , "Uint", 0x00000003 | 0x00080000  | 0x40000000 
                                 ;dwPipeMode - PIPE_NOWAIT | PIPE_REJECT_REMOTE_CLIENTS
                                 , "Uint", 0x00000001 | ( A_OSVersion ~= "WIN_XP|WIN_2003" ? 0 : 0x00000008 )
                                 , "Uint", 10                                        ;nMaxInstances
                                 , "Uint", 1024*1024*10                             ;nOutBufferSize 
                                 , "Uint", 1024*1024*10                             ;nInBufferSize 
                                 , "Uint", timeout                                  ;nDefaultTimeOut
                                 , "ptr", 0 )                                       ;lpSecurityAttributes
  if !( h > 0 )
    return 0
  return h
}

PipeOpen( pipeName, timeout = 5 )
{
  curTime := A_TickCount
  while( ( A_TickCount - curTime ) < timeout*1000 )
  {
    h := DllCall( "CreateFileW", "WStr", pipeName
                            , "Uint", 0x40000000 | 0x80000000 ;GENERIC_WRITE | GENERIC_READ
                            , "Uint", 0x00000001 | 0x00000002 ;FILE_SHARE_READ | FILE_SHARE_WRITE
                            , "Ptr", 0
                            , "Uint", 3 ;OPEN_EXISTING
                            , "Uint", 0x80 | 0x40000000 ;FILE_ATTRIBUTE_NORMAL
                            , "Ptr", 0 )
    if ( h > 0 )
      return h
    if( GetLastError() != 231 ) ;ERROR_PIPE_BUSY
      return 0
    if !WaitNamedPipe( pipeName )
      return 0
  }
  return 0
}

PipeWrite( hPipe, sData )
{
  sLen := StrLen( sData )*2
  ret := DllCall( "WriteFile", "ptr", hPipe
                            , "WStr", sData
                            , "Uint", sLen
                            , "Uint*", outLen
                            , "ptr", 0 )
  
  if !ret
    return "Failed to write data into pipe: ErrLevel " ErrorLevel ", format: " ErrorFormat(GetLastError())
  if( outLen < sLen )
    return "Failed to write data into pipe (wrote " outLen "/" sLen " bytes): ErrLevel " ErrorLevel ", format: " ErrorFormat(GetLastError())
  return 0
}

PipeRead( hPipe, readSize )
{
  VarSetCapacity( BufOut, readSize, 0 )
  ret := DllCall( "ReadFile", "ptr", hPipe
                        , "Ptr", &BufOut
                        , "Uint", readSize
                        , "Uint*", outLen
                        , "ptr", 0 )
  
  if !ret
    return 0
  sOut := StrGet( &BufOut + 0, outLen, "utf-16" )
  return sOut
}

WaitNamedPipe( pipeName )
{
  return DllCall( "WaitNamedPipeW", "WStr", pipeName
                  , "Uint", 0 )
}

ConnectNamedPipe( hPipe )
{
  return DllCall("ConnectNamedPipe","UPtr",hPipe, "UPtr", 0 )
}

DisconnectNamedPipe( hPipe )
{
  return DllCall( "DisconnectNamedPipe", "UPtr", hPipe )
}