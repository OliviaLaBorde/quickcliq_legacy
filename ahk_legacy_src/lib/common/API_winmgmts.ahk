WMIObj()
{
  static wmg
  if( !wmg )
    wmg := ComObjGet( "winmgmts:{impersonationLevel=impersonate, (Debug)}!\\.\root\cimv2" )
  return wmg
}

GetWin32Proc()
{
  wmg := WMIObj()
  query := "SELECT * FROM Win32_Process WHERE ProcessID > 0"
  out := {}
  w32_procs := wmg.ExecQuery( query )
  out[ "count" ] := w32_procs.Count
  l := {}
  for proc in w32_procs
  {
    l[ proc.ProcessID ] := { "name" : proc.Name
                               ,"cmd"  : proc.CommandLine
                               ,"exec" : proc.ExecutablePath }
  }
  out[ "list" ] := l
  return out
}

GetWin32Svc()
{
  wmg := WMIObj()
  out := {}
  query := "SELECT * FROM Win32_Service WHERE ProcessID > 0"
  w32_svcs := wmg.ExecQuery( query )
  out[ "count" ] := w32_svcs.Count
  l := {}
  for svc in w32_svcs
  {
    l[ svc.ProcessID ] := { "name" : svc.Name
                            ,"cmd"  : svc.PathName }
  }
  out[ "list" ] := l
  return out
}