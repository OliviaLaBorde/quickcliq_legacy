# Current testing issues and thoughts:

## Phase 3 issues:
- [ ] Need support for multiple commands. Currently errors on two or more commands

    Execution errors:
Command 1: Failed to execute: An error occurred trying to start process 'calc.exe notepad.exe' with working directory 'C:\dev\quickcliq_legacy\.net\QC\QC.net\bin\Debug\net10.0-windows'. The system cannot find the file specified.

- [ ] Need new buttons for adding and deleting commands - rebuild as a commands control as list, not a text field. "New" button should open a new window where you can build an individual command using dialog boxes and a help section for the built in variables

- [ ] Do we need a "Is Submenu" checkbox? Submenu does not need a command list

- [ ] We need font support 

- [x] When submenu color is changed it should trickle down to all items in that menu unless a specific color is set on the item/submenu

- [ ] Need to make the UI larger so it fits all controls inside without having to scroll by default. if the user resizes then fine but it should open cleanly with all controls visible without scrolling

- [ ] expand / collapse buttons do not work

- [x] need to restyle the tool bar buttons to look like the icon browse button

- [ ] when a bg color is set on the main menu the submenus that don't have a bg color set stay the material theme grey. How can we get it to set all submenus the mainmenu color when the submenu bg color isn't set? hmmmmmmm