@echo off

:setup
	setlocal

:findphynum
	rem
	rem listvolume.txt is the name of the script to find the volumes
	rem
	echo.
	echo Looking for the Physical Drive Partition
	for /f "tokens=2-4" %%a in ('diskpart /s %systemdrive%\srs\listvolume.txt') do (
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
			goto :runhooks
		)
	)
	echo.
	echo Can't find the Physical Drive or its drive letter.  I can't fix
	echo this so I've got to exit. You can disregard this message if you
	echo don't care about hiding the Physical Drive.
	goto :badend

:runhooks
	echo Attempting to run hooks...
	set hookinfo=false
	for %%i in (hooks\*) do (
		set hookinfo=true
		echo Attempting to run hook %%i
		call %%i
		echo Completed attemmpt on hook %%i.
	)
	if %hookinfo%==false (
		echo No hooks were found for running.
	) else (
		echo ...done running hooks.
	)

:restarttasks
	rem
	rem Create a few commands and tasks to reboot the computer
	rem every night. We found this necessary to maintain the
	rem computer's relationship with the domain, as well as
	rem facilitate updates, especially Windows Updates.
	rem
	echo.
	echo Creating nightlyreset.cmd
	echo shutdown /r /t 0 > %systemdrive%\srs\nightlyreset.cmd
	echo.
	echo Creating nightlymerge.cmd
	echo. > %systemdrive%\srs\automerge.txt
	echo copy %systemdrive%\srs\automerge.txt %_phydrive%:\ > %systemdrive%\srs\nightlymerge.cmd
	echo shutdown /r /t 0 >> %systemdrive%\srs\nightlymerge.cmd
	echo.
	echo Creating a few tasks to reboot the computer every night
	schtasks /Create /RU "NT AUTHORITY\SYSTEM" /SC DAILY /TN nightlyrestart0 /TR %systemdrive%\srs\nightlyreset.cmd /ST 01:00 /F
	schtasks /Create /RU "NT AUTHORITY\SYSTEM" /SC DAILY /TN nightlyrestart1 /TR %systemdrive%\srs\nightlymerge.cmd /ST 03:00 /F
	schtasks /Create /RU "NT AUTHORITY\SYSTEM" /SC DAILY /TN nightlyrestart2 /TR %systemdrive%\srs\nightlymerge.cmd /ST 05:00 /F

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
	endlocal
	echo.
	echo This copy of SteadierState has been updated to work with
	echo Windows 7, 8, 8.1 and 10. The source can be found at
	echo https://github.com/7heMC/SteadierState
	echo.
	echo Exiting...
