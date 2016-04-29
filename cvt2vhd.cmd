@echo off
setlocal ENABLEDELAYEDEXPANSION

:background
echo How and Why To Use CVT2VHD in Steadier State
echo --------------------------------------------
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
echo This copy of SteadierState has been modified and the source
echo can be found at https://github.com/7heMC/SteadierState
goto :end

echo.
echo Here is the list of current volumes on your computer. This will hopefully
echo help you answer the following questions.
echo.
for /f "delims={}" %%a in ('diskpart /s %sourceresp%\listvolume.txt') do (echo %%a)
echo.

:imgdrivequestion
REM
REM imgdrive = local drive with Windows folder on it that we'll be imaging (does not sysprep, that's up to you) (should include colon)
REM
echo =========================================================
echo Question 1: What drive will be imaged?
echo.
echo What is that local drive with Windows folder on it that we'll be imaging.
echo This process does not sysprep, that's up to you. Your response should
set /p imgdrive=include a colon (probably C:). Type 'end' to quit.
if '%imgdrive%'=='end' ((echo.)&(echo Exiting as requested.)&(goto :end))
if '%imgdrive%'='' ((echo.)&(echo ---- ERROR ----)&(echo.)&(echo There doesn't seem to be anything at %imgdrive%.  Let's try again.)&(echo.)&(goto :imgdrivequestion))

:exdrivequestion
REM
REM exdrive = external drive letter we'll write the wim and then vhd to (should include colon)
REM
echo.
echo =========================================================
echo Question 2: Where will the image be stored?
echo.
echo What is the external drive and folder where you would like to store the vhd file.
echo If you would like to store the vhd at the root of a drive you can simply enter the
echo drive letter with a colon. If you would like to store it in a directory
echo please enter the path. For example, E:\images
set /p exdrive=What is your response?
if '%exdrive%'=='end' ((echo.)&(echo Exiting as requested.)&(goto :end))
if '%exdrive%'='' ((echo.)&(echo ---- ERROR ----)&(echo.)&(echo There doesn't seem to be anything at %exdrive%.  Let's try again.)&(echo.)&(goto :exdrivequestion))

:vhdsizequestion
REM
REM vhdsize = size of the image.vhd file (an expandable file) in megabytes... we'll add 000 to make it gigabytes
REM
echo.
echo =========================================================
echo Question 3: What is the maximum size of the vhd?
echo.
echo What is the maximum size that the VHD will need to be, in gigabytes?
echo Remember that the physical volume that you deploy this image.vhd to
echo should have an amount of free space equal to at least 2.5 times the
echo image.vhd maximum size -- For example if the maximum size is 80 GB
echo then the external drive would need to be 200 GB. (80 GB x 2.5 = 200 GB.)
set /p vhdsize=Please enter just the number.
if '%vhdsize%'=='end' ((echo.)&(echo Exiting as requested.)&(goto :end))
if '%vhdsize%'='' ((echo.)&(echo ---- ERROR ----)&(echo.)&(echo You did not provide a number.  Let's try again.)&(echo.)&(goto :vhdsizequestion))
echo.
set /a sizereq=(%vhdsize%*2)+(%vhdsize%/2)
echo You have selected a vhdsize of %vhdsize% GB. So you will need atleast 
echo %vhdsize% GB on your physical drive.

:skipwimquestion
REM
REM skipwim = determines whether a wim file is created
REM
echo.
echo =========================================================
echo Question 3: Skip wim creation?
echo.
echo Do you want to skip the step of creating a wim file. This step
echo recommended and will be processed unless you type 'skip' below.
set /p skipwim=What is your response?
if '%skipwim%'=='end' ((echo.)&(echo Exiting as requested.)&(goto :end))
if '%skipwim%'=='skip' ((echo.)&(echo You have chosen not to create a wim file.)&(set skipwim=true)&(goto :end))
set skipwim=false

REM
REM tdrive = temporary drive letter to use when creating and attaching the VHD (should include colon)
REM Find an available drive letter for a temporary drive
REM
set tdrive=none
if not exist W:\ set tdrive=w
if not exist V:\ set tdrive=v
if not exist U:\ set tdrive=u
if not exist T:\ set tdrive=t
if not exist S:\ set tdrive=s
if not exist R:\ set tdrive=r
if not exist Q:\ set tdrive=q
if not %tdrive%==none goto :foundtdrive
echo.
echo Error:  I need a temporary drive letter, but could
echo not find one between Q: and W:.  I can't do the job
echo without a free drive letter, so I've got to stop.
echo.
goto :end

:foundtdrive
REM 
REM check for inputs on everything
REM
if '%exdrive%'=='' (goto :needinputs)
if '%imgdrive%'=='' (goto :needinputs)
if '%vhdsize%'=='' (goto :needinputs)
REM
REM osversion = version of Windows PE
REM Check the drives exist
REM
if not exist %exdrive%\ ((echo.) & (echo Drive %exdrive% seems not to exist.) & (goto :end))
if not exist %imgdrive%\ ((echo.) & (echo Drive %imgdrive% seems not to exist.) & (goto :end))
if exist %exdrive%\image.vhd ((echo.)&(echo %exdrive%\image.vhd already exists.) & (goto :end))
if exist \windows\system32\imagex.exe ((echo.)&(set osversion=7)&(goto :drivesok)
if exist \windows\system32\Dism.exe ((echo.)&(set osversion=10)&(if not exist %exdrive%\scratch mkdir %exdrive%\scratch)&(goto :drivesok)
echo ImageX and Dism missing... please only run this from a system booted from
echo a Steadier State USB stick/CD.
goto :end

:drivesok
CLS
echo.
echo                      Convert PC to VHD Routine
echo                      -------------------------
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
echo You've said that:
echo   the OS you want to convert to VHD is %imgdrive%.
echo   the drive you want to create the image/VHD on is %exdrive%.
echo   you want the resulting "image.vhd" file to be %vhdsize% gigabytes.
echo I have noticed that you are preparing a Windows %osversion% system.
echo Additionally, I will use drive %tdrive%: as a temporary drive letter.
echo.
REM
REM Ready to get to work
REM
if %skipwim%==true goto :makevhd
echo =========================================
echo Step 1: Capture Windows drive as an image
echo =========================================
echo Imaging %imgdrive% to %exdrive%, command is: 
if %osversion%==7 (
echo imagex /capture %imgdrive% %exdrive%\image.wim "Intermediate image"  /verify
imagex /capture %imgdrive% %exdrive%\image.wim "Intermediate image" /verify
set capturerc=!errorlevel!
if not !capturerc!==0 ((echo ImageX failed with error code %imagexrc%, exiting.)&(goto :eof))
) else (
echo Dism /Capture-Image /ImageFile:%exdrive%\image.wim /CaptureDir:%imgdrive%  /ScratchDir:%exdrive%\scratch /Name:"Intermediate image"  /Verify
Dism /Capture-Image /ImageFile:%exdrive%\image.wim /CaptureDir:%imgdrive%  /ScratchDir:%exdrive%\scratch /Name:"Intermediate image"  /Verify
set capturerc=!errorlevel!
if not !capturerc!==0 ((echo Dism failed with error code !capturerc!, exiting.)&(goto :eof))
)
echo.
echo Step 1 successful.
echo.

:makevhd
echo ====================================================== 
echo Step 2: create an empty VHD file to receive the image.
echo ======================================================
echo.
echo create vdisk file="%exdrive%\image.vhd" type=expandable maximum=%vhdsize%000 >diskpart1script.txt
echo select vdisk file="%exdrive%\image.vhd" >>diskpart1script.txt
echo attach vdisk >>diskpart1script.txt
echo create partition primary >>diskpart1script.txt
echo format fs=ntfs quick label="Windows_SrS" >>diskpart1script.txt
echo assign letter=%tdrive% >>diskpart1script.txt
echo exit >>diskpart1script.txt
echo We'll issue these commands to DISKPART:
echo.
type diskpart1script.txt
diskpart /s diskpart1script.txt
set diskpart1rc=%errorlevel%
if %diskpart1rc%==0 ((echo.)&(echo Step 2 successful.) & (goto :fillvhd))
echo.
echo Diskpart failure.  Return code=%diskpart1rc%.  CVT2VHD unable to finish, exiting.
goto :eof

:fillvhd
echo.
echo =============================
echo Step 3: Apply image to VHD
echo =============================
echo.
REM
REM now to VHD
REM
echo we'll run this command:
if %osversion%==7 (
echo imagex /apply %exdrive%\image.wim 1 %tdrive%: /verify
imagex /apply %exdrive%\image.wim 1 %tdrive%: /verify
set applyrc=!errorlevel!
if not !applyrc!==0 ((echo ImageX failed with error code !applyrc!, exiting.)&(goto :eof))
) else (
echo Dism /Apply-Image /ImageFile:%exdrive%\image.wim /ApplyDir:%tdrive% /ScratchDir:%exdrive%\scratch /Index:1 /Verify
Dism /Apply-Image /ImageFile:%exdrive%\image.wim /ApplyDir:%tdrive%: /ScratchDir:%exdrive%\scratch /Index:1 /Verify
set applyrc=!errorlevel!
if not !applyrc!==0 ((echo Dism failed with error code !applyrc!, exiting.)&(goto :eof))
)
echo.
echo Step 3 successful.
echo.
echo ====================================
echo Step 4: Detach and close VHD file
echo ====================================
REM
REM now detach image.vhd and free up the temp drive letter
REM
echo Finally, unmount the VHD:
echo select vdisk file="%exdrive%\image.vhd" >diskpart2script.txt
echo detach vdisk >>diskpart2script.txt
echo exit >>diskpart2script.txt
echo.
echo We'll execute these DISKPART commands:
echo diskpart2script.txt:
echo.
type diskpart2script.txt
diskpart /s diskpart2script.txt
echo.
echo Done.
set diskpart2rc=%errorlevel%
if %diskpart2rc%==0 ((echo Diskpart successful.)&(goto :happyend))
echo.
echo Diskpart failure detaching VHD.  Return code=%diskpart2rc%.  
echo Check there's enough space on drive %imgdrive% and try again.
echo CVT2VHD unable to finish, exiting.
goto :eof

:happyend
REM
REM and now we're done, it's in image.vhd
REM
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
echo This copy of SteadierState has been modified and the source
echo can be found at https://github.com/7heMC/SteadierState
goto :eof

:needinputs
echo.
echo This script needs three inputs: the drive letter you want 
echo to image, like C:, the drive letter with sufficient space
echo to let you create the image, and the size of the VHD
echo file you want, in gigabytes.  So, for example, if you typed
echo.
echo cvt2vhd e: g: 80
echo.
echo Then cvt2vhd would image drive E: as image.vhd onto drive G:,
echo creating an image.vhd file that can expand as large as 80 GB.
echo.
echo NOTE:  the physical hard disk that you deploy the resulting
echo image.vhd onto should be at least 2.5 times the VHD file size
echo that you specified, so, for example, in the above case the 
echo image.vhd file you've capped at 80 GB should be deployed to a
echo physical volume that has at least 2.5x80 or 200 GB free.
echo.
echo Thanks for using Steadier State, I hope it's useful.
echo -- Mark Minasi help@minasi.com www.steadierstate.com
echo This copy of SteadierState has been modified and the source
echo can be found at https://github.com/7heMC/SteadierState

:end
