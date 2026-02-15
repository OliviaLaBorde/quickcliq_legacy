# Current testing issues and thoughts:

## Phase 3 issues:
- [x] Need different property window controls loaded in property panel based on item type - mainmenu item will have different properties than a submenu or shortcut item -  for instance:
    Do we need a "Is Submenu" checkbox? A submenu does not need a command list because it is a submenu. This goes for Mainmenu as well

- [x] Need new buttons for adding and deleting commands - rebuild as a commands control as list, not a text field. "New" button should open a new window where you can build an individual command using dialog boxes and a help section for the built in variables - Get rid of the tips panel in the properties window and place it in the new add command window

- [ ] We need font support for main menu - this will propagate down to all menus items and submenus for now

- [x] When submenu color is changed it should trickle down to all items in that menu unless a specific color is set on the item/submenu **!!DONE!!**

- [x] expand / collapse buttons do not work on editor window

- [x] need to restyle the tool bar buttons to look like the icon browse button **!!DONE!!**

- [x] when a bg color is set on the main menu the submenus that don't have a bg color set stay the material theme grey. How can we get it to set all submenus the mainmenu color when the submenu bg color isn't set? hmmmmmmm **!!DONE!!**

- [ ] better icon support - not just from exe resources - can we use the material icons?? can we parse built in windows icons without having to manualy navigate to them? what about text emojis? what about web icon libraries like fontawesome? Let's flesh this out!

- [x] when the editor window opens it shows the last item edited property controls even though the item in the treeview is not selected. The property panel should either default to the mainmenu item or show nothing at all until an item in the treeview is selected. **!!DONE!!**