GetCurrentProcessID()
{
  Return DllCall("GetCurrentProcessId")  ; http://msdn2.microsoft.com/ms683180.aspx
}

GetCurrentParentProcessID()
{
  Return GetParentProcessID(GetCurrentProcessID())
}

GetProcessName(ProcessID)
{
  Return GetProcessInformation(ProcessID, "Str", 260, 36)  ; TCHAR szExeFile[MAX_PATH]
}

GetParentProcessID(ProcessID)
{
  Return GetProcessInformation(ProcessID, "UInt *", 4, 24)  ; DWORD th32ParentProcessID
}

GetProcessThreadCount(ProcessID)
{
  Return GetProcessInformation(ProcessID, "UInt *", 4, 20)  ; DWORD cntThreads
}

GetProcessInformation(ProcessID, CallVariableType, VariableCapacity, DataOffset)
{
  hSnapshot := DLLCall("CreateToolhelp32Snapshot", "UInt", 2, "UInt", 0)  ; TH32CS_SNAPPROCESS = 2
  if (hSnapshot >= 0)
  {
    VarSetCapacity(PE32, 304, 0)  ; PROCESSENTRY32 structure -> http://msdn2.microsoft.com/ms684839.aspx
    DllCall("ntdll.dll\RtlFillMemoryUlong", "Ptr", &PE32, "UInt", 4, "UInt", 304)  ; Set dwSize
    VarSetCapacity(th32ProcessID, 4, 0)
    if (DllCall("Process32First", "Ptr", hSnapshot, "Ptr", &PE32))  ; http://msdn2.microsoft.com/ms684834.aspx
      Loop
      {
        DllCall("RtlMoveMemory", "UInt *", th32ProcessID, "UInt", &PE32 + 8, "UInt", 4)  ; http://msdn2.microsoft.com/ms803004.aspx
        if (ProcessID = th32ProcessID)
        {
          VarSetCapacity(th32DataEntry, VariableCapacity, 0)
          DllCall("RtlMoveMemory", CallVariableType, th32DataEntry, "UInt", &PE32 + DataOffset, "UInt", VariableCapacity)
          DllCall("CloseHandle", "Ptr", hSnapshot)  ; http://msdn2.microsoft.com/ms724211.aspx
          Return StrGet( &th32DataEntry, VariableCapacity, "CP0" )  ; Process data found
        }
        if not DllCall("Process32Next", "Ptr", hSnapshot, "Ptr", &PE32)  ; http://msdn2.microsoft.com/ms684836.aspx
          Break
      }
    DllCall("CloseHandle", "Ptr", hSnapshot)
  }
  Return  ; Cannot find process
}

GetModuleFileNameEx(ProcessID)
{
  if A_OSVersion in WIN_95,WIN_98,WIN_ME
    Return GetProcessName(ProcessID)
 
  ; #define PROCESS_VM_READ           (0x0010)
  ; #define PROCESS_QUERY_INFORMATION (0x0400)
  hProcess := DllCall( "OpenProcess", "UInt", 0x10|0x400, "Int", False, "UInt", ProcessID,"Ptr")
  if (ErrorLevel or hProcess = 0)
    Return, "fail"
  FileNameSize := glb[ "MAX_PATH" ]
  VarSetCapacity(ModuleFileName, FileNameSize, 0)
  CallResult := DllCall("Psapi.dll\GetModuleFileNameExW", "Ptr", hProcess, "Ptr", 0, "Ptr", &ModuleFileName, "UInt", FileNameSize)
  DllCall("CloseHandle", "Ptr", hProcess)
  Return ModuleFileName
}

GetProcessImageFileName( ProcessID )
{
  if A_OSVersion in WIN_95, WIN_98, WIN_ME
    Return GetProcessName(ProcessID)
 
  ; #define PROCESS_VM_READ           (0x0010)
  ; #define PROCESS_QUERY_INFORMATION (0x0400)
  ; #define PROCESS_QUERY_LIMITED_INFORMATION (0x1000)
  hProcess := DllCall( "OpenProcess", "UInt", 0x10|0x400|0x1000, "Int", False, "UInt", ProcessID,"UPtr")
  if (ErrorLevel or hProcess = 0)
    Return, "fail"
  FileNameSize := 260
  VarSetCapacity(ModuleFileName, FileNameSize, 0)
  CallResult := DllCall("Psapi.dll\GetProcessImageFileNameW", "Ptr", hProcess, "Str", ModuleFileName, "UInt", FileNameSize)
  DllCall("CloseHandle","Ptr", hProcess)
  Return ModuleFileName
}

GetProcessCommandLine( processID )
{
  ; #define PROCESS_VM_READ           (0x0010)
  ; #define PROCESS_QUERY_INFORMATION (0x0400)
  ; #define PROCESS_QUERY_LIMITED_INFORMATION (0x1000)
  hProcess := DllCall( "OpenProcess", "UInt", 0x0400|0x10|0x1000, "Int", false, "UInt", processID, "Ptr")
  if !hProcess
    return
    ;~ ShowErr( A_ThisFunc "/OpenProcess", "processID="processID )
  PBILen := 6*A_PtrSize
  VarSetCapacity( PBI, PBILen, 0 )
  pFunc := LoadDllFunction( "Ntdll.dll", "NtQueryInformationProcess" )
  VarSetCapacity( nLen, 4, 0 )
  DllCall( pFunc, "ptr", hProcess, "Uint", 0, "Ptr", &PBI, "Uint", PBILen, "Uint*", nLen )
  pPEB := NumGet( &PBI, A_PtrSize, "UPtr" )
  ;~ VarSetCapacity( pProcParams, A_PtrSize, 0 )
  DllCall( "ReadProcessMemory", "ptr", hProcess, "Uint", pPEB+4*A_PtrSize, "Ptr*", pProcParams, "Uint", A_PtrSize, "Ptr", 0 )
  CmdLineOffset := 16 + 5*A_PtrSize + 3*( 2*A_PtrSize ) + A_PtrSize
  ;~ VarSetCapacity( nCmdLen, 2, 0 )
  DllCall( "ReadProcessMemory", "ptr", hProcess, "Uint", pProcParams+CmdLineOffset, "UShort*", nCmdLen, "Uint", 2, "Ptr", 0 )
  DllCall( "ReadProcessMemory", "ptr", hProcess, "Uint", pProcParams+CmdLineOffset+A_PtrSize, "Ptr*", pBuf, "Uint", A_PtrSize, "Ptr", 0 )
  VarSetCapacity( str_buf, nCmdLen, 0 )
  DllCall( "ReadProcessMemory", "ptr", hProcess, "Uint", pBuf, "str", str_buf, "Uint", nCmdLen, "Ptr", 0 )
  ;~ msgbox % nCmdLen "`n" pBuf "`n" StrGet( &str_buf, nCmdLen, "UTF-16" )
  return StrGet( &str_buf, nCmdLen, "UTF-16" )
}

SetDebugPrivilege()
{
  ; Get the handle of this script with PROCESS_QUERY_INFORMATION (0x0400)
  if !( h := DllCall("OpenProcess", "UInt", 0x0400, "Int", false, "UInt", GetCurrentProcessID(), "Ptr") )
    ShowErr( "OpenProcess" )
  ; Open an adjustable access token with this process (TOKEN_ADJUST_PRIVILEGES = 32)
  if !DllCall("Advapi32.dll\OpenProcessToken", "Ptr", h, "UInt", 0x20, "Ptr*", t)
    ShowErr( "OpenProcessToken" )
  VarSetCapacity(ti, 16, 0)  ; structure of privileges
  NumPut(1, ti, 0, "UInt")  ; one entry in the privileges array...
  ; Retrieves the locally unique identifier of the debug privilege:
  if !DllCall( "Advapi32.dll\LookupPrivilegeValue", "Ptr", 0, "Str", "SeDebugPrivilege", "Int64P", luid )
    ShowErr( "LookupPrivilegeValue" )
  NumPut(luid, ti, 4, "Int64")
  NumPut(2, ti, 12, "UInt")  ; enable this privilege: SE_PRIVILEGE_ENABLED = 2
  ; Update the privileges of this process with the new access token:
  if !DllCall("Advapi32.dll\AdjustTokenPrivileges", "Ptr", t, "Int", false, "Ptr", &ti, "UInt", 0, "Ptr", 0, "Ptr", 0)
  {
    if( A_LastError != 5 ) ;access denied :/
      ShowErr( "AdjustTokenPrivileges" )
  }
  DllCall("CloseHandle", "Ptr", t)  ; close this access token handle to save memory
  DllCall("CloseHandle", "Ptr", h)  ; close this process handle to save memory
  return 0
}

GetProcessList()
{
  d = `n  ; string separator
  s := 4096  ; size of buffers and arrays (4 KB)

  hModule := DllCall("LoadLibraryW", "WStr", "Psapi.dll","UPtr")  ; increase performance by preloading the library
  s := VarSetCapacity(a, s)  ; an array that receives the list of process identifiers:
  c := 0  ; counter for process idendifiers
  DllCall("Psapi.dll\EnumProcesses", "Ptr", &a, "UInt", s, "UIntP", r)
  Loop, % r // 4  ; parse array for identifiers as DWORDs (32 bits):
  {
     id := NumGet(a, A_Index * 4, "UInt")
     ; Open process with: PROCESS_VM_READ (0x0010) | PROCESS_QUERY_INFORMATION (0x0400)
     h := DllCall("OpenProcess", "UInt", 0x0010 | 0x0400, "Int", false, "UInt", id, "Ptr")
     if !h
      continue
     VarSetCapacity(n, s, 0)  ; a buffer that receives the base name of the module:
     e := DllCall("Psapi.dll\GetModuleBaseName", "Ptr", h, "Ptr", 0, "Str", n, "UInt", A_IsUnicode ? s//2 : s)
     if !e    ; fall-back method for 64-bit processes when in 32-bit mode:
      if e := DllCall("Psapi.dll\GetProcessImageFileName", "Ptr", h, "Str", n, "UInt", A_IsUnicode ? s//2 : s)
       SplitPath, n, n
     
     DllCall("CloseHandle", "Ptr", h)  ; close process handle to save memory
     if (n && e)  ; if image is not null add to list:
      l .= n " : " GetProcessCommandLine( id ) . d, c++
  }
  DllCall("FreeLibrary", "Ptr", hModule)  ; unload the library to free memory
  ;Sort, l, C  ; uncomment this line to sort the list alphabetically
;~ 	MsgBox, 0, %c% Processes, %l%
  return, c . " Processes:`n`n" . l
}