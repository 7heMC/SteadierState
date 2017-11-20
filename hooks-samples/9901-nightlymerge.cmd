@echo off

:setup
	setlocal

:nightlymerge
	rem
	rem Create a few commands and tasks to reboot the computer
	rem every night. We found this necessary to maintain the
	rem computer's relationship with the domain, as well as
	rem facilitate updates, especially Windows Updates.
	rem
	echo.
	echo Creating nightlymerge.cmd
	echo. > %systemdrive%\srs\automerge.txt
	echo copy %systemdrive%\srs\automerge.txt %_phydrive%:\srsdirectives > %systemdrive%\srs\nightlymerge.cmd
	echo shutdown /r /t 0 >> %systemdrive%\srs\nightlymerge.cmd
	echo.
	echo Creating a few tasks to reboot the computer every night
	schtasks /Create /RU "NT AUTHORITY\SYSTEM" /SC DAILY /TN nightlyrestart1 /TR %systemdrive%\srs\nightlymerge.cmd /ST 03:00 /F
	schtasks /Create /RU "NT AUTHORITY\SYSTEM" /SC DAILY /TN nightlyrestart2 /TR %systemdrive%\srs\nightlymerge.cmd /ST 05:00 /F

:goodend
	rem
	rem Success
	rem
	echo.
	echo Hook appears to have completed successfully!
	goto :end

:badend
	rem
	rem Something failed
	rem
	echo.
	echo Please check the hook output and documentation, which might help you
	echo figure out what went wrong.

:end
	rem
	rem Final message before exiting hook
	rem
	endlocal
	echo.
