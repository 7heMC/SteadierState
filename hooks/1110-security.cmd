@echo off

:setup
	setlocal

:security
	rem
	rem Set permissions on the srs folder for tighter security and
	rem the _phydrive\srsdirectives folder. If the _phydrive\srsdirectives
	rem folder does not exist then we will create it before attempting to set
	rem permissions.
	rem
	rem This hook expects the first param passed to be the _phydrive for
	rem install.
	rem
	rem First set set a local variable to hold the drive letter passed
	set _phydrivepassed=%1
	echo.
	echo Attempting to set some security on \srs and %_phydrivepassed%:\srsdirectives folders and files.
	rem We can assume that the srs folder is on same drive as we are running from
	echo Dropping inheritance on \srs folder...
	icacls \srs /inheritance:d
	echo Dropping access for Authenticated Users group on \srs folder...
	icacls \srs /remove "Authenticated Users"
	echo Dropping access for Users on \srs folder...
	icacls \srs /remove "Users"
	echo.
	if exist %_phydrivepassed%:\srsdirectives (
		echo %_phydrivepassed%:\srsdirectives already exists.
	) else (
		echo Attempting to make the %_phydrivepassed%:\srsdirectives directory.
		md %_phydrivepassed%:\srsdirectives
	)
	echo.
	if exist %_phydrivepassed%:\srsdirectives (
		echo Dropping inheritance on %_phydrivepassed%:\srsdirectives folder...
		icacls %_phydrivepassed%:\srsdirectives /inheritance:d
		echo Dropping access for Authenticated Users group on %_phydrivepassed%:\srsdirectives folder...
		icacls %_phydrivepassed%:\srsdirectives /remove "Authenticated Users"
		echo Dropping access for Users on %_phydrivepassed%:\srsdirectives folder...
		icacls %_phydrivepassed%:\srsdirectives /remove "Users"
	) else (
		echo The %_phydrivepassed%:\srsdirectives folder does not exist to assign permission.
		goto :badend
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
