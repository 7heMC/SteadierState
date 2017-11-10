@echo off
	rem
	rem Steadier State command file \srs\merge.cmd
	rem
	rem	FUNCTION:
	rem Merges files snapshot.vhd and image.vhd into image.vhd Here are
	rem the detailed steps.
	rem 1) Gets information about the existence of image.vhd and
	rem	snapshot.vhd from startnet
	rem 2) Merges the two files
	rem 3) Deletes the old snapshot.vhd
	rem 4) Creates a new empty snapshot.vhd -- no BCD work required.
	rem
	rem SETUP:
	rem	assumes we've booted to the onboard SRS Tools WinPE (X:)
	rem assumes that \snapshot.vhd is on the same drive as WinPE's running (X: now, C: when rebooted to Win 7)
	rem
	rem if we got here, time to get to work: merge the files, delete the old snapshot, create a new one.
	rem
	echo.
	echo Found base image and snapshot files.  Merging files... (This can take a while,
	echo and Diskpart will offer "100 percent" for progress information, BUT the wait
	echo to finish merging the VHDs AFTER that "100 percent" message can be one to seven
	echo minutes depending on disk speeds, memory, the volume of changes etc.)

:setup
	rem
	rem Delete automerge
	rem
	echo.
	echo Deleting unneeded files
	if exist mergesnaps.txt del mergesnaps.txt

:mergesnapshot
	rem
	rem Merge snapshot.vhd into image.vhd
	rem
	echo.
	echo Merging snapshot.vhd into image.vhd
	echo select vdisk file="%_phydrive%\snapshot.vhd" >mergesnaps.txt
	echo merge vdisk depth=1 >>mergesnaps.txt
	echo exit >>mergesnaps.txt
	diskpart /s mergesnaps.txt
	del mergesnaps.txt

:deletesnapshot
	echo.
	echo Deleting old snapshot...
	del %_phydrive%\snapshot.vhd

:makesnapshot
	rem
	rem Make snapshot.vhd
	rem
	echo.
	echo Making a new copy of snapshot.vhd
	del makesnapshot.txt
	echo create vdisk file="%_phydrive%\snapshot.vhd" parent="%_phydrive%\image.vhd" > makesnapshot.txt
	echo exit >>makesnapshot.txt
	diskpart /s makesnapshot.txt
	del makesnapshot.txt

:bcdcheck
	rem
	rem What I'm about to do is to take the output of the "bcdedit"
	rem command looking for the string "snapshot.vhd."  If I find it,
	rem I'm assuming that we already have a boot-from-VHD entry in the
	rem BCD that tries to boot from [%_phydrive%]\snapshot.vhd, and in
	rem that case, we simply set it as the default.
	rem
	echo.
	echo Setting the snapshot.vhd BCD entry as default
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
					goto :goodend
				)
			)
		)
	)

:goodend
	rem
	rem Success
	rem
	echo.
	echo Complete. Image.vhd now contains the old snapshot's
	echo information, and that information cannot be lost by a future
	echo rollback. It's safe to reboot now.
	set _mergerc=0
	goto :end

:badend
	rem
	rem Something failed
	rem
	set _mergerc=99
	goto :end

:end
	rem
	rem Final message before exiting merge.cmd
	rem
	echo.
	echo This copy of SteadierState has been updated to work with
	echo Windows 7, 8, 8.1 and 10. The source can be found at
	echo https://github.com/7heMC/SteadierState
	echo.
	echo Exiting...
