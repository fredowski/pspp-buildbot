These are debug versions identical to the installers in the directory above, except that there is a separate console window in which output messages are displayed. In case of problems, these messages can give a clue about the reason of the problem. By using this version you can get info the developers need to solve your problem. 

To use this debug version:
- download the *.Debug file and rename *.Debug to *.exe
- run the installer. This will install the PSPP version with additional debug features for bug hunting on your computer.


After installing, the debug version has mainly 2 ways to use:

1)
Run PSPPire the usual way and you get a commandprompt (black) screen on which warnings and errors are displayed. (The developers are working at these warnings, so no reason to report them) PSPP might display an error here and might give some addtional info when you have a crash. This info is useful for the developers.

2)
Run PSPPire in debugmode.  For basic usage the next steps are sufficient.
Steps for a simple run in debugmode:
- click on  your windows "Start" button | "all programs" | "PSPP" | "DebugPSPP"     or   "DebugPSPP" on your desktop
   you wil get a CommandPrompt (black) screen with a lot of text. No need to read/understand this.
- type  "run"  (without ")  and enter in the black CommandPrompt screen
  PSPPire will start as usualy
- do your work in PSPPire as usual

If you get a crash
  - go back to the (black) CommandPrompt screen. The last lines will give some information.
  - type in the CommandPrompt screen "backtrace" and enter
  - make a screenshot of the CommandPrompt screen and post it.
  
Actually you are using the program GDB in this option, you can look on the internet https://sourceware.org/gdb/current/onlinedocs/gdb/ for more advanced features of GDB and how to use them.

PS. The debug package can also be used on GNU/Linux with Wine. In that case, start the debugpackage with the shortcut on your desktop, or go with "Wine file" to the directory where PSPP is installed and start the shortcut DebugPSPP.lnk


