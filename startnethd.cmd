wpeinit
@echo off

:setup
	setlocal enabledelayedexpansion
	set "_strletters=C D E F G H I J K L M N O P Q R S T U V W Y Z"
	rem
	rem As we're (1) booting WinPE and (2) booting from a hard
	rem disk image rather than a RAMdisk, we can be sure that
	rem the System Reserved partition -- which contains WinPE --
	rem is running as X:.
	rem Use the drive letter %_actdrive% to stop people from running the
	rem script from Windows accidentally
	rem
	set _actdrive=%~d0
	if not '%_actdrive%'=='X:' goto :notwinpe
	%_actdrive%
	cd \
	if not exist %_actdrive%\windows\system32\Dism.exe (
		echo.
		echo Dism missing... please only run this from a system booted
		echo from a Steadier State USB stick/DVD.
		goto :notwinpe
	)
	set path=%path%X:\srs;
	echo Booted from local install of Windows PE.
	ver

:bioscheck
	rem
	rem Use wpeutil and reg to find out if PE was booted using bios/uefi
	rem
	wpeutil UpdateBootInfo
	for /f "tokens=1-3" %%a in ('reg query HKLM\System\CurrentControlSet\Control /v PEFirmwareType') DO set _firmware=%%c
	if %_firmware%==0x1 (
		echo The system was booted in BIOS mode.
		set _firmware=bios
		set _winload=\windows\system32\boot\winload.exe
		set _bcdstore=
		goto :findphynum
	)
	if %_firmware%==0x2 (
		echo The system was booted in UEFI mode.
		set _firmware=uefi
		set _winload=\windows\system32\boot\winload.efi
		goto :findphynum
	)
	echo.
	echo Unable to determine if the system was booted using BIOS or
	echo UEFI. It is not safe to continue.
	goto :badend

:findphynum
	rem
	rem listvolume.txt is the name of the script to find the volumes
	rem
	echo.
	echo Looking for the Physical Drive Partition
	for /f "tokens=2-4" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (
		if %%b==Physical_Dr (
			set _phynum=%%a
			echo.
			echo The Physical Drive Partition has not yet been assigned a drive
			echo letter. We will find one that's available and assign it.
			goto :findphydrive
		)
		if %%c==Physical_Dr (
			set _phydrive=%%b:
			echo.
			echo The Physical Drive Partition was automatically assigned a drive
			echo letter and is using %%b:
			if %_firmware%==bios goto :vhdcheck
			if %_firmware%==uefi goto :findefinum
		)
	)
	echo.
	echo Can't find the Physical Drive or its drive letter.  I can't fix
	echo this so I've got to exit. You can disregard this message if you
	echo don't care about hiding the Physical Drive.
	goto :badend

:findphydrive
	rem
	rem Find an available drive letter for the Physical Drive
	rem
	echo.
	echo Looking for an available drive letter to use for the Physical
	echo Drive Partition
	for /f "tokens=3" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (
		set _volletter=%%a
		set _volletter=!_volletter:~0,1!
		call set _strletters=%%_strletters:!_volletter! =%%
	)
	for %%a in (%_strletters%) do (
		if not exist %%a:\ (
			echo.
			echo Found %%a: as an available drive letter for the Physical
			echo Drive Partition.
			set _phydrive=%%a
			goto :phymount
		)
	)
	echo.
	echo Error:  I need a drive letter for the Physical Drive Partition,
	echo but could not find one in the following range D-W,Y,Z. I can't
	echo do the job without a free drive letter, so I've got to stop.
	goto :badend

:phymount
	rem
	rem Mount the Physical Drive Partition
	rem
	echo.
	echo Mounting the Physical Drive Partition
	echo select volume %_phynum% >%_actdrive%\mountphy.txt
	echo assign letter=%_phydrive% >>%_actdrive%\mountphy.txt
	echo rescan >>%_actdrive%\mountphy.txt
	echo exit >>%_actdrive%\mountphy.txt
	diskpart /s %_actdrive%\mountphy.txt
	set _mountphyrc=%errorlevel%
	if %_mountphyrc%==0 (
		echo Diskpart successfully mounted the Physical Drive Partition.
		echo using %_phydrive%:
		set _phydrive=%_phydrive%:
		del %_actdrive%\mountphy.txt
		if %_firmware%==bios goto :vhdcheck
		if %_firmware%==uefi goto :findefinum
	)
	echo.
	echo Diskpart failed to mount the Physical Drive Partition, return
	echo code %_mountphyrc%. It's not really safe to continue so I'm
	echo stopping here.  Look at what Diskpart just reported to see if
	echo there's a clue in there. You may also get a clue from the
	echo diskpart script: %_actdrive%\mountphy.txt.
	goto :badend

:findefinum
	rem
	rem Check for UEFI partition
	rem
	echo.
	echo Looking for the SYSTEM_UEFI partition
	for /f "tokens=2,3" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (
		if %%b==SYSTEM_UEFI (
			set _efinum=%%a
			echo.
			echo The SYSTEM_UEFI Partition has not yet been assigned a drive
			echo letter. We will find one that's available and assign it.
			goto :findefidrive
		)
	)
	set _efinumrc=%errorlevel%
	if '%_efinum%'=='' (
		echo.
		echo Unable to find any mounted volume name "System UEFI"
		goto :badend
	)
	echo.
	echo Can't find the SYSTEM_UEFI drive or its letter.  I can't fix
	echo this so I've got to exit. Please check the error message and
	echo try recreating steadier state from the beginning.
	goto :badend

:findefidrive
	rem
	rem Find an available drive letter for the SYSTEM_UEFI
	rem
	echo.
	echo Looking for an available drive letter to use for the Physical
	echo Drive Partition
	for /f "tokens=3" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (
		set _volletter=%%a
		set _volletter=!_volletter:~0,1!
		call set _strletters=%%_strletters:!_volletter! =%%
	)
	for %%a in (%_strletters%) do (
		if not exist %%a:\ (
			echo Found %%a: as an available drive letter for the SYSTEM_UEFI
			echo partition.
			set _efidrive=%%a
			goto :efimount
		)
	)
	echo.
	echo Error:  I need a drive letter for the UEFI System Partition,
	echo but could not find one in the following range D-W,Y,Z.
	echo I can't do the job without a free drive letter, so I've got to stop.
	echo.
	goto :badend

:efimount
	rem
	rem Mount the SYSTEM_UEFI Partition
	rem
	echo.
	echo Mounting the SYSTEM_UEFI Partition
	echo select volume %_efinum% >%_actdrive%\mountefi.txt
	echo assign letter=%_efidrive% >>%_actdrive%\mountefi.txt
	echo rescan >>%_actdrive%\mountefi.txt
	echo exit >>%_actdrive%\mountefi.txt
	diskpart /s %_actdrive%\mountefi.txt
	set _mountefirc=%errorlevel%
	if %_mountefirc%==0 (
		echo Diskpart successfully mounted SYSTEM_UEFI Partition.
		echo using %_efidrive%:
		set "_bcdstore=/store %_efidrive%:\EFI\Microsoft\Boot\BCD"
		set _efidrive=%_efidrive%:
		del %_actdrive%\mountefi.txt
		goto :vhdcheck
	)
	echo.
	echo Diskpart failed to create the UEFI System Partition, return code %_mountefirc%.
	echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
	echo just reported to see if there's a clue in there.  You may also get a clue from
	echo the diskpart script: %_actdrive%\mountefi.txt.
	goto :badend

:vhdcheck
	rem
	rem Verify there's a file \image.vhd and \snapshot.vhd on the current drive
	rem
	set _noimage=false
	If not exist %_phydrive%\image.vhd set _noimage=true
	set _nosnap=false
	If not exist %_phydrive%\snapshot.vhd set _nosnap=true

:filecheck
	rem
	rem Check if automerge.txt and/or noauto.txt exist
	rem
	set _automerge=false
	set _noauto=false
	for /f "tokens=3" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (
		if exist %%a:\srsdirectives\automerge.txt (
			set _automerge=true
			set _amfile=%%a:\srsdirectives\automerge.txt
		)
		if exist %%a:\srsdirectives\noauto.txt (
			set _noauto=true
			set _noafile=%%a:\srsdirectives\noauto.txt
		)
	)

:logic
	rem
	rem If _noimage=false AND _nosnap=false AND _noauto=false, do auto rollback
	rem
	if %_noimage%%_nosnap%%_noauto%%_automerge%==falsefalsefalsefalse goto :autoroll
	rem
	rem If _noimage=true, show "next step" message and return to prompt, as
	rem the user's in the middle of getting things going.
	rem
	if %_noimage%==true goto :noimage
	rem
	rem If _nosnap=true, we have an image but no snapshot, so just set up that snapshot
	rem and tell the user what we did.  (Advise here about noauto.txt as well.)
	rem
	if %_nosnap%==true goto :nosnap
	rem
	rem If _automerge=true, we have to automatically merge the snapshot.vhd and image.vhd
	rem
	if %_automerge%==true goto :automerge
	rem
	rem Otherwise, we're asking for user input
	rem
	goto :showshell

:autoroll
	rem
	rem Call rollback.cmd
	rem if something goes wrong and the user needs to see it, there's
	rem a "99" exit code; otherwise "exit" to cause an auto reboot
	rem
	call rollback.cmd
	if %_rollbackrc%==0 exit
	goto :badend

:noimage
	rem
	rem if here, \image.vhd wasn't found
	rem
	echo.
	echo Hi.  I see that you've prepared this computer's hard disk to
	echo use Steadier State, but haven't yet put an image on %_phydrive%.
	echo.
	echo Steadier State depends on a system image named image.vhd
	echo residing on your large partition, what is probably drive %_phydrive%.
	echo Please reboot using the Steadier State USB/DVD and run
	echo prepnewpc.cmd before going any further.
	echo.
	echo If you DON'T have an image.vhd yet, it's easy to make one. Just
	echo get a Windows 7, 8, 8.1, or 10 machine exactly as you want it,
	echo then boot that system with your Steadier State USB/DVD.  Run
	echo the command "cvt2vhd" and follow the instructions that'll
	echo appear on the screen. Once you've got your image.vhd copied to
	echo %_phydrive%\, then run "rollback"  from the command line and
	echo it'll get your snapshot set up so that you can use Steadier
	echo State to instantly roll back your computer to a snapshot.
	echo.
	echo Thanks for using Steadier State, I hope it's helpful.
	echo -- Mark Minasi help@minasi.com www.steadierstate.com
	goto :end

:nosnap
	rem
	rem if here, \snapshot.vdh wasn't found
	rem
	echo.
	echo Creating initial snapshot file
	call rollback.cmd
	if %_rollbackrc%==0 goto :goodend
	goto :badend

:automerge
	rem
	rem if here, %_phydrive%\automerge.txt was found
	rem
	echo.
	echo Automatically merging snapshot.vhd and image.vhd
	echo System will reboot automatically when done!
	del %_amfile% 2>nul
	call merge.cmd
	if %_mergerc%==0 exit
	goto :badend

:showshell
	rem
	rem otherwise, delete noauto.txt and offer options
	rem
	del %_noafile%
	echo.
	echo Hi.  You're here because you booted your system to the "Roll
	echo Back Windows" Partition and had a noauto.txt file located at
	echo %_noafile%. I have deleted it so that you can
	echo simply reboot when done.
	echo To roll back your copy of Windows to
	echo when you created its last snapshot, type:
	echo.
	echo 'rollback' and hit enter.
	echo.
	echo If you want to keep the changes that you've made to your system
	echo since the last snapshot (which deletes the current snapshot and
	echo creates a new one), type:
	echo.
	echo 'merge' and hit enter.
	echo.
	echo Type anything else to exit this script and use the command prompt.
	set /p _response=What is your answer? 
	if '%_response%'=='' goto :end
	if %_response%==merge goto :merge
	if %_response%==rollback goto :rollback
	goto :end

:rollback
	rem
	rem User chose to rollback
	rem
	echo.
	echo Warning: This will rollback any changes in your current
	echo snapshot (snapshot.vhd) and replace it with your base image
	echo (image.vhd). This change isn't reversible, so I'm just double-
	echo checking to see that you mean it. Please enter 'y' and press
	echo enter to merge, or type anything else and press enter to change
	echo your mind and NOT rollback the files.
	set /p _confirm=What is your response? 
	if not '%_confirm%'=='y' goto :end
	echo.
	echo Okay, then let's continue.
	call rollback.cmd
	if %_rollbackrc%==0 goto :goodend
	goto :badend

:merge
	rem
	rem User chose to merge snapshot.vhd into image.vhd
	rem
	echo.
	echo Warning: This will merge whatever's in your current snapshot
	echo (snapshot.vhd) into your base image (image.vhd) file on this
	echo computer. This change isn't reversible, so I'm just double-
	echo checking to see that you mean it. Please enter 'y' and press
	echo enter to merge, or type anything else and press enter to change
	echo your mind and NOT merge the files.
	set /p _confirm=What is your response? 
	if not '%_confirm%'=='y' goto :end
	echo.
	echo Okay, then let's continue.
	call merge.cmd
	if %_mergerc%==0 goto :goodend
	goto :badend

:goodend
	rem
	rem Success
	rem
	echo.
	echo To make the system henceforth roll back and reboot
	echo AUTOMATICALLY the next time someone reboots this system ensure
	echo that no drive contains a file named "noauto.txt" in its root.
	echo Inversely,  if you ever DO want to see this command prompt
	echo window when "Roll Back Windows" is chosen as the boot device,
	echo create a file named "noauto.txt" in the root of any drive
	echo letter. (See the documentation for more details on noauto.txt.)
	echo.
	echo Thanks for using Steadier State, I hope it's helpful.
	echo -- Mark Minasi help@minasi.com www.steadierstate.com
	goto :end

:badend
	rem
	rem Something failed
	rem
	echo.
	echo Something went wrong and we were not able to prepare this
	echo computer for Steadier State. In its current state the computer
	echo may be unbootable. You should check the logs and see what went
	echo and try again.

:end
	rem
	rem Final message before exiting
	rem
	endlocal
	echo.
	echo This copy of SteadierState has been updated to work with
	echo Windows 7, 8, 8.1 and 10. The source can be found at
	echo https://github.com/7heMC/SteadierState
	echo.
	echo Exiting...
