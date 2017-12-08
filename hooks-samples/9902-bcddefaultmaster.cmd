@echo off

:main
	rem
	rem List all bcdedit entries on the current system
	rem Check if any of the entries contain the text "image.vhd"
	rem If the phrase is found atleast once, then the guid for that entry is
	rem stored and set as the default boot entry.
	rem
	setlocal enabledelayedexpansion
	if exist %systemdrive%\srs\temp.txt del %systemdrive%\srs\temp.txt /y 2>nul
	for /f "delims=" %%a in ('bcdedit /enum /v') do (
		for /f "tokens=1,2" %%b in ('echo %%a') do (
			if %%b==identifier (
				set _guid=%%c
				bcdedit /enum !_guid! /v | find /c "image.vhd" >%systemdrive%\srs\temp.txt
				set _total=
				set /p _total= <%systemdrive%\srs\temp.txt
				del %systemdrive%\srs\temp.txt 2>nul
				if not !_total!==0 (
					bcdedit /default !_guid!
					bcdedit /timeout 0
				)
			)
		)
	)
	endlocal
