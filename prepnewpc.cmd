@echo off

:background
	rem
	rem Provide user with background information about prepnewpc.cmd
	rem
	echo How and Why To Use PREPNEWPC in Steadier State
	echo --------------------------------------------
	echo.
	echo Steadier State lets you create a "snapshot" of a Windows
	echo installation so that you can choose at any time to reboot your
	echo Windows system, choose "Roll Back Windows," and at that point
	echo every change you've made to the system is un-done. To do that,
	echo however, Steadier State requires you to prepare your Windows
	echo system, and PREPNEWPC does that for you.
	echo.
	echo To get a system ready for conversion, first boot it from your
	echo Steadier State USB/DVD.  Then, connect the system to some large
	echo external drive, whether it's a networked drive mapped to a
	echo drive letter or perhaps a large external hard disk -- you'll
	echo need that because you're going to take the VHD file that you
	echo created with CVT2VHD. On the USB stick/DVD, you'll see a file
	echo named prepnewpc.cmd
	echo.
	echo That'll take a while, but when it's done, the vhd file will be
	echo copied from the external drive to your C: drive. Once you've got
	echo that image.vhd on the C: drive you can boot a system to get it
	echo ready to be able to use that VHD.  You can do it by simply
	echo restarting your computer.
	pause

:setup
	rem
	rem Check that we're running from the root of the boot device
	rem Use the pseudo-variable ~d0 to get the job done
	rem _actdrive = the currently active drive
	rem
	setlocal enabledelayedexpansion
	set "_strletters=C D E F G H I J K L M N O P Q R S T U V W Y Z"
	set _actdrive=%~d0
	if not '%_actdrive%'=='X:' goto :notwinpe
	%_actdrive%
	cd \
	if not exist %_actdrive%\windows\system32\Dism.exe (
		echo.
		echo Dism missing... please only run this from a system booted from
		echo a Steadier State USB stick/DVD.
		goto :notwinpe
	)

:bioscheck
	rem
	rem Use wpeutil and reg to find out if PE was booted using bios/uefi
	rem
	wpeutil UpdateBootInfo
	for /f "tokens=3" %%a in ('reg query HKLM\System\CurrentControlSet\Control /v PEFirmwareType') do (set _firmware=%%a)
	if '%_firmware%'=='' (
		echo.
		echo Unable to determine if the system was booted using BIOS or
		echo UEFI. It is not safe to continue.
		goto :badend
	)
	if '%_firmware%'=='0x1' (
		echo The PC is booted in BIOS mode.
		set _firmware=bios
		set _winload=\windows\system32\boot\winload.exe
	)
	if '%_firmware%'=='0x2' (
		echo The PC is booted in UEFI mode.
		set _firmware=uefi
		set _winload=\windows\system32\boot\winload.efi
	)

:extdrivequestion
	rem
	rem _extdrive = external drive letter where we'll write the wim and then vhd (should include colon)
	rem
	echo.
	echo ===============================================================
	echo Where is the image stored?
	echo.
	echo Here is the list of current volumes on your computer. This will
	echo hopefully help you answer the following question. Also, please
	echo note which drive is drive 0...you will need that for later.
	echo.
	for /f "delims={}" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (echo %%a)
	echo.
	echo What is the external drive and folder where the vhd file is
	echo stored. If the vhd file is stored at the root of a drive you
	echo can simply enter the drive letter with a colon. If it is stored
	echo in a directory please enter the path. For example, E:\images.
	echo You can also type 'end' to quit.
	set /p _extdrive=What is your response? 
	if '%_extdrive%'=='end' goto :end
	if '%_extdrive%'=='' (
		echo.
		echo -------- ERROR -----------
		echo.
		echo There doesn't seem to be anything at %_extdrive%.  Let's try
		echo again.
		goto :extdrivequestion
	)
	if not exist %_extdrive%\scratch md %_extdrive%\scratch

:warnings
	rem
	rem Warn about data loss and give outline of the remaining steps
	rem
	cls
	echo ===============================================================
	echo        W A R N I N G !!!!!!       W A R N I N G !!!!!!
	echo ===============================================================
	echo.
	echo This command file prepares this PC to receive an image.vhd file
	echo prepared by Steadier State and the support files that make
	echo Steadier State work. BUT... as part of its job, this file WIPES
	echo THIS COMPUTER'S DRIVE 0 CLEAN.
	echo.
	echo I hope I now have your complete attention?
	echo.
	echo More specifically, this wipes drive 0, you should have taken
	echo note of this when the drives were listed above. If you are even
	echo slightly unsure about whether there's data on your system that
	echo you would regret losing, then please press ctrl-C and stop this
	echo command file. Otherwise, just press any key.
	pause
	cls
	echo After wiping disk 0, it will install a 1GB Windows boot
	echo partition and a copy of WinPE.
	echo (This would be useful even if you DIDN'T want to run Steadier
	echo State, as you could then just run the normal Windows install
	echo after this runs and you'd end up with a copy of Windows, but
	echo with an extra "maintenance" copy of WinPE that you can access
	echo to fix various "cannot boot" problems.)
	if %_firmware%==uefi (
		echo Next, we will create a 100MB uefi partition, that will contain
		echo the Windows boot manager.
	)
	echo Finally, this takes the remaining disk space and creates one
	echo big C: drive.
	echo.
	echo For this command file to work, you must run this from a WinPE-
	echo equipped USB stick or DVD created with the BUILDPE.CMD command
	echo file that accompanied this file.
	echo.
	echo If you ARE sure that you want to wipe drive 0 clean and install
	echo a WinPE-equipped Windows boot manager and partition then please
	echo type the ninth word in this paragraph and then press Enter to
	echo start the wipe-and-rebuild process. (The 4-letter word starts
	echo with a "w.") Or type anything else and press Enter to stop the
	echo process.
	echo.
	set /p _wiperesponse=Please type the word in lowercase and press Enter. 
	echo.
	if not %_wiperesponse%==wipe goto :goodend

:findusbdrive
	rem
	rem Next, find the USB drive's "real" drive letter
	rem (The USB or DVD boots from a drive letter like C: or
	rem the like, mounting and expanding a single file named
	rem boot.wim into an X: drive.  As I want to image WinPE
	rem onto the hard disk, I need access to non-expanded
	rem version of the \sources\boot.wim image.  This tries to
	rem find that by using diskpart to check the volume label
	rem _usbdrive = The USB drive's "real" drive letter
	rem listvolume.txt = The script to find the volumes
	rem
	echo.
	echo Finding the drive letter for the USB/DVD
	for /f "tokens=3,4" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (if %%b==WINPE set _usbdrive=%%a:)
	set _usbdriverc=%errorlevel%
	if '%_usbdrive%'=='' (
		echo.
		echo Unable to find any mounted volume name "WINPE". That means
		echo that the "real" drive letter of the USB/DVD was not found. I
		echo can't fix this so I've got to exit. Please ensure that you
		echo are running this command file from a WinPE-equipped USB/DVD
		echo prepared by Steadier State.
		goto :badend
	)
	if %_usbdriverc%==0 (
		echo.
		echo The Real USB drive is letter %_usbdrive%.
		echo Now checking to make sure boot.wim exists.
		goto :findbootwim
	)
	echo.
	echo Diskpart failed when looking for the USB drive letter, return
	echo code %_usbdriverc%. It's not really safe to continue so I'm
	echo stopping here. Look at what Diskpart just reported to see if
	echo there's a clue in there.  You may also get a clue from the
	echo diskpart script %_actdrive%\srs\listvolume.txt.
	goto :badend

:findbootwim
	rem
	rem Check if boot.wim exists
	rem
	echo.
	echo Checking if the boot.wim file exists
	if exist %_usbdrive%\sources\boot.wim (
		echo.
		echo boot.wim was found on %_usbdrive%. We can now continue.
		goto :findsrsdrive
	)
	echo.
	echo Found what should have been the USB drive, but was unable to
	echo locate the boot.wim file. Make sure that the Steadier State USB
	echo is the only drive with a label of WINPE.
	echo.
	goto :badend

:findsrsdrive
	rem
	rem Find an available drive letter for the Steadier State Tools Partition
	rem srsdrive = Partition for the Steadier State Tools (SrS tools)
	rem
	echo.
	echo Finding a drive letter to use for the Steadier State (SrS)
	echo Tools Partition
	for /f "tokens=3" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (
		set _volletter=%%a
		set _volletter=!_volletter:~0,1!
		call set _strletters=%%_strletters:!_volletter! =%%
	)
	for %%a in (%_strletters%) do (
		if not exist %%a:\ (
			echo.
			echo Found %%a: as an available drive letter for the SRS
			echo Tools Partition.
			set _srsdrive=%%a
			goto :makesrsdrive
		)
	)
	echo.
	echo Error:  I need a drive letter for the SrS Tools Partition but
	echo could not find one in the following range: C-W,Y,Z. I can't do
	echo the job without a free drive letter, so I've got to stop.
	goto :badend

:makesrsdrive
	rem
	rem Create SrS tools partition
	rem
	echo.
	echo Using diskpart to create the Steadier State (SrS) Tools
	echo Partition
	echo select disk 0 >%_actdrive%\makesrs.txt
	echo clean >>%_actdrive%\makesrs.txt
	if %_firmware%==uefi echo convert gpt >>%_actdrive%\makesrs.txt
	echo create partition primary size=1000 >>%_actdrive%\makesrs.txt
	echo format quick fs=ntfs label="SrS_Tools" >>%_actdrive%\makesrs.txt
	if %_firmware%==bios echo active >>%_actdrive%\makesrs.txt
	echo assign letter=%_srsdrive% >>%_actdrive%\makesrs.txt
	if %_firmware%==uefi echo set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac" >>%_actdrive%\makesrs.txt
	if %_firmware%==uefi echo gpt attributes=0x8000000000000001 >>%_actdrive%\makesrs.txt
	echo rescan >>%_actdrive%\makesrs.txt
	echo exit >>%_actdrive%\makesrs.txt
	diskpart /s %_actdrive%\makesrs.txt
	set _makesrsrc=%errorlevel%
	if %_makesrsrc%==0 (
		echo.
		echo Diskpart successfully created SrS Tools Partition.
		echo We will use %_srsdrive%:
		set _srsdrive=%_srsdrive%:
		if %_firmware%==uefi (
			goto :findefidrive
		) else (
			goto :findphydrive
		)
	)
	echo.
	echo Diskpart failed to create the SrS Tools Partition, return code
	echo %_makesrsrc%. It's not really safe to continue so I'm stopping
	echo here.  Look at what Diskpart just reported to see if there's a
	echo clue in there.  You may also get a clue from the diskpart
	echo script: %_actdrive%\makesrs.txt.
	goto :badend

:findefidrive
	rem
	rem Find an available drive letter for the System Partition
	rem _efidrive = System Partition for uefi boot
	rem
	echo.
	echo Finding a drive letter to use for the UEFI Partition
	for /f "tokens=3" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (
		set _volletter=%%a
		set _volletter=!_volletter:~0,1!
		call set _strletters=%%_strletters:!_volletter! =%%
	)
	for %%a in (%_strletters%) do (
		if not exist %%a:\ (
			echo.
			echo Found %%a: as an available drive letter for the UEFI
			echo Partition.
			set _efidrive=%%a
			goto :makeefidrive
		)
	)
	echo.
	echo Error:  I need a drive letter for the UEFI System Partition,
	echo but could not find one in the following range: C-W,Y,Z. I can't
	echo do the job without a free drive letter, so I've got to stop.
	goto :badend

:makeefidrive
	rem
	rem Create System_UEFI partition
	rem
	echo.
	echo Using diskpart to create the UEFI Partition
	echo select disk 0 >%_actdrive%\makeefi.txt
	echo create partition efi size=100 >>%_actdrive%\makeefi.txt
	echo format quick fs=fat32 label="SYSTEM_UEFI" >>%_actdrive%\makeefi.txt
	echo assign letter=%_efidrive% >>%_actdrive%\makeefi.txt
	echo rescan >>%_actdrive%\makeefi.txt
	echo exit >>%_actdrive%\makeefi.txt
	diskpart /s %_actdrive%\makeefi.txt
	set _makeefirc=%errorlevel%
	if %_makeefirc%==0 (
		echo.
		echo Diskpart successfully created UEFI System Partition.
		echo We will use %_efidrive%:
		set _efidrive=%_efidrive%:
		goto :makemsrdrive
	)
	echo.
	echo Diskpart failed to create the UEFI System Partition, return
	echo code %_makeefirc%. It's not really safe to continue so I'm
	echo stopping here. Look at what Diskpart just reported to see if
	echo there's a clue in there. You may also get a clue from the
	echo diskpart script: %_actdrive%\makeefi.txt.
	goto :badend

:makemsrdrive
	rem
	rem Create Microsoft Reserved (MSR) partition
	rem
	echo.
	echo Using diskpart to create the MSR Partition
	echo select disk 0 >%_actdrive%\makemsr.txt
	echo create partition msr size=128 >>%_actdrive%\makemsr.txt
	echo exit >>%_actdrive%\makemsr.txt
	diskpart /s %_actdrive%\makemsr.txt
	set _makemsrrc=%errorlevel%
	if %_makemsrrc%==0 (
		echo.
		echo Diskpart successfully created MSR Partition.
		goto :findphydrive
	)
	echo.
	echo Diskpart failed to create the MSR Partition, return code
	echo %_makemsrrc%. It's not really safe to continue so I'm stopping
	echo here.  Look at what Diskpart just reported to see if there's a
	echo clue in there. You may also get a clue from the diskpart
	echo script: %_actdrive%\makemsr.txt.
	goto :badend

:findphydrive
	rem
	rem Find an available drive letter for the remaining space on the Hard Drive
	rem _phydrive = Physical Drive Partition
	rem
	echo.
	echo Finding a drive letter to use for the Physical Drive Partition
	for /f "tokens=3" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (
		set _volletter=%%a
		set _volletter=!_volletter:~0,1!
		call set _strletters=%%_strletters:!_volletter! =%%
	)
	for %%a in (%_strletters%) do (
		if not exist %%a:\ (
			echo.
			echo Found %%a: as an available drive letter for the
			echo Physical Drive Partition.
			set _phydrive=%%a
			goto :makephydrive
		)
	)
	echo.
	echo Error:  I need a drive letter for the Physical Drive Partition
	echo but could not find one in the following range: C-W,Y,Z. I can't
	echo do the job without a free drive letter, so I've got to stop.
	goto :badend

:makephydrive
	rem
	rem Create Physical Drive partition
	rem
	echo.
	echo Using diskpart to create the Physical Drive Partition
	echo select disk 0 >%_actdrive%\makephy.txt
	echo create partition primary  >>%_actdrive%\makephy.txt
	echo format quick fs=ntfs label="Physical_Drive" >>%_actdrive%\makephy.txt
	echo assign letter=%_phydrive% >>%_actdrive%\makephy.txt
	echo rescan >>%_actdrive%\makephy.txt
	echo exit >>%_actdrive%\makephy.txt
	diskpart /s %_actdrive%\makephy.txt
	set _makephyrc=%errorlevel%
	if %_makephyrc%==0 (
		echo.
		echo Diskpart successfully created Physical Disk Partition. We
		echo will use %_phydrive%:
		echo.
		echo All diskpart phases completed successfuly!!
		set _phydrive=%_phydrive%:
		goto :applywim
	)
	echo.
	echo Diskpart failed to create the Physical Disk Partition, return
	echo code %makephyrc%. It's not really safe to continue so I'm
	echo stopping here. Look at what Diskpart just reported to see if
	echo there's a clue in there. You may also get a clue from the
	echo diskpart script: %_actdrive%\makephy.txt.
	goto :badend

:applywim
	rem
	rem Apply the boot.wim from the PE drive to the %_srsdrive%
	rem
	echo.
	echo Installing WinPE on System Reserved Partition
	echo We'll use Dism to lay down a WinPE image on our new System
	echo Reserved partition, which is using %_srsdrive%. The Steadier
	echo State files will run atop WinPE (which is the main reason we're
	echo installing it) AND -- bonus! -- serves as a "maintenance" copy
	echo of Windows that's very useful for resolving various boot and
	echo storage problems.
	Dism /ScratchDir:%_extdrive%\scratch /Apply-Image /ImageFile:%_usbdrive%\sources\boot.wim /ApplyDir:%_srsdrive% /Index:1 /CheckIntegrity /Verify
	set _applyrc=%errorlevel%
	if %_applyrc%==0 (
		echo.
		echo Dism successfully imaged boot.wim onto %_srsdrive%.
		goto :findvhddrive
	)
	echo.
	echo ERROR: Failed to apply the image with return code %_applyrc%.
	echo Can't continue. Please check the logs and try again.
	goto :badend

:findvhddrive
	rem
	rem Find an available drive letter that can be used to mount the image.vhd
	rem _vhddrive = The drive letter used to mount image.vhd
	rem
	echo.
	echo Finding a drive letter to use for the Physical Drive Partition
	for /f "tokens=3" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (
		set _volletter=%%a
		set _volletter=!_volletter:~0,1!
		call set _strletters=%%_strletters:!_volletter! =%%
	)
	for %%a in (%_strletters%) do (
		if not exist %%a:\ (
			echo.
			echo Found %%a: as an available drive letter for the vhd.
			set _vhddrive=%%a
			goto :copyvhd
		)
	)
	echo.
	echo Error: I need a drive letter to mount image.vhd but could not
	echo find one in the following range C-W,Y,Z. I can't do the job
	echo without a free drive letter, so I've got to stop.
	goto :badend

:copyvhd
	rem
	rem Copy the vhd on to the %_phydrive% drive
	rem
	echo.
	echo Using Robocopy to copy the image.vhd file located in
	echo %_extdrive% to the %_phydrive% partition.
	robocopy %_extdrive% %_phydrive% image.vhd /mt:50
	set _copyvhdrc=%errorlevel%
	if %_copyvhdrc%==1 (
		echo.
		echo VHD file successfully transferred to %_phydrive%\image.vhd
		goto :attachvhd
	)
	echo.
	echo ERROR: Robocopy failed with return code %copyvhdrc%. Can't
	echo continue without copying the vhd. Please check the logs and try
	echo again.
	goto :badend

:attachvhd
	rem
	rem attachvhd.txt is the name of the script attach the vhd
	rem
	echo.
	echo Using diskpart to attach image.vhd
	echo select vdisk file=%_phydrive%\image.vhd >%_actdrive%\attachvhd.txt
	echo attach vdisk >>%_actdrive%\attachvhd.txt
	echo exit >>%_actdrive%\attachvhd.txt
	diskpart /s %_actdrive%\attachvhd.txt
	set _attachvhdrc=%errorlevel%
	if %_attachvhdrc%==0 (
		echo.
		echo Diskpart successfully attached image.vhd.
		goto :listvolume
	)
	echo.
	echo Diskpart failed to atach image.vhd, return code
	echo %_attachvhdrc%.
	echo It's not really safe to continue so I'm stopping here. Look at
	echo what Diskpart just reported to see if there's a clue in there.
	echo You may also get a clue from the diskpart script:
	echo %_actdrive%\attachvhd.txt.
	goto :badend

:listvolume
	rem
	rem listvolume.txt is the name of the script to find the volumes
	rem
	echo.
	echo Using diskpart to find the Volume Number of the vhd
	for /f "tokens=2,4" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (if %%b==Windows_SrS set _volnum=%%a)
	set _volnumrc=%errorlevel%
	if '%_volnum%'=='' (
		echo.
		echo Unable to find any mounted volume name "Windows_SrS"
		echo Have you already run the cvt2vhd command?
		goto :badend
	)
	if %_volnumrc%==0 (
		echo.
		echo Diskpart successfully attached image.vhd. It is volume %_volnum%.
		goto :mountvhd
	)
	echo.
	echo Diskpart was unable to attach image.vhd, return code %_volnumrc%.
	echo It's not really safe to continue so I'm stopping here. Look at
	echo what Diskpart just reported to see if there's a clue in there.
	echo You may also get a clue from the diskpart script:
	echo %_actdrive%\listvolume.txt.
	goto :badend

:mountvhd
	rem
	rem mountvhd.txt is the name of the script to assign the drive letter
	rem
	echo.
	echo Using diskpart to mount image.vhd
	echo select volume %_volnum% >%_actdrive%\mountvhd.txt
	echo assign letter=%_vhddrive% >>%_actdrive%\mountvhd.txt
	echo exit >>%_actdrive%\mountvhd.txt
	diskpart /s %_actdrive%\mountvhd.txt
	set _mountvhdrc=%errorlevel%
	if %_mountvhdrc%==0 (
		echo.
		echo Diskpart successfully mounted image.vhd. We will used %_vhddrive%:
		set _vhddrive=%_vhddrive%:
		goto :copybcd
	)
	echo.
	echo Diskpart was unable to mount image.vhd return code %_mountvhdrc%.
	echo It's not really safe to continue so I'm stopping here. Look at
	echo what Diskpart just reported to see if there's a clue in there.
	echo You may also get a clue from the diskpart script:
	echo %_actdrive%\mountvhd.txt.
	goto :badend

:copybcd
	rem
	rem Grab a basic boot folder and BOOTMGR
	rem
	echo.
	echo With that out of the way, we'll need some extra boot files that
	echo do not ship with WinPE, so we'll copy them from image.vhd with
	echo BCDBoot.
	if %_firmware%==bios (
		set _bcdstore=/store %_srsdrive%\Boot\BCD
		bcdboot %_vhddrive%\windows /s %_srsdrive% /f ALL
	)
	if %_firmware%==uefi (
		set _bcdstore=/store %_efidrive%\EFI\Microsoft\Boot\BCD
		bcdboot %_vhddrive%\windows /s %_efidrive% /f ALL
	)
	set _bcdbootrc=%errorlevel%
	if %_bcdbootrc%==0 (
		echo.
		echo BCDBoot successfully copied the bcd settings.
		goto :bcdconfig
	)
	echo.
	echo ERROR: BCDBoot failed with return code %_bcdbootrc%.  It's not
	echo really safe to continue so I'm stopping here.
	goto :badend

:bcdconfig
	rem
	rem Modify the BCD to support Steadier State
	rem
	echo.
	echo Now we'll need to edit the boot configuration database (BCD).
	echo It's an essential file that every copy of Windows since Vista
	echo requires, and we need one that knows how to boot WinPE from
	echo your hard disk's SRS Tools partition.
	echo We do that with a dozen "bcdedit" commands.
	echo.
	echo You should see a series of responses that indicate they were completed
	echo successfully. If they do not all complete successfully something went
	echo wrong.
	echo.
	echo on
	for /f "tokens=2 delims={}" %%a in ('bcdedit %_bcdstore% /create /d "Roll Back Windows" /application osloader') do (set _guid={%%a})
	@echo off
	if '%_guid%'=='' (
		echo.
		echo Unable to create Roll Back Windows entry with bcdedit
		goto :badend
	)
	echo on
	bcdedit %_bcdstore% /set %_guid% osdevice partition=%_srsdrive%
	bcdedit %_bcdstore% /set %_guid% device partition=%_srsdrive%
	bcdedit %_bcdstore% /set %_guid% path %_winload%
	bcdedit %_bcdstore% /set %_guid% systemroot \windows
	bcdedit %_bcdstore% /set %_guid% winpe yes
	bcdedit %_bcdstore% /set %_guid% detecthal yes
	bcdedit %_bcdstore% /displayorder %_guid% /addlast
	bcdedit %_bcdstore% /timeout 1
	@echo off
	for /f "delims=" %%a in ('bcdedit %_bcdstore% /enum /v') do (
		for /f "tokens=1,2" %%b in ('echo %%a') do (
			if %%b==identifier (
				set _guid=%%c
				bcdedit %_bcdstore% /enum !_guid! /v | find /c "image.vhd" >%_actdrive%\temp.txt
				set _total=
				set /p _total= <%_actdrive%\temp.txt
				del %_actdrive%\temp.txt 2>nul
				if not !_total!==0 (
						bcdedit %_bcdstore% /default !_guid!
						echo Successfully set image.vhd as default, reboot and you're ready to go.
						goto :copysrs
				)
			)
		)
	)
	echo.
	echo Something went wrong and I was unable to set image.vhd as the
	echo default entry in the following bcd store:
	echo %_bcdstore%
	goto :badend

:copysrs
	rem
	rem copy over the Steadier State files from the USB/DVD
	rem
	echo.
	echo Finally, we'll a create a folder \srs inside the copy of WinPE
	echo that we've just installed in your System Reserved partition and
	echo then copy the Steadier State support files. While we're at it,
	echo we'll add Dism to the System32 folder of that copy of WinPE so
	echo that cvt2vhd can employ it. (And because it's useful to have a
	echo copy of Dism close at hand for re-imaging sometimes.)
	robocopy %_actdrive%\srs %_srsdrive%\srs
	rem
	rem and the updated startnet.cmd
	rem
	copy %_actdrive%\startnethd.cmd %_srsdrive%\windows\system32\startnet.cmd /y
	copy %_actdrive%\windows\system32\Dism.exe %_srsdrive%\windows\system32 /y
	rem
	rem and the necessary files for the vhd
	rem
	md %_vhddrive%\srs
	copy %_actdrive%\srs\bcddefault.cmd %_vhddrive%\srs /y
	copy %_actdrive%\srs\firstrun.cmd %_vhddrive%\srs /y
	copy %_actdrive%\srs\listvolume.txt %_vhddrive%\srs\listvolume.txt
	md %_vhddrive%\srs\hooks
	copy %_actdrive%\srs\hooks\* %_vhddrive%\srs\hooks /y
	md %_vhddrive%\srs\hooks-samples
	copy %_actdrive%\srs\hooks-samples\* %_vhddrive%\srs\hooks-samples /y
	goto :goodend

:notwinpe
	rem
	rem prepnewpc.cmd was not run from a PE
	rem
	echo.
	echo This command file only runs from a WinPE-equipped USB/DVD,
	echo and only when you've booted from that USB stick.
	echo.
	echo Please set up your bootable WinPE USB/DVD as explained
	echo in the documentation, and run prepnewpc.cmd from that USB/DVD.
	echo.
	goto :end

:goodend
	rem
	rem Success
	rem
	echo.
	echo ===============================================================
	echo PREPNEWPC COMPLETED SUCCESSFULLY
	echo ===============================================================
	echo.
	echo Once rebooted, Steadier State will automatically reboot using
	echo the image.vhd, which will be the base image from now on. You
	echo should login and run the firstrun.cmd found in the C:\srs
	echo directory.
	echo.
	echo After that file is run you are safe to reboot the computer,
	echo which will automatically reboot your computer to the SRS Tools
	echo partition. The SRS tools partition will create your first
	echo snapshot file AND reboot so that you can start using Windows
	echo with Steadier State. (Don't worry when it does a little work
	echo and then reboots.)
	echo.
	echo If you plan to modify the image further before final
	echo deployment, then take a look in the documentation about using
	echo the "merge" command.
	echo.
	echo I hope you find this useful!
	echo -- Mark Minasi help@minasi.com www.steadierstate.com
	goto :end

:badend
	rem
	rem Something failed
	rem
	echo.
	echo Something went wrong and we were not able to prepare this
	echo computer for Steadier State. In its current state the computer
	echo may unbootable. You should check the logs and see what went
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
