@echo off
REM
REM vdrive should point to the drive where image.vhd exists
REM That SHOULD be drive C: because System Reserved -- which
REM might otherwise snatch C: first -- contains WinPE and we're
REM booting WinPE from a hard disk, not a RAM drive, leading to
REM the interesting situation that we can pretty much assume that
REM System Reserved WILL have a drive letter... and it'll be X:.
REM 
REM HOWEVER, this did not always occur, so we added a check looking
REM for the Volume with the Description "Physical Dr"
REM
REM Steadier State command file \srs\rollback.cmd
REM
REM FUNCTION:
REM
REM Takes a boot-from-VHD system that's running off a child VHD
REM named "\snapshot.vhd" and "rolls back" the system by deleting
REM that snapshot.vhd and creating a new one.  More specifically,
REM 1) Looks to see that "image.vhd" is sitting in the root of the
REM    Physical drive, probably C:.  If not, it errors out and exits.
REM 2) Otherwise, it deletes the old snapshot.
REM 3) Then, it creates a script for DISKPART to create a new one.
REM 4) Using that, DISKPART creates that new snapshot.vhd.
REM 5) Next, it creates an OS entry in bcdedit or re-uses an
REM    existing one.  If it's got to create a new one, it does it
REM    ex nihilo rather than copying an existing entry and modifying
REM    it -- best to leave as little to chance as is possible. 
REM 6) The fact that this will create an empty snapshot.vhd and create
REM    a BCD entry from nothing means that you can ALSO use rollback
REM    to set up your FIRST snapshot.  All you need is a system with
REM    an "image.vhd" in its root and rollback.cmd.  Just run rollback
REM    and in a trice you'll have your snapshot and your OS entry.
REM 7) Rollback sets the new OS entry to be the default one.
REM 8) Finally, rollback automatically reboots your system.  It does
REM    that to enable the possibility of making a user's computer
REM    "rollback-able."  The idea is that if you rename the current
REM    OS entry for WinPE (which is called "WinPE" by default) to
REM    "Roll back" and then tell startnet.cmd to run rollback on startup,
REM    you can have the user reimage his/her machine by just booting
REM    the system and choosing "Roll back" rather than "Windows 7 or 10."
REM    that would cause the user's system to boot WinPE, which would run
REM    rollback.cmd, which would then cause a reboot.  Result:  in just
REM    about five to seven minutes, with no user interaction save for
REM    choosing "Roll back," the system would be rolled back and rebooted
REM    to a "pristine" Windows 7.
REM
REM    As a result, when you want to "reimage" a an employee's system
REM    back to your starting point -- image.vhd -- you need only say to
REM    employee, "please reboot the computer and, when you see the 
REM    Boot Manager menu, choose "Roll Back Windows," press Enter and
REM    just walk away.
REM
REM    Note on auto-reboot:  if you want rollback NOT to automatically 
REM    reboot, just create a file named "noauto.txt" in the \srs 
REM    folder, or in the root of any drive between C: and N:
REM
REM ROLLBACK.CMD
REM
REM Sets up a system to boot from snapshot, deleting an old snapshot first if it exists
REM Deletes old snapshot.vhd, creates new snapshot.vhd, creates a new BCD entry for 
REM the new snapshot.vhd if necessary, and if not then just re-uses it
REM Finally, it auto-reboots WinPE so your rolled-back system comes up automatically
REM unless you have created a file x:\srs\noauto.txt in the WinPE \windows
REM folder or in the root of any drive between C: and N:... then WinPE stays up
REM
REM SETUP/ASSUMPTIONS:
REM
REM WILL NOT RUN RELIABLY FROM PREPNEWPC.CMD!!!
REM You must first run prepnewpc.cmd batch file, then reboot and
REM then it's okay to run this.
REM ????  is there a way to check for/automate that??? ???
REM
REM Requirements
REM 
REM (1) Must have WinPE installed in the 1GB partition, booted from it (X:)
REM (2) Computer must have been booted from that on-disk WinPE so that it's running on X:
REM (3) PC must have the support Steadier State files on x:\srs
REM (4) image.vhd, a Win 7/10 image, must be in the root on the physical drive
REM (5) if you've run this before, then it'll wipe %vdrive%\snapshot.vhd
REM     But if not, no problem, it'll create the first snapshot.vhd
REM (6) Thus far I'm assuming that image.vhd is on drive C:, I THINK that's safe
REM		(However, tests with 10 have mixed results)
REM
REM first verify there's a file \image.vhd on the current drive
REM and use the drive letter %vdrive% to stop people from running the
REM script from Windows 7 accidentally
REM
set drive=%~d0
if not '%drive%'=='X:' goto :notwinpe
REM
REM listvolume.txt is the name of the script to find the volumes
REM
for /f "tokens=3,4" %%a in ('diskpart /s %drive%\srs\listvolume.txt') do (if '%%b'=='Physical Dr' set volletter=%%a)
if '%volletter%'=='' goto :badend
set vdrive=%volletter%:
echo Checking for master image file on disk...
if not exist %vdrive%\image.vhd goto :Noimage
echo ... found master image (image.vhd) file on %vdrive%. 
echo. 
echo STEP ONE: DELETE CURRENT SNAPSHOT
echo.
REM
REM The image file is there, so we're ready to go
REM Let's delete the snapshot
REM
del %vdrive%\snapshot.vhd 2>nul
REM
REM Next, prepare the script for diskpart
REM
del %drive%\makesnapshot.txt 2>nul
echo create vdisk file="%vdrive%\snapshot.vhd" parent="%vdrive%\image.vhd" >%drive%\makesnapshot.txt
echo exit >>%drive%\makesnapshot.txt
REM
REM And now make a new snapshot, using that script.
REM
echo.
echo STEP TWO: CREATE NEW SNAPSHOT
echo.
diskpart /s %drive%\makesnapshot.txt 
set diskpart1rc=%errorlevel%
if %diskpart1rc%==0 goto :dpok1
REM
REM If here, something went wrong creating the snapshot
REM
echo.
echo ERROR:  Diskpart couldn't create snapshot.vhd, return code=%diskpart1rc%
echo look at the above Diskpart output for indications of what whent wrong.
echo.
exit 99
goto :eof

:dpok1
del %drive%\makesnapshot.txt 2>rollbacklog.txt
echo ... success.
echo Looking to see if a new BCD entry necessary...
echo.
REM
REM Next, we may have to create a bcdedit entry for booting from
REM the snapshot, but we don't want to do that if one already
REM exists!
REM What I'm about to do is to take the output of the "bcdedit" command looking for
REM the string "snapshot.vhd."  If I find it, I'm assuming that we already have
REM a boot-from-VHD entry in the BCD that tries to boot from [%vdrive%]\snapshot.vhd and
REM in that I do nothing.  Otherwise, I build a new OS entry that boots from the
REM snapshot.
REM
REM @echo off
REM
del %drive%\temp.txt 2> nul
bcdedit |find /c "snapshot.vhd">%drive%\temp.txt
set total=
set /p total= <%drive%\temp.txt
del %drive%\temp.txt 2>nul
if Not %total%==0 ((echo ... None required, existing one will work fine.)&(echo Successfully completed rollback, reboot and you're ready to go.)&(goto :goodend))
REM
REM otherwise we have to create a BCD entry
REM
set total=
set guid=
echo No BCD entries currently to boot from snapshot.vhd, so we'll create one...
for /f "tokens=2 delims={}" %%a in ('bcdedit /create /d "Windows 10" /application osloader') do (set guid={%%a})
bcdedit /set %GUID% device vhd=[%vdrive%]\snapshot.vhd >nul
bcdedit /set %GUID% osdevice vhd=[%vdrive%]\snapshot.vhd >nul
bcdedit /set %GUID% path \windows\system32\winload.efi >nul
bcdedit /set %GUID% inherit {bootloadersettings} >nul
bcdedit /set %GUID% recoveryenabled no >nul
bcdedit /set %GUID% systemroot \windows	 >nul	
bcdedit /set %GUID% nx OptIn >nul
bcdedit /set detecthal yes >nul
bcdedit /displayorder %GUID% /addlast >nul
bcdedit /default %GUID%  >nul
echo Success.  Reboot and from now on any changes can be un-done by running this command file again.
goto :goodend

:Noimage
REM
REM if here, C:\image.vhd wasn't found
REM
echo The file "%vdrive%\image.vhd" isn't on this drive and
echo Steadier State depends on a system image named image.vhd
echo residing on your large drive, what is probably drive C:.
echo Please get an image.vhd and put it on C: before going
echo any further.
echo.
echo If you DON'T have an image.vhd yet, it's easy to make one.
echo Just get a Windows 7 Ultimate/Enterprise or any version of
echo Windows Server 2008 R2 exactly as you want it, then boot
echo that system with your Steadier State USB stick or CD.  Run
echo the command "cvt2vhd" and follow the instructions that'll
echo appear on the screen.  Once you've got your image.vhd copied
echo to C:, then reboot your system and choose "Roll Back Windows"
echo from the Boot Manager.  I'll run automatically and get your
echo first snapshot up and ready.
echo up.  Thanks!
exit 99
goto :badend

:notwinpe
echo.
echo This can only be run from WinPE. However, it does not appear that
echo the system is running from the X: drive. Please restart and boot
echo into the Rollback Windows environment.
goto :eof

:goodend

:badend
