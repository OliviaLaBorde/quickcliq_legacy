#NoEnv
#Include PUM_API.ahk
#Include PUM.ahk

pumParams := { "oninit"      : "PUM_out" }
               
pm := new PUM( pumParams )
global main_menu := pm.CreateMenu()
sub1 := pm.CreateMenu()
global sub2 := pm.CreateMenu()
sub3 := pm.CreateMenu()
global sub2sub1 := pm.CreateMenu()
global sub2sub2 := pm.CreateMenu()

g_Menus := [ main_menu, sub1, sub2, sub3, sub2sub1, sub2sub2 ]

main_menu.add( { "name" : "sub1", "submenu" : sub1 } )
main_menu.add( { "name" : "sub2", "submenu" : sub2 } )
main_menu.add( { "name" : "sub3", "submenu" : sub3 } )
  
SetTimer,AddItemsToMenu,-500

main_menu.Show( A_ScreenWidth/3, A_ScreenHeight/3 )
pm.Destroy()
ExitApp
return

AddItemsToMenu( oMenu = "" )
{
  if !oMenu ;adding items to main menu
    oMenu := main_menu
  if( oMenu == sub2 )
  {
    oMenu.add( { "name" : "sub2sub1", "submenu" : sub2sub1 } )
    oMenu.add( { "name" : "sub2sub2", "submenu" : sub2sub2 } )
  }
  loop,3
  { 
    oMenu.add( ( { "name" : "item" A_index } ) )
    if( oMenu == main_menu ) ;this is just a testing sleep
      sleep 1000
  }
  oMenu.fAllItemsAdded := True
}

PUM_out( msg, oMenu )
{
  if ( msg = "oninit" )
  {
    if !oMenu.owner ; = main menu
      return
    if oMenu.fAllItemsAdded ;all items added to current menu
      return
    if oMenu.owner.menu.fAllItemsAdded ;all items added to the parent menu
      AddItemsToMenu( oMenu )
  }
}