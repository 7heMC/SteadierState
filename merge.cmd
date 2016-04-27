@echo off
REM
REM Steadier State command file \sdrstate\merge.cmd
REM
REM FUNCTION:
REM Merges files snapshot.vhd and image.vhd into image.vhd
REM Specifically, (1) Checks for file existence, (2) merges files, (3) deletes old
REM snapshot.vhd, and (4) creates new empty snapshot.vhd -- no BCD work required.
REM
REM SETUP:
REM
REM assumes we've booted to the onboard SRV WinPE (X:)
REM assumes that \snapshot.vhd is on the same drive as WinPE's running (X: now, C: when rebooted to Win 7)
REM
REM Next, check with the human. 
echo.
echo.
echo        MERGE SNAPSHOT
echo.
echo Warning:  this routine will merge whatever's in your current snapshot 
echo (snapshot.vhd) into your base "image.vhd" file on this computer.  This change
echo isn't reversible, so I'm just double-checking to see that you mean it.  Please
echo enter "y" (lowercase only, please) and press enter to merge, or type anything
echo else and press enter to change your mind and NOT merge the files.
echo.
set /p response=Enter "y" to merge, anything else to leave things untouched? 
rem
echo.
if not %response%==y ((echo Exiting...)&(goto :eof))

echo Okay, then let's continue.
echo.


REM
REM verify that files c:\image.vhd and c:\snapshot.vhd exist
REM
REM
echo Checking for the base image and snapshot files.
if not exist C:\image.vhd ((echo.) & (echo I couldn't find C:\image.vhd so I can't continue; exiting.) & (goto :eof))
if not exist C:\snapshot.vhd ((echo.) & (echo I couldn't find C:\snapshot.vhd so I can't continue; exiting.) & (goto :eof))

REM 
REM if we got here, time to get to work: merge the files, delete the old snapshot, create a new one.
echo.
echo Found base image and snapshot files.  Merging files... (This can take a while,
echo and Diskpart will offer "100 percent" for progress information, BUT the wait
echo to finish merging the VHDs AFTER that "100 percent" message can be one to seven
echo minutes depending on disk speeds, memory, the volume of changes etc.)
echo.

del mergesnaps.txt 2> nul
echo select vdisk file="C:\snapshot.vhd" > mergesnaps.txt
echo merge vdisk depth=1 >> mergesnaps.txt
echo exit >> mergesnaps.txt

diskpart /s mergesnaps.txt 

del mergesnaps.txt 2> nul

echo.
echo Deleting old snapshot...
echo.
del C:\snapshot.vhd
REM
REM Next, prepare the script for diskpart
REM
del makesnapshot.txt 2>nul
echo create vdisk file="C:\snapshot.vhd" parent="C:\image.vhd" > makesnapshot.txt
echo exit >>makesnapshot.txt
REM
REM And now make a new snapshot, using that script.
REM
diskpart /s makesnapshot.txt 
del makesnapshot.txt 2>nul
echo.
echo Complete.  Image.vhd now contains the old snapshot's information, and that
echo information cannot be lost by a future rollback. It's safe to reboot now.
echo.



