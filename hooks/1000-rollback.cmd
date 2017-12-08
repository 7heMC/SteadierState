@echo off

:setup
	setlocal

:rollback
	rem
	rem Create the task to change boot order to WinPE for one of the
	rem following directives: rollback (default), automerge.txt, or noauto.txt.
	rem
	echo.
	echo Creating a task to change the boot order upon restart.
	echo Whenever Windows reboots, it will perform the assigned directive
	echo of rollback, merge, or interactive mode.
	schtasks /Create /RU "NT AUTHORITY\SYSTEM" /SC ONSTART /TN bcddefault /TR %systemdrive%\srs\bcddefault.cmd /F

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
