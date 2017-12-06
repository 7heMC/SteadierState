@echo off

:background
	rem
	rem Provide user with background information about cvt2vhd.cmd
	rem
	echo ===============================================================
	echo How and Why To Use CVT2VHD in Steadier State
	echo ===============================================================
	echo.
	echo Steadier State lets you create a "snapshot" of a Windows
	echo installation so that you can choose at any time to reboot
	echo your Windows system, choose "Roll Back Windows," and at
	echo that point every change you've made to the system is un-done.
	echo To do that, however, Steadier State requires you to convert
	echo your Windows system to a VHD file, and CVT2VHD does that
	echo for you.
	echo.
	echo To get a system ready for conversion, first boot it from
	echo your SteadierState bootable USB stick or CD.  Then, connect
	echo the system to some large external drive, whether it's a
	echo networked drive mapped to a drive letter or perhaps a large
	echo external hard disk -- you'll need that because you're going
	echo to take that system's C: drive and rebuild it as one large
	echo VHD file.  On the USB stick/CD, you'll see a file named
	echo cvt2vhd.cmd.
	echo.
	echo This'll take a while, but when it's done, you'll have a file
	echo named image.vhd on your target drive. Once you've got the
	echo image.vhd, you're ready to prep a system to get it ready to
	echo be able to use that VHD.  You can do that by booting the system
	echo with your USB stick/CD and then running prepnewpc. Or if you
	echo want to deploy it on this machine simply use run the prepnewpc
	echo command once this is complete.
	echo.
	echo Thanks for using Steadier State, I hope it's of value.
	echo -- Mark Minasi help@minasi.com www.steadierstate.com
	echo.
	echo This copy of SteadierState has been updated to work with
	echo Windows 7, 8, 8.1 and 10. The source can be found at
	echo https://github.com/7heMC/SteadierState
	pause

:setup
	rem
	rem Check that we're running from the root of the boot device
	rem Use the pseudo-variable ~d0 to get the job done
	rem _actdrive = this currently active drive
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
		echo a Steadier State USB stick/CD.
		goto :notwinpe
	)
	echo.
	echo Here is the list of current volumes on your computer. This will
	echo hopefully help you answer the following question.
	echo.
	for /f "delims={}" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (echo %%a)

:imgdrivequestion
	rem
	rem _imgdrive = local drive with Windows folder on it that we'll be imaging (does not sysprep, that's up to you) (should include colon)
	rem
	echo ===============================================================
	echo What drive will be imaged?
	echo.
	echo What is the local drive with Windows folder on it that we'll be
	echo imaging. This process does not sysprep, that's up to you. Your
	echo response should include a colon (probably C:). Type 'end' to
	set /p _imgdrive=quit. 
	if '%_imgdrive%'=='end' goto :end
	if '%_imgdrive%'=='' (
		echo.
		echo You did not supply an answer. Let's try again.
		goto :imgdrivequestion
	)
	if not exist %_imgdrive%\ (
		echo.
		echo Drive %_imgdrive% does not seem to exist. Let's try again.
		goto :imgdrivequestion
	)

:extdrivequestion
	rem
	rem _extdrive = external drive letter we'll write the wim and then vhd to (should include colon)
	rem
	echo.
	echo ===============================================================
	echo Where will the image be stored?
	echo.
	echo What is the external drive and folder where you would like to
	echo store the vhd file. If you would like to store the vhd at the
	echo root of a drive you can simply enter the drive letter with a
	echo colon. If you would like to store it in a directory please
	echo enter the path. For example, E:\images
	set /p _extdrive=What is your response? 
	set _extdriveletter=%_extdrive:~0,2%
	if '%_extdrive%'=='end' goto :end
	if '%_extdrive%'=='' (
		echo.
		echo You did not supply an answer. Let's try again.
		goto :extdrivequestion
	)
	if not exist %_extdriveletter%\ (
		echo.
		echo Drive %_extdriveletter% does not seem to exist. Let's try again.
		goto :extdrivequestion
	)
	if exist %_extdrive%\image.vhd (
		echo.
		echo %_extdrive%\image.vhd already exists. Please enter a
		echo different location.
		goto :extdrivequestion
	)
	if not exist %_extdrive%\scratch md %_extdrive%\scratch

:vhdsizequestion
	rem
	rem _vhdsize = size of the image.vhd file (an expandable file) in
	rem megabytes... we'll add 000 to make it gigabytes
	rem
	echo.
	echo ===============================================================
	echo What is the maximum size of the vhd?
	echo.
	echo What is the maximum size that the VHD will need to be, in
	echo gigabytes? Remember that the physical volume that you deploy
	echo this image.vhd to should have an amount of free space equal to
	echo at least 2.5 times the image.vhd maximum size. For example, if
	echo the maximum size is 80GB then the external drive would need to
	echo be 200GB. (80GB x 2.5 = 200GB.)
	set /p _vhdsize=Please enter just the number. 
	if '%_vhdsize%'=='end' goto :end
	if '%_vhdsize%'=='' (
		echo.
		echo -------- ERROR -----------
		echo.
		echo You did not provide a number.  Let's try again.
		goto :vhdsizequestion
	)
	echo.
	set /a _sizereq=(%_vhdsize%*2)+(%_vhdsize%/2)
	echo You have selected a vhd size of %_vhdsize% GB. So you will need
	echo atleast %_sizereq%GB on your physical drive.

:findvhddrive
	rem
	rem Find an available drive letter for attaching the vhd
	rem tmpdrive = temporary drive letter to use when creating and
	rem attaching the VHD.
	rem
	for /f "tokens=3" %%a in ('diskpart /s %_actdrive%\srs\listvolume.txt') do (
		set _volletter=%%a
		set _volletter=!_volletter:~0,1!
		call set _strletters=%%_strletters:!_volletter! =%%
	)
	for %%a in (%_strletters%) do (
		if not exist %%a:\ (
			set _vhddrive=%%a
			goto :confirm
		)
	)
	echo.
	echo Error:  I need a drive letter for mounting the vhd but could
	echo not find one in the following range C-W,Y,Z.  I can't do the
	echo job without a free drive letter, so I've got to stop.
	goto :badend

:confirm
	rem
	rem Confirm with user before proceeding
	rem
	cls
	echo.
	echo ================== Convert PC to VHD Routine ==================
	echo.
	echo This command file takes the operating system drive of this
	echo computer and re-images it as a file named image.vhd.
	echo To run this correctly, you should have booted the computer
	echo that you want to convert to VHD to WinPE using the USB
	echo stick that you created with buildpe, as part of Steadier State.
	echo If that's not the case, just press ctrl-C and stop this.
	echo.
	echo Before going further, you should have the PC connected to
	echo a drive -- networked, external, or whatever -- with enough
	echo space to hold your Windows box's C: drive on it.
	echo.
	echo Confirming, you chose:
	echo	Drive to to convert to VHD=%_imgdrive%.
	echo	Drive/folder to store the image/VHD=%_extdrive%.
	echo	Maximum "image.vhd" size=%_vhdsize%GB.
	echo Additionally, I will use drive %_vhddrive%: to mount the vhd.
	echo.
	set /p _confirm=Type 'y' and Enter to continue. Anything else to cancel. 
	if not '%_confirm%'=='y' goto :end

:capturewim
	rem
	rem Capture the wim from the hard drive
	rem
	echo.
	echo Capturing the wim, which will be used to fill the vhd.
	echo Imaging %_imgdrive% to %_extdrive%, command is:
	echo Dism /ScratchDir:%_extdrive%\scratch /Capture-Image /ImageFile:%_extdrive%\image.wim /CaptureDir:%_imgdrive%\ /Name:"Intermediate image" /Verify
	Dism /ScratchDir:%_extdrive%\scratch /Capture-Image /ImageFile:%_extdrive%\image.wim /CaptureDir:%_imgdrive%\ /Name:"Intermediate image" /Verify
	set _capturerc=%errorlevel%
	if %_capturerc%==0 (
		echo.
		echo Dism created image.wim successfully.
		goto :makevhd
	)
	echo.
	echo ============= ERROR: Dism capture attempt failed ==============
	echo.
	echo Dism failed with error code %_capturerc%.
	goto :badend

:makevhd
	rem
	rem Make the vhd container
	rem
	echo.
	echo Using diskpart to make the vhd container to hold the wim
	echo create vdisk file="%_extdrive%\image.vhd" type=expandable maximum=%_vhdsize%000 >makevhd.txt
	echo select vdisk file="%_extdrive%\image.vhd" >>makevhd.txt
	echo attach vdisk >>makevhd.txt
	echo create partition primary >>makevhd.txt
	echo format fs=ntfs quick label="Windows_SrS" >>makevhd.txt
	echo assign letter=%_vhddrive% >>makevhd.txt
	echo exit >>makevhd.txt
	set _vhddrive=%_vhddrive%:
	echo.
	echo Making a vhd container for the image.wim
	echo We'll issue these commands to DISKPART:
	echo.
	type makevhd.txt
	diskpart /s makevhd.txt
	set _makevhdrc=%errorlevel%
	if %_makevhdrc%==0 (
		echo.
		echo Diskpart created and attached image.vhd
		goto :fillvhd
	)
	echo.
	echo =========== ERROR: Diskpart make vhd attempt failed ===========
	echo.
	echo Diskpart failed with error code=%_makevhdrc%.
	goto :badend

:fillvhd
	rem
	rem Fill the vhd container
	rem
	echo.
	echo Filling vhd with image.wim, we'll run this command:
	echo Dism /ScratchDir:%_extdrive%\scratch /Apply-Image /ImageFile:%_extdrive%\image.wim /ApplyDir:%_vhddrive%\ /Index:1 /Verify
	Dism /ScratchDir:%_extdrive%\scratch /Apply-Image /ImageFile:%_extdrive%\image.wim /ApplyDir:%_vhddrive%\ /Index:1 /Verify
	set _applyrc=%errorlevel%
	if %_applyrc%==0 (
		echo.
		echo Dism applied image.wim to image.vhd successfully.
		goto :detachvhd
	)
	echo.
	echo ============== ERROR: Dism apply attempt failed ===============
	echo.
	echo Dism failed with error code %_applyrc%.
	goto :badend

:detachvhd
	rem
	rem Detach the vhd
	rem
	echo.
	echo Finally, unmount the VHD:
	echo select vdisk file="%_extdrive%\image.vhd" >detachvhd.txt
	echo detach vdisk >>detachvhd.txt
	echo exit >>detachvhd.txt
	echo We'll execute these DISKPART commands:
	echo.
	type detachvhd.txt
	diskpart /s detachvhd.txt
	echo.
	set _detachvhdrc=%errorlevel%
	if %_detachvhdrc%==0 (
		echo.
		echo Diskpart detached image.vhd.
		goto :goodend
	)
	echo.
	echo =========== ERROR: Diskpart make vhd attempt failed ===========
	echo.
	echo Diskpart failed with error code=%_detachvhdrc%.
	goto :badend

:goodend
	rem
	rem Now we're done, it's in image.vhd
	rem
	echo Completed creating your image.vhd.  To deploy this to a PC, you should:
	echo.
	echo  1) Boot the target PC with your Steadier State USB stick/CD.
	echo  2) Run prepnewpc on the target PC (which will wipe the hard drive of that
	echo     system, so if there's anything you care about on that target PC, back
	echo     it up first)!
	echo  3) Your target PC will now have a large empty C: drive.  Copy this image.vhd
	echo     that you've just created to the root of that C:\ drive.
	echo  4) Once image.vhd has copied, remove the USB stick/CD and reboot the PC from
	echo     its hard drive.  When you reboot, Steadier State will determine that your
	echo     system needs a snapshot file and an OS boot entry, so it creates those
	echo     things and automatically reboots again.  Let it do its work and reboot and
	echo     your system will soon boot up in Windows 7, but at that point you'll be
	echo     protected by Steadier State -- whenever you want your system to forget
	echo     everything done to it since now, just reboot and at Boot Manager, choose
	echo     "Roll Back Windows."
	echo.
	echo Thanks for using Steadier State, I hope it's of value.
	echo -- Mark Minasi help@minasi.com www.steadierstate.com
	goto :end

:notwinpe
	rem
	rem cvt2vhd.cmd was not run from a PE
	rem
	echo.
	echo This command file only runs from a WinPE-equipped USB
	echo stick or DVD, and it will only work if you've booted from one
	echo of those devices.
	echo.
	echo Please set up your bootable WinPE device as explained in the
	echo documentation, and run prepnewpc.cmd from that device.
	echo.
	echo Thanks, and I hope you find Steadier State useful.
	goto :end

:badend
	rem
	rem Something failed
	rem
	echo.
	echo Please check the errors listed to see if it provides any help
	echo in figuring out what happened.

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
