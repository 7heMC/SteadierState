@echo off

:setup
	setlocal

:security
	rem
	rem Set permissions on the srs folder for tighter security
	rem
	echo.
	echo Creating a sample task to demonstrate how to structure task operations
	echo Performing a directory listing
	rem We can assume that the srs folder is on same drive as we are running from
	rem Drop inheritance on \srs
	icacls \srs /inheritance:d
	rem Drop access for Authenticated Users group
	icacls \srs /remove "Authenticated Users"
	rem Drop access for Users
	icacls \srs /remove "Users"

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
