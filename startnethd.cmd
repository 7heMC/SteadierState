wpeinit
@echo off
REM As we're (1) booting WinPE and (2) booting from a hard
REM disk image rather than a RAMdisk, we can be sure that 
REM the System Reserved partition -- which contains WinPE --
REM is running as X:.
REM It also means that the remaining large drive with the
REM label "Physical Drive" is lettered C:.
set path=%path%X:\SDRState;
set bootsource=Hard Drive
echo Windows PE 3.0 booted from local hard drive.

REM
REM gather state information
REM
cd \SDRState
set noimage=false
If not exist c:\image.vhd set noimage=true
set nosnap=false
If not exist c:\snapshot.vhd set nosnap=true
set showcmd=false
if exist x:\SDRState\noauto.txt set showcmd=true
if exist c:\noauto.txt set showcmd=true 
if exist d:\noauto.txt set showcmd=true 
if exist e:\noauto.txt set showcmd=true
if exist f:\noauto.txt set showcmd=true 
if exist g:\noauto.txt set showcmd=true
if exist h:\noauto.txt set showcmd=true
if exist i:\noauto.txt set showcmd=true
if exist j:\noauto.txt set showcmd=true
if exist k:\noauto.txt set showcmd=true
if exist l:\noauto.txt set showcmd=true
if exist m:\noauto.txt set showcmd=true
if exist n:\noauto.txt set showcmd=true

REM
REM If noimage=false AND nosnap=false AND showcmd=false, do auto rollback
REM
if %noimage%%nosnap%%showcmd%==falsefalsefalse goto :automatic 

REM
REM If noimage=true, show "next step" message and return to prompt, as
REM the user's in the middle of getting things going.
REM
if %noimage%==true goto :noimage

REM
REM If nosnap=true, we have an image but no snapshot, so just set up that snapshot
REM and tell the user what we did.  (Advise her about noauto.txt as well.)
REM
if %nosnap%==true goto :nosnap

REM
REM Otherwise, we're just invoking WinPE.
REM

goto :showshell

:automatic
call rollback.cmd
REM
REM if something went wrong and the user needs to see it, there's
REM a "99" exit code; otherwise "exit" to cause an auto reboot
REM
if %errorlevel%==99 goto :end
exit
goto :eof

:noimage
REM
REM if here, \image.vhd wasn't found
REM
echo.
echo Hi.  I see that you've prepared this computer's hard disk to use Steadier
echo State, but haven't yet put an image on C:.
echo.
echo Steadier State depends on a system image named image.vhd residing on your
echo large partition, what is probably drive C:.  Please get an image.vhd and put
echo it on C: before going any further.
echo.
echo If you DON'T have an image.vhd yet, it's easy to make one.  Just get a
echo Windows 7 Ultimate/Enterprise or any version of Windows Server 2008 R2
echo exactly as you want it, then boot that system with your Steadier State USB
echo stick or CD.  Run the command "cvt2vhd" and follow the instructions that'll
echo appear on the screen.  Once you've got your image.vhd copied to C:\, then run
echo "rollback"  from the command line and it'll get your snapshot set up so that
echo you can use Steadier State to instantly roll back your computer to a 
echo snapshot.  Thanks!
echo.
echo Thanks for using Steadier State, I hope it's helpful.
echo -- Mark Minasi help@minasi.com www.steadierstate.com
goto :eof

:nosnap
echo.
echo ---- CREATING INITIAL SNAPSHOT FILE ---
echo  System will reboot automatically when done!
echo ---------------------------------------------
echo.
echo.
echo.
echo.
call rollback.cmd
echo.

exit
goto :eof


:showshell
REM
REM otherwise, offer options
REM
echo.
echo Hi.  You're here because you booted your system and chose "Roll Back Windows."
echo To roll back your copy of Windows to when you created its last snapshot, type
echo.
echo rollback
echo.
echo and press Enter.  Once it finishes running, just reboot. 
echo.
echo If you want to keep the changes that you've made to your system since the last
echo snapshot (which deletes the current snapshot and creates a new one), type
echo.
echo merge
echo.
echo Reboot once "merge" is done.
echo.
echo To make the system henceforth roll back and reboot AUTOMATICALLY the next time
echo someone reboots this and chooses "Roll Back Windows," ensure that no drive 
echo between C: and L: contains a file named "noauto.txt" in its root.  Inversely, 
echo if you ever DO want to see this command prompt window when "Roll Back Windows"
echo is chosen, create a file named "noauto.txt" in the root of any drive letter
echo between C: and L:.  (See the documentation for more details on noauto.txt.)
echo.
echo Thanks for using Steadier State, I hope it's helpful.
echo -- Mark Minasi help@minasi.com www.steadierstate.com

goto :end
:end