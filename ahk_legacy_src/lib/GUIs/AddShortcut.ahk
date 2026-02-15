;############################### CREATE NEW SHORTCUT
Gui_AddSh_Show( sCmd )
{
  global
  local name, ext
  Gui, 4:Default
  QCSetGuiFont( 4 )
  if WinExist( "ahk_id " glb[ "hGuiNS" ] )
  {
    WinActivate,% "ahk_id " glb[ "hGuiNS" ]
    return
  }
  Gui, -0x10000 -0x20000 +hwndhwnd
  glb[ "hGuiNS" ] := hwnd
  if qcOpt[ "gen_noTheme" ]
    Gui,-Theme
  SplitPath, sCmd,,,Ext,Name
  gui, add, text, ,Choose menu, where to place shortcut:
  Gui,Add,TreeView,hwndhwnd w250 h100
  glb[ "hGuiNS_TV" ] := hwnd
  gui, add, text, , Shortcut name:
  Gui, Add, Edit, W250 hwndhwnd R1,% Name
  glb[ "hGuiNS_NameED" ] := hwnd
  gui, add, text, ,Command:
  Gui, Add, Edit, W250 h50 hwndhwnd,% sCmd
  glb[ "hGuiNS_PathED" ] := hwnd
  cancelXpos := 250 - glb[ "defButW" ] + 10
  Gui, add, button,% "xm gAddChoosenShortcut w" glb[ "defButW" ] " h" glb[ "defButH" ], Ok
  Gui, add, button,% "x" cancelXpos " yp g4GuiClose w" glb[ "defButW" ] " h" glb[ "defButH" ], Cancel
  Gui_NewSh_AddMenu()
  Gui, Show,, Add Shortcut
  Loop
  {
    if !WinExist( "ahk_id " glb[ "hGuiNS" ] )
      break
    sleep 100
  }
  return
  
  ;############################### 
  4GuiEscape:
  4GuiClose:
  Gui, 4:Destroy
  return

  ;############################### ADD CHOOSED SHORCUT
  AddChoosenShortcut:
  Gui_NewSh_AddShortcut()
  GoSub, 4GuiClose
  return
}

;############################### ADDMENUSTODDL
Gui_NewSh_AddMenu( tvID = 0, xmlNode = "" )
{
  Gui, 4:Default
  if ( tvID = 0 )
  {
    tvID := TV_Add( "Main", "", "Select Expand" )
    xmlNode := qcconf.GetMenuNode()
    glb[ "AddSH_TVItems" ]  := { (tvID) : xmlNode.getattribute( "ID" ) }
  }
  for xMenu in xmlNode.selectNodes( "item[item]" )
  {
    childTVID := TV_Add( xMenu.getattribute( "name" ), tvID  )
    glb[ "AddSH_TVItems" ][ childTVID ] := xMenu.getattribute( "ID" )
    Gui_NewSh_AddMenu( childTVID, xMenu )
  }
  return
}

Gui_NewSh_AddShortcut()
{
  Gui, 4:Default
  cmd := GuiControlGet( glb[ "hGuiNS_PathED" ], 4 )
  name := GuiControlGet( glb[ "hGuiNS_NameED" ], 4 )
  
  ; cmd cannot be .lnk file because Windows give us target autom. if we add .lnk
  FileGetAttrib, attrs,% cmd
  icoPath := instr(attrs,"D") ? ( RegExMatch( cmd,"^\\.*") ? glb[ "icoRemoteFol" ] : glb[ "icoFolder" ] )
            : IconGetFromPath( PathRemoveArgs( PathQuoteSpaces( cmd ) ) )
  cmd := PathQuoteSpaces( cmd )
  QC_AddXMLItem( { name : name
                , icon  : icoPath
                , cmd   : cmd
                , menuID : glb[ "AddSH_TVItems" ][ TV_GetSelection() ] } )
  qcconf.Save()
  Gui,1:+LastFoundExist
  if WinExist()
    QC_BuildTV( 0 )
  if qcMainMenu             ;check that this is running QC, not one called for adding this shortcut
    QCMenuRebuild( "main" )
}

Gui_AddSh_AddTimer( p* )
{
  static s_cmd
  if IsObject( p )
  {
    s_cmd := p[ 1 ]
    return
  }
  SetTimer( "Gui_AddSh_AddTimer", "OFF" )
  Gui_AddSh_Show( s_cmd )
}

Gui_AddSh_SendMsg( sCmd )
{
  ret := IPCSendMsg( "{ADDSH}" sCmd )
  if !ret
  {
    qcconf := new XMLManager()
    Gui_AddSh_Show( sCmd )
  }
  return ret
}