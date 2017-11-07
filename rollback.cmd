@echo off

:background
	rem
	rem Steadier State command file \srs\rollback.cmd
	rem
	rem FUNCTION:
	rem Takes a boot-from-VHD system that's running off a child VHD
	rem named "\snapshot.vhd" and "rolls back" the system by deleting
	rem that snapshot.vhd and creating a new one.  Here are the detailed
	rem steps.
	rem 1) Deletes the old snapshot.
	rem 2) Creates a script for DISKPART to create a new one.
	rem 3) Using that, DISKPART creates that new snapshot.vhd.
	rem 4) Creates an OS entry in bcdedit or re-uses an
	rem    existing one.
	rem 5) The fact that this will create an empty snapshot.vhd and
	rem    create a BCD entry means that it can create the initial
	rem    snapshot.vhd if one does not exist.
	rem 6) Sets the new OS entry to be the default one.
	rem 7) Rollback can automatically reboot your system.  It does
	rem    that to enable the possibility of making a user's computer
	rem    "rollback-able."  The idea is that you can have the user
	rem    reimage his/her machine by just booting the system.
	rem
	rem RESULT:
	rem In just a few minutes, depending on hardware capabilities, with
	rem no user interaction, the system would be rolled back and
	rem rebooted to a "pristine" copy of Windows.
	rem
	rem As a result, when you want to "reimage" a an employee's system
	rem back to your starting point -- image.vhd -- you need only say to
	rem employee, "please reboot the computer.
	rem Note on auto-reboot:  if you want rollback NOT to automatically
	rem reboot, just create a file named "noauto.txt" in the \srs
	rem folder, or in the root of any drive.
	rem
	rem REQUIREMENTS:
	rem
	rem 1) You have rebooted since running prepnewpc.cmd
	rem 2) Must have WinPE installed in the 1GB partition
	rem 3) Computer must have been booted from that on-disk WinPE so
	rem    that it's running on X:
	rem 4) PC must have the Steadier State support files on x:\srs
	rem 5) image.vhd, Win 7, 8, 8.1 or 10 image, must be in the root of
	rem    the physical drive
	rem 6) If you've run this before, then it'll wipe
	rem    %_phydrive%\snapshot.vhd. If you have not, it will create the
	rem    first snapshot.vhd
	rem 7) Thus far I'm assuming that image.vhd is on %_phydrive%.
	rem    %_phydrive% should point to the drive where image.vhd exists
	rem    as indicated by the :vhdcheck subroutine in startnet.cmd

:setup
	setlocal enabledelayedexpansion
	rem
	rem If a snapshot exists delete it
	rem
	echo.
	echo Deleting the current snapshot if it exists
	if exist %_phydrive%\snapshot.vhd del %_phydrive%\snapshot.vhd 2>nul

:makesnapshot
	rem
	rem Make snapshot.vhd
	rem
	echo.
	echo Creating snapshot.vhd from image.vhd
	echo create vdisk file="%_phydrive%\snapshot.vhd" parent="%_phydrive%\image.vhd" >%_actdrive%\makesnapshot.txt
	echo exit >>%_actdrive%\makesnapshot.txt
	diskpart /s %_actdrive%\makesnapshot.txt
	set _phydriverc=%errorlevel%
	if %_phydriverc%==0 (
		echo.
		echo Diskpart created snapshot.vhd.
		goto :bcdcheck
	)
	echo.
	echo ERROR:  Diskpart couldn't create snapshot.vhd, return code=%_phydriverc%.
	echo Look at the above Diskpart output for indications of what went
	echo wrong.
	goto :badend

:bcdcheck
	rem
	rem Next, we may have to create a bcdedit entry for booting from
	rem the snapshot, but we don't want to do that if one already
	rem exists!
	rem What I'm about to do is to take the output of the "bcdedit"
	rem command looking for the string "snapshot.vhd."  If I find it,
	rem I'm assuming that we already have a boot-from-VHD entry in the
	rem BCD that tries to boot from [%_phydrive%]\snapshot.vhd, and in
	rem that case, we simply set it as the default.  Otherwise, we build
	rem a new OS entry that boots from the snapshot.
	rem
	echo.
	echo Looking to see if a new BCD entry is necessary...
	for /f "delims=" %%a in ('bcdedit %_bcdstore% /enum /v') do (
		for /f "tokens=1,2" %%b in ('echo %%a') do (
			if %%b==identifier (
				set _guid=%%c
				bcdedit %_bcdstore% /enum !_guid! /v | find /c "snapshot.vhd" >%_actdrive%\temp.txt
				set _total=
				set /p _total= <%_actdrive%\temp.txt
				del %_actdrive%\temp.txt 2>nul
				if not !_total!==0 (
					bcdedit %_bcdstore% /default !_guid!
					echo ... None required, existing one will work fine.
					echo Successfully completed rollback, reboot and you're ready to go.
					goto :goodend
				)
			)
		)
	)

:bcdconfig
	rem
	rem otherwise we have to create a BCD entry
	rem
	echo.
	echo No BCD entries currently to boot from snapshot.vhd, so we'll create one...
	set _guid=
	if %_noauto%==false (
		for /f "tokens=2 delims={}" %%a in ('bcdedit %_bcdstore% /create /d "Snapshot" /application osloader') do (set _guid={%%a})
		if '!_guid!'=='' goto :badend
		bcdedit %_bcdstore% /set !_guid! device vhd=[%_phydrive%]\snapshot.vhd >nul
		bcdedit %_bcdstore% /set !_guid! osdevice vhd=[%_phydrive%]\snapshot.vhd >nul
		bcdedit %_bcdstore% /set !_guid! path %_winload% >nul
		bcdedit %_bcdstore% /set !_guid! inherit {bootloadersettings} >nul
		bcdedit %_bcdstore% /set !_guid! recoveryenabled no >nul
		bcdedit %_bcdstore% /set !_guid! systemroot \windows	 >nul
		bcdedit %_bcdstore% /set !_guid! nx OptIn >nul
		bcdedit %_bcdstore% /set !_guid! detecthal yes >nul
		bcdedit %_bcdstore% /displayorder !_guid! /addlast >nul
		bcdedit %_bcdstore% /default !_guid!  >nul
		echo Rebooting...Hopefully it worked. If not, there was an error with bcdedit.
		goto :goodend
	) else (
		echo on
		for /f "tokens=2 delims={}" %%a in ('bcdedit %_bcdstore% /create /d "Snapshot" /application osloader') do (set _guid={%%a})
		@echo off
		if '!_guid!'=='' (
			echo.
			echo Unable to create Snapshot entry with bcdedit
			goto :badend
		)
		echo on
		bcdedit %_bcdstore% /set !_guid! device vhd=[%_phydrive%]\snapshot.vhd
		bcdedit %_bcdstore% /set !_guid! osdevice vhd=[%_phydrive%]\snapshot.vhd
		bcdedit %_bcdstore% /set !_guid! path %_winload%
		bcdedit %_bcdstore% /set !_guid! inherit {bootloadersettings}
		bcdedit %_bcdstore% /set !_guid! recoveryenabled no
		bcdedit %_bcdstore% /set !_guid! systemroot \windows
		bcdedit %_bcdstore% /set !_guid! nx OptIn
		bcdedit %_bcdstore% /set !_guid! detecthal yes
		bcdedit %_bcdstore% /displayorder !_guid! /addlast
		bcdedit %_bcdstore% /default !_guid!
		@echo off
		echo.
		echo If you don't see any errors above, then it worked. The new
		echo osloader entry was created in the Windows Boot Manager.
		goto :goodend
	)

:badend
	rem
	rem Set badend rollbackrc
	rem
	endlocal
	set _rollbackrc=99
	goto :end

:goodend
	rem
	rem Set goodend rollbackrc
	rem
	endlocal
	set _rollbackrc=0
	goto :end

:end
	rem
	rem Final message before exiting rollback.cmd
	rem
	echo.
	echo This copy of SteadierState has been updated to work with
	echo Windows 7, 8, 8.1 and 10. The source can be found at
	echo https://github.com/7heMC/SteadierState
	echo.
	echo Exiting...
