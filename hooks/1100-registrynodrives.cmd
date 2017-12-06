@echo off

:setup
	setlocal

:registrynodrives
	rem
	rem Set the value for the NoDrives registry key
	rem
	echo.
	echo Adding Registry key to hide the Physical Drive Partition
	if %_phydrive%==A set _regvalue=00000001
	if %_phydrive%==B set _regvalue=00000002
	if %_phydrive%==C set _regvalue=00000004
	if %_phydrive%==D set _regvalue=00000008
	if %_phydrive%==E set _regvalue=00000016
	if %_phydrive%==F set _regvalue=00000032
	if %_phydrive%==G set _regvalue=00000064
	if %_phydrive%==H set _regvalue=00000128
	if %_phydrive%==I set _regvalue=00000256
	if %_phydrive%==J set _regvalue=00000512
	if %_phydrive%==K set _regvalue=00001024
	if %_phydrive%==L set _regvalue=00002048
	if %_phydrive%==M set _regvalue=00004096
	if %_phydrive%==N set _regvalue=00008192
	if %_phydrive%==O set _regvalue=00016384
	if %_phydrive%==P set _regvalue=00032768
	if %_phydrive%==Q set _regvalue=00065536
	if %_phydrive%==R set _regvalue=00131072
	if %_phydrive%==S set _regvalue=00262144
	if %_phydrive%==T set _regvalue=00524288
	if %_phydrive%==U set _regvalue=01048576
	if %_phydrive%==V set _regvalue=02097152
	if %_phydrive%==W set _regvalue=04194304
	if %_phydrive%==X set _regvalue=08388608
	if %_phydrive%==Y set _regvalue=16777216
	if %_phydrive%==Z set _regvalue=33554432
	echo Windows Registry Editor Version 5.00 >%temp%\nodrives.reg
	echo. >>%temp%\nodrives.reg
	echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer] >>%temp%\nodrives.reg
	echo "NoDrives"=dword:%_regvalue% >>%temp%\nodrives.reg
	regedit /S %temp%\nodrives.reg
	del %temp%\nodrives.reg

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
