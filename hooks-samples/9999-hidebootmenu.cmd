@echo off

:setup
	setlocal

:sample
	rem
	rem This hook sets the boot menu timeout to 0 hence hiding the menu
	rem
	echo.
	echo Hiding the boot menu options by setting the timeout to 0
	bcdedit /timeout 0

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
