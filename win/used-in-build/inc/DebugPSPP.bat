@echo off
IF EXIST bin\gdb.exe GOTO ok
goto end
:ok
echo This debug version has additional feature for bug hunting.  It can be very useful to provide the developers with additional information about a problem.
echo . 
echo You run PSPPire in debugmode. Actually you are using the program GDB. 
echo . 
echo Type  "run"  (without ")  and enter in the black CommandPrompt screen. PSPPire will start as usualy.
echo Do your work in PSPPire as usual
echo .
echo If you get a crash
echo   - go back to the CommandPrompt screen. The last lines will give some information.
echo   - type in the CommandPrompt screen "backtrace" and enter
echo   - make a screenshot of the CommandPrompt screen and post it at bug-gnu-pspp@gnu.org
echo .
bin\gdb bin/psppire.exe
:end