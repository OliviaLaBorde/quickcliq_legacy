GetProcessId( hProcess )
{
  return DllCall( "GetProcessId", "UPtr", hProcess )
}

GetExitCodeProcess( hProcess )
{
  DllCall( "GetExitCodeProcess", "UPtr", hProcess, "Uint*", uExitCode )
  return uExitCode
}

API_ShellExecute(target,args = "", work_dir = "",verb = "",nShowCmd=1)
{
	return DllCall("shell32\ShellExecuteW", "Ptr", 0, "str", verb, "str", target, "str", args, "str", work_dir, "int", nShowCmd)
}

API_ShellExecuteEx(target,args = "", work_dir = "",verb = "",nShowCmd=1)
{  
  static cbSize := A_PtrSize = 8 ? ( 16 + 12*A_PtrSize ) : ( 16 + 11*A_PtrSize )
        ,pfMask := 4
        ,plpVerb := 8 + A_PtrSize
        ,plpFile := 8 + 2*A_PtrSize
        ,plpParameters := 8 + 3*A_PtrSize
        ,plpDirectory := 8 + 4*A_PtrSize
        ,pnShow := 8 + 5*A_PtrSize
        ,phProcess := A_PtrSize = 8 ? ( 16 + 11*A_PtrSize ) : ( 16 + 10*A_PtrSize )
        ,phInstApp := 12 + 5*A_PtrSize
        
    /* typedef struct _SHELLEXECUTEINFO {
  DWORD     cbSize;        4   0
  ULONG     fMask;         4   4
  HWND      hwnd;          8   8
  LPCTSTR   lpVerb;        8   8 + A_PtrSize
  LPCTSTR   lpFile;        8   8 + 2*A_PtrSize
  LPCTSTR   lpParameters;  8   8 + 3*A_PtrSize
  LPCTSTR   lpDirectory;   8   8 + 4*A_PtrSize
  int       nShow;         4   8 + 5*A_PtrSize
  HINSTANCE hInstApp;      8   12 + 5*A_PtrSize
  LPVOID    lpIDList;      8   12 + 6*A_PtrSize
  LPCTSTR   lpClass;       8   12 + 7*A_PtrSize
  HKEY      hkeyClass;     8   12 + 8*A_PtrSize
  DWORD     dwHotKey;      4   12 + 9*A_PtrSize
  union {
    HANDLE hIcon;          8   16 + 9*A_PtrSize
    HANDLE hMonitor;       8   16 + 10*A_PtrSize // exist only in x64
  } DUMMYUNIONNAME;
  HANDLE    hProcess;      8   16 + 11*A_PtrSize
} SHELLEXECUTEINFO, *LPSHELLEXECUTEINFO; 
                              16 + 12*A_PtrSize
  */
  VarSetCapacity( SHELLEXECUTEINFO, cbSize, 0 )
  NumPut( cbSize, &SHELLEXECUTEINFO+0, 0, "UInt" )  ;cbSize
  ;fMask - SEE_MASK_NOCLOSEPROCESS | SEE_MASK_FLAG_NO_UI | SEE_MASK_NOASYNC
  NumPut( 0x00000040 | 0x00000400 | 0x00000100, &SHELLEXECUTEINFO, pfMask, "UInt" )  
  if ( verb != "" )
  {
    StrPutVar(verb, verbVar, 2, "UTF-16")
    NumPut( &verbVar, &SHELLEXECUTEINFO, plpVerb, "UPtr" ) ;lpVerb
  }
  StrPutVar(target, targetVar, 2, "UTF-16")
  NumPut( &targetVar, &SHELLEXECUTEINFO, plpFile, "UPtr" ) ;lpFile
  if ( args != "" )
  {
    StrPutVar(args, argsVar, 2, "UTF-16")
    NumPut( &argsVar, &SHELLEXECUTEINFO, plpParameters, "UPtr" ) ;lpParameters
  }
  if ( work_dir != "" )
  {
    StrPutVar(work_dir, wdirVar, 2, "UTF-16")
    NumPut( &wdirVar, &SHELLEXECUTEINFO, plpDirectory, "UPtr" ) ;lpDirectory
  }
  NumPut( nShowCmd, &SHELLEXECUTEINFO, pnShow, "UInt" )  ;nShow
  
	ret := DllCall("shell32\ShellExecuteExW", "Ptr", &SHELLEXECUTEINFO )
  hProc := 0
  
  if ret
  {
    hProc := NumGet( &SHELLEXECUTEINFO+0, phProcess, "UPtr" )
    return { "hProc" : hProc }
  }
  else
  {
    hInstApp := NumGet( &SHELLEXECUTEINFO+0, phInstApp, "UPtr" )
    errstr := "hinst: " hInstApp "`nErrLvl: " ErrorLevel "`n" ErrorFormat( GetLastError() )
    return { "err" : errstr }
  }  
}