@echo off

:setup
	setlocal enabledelayedexpansion

:dropwin10entry
	rem
	rem List all bcdedit entries on the current system
	rem Check if any of the entries contain the text "Windows 10"
	rem If the phrase is found atleast once, then the guid for that entry is
	rem stored and removed from the boot menu.
	rem
	echo Dropping the original Windows 10 boot entry.
	echo.
	if exist %systemdrive%\srs\temp.txt del %systemdrive%\srs\temp.txt /y 2>nul
	for /f "delims=" %%a in ('bcdedit /enum /v') do (
		for /f "tokens=1,2" %%b in ('echo %%a') do (
			if %%b==identifier (
				set guid=%%c
				bcdedit /enum !guid! /v | find /c "Windows 10" >%systemdrive%\srs\temp.txt
				set total=
				set /p total= <%systemdrive%\srs\temp.txt
				del %systemdrive%\srs\temp.txt 2>nul
				if not !total!==0 (
					bcdedit /delete !guid!
					echo Windows 10 boot entry of !guid! has been dropped.
				)
			)
		)
	)

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
@echo off

:main

