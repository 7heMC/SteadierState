@echo off

:bcdtask
	rem
	rem Create the task to change boot order and run the command
	rem
	echo.
	echo Creating a task to change the boot order upon restart
	echo Whenever Windows reboots, it will automatically rollback
	echo and create a new snapshot
	schtasks /Create /RU "NT AUTHORITY\SYSTEM" /SC ONSTART /TN bcddefault /TR %systemdrive%\srs\bcddefault.cmd /F
	call %systemdrive%\srs\bcddefault.cmd

:findphynum
	rem
	rem listvolume.txt is the name of the script to find the volumes
	rem
	echo.
	echo Looking for the Physical Drive Partition
	for /f "tokens=2-4" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (
		if %%b==Physical_Dr (
			echo.
			echo The Physical Drive Partition has not yet been assigned a drive
			echo letter. No further action is required.
			goto :goodend
		)
		if %%c==Physical_Dr (
			echo.
			echo The Physical Drive Partition was automatically assigned a drive
			echo letter and is using %%b:
			set _phydrive=%%b
			goto :registryfix
		)
	)
	echo.
	echo Can't find the Physical Drive or its drive letter.  I can't fix
	echo this so I've got to exit. You can disregard this message if you
	echo don't care about hiding the Physical Drive.
	goto :badend

:findphydrive
	rem
	rem Find an available drive letter for the Physical Drive
	rem
	echo.
	echo Looking for an available drive letter to use for the Physical
	echo Drive Partition
	for %%a in (d e f g h i j k l m n o p q r s t u v w y z) do (
		if not exist %%a:\ (
			echo.
			echo Found %%a: as an available drive letter for the Physical
			echo Drive Partition.
			set _phydrive=%%a
			goto :phymount
		)
	)
	echo.
	echo Error:  I need a drive letter for the Physical Drive Partition,
	echo but could not find one in the following range D-W,Y,Z. I can't
	echo do the job without a free drive letter, so I've got to stop.
	goto :badend

:phymount
	rem
	rem Mount the Physical Drive Partition
	rem
	echo.
	echo Mounting the Physical Drive Partition
	echo select volume %_phynum% >%_actdrive%\mountphy.txt
	echo assign letter=%_phydrive% >>%_actdrive%\mountphy.txt
	echo rescan >>%_actdrive%\mountphy.txt
	echo exit >>%_actdrive%\mountphy.txt
	diskpart /s %_actdrive%\mountphy.txt
	set _mountphyrc=%errorlevel%
	if %_mountphyrc%==0 (
		echo Diskpart successfully mounted the Physical Drive Partition.
		echo using %_phydrive%:
		set _phydrive=%_phydrive%:
		del %_actdrive%\mountphy.txt
		goto :registryfix
	)
	echo.
	echo Diskpart failed to mount the UEFI System Partition, return code
	echo %_mountphyrc%. It's not really safe to continue so I'm stopping
	echo here.  Look at what Diskpart just reported to see if there's a
	echo clue in there.  You may also get a clue from the diskpart
	echo script: %_actdrive%\mountphy.txt.
	goto :badend
	
:registryfix
	rem
	rem Set the value for the NoDrives registry key
	rem
	echo.
	echo Adding Registry key to hide the Physical Drive Partition
	if %_phydrive%==A set _regvalue=00000001
	if %_phydrive%==B set _regvalue=00000002
	if %_phydrive%==C set _regvalue=00000004
	if %_phydrive%==D set _regvalue=00000008
	if %_phydrive%==E set _regvalue=00000016
	if %_phydrive%==F set _regvalue=00000032
	if %_phydrive%==G set _regvalue=00000064
	if %_phydrive%==H set _regvalue=00000128
	if %_phydrive%==I set _regvalue=00000256
	if %_phydrive%==J set _regvalue=00000512
	if %_phydrive%==K set _regvalue=00001024
	if %_phydrive%==L set _regvalue=00002048
	if %_phydrive%==M set _regvalue=00004096
	if %_phydrive%==N set _regvalue=00008192
	if %_phydrive%==O set _regvalue=00016384
	if %_phydrive%==P set _regvalue=00032768
	if %_phydrive%==Q set _regvalue=00065536
	if %_phydrive%==R set _regvalue=00131072
	if %_phydrive%==S set _regvalue=00262144
	if %_phydrive%==T set _regvalue=00524288
	if %_phydrive%==U set _regvalue=01048576
	if %_phydrive%==V set _regvalue=02097152
	if %_phydrive%==W set _regvalue=04194304
	if %_phydrive%==X set _regvalue=08388608
	if %_phydrive%==Y set _regvalue=16777216
	if %_phydrive%==Z set _regvalue=33554432
	echo Windows Registry Editor Version 5.00 >%temp%\nodrives.reg
	echo. >>%temp%\nodrives.reg
	echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer] >>%temp%\nodrives.reg
	echo "NoDrives"=dword:%_regvalue% >>%temp%\nodrives.reg
	regedit /S %temp%\nodrives.reg
	del %temp%\nodrives.reg

:goodend
	rem
	rem Success
	rem
	echo.
	echo Everything completed successfully! You should now have a fully
	echo functioning version of Steadier State. Please reboot to allow
	echo the changes to take effect.
	goto :end
	
:badend
	rem
	rem Something failed
	rem
	echo.
	echo Please check the logs and documentation, which might help you
	echo figure out what went wrong.

:end
	rem
	rem Final message before exiting
	rem
	echo.
	echo This copy of SteadierState has been updated to work with
	echo Windows 7, 8, 8.1 and 10. The source can be found at
	echo https://github.com/7heMC/SteadierState
	echo.
	echo Exiting...
