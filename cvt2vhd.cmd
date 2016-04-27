@echo off
REM
REM invoke this cvt2vhd <letter of drive we're imaging:> <letter of drive we're using to save WIM and VHD:> <size of VHD in gigabytes>
REM if you add "skipwim," it'll skip imaging (which takes time)
REM
REM exdrive = external drive letter we'll write the wim and then vhd to (should include colon)
REM imgdrive = local drive with Windows folder on it that we'll be imaging (does not sysprep, that's up to you) (should include colon)
REM vhdsize = size of the image.vhd file (an expandable file) in megabytes... we'll add 000 to make it gigabytes
REM tdrive = temporary drive letter to use when creating and attaching the VHD (should include colon)
set exdrive=%2
set imgdrive=%1
set vhdsize=%3
set skipwim=false
if a%4==askipwim set skipwim=true
if a%exdrive%%imgdrive%%vhdsize%==a (goto :background)

REM
REM Find an available drive letter for a temporary drive
REM
set tdrive=none
if not exist w:\ set tdrive=w
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
if a%exdrive%==a (goto :needinputs)
if a%imgdrive%==a (goto :needinputs)
if a%vhdsize%==a (goto :needinputs)
REM
REM Check the drives exist
REM 
if not exist %exdrive%\ ((echo.) & (echo Drive %exdrive% seems not to exist.) & (goto :end))
if not exist %imgdrive%\ ((echo.) & (echo Drive %imgdrive% seems not to exist.) & (goto :end))
if exist %exdrive%\image.vhd ((echo.)&(echo %exdrive%\image.vhd already exists.) & (goto :end))
if not exist \windows\system32\imagex.exe ((echo.)&(echo ImageX missing... please only run this from a system booted from & echo a Steadier State USB stick/CD.) & (goto :end))

REM 
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
echo   the OS you want convert to VHD is %imgdrive%.
echo   the drive you want to create the image/VHD on is %exdrive%.
echo   you want the resulting "image.vhd" file to be %vhdsize% gigabytes.
echo Additionally, I will use drive %tdrive%: as a temporary drive letter.
echo.

REM
REM Ready to get to work
REM


if a%skipwim%==atrue goto :makevhd

echo =========================================
echo Step 1: Capture Windows drive as an image
echo =========================================

echo Imaging %imgdrive% to %exdrive%, command is: 

echo imagex /capture %imgdrive% %exdrive%\image.wim "Intermediate image"  /verify

imagex /capture %imgdrive% %exdrive%\image.wim "Intermediate image" /verify

set imagexrc=%errorlevel%

if not %imagexrc%==0 ((echo ImageX failed with error code %imagexrc%, exiting.) & (goto :eof))
echo.
echo Step 1 successful.
echo.
:makevhd
echo ====================================================== 
echo Step 2: create an empty VHD file to receive the image.
echo ======================================================
echo.

echo create vdisk file="%exdrive%\image.vhd" type=expandable maximum=%vhdsize%000 >dps1.txt
echo select vdisk file="%exdrive%\image.vhd" >>dps1.txt
echo attach vdisk >>dps1.txt
echo cre par pri >>dps1.txt
echo format fs=ntfs quick label="Windows" >>dps1.txt
echo assign letter=%tdrive% >>dps1.txt
echo exit >>dps1.txt
rem
echo We'll issue these commands to DISKPART:
echo.
type dps1.txt
diskpart /s dps1.txt
set dprc=%errorlevel%
if %dprc%==0 ((echo Diskpart successful.) & (goto :fillvhd))
echo.
echo Diskpart failure.  Return code=%dprc%.  CVT2VHD unable to finish, exiting.
goto :eof
:fillvhd
echo.
echo =============================
echo Step 3: Apply image to VHD
echo =============================
echo.
rem
rem now to VHD
rem
echo we'll run this command:
echo imagex /apply %exdrive%\image.wim 1 %tdrive%: /verify
imagex /apply %exdrive%\image.wim 1 %tdrive%: /verify

set imagexrc=%errorlevel%

if not %imagexrc%==0 ((echo ImageX failed with error code %imagexrc%, exiting.) & (goto :eof))
echo.
echo ImageX /apply succeeded.
:freevhd
echo.
echo ====================================
echo Step 4: Detach and close VHD file
echo ====================================
rem
rem now detach image.vhd and free up the temp drive letter
rem
echo Finally, unmount the VHD:

echo select vdisk file="%exdrive%\image.vhd" >dps1.txt
echo detach vdisk >>dps1.txt
echo exit >>dps1.txt

echo.
echo We'll execute these DISKPART commands:
echo dps1.txt:
echo.
type dps1.txt
diskpart /s dps1.txt
echo.
echo Done.
set dprc=%errorlevel%
if %dprc%==0 ((echo Diskpart successful.) & (goto :happyend))
echo.
echo Diskpart failure detaching VHD.  Return code=%dprc%.  
echo Check there's enough space on drive %imgdrive% and try again.
echo CVT2VHD unable to finish, exiting.
goto :eof

:happyend
rem
rem and now we're done, it's in image.vhd
rem

Echo Completed creating your image.vhd.  To deploy this to a PC, you should:
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
goto :eof

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
echo your SDRState bootable USB stick or CD.  Then, connect
echo the system to some large external drive, whether it's a 
echo networked drive mapped to a drive letter or perhaps a large
echo external hard disk -- you'll need that because you're going
echo to take that system's C: drive and rebuild it as one large
echo VHD file.  On the USB stick/CD, you'll see a file named
echo cvt2vhd.cmd.  Run that file, putting in the drive letter
echo to image (probably C:), the external drive/mapped drive to
echo save the new VHD to (could be anything, I'll use e: in my
echo example), and then the maximum size that the VHD will need
echo to be, in gigabytes (I'll assume 80 GB in my example).  For
echo example, you might start it like this:
echo.
echo cvt2vhd c: e: 80
echo.
echo That'll take a while, but when it's done, you'll have a file
echo named image.vhd on your target drive -- again, E: in my 
echo example.  Once you've got that image.vhd, it's ready to prep
echo a system to get it ready to be able to use that VHD.  You can
echo do that by booting the system with your USB stick/CD and
echo then running prepnewpc.
echo.
echo Also, remember that the physical volume that you deploy this
echo image.vhd to should have an amount of free space equal to at
echo least 2.5 times the image.vhd maximum size -- 200 GB in this
echo case.  (80 GB x 2.5 = 200 GB.)
echo.
echo Thanks for using Steadier State, I hope it's of value.
echo -- Mark Minasi help@minasi.com www.steadierstate.com

goto :end
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
:end
