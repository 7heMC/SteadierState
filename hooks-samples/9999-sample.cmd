@echo off

:setup
	setlocal

:sample
	rem
	rem Create the sample task to perform some desired action or command
	rem
	echo.
	echo Creating a sample task to demonstrate how to structure task operations
	echo Performing a directory listing
	dir c:\srs\

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
