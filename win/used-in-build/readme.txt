This is a new MSWindows build of the PSPP master branch as of the date this binary was built and includes all fixes and updates till today. However these updates are not thorougly tested.

If you currently use a PSPP version dated before 2019-05-24, remove your existing PSPP installation before installing this new version.
 - uninstall/remove your existing PSPP installation BEFORE installing this version,
   if necessary by deleting the PSPP directory. 
   Most likely this is on c:\program files\pspp. 
 - If you forgot to remove the directory before installing: 
   uninstall, remove it and install again.
 
To find the correct version for you:
  - review the architecture of your MSWindows version: 
    Control Panel | System and Security | System
  - there, you will find a section called "system type" where MSWindows 
    tells whether it is 32 or 64 bit 
  - With that information select the appropriate installer 
    (has the word "32bit or 64bit" in the filename)
If you can't find the architecture of your MSWindows, 32 bit will always work.

Feel free to report your findings, good or bad, at <https://lists.gnu.org/mailman/listinfo/pspp-users> or email to pspp-users@gnu.org
