@echo off

:background
	rem ====================================================================
	rem 						BUILDPE.CMD
	rem 
	rem Function: automates creating the USB stick or CD used to deploy
	rem 	Steadier State to a system
	rem End product:  an ISO folder and optionally puts it on a USB
	rem 	stick.
	rem
	rem Assumes:ADK installed in default location
	rem 		Can create and delete a folder %temp%\SrS
	rem	Inputs:	Which version of OS to use, Win 7, 8, 10, etc.
	rem    		Which architecture to use, 32 or 64 bit
	rem			Where to write the ISO for a CD if desired
	rem			Drive letter of the USB stick to create if desired
	rem
	rem ADK LOCATION
	rem 	Needs Windows ADK installed in its default location. If
	rem 	that's an issue, change the "_adkbase" variable to point to the
	rem		top level folder wherever the ADK is installed. This script was
	rem		designed to use Windows 10 ADK, which can be installed and used
	rem		on any Windows 7 or newer system. If it is not found, we will
	rem		ask to install it. Previous versions are listed here as well,
	rem		but are untested and should not be used with this script.
	rem		Windows 7 WAIK:
	rem 		http://www.microsoft.com/en-us/download/details.aspx?id=5753
	rem		Windows 8 ADK:
	rem 		http://www.microsoft.com/en-us/download/details.aspx?id=30652
	rem		Windows 8.1 ADK:
	rem 		http://www.microsoft.com/en-US/download/details.aspx?id=39982
	rem		Windows 10 ADK:
	rem 		https://msdn.microsoft.com/en-us/windows/hardware/dn913721.aspx
	rem
	rem
	rem Provide user with background information about buildpe.cmd
	rem
	echo.
	echo ===============================================================
	echo               B U I L D   U S B / I S O  T O O L
	echo ===============================================================
	echo.
	echo This command file (buildpe.cmd) creates the tool you'll
	echo need to get started using Steadier State, the free "Windows
	echo Rollback," SteadyState-like tool for un-doing all changes
	echo to a Windows system in under three minutes.  This creates a
	echo bootable USB stick or CD that you can then use to prepare a
	echo computer to be roll-back-able.
	echo.
	echo You've got some options about building that tool, however, so
	echo this command file will have to ask a few questions before we
	echo get started.
	echo.
	echo To stop this program, you can type the word "end" as the answer
	echo to any question.  Please type all responses in LOWERCASE!

:setup
	rem
	rem Perform a few checks and variable assignments for use later
	rem
	setlocal
	cls
	if %processor_architecture%==AMD64 (
		set _arch=amd64
		set _len=64
		set "_adkbase=%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit"
	) else (
		set _arch=x86
		set _len=32
		set "_adkbase=%programfiles%\Windows Kits\10\Assessment and Deployment Kit"
	)
	set _logdir=%systemroot%\logs\buildpelogs
	set _buildpepath=%temp%\BuildPE
	set _adkcheckcount=0
	
:adkcheck
	rem
	rem Check to see if the Windows 10 ADK is installed
	rem
	if not exist %_adkbase%\nul (
		if %_adkcheckcount%==0 (
			call :adkmissing
		) else (
			echo.
			echo We tried to install Windows ADK, but something went wrong.
			echo Please try to install it manually.
			goto :badend
		)
	) else (
		echo.
		echo Found Windows adk at %_adkbase%
		goto :admincheck
	)
	
:adkmissing
	rem
	rem The Windows 10 ADK was not found; ask user how to proceed
	rem
	echo For this to work, you MUST have the Windows Assessment and
	echo Deployment Kit downloaded and installed in its default
	echo location, or modify the "set _adkbase=" line in the command
	echo file with the ADK's alternate location. Would you like to
	echo download and install the current Windows ADK? This could take
	echo well over 30 minutes. Type 'y' and press Enter if you do or
	set /p _adkresp=anything else if you do not.
	if '%_adkresp%'=='y' goto :adkinstall
	goto :badend

:adkinstall
	rem
	rem Download and install the Windows 10 ADK
	rem
	echo You have chosen to install the Windows 10 ADK. I will now download
	echo it using bitsadmin and install it to the default location.
	set _adkcheckcount=1
	bitsadmin /transfer adksetup /priority normal http://go.microsoft.com/fwlink/p/?LinkId=526740 %temp%\adksetup.exe
	start %temp%\adksetup.exe /features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment /ceip off /q
	echo Please wait while the adk is installed. This can take a very
	echo long time. We will check every 10 seconds to see when the install is
	echo completed. The progress bar will continue until finished.
	call :adkwait
	goto :adkcheck

:adkwait
	rem
	rem Subroutine for checking to see if the Windows 10 ADK is finished
	rem installing
	rem
	if exist %temp%\temp.txt del %temp%\temp.txt
	tasklist /nh |find /c "adksetup.exe">%temp%\temp.txt
	set _adksetupactive=
	set /p _adksetupactive= <%temp%\temp.txt
	if not %_adksetupactive%==0 (
		del %temp%\temp.txt
		timeout /t 10 /nobreak >NUL
		<NUL set /p _progress=.
		goto :adkwait
	)
	exit /b
	
:admincheck	
	rem
	rem Check that we're running as an admin
	rem
	if exist %temp%\temp.txt del %temp%\temp.txt
	whoami /groups |find /c "High Mandatory">%temp%\temp.txt
	set _admin=
	set /p _admin= <%temp%\temp.txt
	del %temp%\temp.txt
	if %_admin%==1 goto :logdir
	echo.
	echo I'm sorry, but you must be running from an elevated 
	echo command prompt to run this command file.  Start a new 
	echo command prompt by right-clicking the Command Prompt icon, and
	echo then choose "Run as administrator" and click "yes" if you see
	echo a UAC prompt.
	goto :badend

:logdir
	rem
	rem Set up and test logging
	rem
	rd %_logdir% /q /s  2>nul
	md %_logdir%\test
	if exist %_logdir%\test (
		rd %_logdir%\test /q /s
		goto :filessearch
	)
	echo.
	echo I can't seem to delete the old logs; continuing anyway.

:filessearch
	rem
	rem Check to see if all of the Steadier State files are in the same
	rem folder. Use the name of the this file to determine it's location
	rem
	set _cmdpath=%0
	set _cmdname=%~n0%~x0
	call :strlen _cmdname _strlen
	call set _srspath=%%_cmdpath:~0,-%_strlen%%%
	goto :filescheck

:strlen <stringVar> <resultVar>
	rem
	rem Subroutine to find the length of a string
	rem
	(   
		setlocal enabledelayedexpansion
		set "_string=!%~1!#"
		set "_strlen=0"
		for %%a in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
			if "!_string:~%%a,1!" NEQ "" ( 
				set /a "_strlen+=%%a"
				set "_string=!_string:~%%a!"
			)
		)
	)
	( 
		endlocal
		set "%~2=%_strlen%"
		exit /b
	)
	
:filesquestion
	rem
	rem The Steadier State files were not found in the same location as
	rem as this file...need user input to find them
	rem
	echo.
	echo ===============================================================
	echo Where are the Steadier State files?
	echo.
	echo We were unable to automatically locate the files. Where is the
	echo folder with the Steadier State command files, i.e. the folder
	echo containing bcddefault.cmd, cvt2vhd.cmd, firstrun.cmd,
	echo listvolume.txt, merge.cmd, nodrives.reg, prepnewpc.cmd,
	echo rollback.cmd, startnethd.cmd. Please enter the folder name here
	echo and press Enter; again, to stop this program just type 'end'
	set /p _srspath=without quotes and press Enter to exit.
	if '%_srspath%'=='end' goto :end
	
:filescheck
	rem
	rem Make sure all of the necessary Steadier State files are present
	rem
	echo.
	echo Checking for the files in folder "%_srspath%"...
	if not exist %_srspath%\bcddefault.cmd (
		set _filemissing=bcddefault.cmd
		goto :filemissing
	)
	if not exist %_srspath%\cvt2vhd.cmd (
		set _filemissing=cvt2vhd.cmd
		goto :filemissing
	)
	if not exist %_srspath%\firstrun.cmd (
		set _filemissing=firstrun.cmd
		goto :filemissing
	)
	if not exist %_srspath%\listvolume.txt (
		set _filemissing=listvolume.txt
		goto :filemissing
	)
	if not exist %_srspath%\merge.cmd (
		set _filemissing=merge.cmd
		goto :filemissing
	)
	if not exist %_srspath%\prepnewpc.cmd (
		set _filemissing=prepnewpc.cmd
		goto :filemissing
	)
	if not exist %_srspath%\rollback.cmd (
		set _filemissing=rollback.cmd
		goto :filemissing
	)
	)
	if not exist %_srspath%\startnethd.cmd (
		set _filemissing=startnethd.cmd
		goto :filemissing
	)
	goto :usbquestion

:filemissing
	rem
	rem Display which Steadier State files were missing
	rem
	echo.
	echo -------- ERROR -----------
	echo.
	echo %_filemissing% not found in %_srspath%.
	goto :filesquestion
	
:usbquestion
	rem
	rem Need user input about whether to create an USB
	rem
	echo.
	echo ===============================================================
	echo Do you want to prepare an USB stick?
	echo.
	echo Would you like me to set up the Steadier State install tool on
	echo a bootable USB stick or any other UFD device?
	echo.
	echo     REMINDER: I'M GOING TO WIPE THAT DEVICE CLEAN!!!
	echo.
	echo Type "y"  (without the quotes) to set up a USB stick.  Enter anything 
	set /p _usbresp=else to NOT create a USB stick, or "end" to end this program.
	echo.
	if '%_usbresp%'=='end' goto :end
	if not '%_usbresp%'=='y' goto :nousbstick
	echo.
	echo Ok, here is the list of current volumes on your computer.
	for /f "delims={}" %%a in ('diskpart /s %_srspath%\listvolume.txt') do (echo %%a)
	echo What is that USB stick's drive letter? Enter just its drive
	set /p _usbdrive=letter, don't add a colon ":" after it. Then press Enter.
	if '%_usbdrive%'=='end' goto :end
	if '%_usbdrive%'=='' (
		echo.
		echo "You did not enter anything. Asking again about USB.
		goto :usbquestion
	)
	rem
	rem Make sure that usbdrive only contains the letter
	rem
	set _usbdrive=%_usbdrive:~0,1%
	echo.
	if not exist %_usbdrive%:\ (
		echo.
		echo -------- ERROR -----------
		echo.
		echo There doesn't seem to be a USB stick at %_usbdrive%:.  Let's
		echo try again.
		echo.
		goto :usbquestion
	)
	set _makeusb=true
	echo.
	echo Found a device at %_usbdrive%:.
	goto :isoquestion

:nousbstick
	rem
	rem The user has opted not to create an USB
	rem
	set _makeusb=false
	echo.
	echo Okay, no need to create a bootable USB stick.
	
:isoquestion
	rem
	rem Need user input about whether to create an ISO
	rem
	echo.
	echo.
	echo ===============================================================
	echo Do you want to prepare an ISO File?
	echo.
	echo Would you like me to create an ISO file of a bootable CD image
	echo (equipped with the Steadier State install files) that you can
	echo burn to a CD or use in a virtual machine environment?  This
	echo will be useful in situations where you don't have a USB stick
	echo or perhaps one might not work.  To create the ISO, please type
	echo 'y' and press Enter. Type anything else to skip making the ISO
	set /p _isoresp=file.
	if '%_isoresp%'=='end' goto :end
	if not '%_isoresp%'=='y' goto :noiso
	set _makeiso=true
	set _isopath=%userprofile%\documents\SrS%_len%Inst.iso
	echo.
	echo Okay, I will create an ISO file in your Documents folder.
	goto :isousbcheck

:noiso
	rem
	rem The user has opted not to create an ISO
	rem
	set _makeiso=false
	echo.
	echo Okay, I won't create an ISO file.


:isousbcheck
	rem
	rem Test to see if neither output is desired
	rem
	if not '%_makeiso%%_makeusb%'=='falsefalse' goto :archquestion
	echo.
	echo You've selected that you want neither a USB stick nor an ISO
	echo file, so there'd be no point in continuing.
	echo.
	goto :badend

:archquestion
	rem
	rem Need user input about which architecture to use
	rem
	echo.
	echo =========================================================
	echo 32 bit or 64 bit?
	echo.
	echo I've noticed you are using running a %_len% bit system.
	echo Will you be putting this on a machine with the same
	echo architecture? If so, you can simply type 'y' and press Enter.
	echo Otherwise type either "32" or "64" and press Enter.
	set /p _archresp=Your response?
	if '%_archresp%'=='end' goto :end
	if '%_archresp%'=='y' goto :confirm
	if '%_archresp%'=='32' (
		set _arch=x86
		set _len=32
		goto :confirm
	)
	if '%_archresp%'=='64' (
		set _arch=amd64
		set _len=64
		goto :confirm
	)
	echo.
	echo -------- ERROR -----------
	echo.
	echo Sorry, that didn't match any of the acceptable responses
	echo (y, 32 or 64)
	echo.
	goto :archquestion

:confirm
	rem
	rem Confirm with user before proceeding
	rem
	echo.
	echo Now I'm ready to prepare your USB stick and/or ISO.
	echo Confirming, you chose:
	echo.
	echo Verified ADK: installed at %_adkbase%
	echo Verified ADK: installed at %_adkbase% >%_logdir%\startlog.txt
	echo Log directory=%_logdir%
	echo Log directory=%_logdir% >>%_logdir%\startlog.txt
	echo WinPE workspace folder=%_buildpepath%
	echo (Folder will be automatically deleted once we're finished.)
	echo WinPE workspace folder=%_buildpepath% >>%_logdir%\startlog.txt
	echo Location of Steadier State command files=%_srspath%
	echo Location of Steadier State command files=%_srspath% >>%_logdir%\startlog.txt
	echo Architecture=%_len% bit.
	echo Architecture=%_len% bit. >>%_logdir%\startlog.txt
	echo Make a USB stick=%_makeusb%
	echo Make a USB stick=%_makeusb% >>%_logdir%\startlog.txt
	if %_makeusb%==true (
		echo Drive for USB stick=%_usbdrive%:
		echo Drive for USB stick=%_usbdrive%: >>%_logdir%\startlog.txt
	)
	echo Make an ISO file=%_makeiso%
	echo Make an ISO file=%_makeiso% >>%_logdir%\startlog.txt
	if %_makeiso%==true (
		echo File name and location of ISO file=%_isopath%
		echo File name and location of ISO file=%_isopath% >>%_logdir%\startlog.txt
	)
	echo.
	echo.
	echo Please press 'y' and Enter to confirm that you want to
	set /p _confirmresp=do this, or anything else and Enter to stop.
	if not '%_confirmresp%'=='y' goto :badend
	echo.
	echo Buildpe started.  This may take about five to ten minutes.
	echo If this fails, look in %_logdir% for detailed output and logs
	echo of each stage of the process.
	
:setenv
	rem
	rem Create WinPE workspace and ADK path stuff
	rem
	pushd
	echo.
	echo Setting ADK environment variables
	echo Setting ADK environment variables >>%_logdir%\startlog.txt
	call "%_adkbase%\Deployment Tools\DandISetEnv.bat" >%_logdir%\01setenv.txt
	set _setenvrc=%errorlevel%
	if %_setenvrc%==0 goto :prepareenv
	echo.
	echo =============== ERROR: Setenv attempt failed ==================
	echo.
	echo Here's the output from the attempt:
	echo ======================== OUTPUT STARTS ========================
	type %_logdir%\01setenv.txt
	echo ========================= OUTPUT ENDS =========================
	goto :badend
	popd
	
:prepareenv
	rem
	rem Cleanup any previous mount points and then mount boot.wim
	rem
	echo.
	echo Now, clean up any mess from previous BUILDPE runs.
	echo Cleaning any previous mount points >>%_logdir%\startlog.txt
	Dism /Cleanup-Mountpoints >%_logdir%\02prepareenv.txt
	set _cleanrc=%errorlevel%
	if %_cleanrc%==0 (
		rd %_buildpepath% /s /q >>%_logdir%\02prepareenv.txt
		del %_isopath% >>%_logdir%\02prepareenv.txt
		goto :copype
	)
	echo.
	echo ============= ERROR: Dism Cleanup attempt failed ==============
	echo.
	echo The answer may simply be an incompletely dismounted previous
	echo run and in that case a simple reboot may clear things up.
	echo Here's the output from the attempted mount:
	echo ======================== OUTPUT STARTS ========================
	type %_logdir%\02prepareenv.txt
	echo ========================= OUTPUT ENDS =========================
	goto :badend

:copype
	rem
	rem Use copype to create the workspace
	rem
	echo.
	echo Creating WinPE workspace
	echo Creating WinPE workspace >>%_logdir%\startlog.txt
	call copype %_arch% %_buildpepath% >%_logdir%\03copype.txt
	set _copyperc=%errorlevel%
	if %_copyperc%==0 goto :mountwim
	echo.
	echo =============== ERROR: CopyPE attempt failed ==================
	echo.
	echo Here's the output from the attemp:
	echo ======================== OUTPUT STARTS ========================
	type %_logdir%\03copype.txt
	echo ========================= OUTPUT ENDS =========================
	goto :baddism
	popd
	
:mountwim
	rem
	rem Mount boot.wim in the created folder
	rem
	echo.
	echo Next, mount the WinPE so we can install some Steadier State
	echo file into that WinPE.  This can take a minute or two.
	echo Mounting boot.wim >>%_logdir%\startlog.txt
	Dism /Mount-Image /ImageFile:%_buildpepath%\media\sources\boot.wim /index:1 /MountDir:%_buildpepath%\mount >%_logdir%\04mountwim.txt
	set _mountrc=%errorlevel%
	if %_mountrc%==0 (
		echo.
		echo WinPE space created with copype and WinPE's boot.wim.
		echo boot.wim mounted, mountrc=%_mountrc% >>%_logdir%\startlog.txt
		goto :srscopy
	)
	echo.
	echo ============== ERROR: Dism mount attempt failed ===============
	echo.
	echo The answer may simply be an incompletely dismounted previous run
	echo and in that case a simple reboot may clear things up. Here's the 
	echo output from the attempted mount:
	echo ======================== OUTPUT STARTS ========================
	type %_logdir%\04mountwim.txt
	echo ========================= OUTPUT ENDS =========================
	goto :baddism

:srscopy
	rem
	rem Copy the Steadier State files to the image
	rem
	echo.
	echo Creating and copying scripts to the USB stick and/or ISO image...
	echo Copying scripts to the image >>%_logdir%\startlog.txt
	md %_buildpepath%\mount\srs >nul
	copy %_srspath%\bcddefault.cmd %_buildpepath%\mount\srs /y >nul
	copy %_srspath%\cvt2vhd.cmd %_buildpepath%\mount /y >nul
	copy %_srspath%\firstrun.cmd %_buildpepath%\mount\srs /y >nul
	copy %_srspath%\listvolume.txt %_buildpepath%\mount\srs /y >nul
	copy %_srspath%\merge.cmd %_buildpepath%\mount\srs /y >nul
	copy %_srspath%\nodrives.reg %_buildpepath%\mount\srs /y >nul
	copy %_srspath%\prepnewpc.cmd %_buildpepath%\mount /y >nul
	copy %_srspath%\rollback.cmd %_buildpepath%\mount\srs /y >nul
	copy %_srspath%\startnethd.cmd %_buildpepath%\mount /y >nul
	rem
	rem different WinPE to differentiate if you booted USB or hard disk
	rem
	echo @cd \ >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @cls  >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo WinPE 3.0 booted from USB stick. >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo. >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo You may use the command prepnewpc to wipe this computer's >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo hard disk, install WinPE and get it ready to deploy a new >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo rollback-able copy of Windows.  >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo. >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo Or, if you're using this to create your image.vhd, then  >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo hook up your system to some external storage -- image.vhd can   >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo be large! -- and use cvt2vhd to create that image.vhd. >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo .  >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo In any case, I hope that Steadier State is proving useful. >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo -- Mark Minasi help@minasi.com, www.steadierstate.com >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo. >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo This copy of SteadierState has been updated to work with >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo Windows 7, 8, 8.1 and 10. The source can be found at >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo @echo https://github.com/7heMC/SteadierState >> "%_buildpepath%\mount\windows\system32\startnet.cmd"
	echo Copied Steadier State files. >>%_logdir%\startlog.txt
	
:unmountwim
	rem
	rem Unmount the image and commit the changes
	rem
	echo.
	echo Unmounting the image and committing changes
	echo Unmounting the image and committing changes >>%_logdir%\startlog.txt
	Dism /Unmount-Image /MountDir:%_buildpepath%\mount /commit >%_logdir%\05unmount.txt
	set unmountrc=%errorlevel%
	if %unmountrc%==0 (
		echo.
		echo Successfully copied files and unmounted boot.wim.
		echo Unmounted boot.wim, Dism rc=%unmountrc% >>%_logdir%\startlog.txt
		goto :makeusb
	)
	echo.
	echo ============= ERROR: Dism unmount attempt failed ==============
	echo.
	echo The answer may simply be an incompletely dismounted previous run
	echo and in that case a simple reboot may clear things up. Here's the 
	echo output from the attempted mount:
	echo ======================== OUTPUT STARTS ========================
	type %_logdir%\05unmount.txt
	echo ========================= OUTPUT ENDS =========================
	goto :baddism

:makeusb
	rem
	rem Create an USB if instructed
	rem
	if %_makeusb%==false goto :makeiso
	echo.
	echo Starting to create USB stick. >>%_logdir%\startlog.txt
	echo I'll copy the WinPE source to the USB stick, using
	echo MakeWinPEMedia.  It's a big file, so this may take a minute.
	call MakeWinPEMedia /ufd /f %_buildpepath% %_usbdrive%: >%_logdir%\06makeusb.txt
	set _makewinpeufdrc=%errorlevel%
	if %_makewinpeufdrc%==0 (
		echo.
		echo MakeWinPEMedia completed successfully.
		echo USB drive at %_usbdrive%: now ready.
		echo USB stick completed. >>%_logdir%\startlog.txt
		set _madeusb=true
		goto :makeiso
	)
	echo.
	echo =============== ERROR: MakeWinPE attempt failed ===============
	echo.
	echo MakeWinPEMedia failed with return code %makewinpeufdrc%.
	echo USB stick NOT successfully created.
	echo ======================== OUTPUT STARTS ========================
	type %_logdir%\06makeusb.txt
	echo ========================= OUTPUT ENDS =========================
	set _madeusb=false
	goto :makeiso

:makeiso
	rem
	rem Create an ISO if instructed
	rem
	if %_makeiso%==false goto :cleanup
	echo Creating ISO with MakeWinPEMedia... >>%_logdir%\startlog.txt
	call MakeWinPEMedia /iso /f %_buildpepath% %_isopath% >%_logdir%\07makeiso.txt
	set _makewinpeisorc=%errorlevel%
	if %makewinpeisorc%==0 (
		echo.
		echo MakeWinPEMedia succeeded. Your ISO is in %_isopath%.
		echo MakeWinPEMedia completed >>%_logdir%\startlog.txt
		set _madeiso=true
		goto :errorcheck
	)
	echo.
	echo =============== ERROR: MakeWinPE attempt failed ===============
	echo.
	echo MakeWinPEMedia failed with return code %makewinpeisorc%.
	echo ISO was NOT successfully created.
	echo ======================== OUTPUT STARTS ========================
	type %_logdir%\07makeiso.txt
	echo ========================= OUTPUT ENDS =========================
	set _madeiso=false
	goto :errorcheck

:errorcheck
	rem
	rem Check that USB and/or ISO were created successfully
	rem
	if '%_madeiso%%_madeusb%'=='falsefalse' (
		echo Errors were encountered and BuildPE was unable to prepare an
		echo USB or create an ISO. Check %_logdir%\startlog.txt for more
		echo details.
		goto :badend
	)
	goto :goodend
	
:goodend
	rem
	rem buildpe.cmd completed successfully
	rem
	echo.
	echo BuildPE finished successfully.  Cleaning up... >>%_logdir%\startlog.txt
	call :cleanup
	echo.
	echo Done.  Now that you have a USB stick and/or an ISO, you can use
	echo them either to convert a working Windows system into one that
	echo can be protected by Steadier State's "Roll Back Windows"
	echo feature, or you can use them to prepare a system to get a
	echo Steadier State-equipped image deployed to it.
	echo.
	echo In both cases, start by booting the system with the USB/CD.
	echo Then, to convert a working Windows system to an SrS-ready
	echo image, run "cvt2vhd."  Alternatively, to get a system ready for
	echo deployment, run "prepnewpc." There are more instructions for
	echo using those command files in the documentation. They do also
	echo include some built-in documentation.
	echo.
	echo Thanks for trying Steadier State, I hope it's useful.
	echo -- Mark Minasi help@minasi.com www.steadierstate.com
	goto :end

:baddism
	rem
	rem Clean up any leftovers from dism
	rem
	echo.
	echo Forcing dism to unmount and clean any mount points
	Dism /Unmount-Image /MountDir:%_buildpepath%\mount /discard >%_logdir%\08baddism.txt
	Dism /Cleanup-Mountpoints >>%_logdir%\08baddism.txt
	
:badend
	rem
	rem Something failed
	rem
	echo.
	echo Buildpe failed and terminated for some reason. If you'd like to
	echo look further into what might have failed, back up the folder
	echo %_logdir% and the files in it and examine them for clues
	echo about what went wrong.  Cleaning up temporary files...
	echo.
	call :cleanup
	goto :end

:cleanup
	rem
	rem Change to different directory so we can delete %_buildpepath%
	rem
	cd %_logdir%
	echo Deleting WinPE workspace. >>%_logdir%\startlog.txt
	if not '%_buildpepath%'=='' rd %_buildpepath% /s /q
	exit /b

:end
	rem
	rem Final message befor exiting
	rem
	endlocal
	echo.
	echo This copy of SteadierState has been updated to work with
	echo Windows 7, 8, 8.1 and 10. The source can be found at
	echo https://github.com/7heMC/SteadierState
	echo.
	echo Exiting...
	echo.
