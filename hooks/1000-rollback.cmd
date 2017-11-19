@echo off

:setup
	setlocal

:rollback
	rem
	rem Create the task to change boot order and run the command
	rem
	echo.
	echo Creating a task to change the boot order upon restart
	echo Whenever Windows reboots, it will automatically rollback
	echo and create a new snapshot
	schtasks /Create /RU "NT AUTHORITY\SYSTEM" /SC ONSTART /TN bcddefault /TR %systemdrive%\srs\bcddefault.cmd /F
	call %systemdrive%\srs\bcddefault.cmd

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
	echo Please check the logs and documentation, which might help you
	echo figure out what went wrong.

:end
	rem
	rem Final message before exiting hook
	rem
	endlocal
	echo.
