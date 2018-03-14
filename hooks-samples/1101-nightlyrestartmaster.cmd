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
	echo @echo off > %systemdrive%\srs\bcddefaultmaster.cmd
	echo. >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo :main >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 	rem >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 	rem List all bcdedit entries on the current system >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 	rem Check if any of the entries contain the text "image.vhd" >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 	rem If the phrase is found atleast once, then the guid for that entry is >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 	rem stored and set as the default boot entry. >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 	rem >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 	setlocal enabledelayedexpansion >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 	if exist %%systemdrive%%\srs\temp.txt del %%systemdrive%%\srs\temp.txt /y 2^>nul >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 	for /f "delims=" %%%%a in ('bcdedit /enum /v') do ( >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 		for /f "tokens=1,2" %%%%b in ('echo %%%%a') do ( >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 			if %%%%b==identifier ( >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 				set _guid=%%%%c >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 				bcdedit /enum !_guid! /v ^| find /c "image.vhd" ^>%%systemdrive%%\srs\temp.txt >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 				set _total= >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 				set /p _total= ^<%%systemdrive%%\srs\temp.txt >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 				del %%systemdrive%%\srs\temp.txt 2^>nul >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 				if not !_total!==0 ( >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 					bcdedit /default !_guid! >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 					bcdedit /timeout 0 >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 				) >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 			) >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 		) >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 	) >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo 	endlocal >> %systemdrive%\srs\bcddefaultmaster.cmd
	echo.
	echo Creating nightlyrestartmaster.cmd
	echo call %systemdrive%\srs\bcddefaultmaster.cmd > %systemdrive%\srs\nightlyrestartmaster.cmd
	echo shutdown /r /t 0 >> %systemdrive%\srs\nightlyrestartmaster.cmd
	echo.
	echo Creating nightlyrestartsnapshot.cmd
	echo shutdown /r /t 0 > %systemdrive%\srs\nightlyrestartsnapshot.cmd
	echo.
	echo Creating a few tasks to reboot the computer every night
	schtasks /Create /RU "NT AUTHORITY\SYSTEM" /SC DAILY /TN nightlyrestart0 /TR %systemdrive%\srs\nightlyrestartmaster.cmd /ST 01:00 /F
	schtasks /Create /RU "NT AUTHORITY\SYSTEM" /SC DAILY /TN nightlyrestart1 /TR %systemdrive%\srs\nightlyrestartsnapshot.cmd /ST 05:00 /F

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