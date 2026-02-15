#NoEnv
#Include PUM_API.ahk
#Include PUM.ahk

global g_CurMenus := object()
global g_ItemsQueue := object()
global g_Menus := object()
global g_NextItem := 0
pumParams := { "oninit"      : "PUM_out"
               ,"onuninit"    : "PUM_out"
               ,"onclose"    : "PUM_out"
               ,"onshow"    : "PUM_out" }
               
pm := new PUM( pumParams )
main_menu := pm.CreateMenu()
sub1 := pm.CreateMenu()
sub2 := pm.CreateMenu()
sub3 := pm.CreateMenu()

g_Menus := [ main_menu, sub1, sub2, sub3 ]

main_menu.add( { "name" : "sub1", "submenu" : sub1 } )
main_menu.add( { "name" : "sub2", "submenu" : sub2 } )
main_menu.add( { "name" : "sub3", "submenu" : sub3 } )

for i,mm in g_Menus
  loop,5
    mm.Add( { "name" : "item" A_Index } )

main_menu.Show( A_ScreenWidth/3, A_ScreenHeight/3 )
pm.Destroy()
ExitApp
return

AddItem()
{
  Random, idx, 1,% g_Menus.Length()
  tooltip % "new item goes to menu " idx-1
  nextMenu := g_Menus[idx]
  g_NextItem++
  newItemParams := { "name" : "item" g_NextItem }
  g_ItemsQueue[g_NextItem] := [ nextMenu, newItemParams ]
}

ProcessItemQueue()
{
  critical ;prevents interrupt
  if !g_ItemsQueue.Length() ;no items
  {
    tooltip % "no items to add"
    return
  }
  fContinueLoop := True
  while(fContinueLoop) ;exit loop only if no item were added
  {
    fContinueLoop := False
    for idx,dItem in g_ItemsQueue
    {
      curActiveMenu := g_CurMenus[g_CurMenus.Length()]
      itemMenu := dItem[1]
      itemParams := dItem[2]
      ; checking if target menu opened
      isMenuOpened := False
      for i,mm in g_CurMenus
      {
        if ( mm.handle == itemMenu.handle )
        {
          isMenuOpened := True
          break
        }
      }
      if( !isMenuOpened || ( curActiveMenu.handle == itemMenu.handle ) )
      {
        itemMenu.Add( itemParams )
        g_ItemsQueue.Delete( idx )
        fContinueLoop := True
        break
      }
    }
  }
  return
}

PUM_out( msg, oMenu )
{
  if( msg == "onshow" )
  {
    SetTimer, AddItem, 500
    SetTimer, ProcessItemQueue, 2000
  }
  if( msg == "onclose" )
  {
    SetTimer, AddItem, OFF
    SetTimer, ProcessItemQueue, OFF
    g_ItemsQueue := object() ;freeing memory of everything that left in queue
  }
  if ( msg = "oninit" )
  {
    g_CurMenus.push( oMenu )
  }
  if ( msg = "onuninit" )
  {
    g_CurMenus.pop()
  }
}