@echo off

:main
	rem
	rem List all bcdedit entries on the current system
	rem Check if any of the entries contain the text "Roll Back Windows"
	rem If the phrase is found atleast once, then the guid for that entry is
	rem store and set as the default boot entry.
	rem
	setlocal enabledelayedexpansion
	if exist %systemdrive%\srs\temp.txt del %systemdrive%\srs\temp.txt /y 2>nul
	for /f "delims=" %%a in ('bcdedit /enum /v') do (
		for /f "tokens=1,2" %%b in ('echo %%a') do (
			if %%b==identifier (
				set guid=%%c
				bcdedit /enum !guid! /v | find /c "Roll Back Windows" >%systemdrive%\srs\temp.txt
				set total=
				set /p total= <%systemdrive%\srs\temp.txt
				del %systemdrive%\srs\temp.txt 2>nul
				if not !total!==0 (
					bcdedit /default !guid!
					bcdedit /timeout 0
				)
			)
		)
	)
	endlocal

