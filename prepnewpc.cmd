@echo off
REM 
REM
REM Check that we're running from the root of the boot device
REM Use the pseudo-variable ~d0 to get the job done
set drive=%~d0
if not x%drive%x==xX:x goto :pleasebootfromUSBfirst
%drive%
cd \
REM
REM Next, find the USB drive's "real" drive letter
REM (The USB or CD boots from a drive letter like C: or
REM the like, mounting and expanding a single file named
REM boot.wim into an X: drive.  As I want to image WinPE
REM onto the hard disk, I need access to non-expanded
REM version of the \sources\boot.wim image.  This tries to
REM find that by checking drive letters C: through P: for 
REM the sources\boot.wim file.)
set realdrive=none
if exist c:\sources\boot.wim set realdrive=c:
if exist d:\sources\boot.wim set realdrive=d:
if exist e:\sources\boot.wim set realdrive=e:
if exist f:\sources\boot.wim set realdrive=f:
if exist g:\sources\boot.wim set realdrive=g:
if exist h:\sources\boot.wim set realdrive=h:
if exist i:\sources\boot.wim set realdrive=i:
if exist j:\sources\boot.wim set realdrive=j:
if exist k:\sources\boot.wim set realdrive=k:
if exist l:\sources\boot.wim set realdrive=l:
if exist m:\sources\boot.wim set realdrive=m:
if exist n:\sources\boot.wim set realdrive=n:
if exist o:\sources\boot.wim set realdrive=o:
if exist p:\sources\boot.wim set realdrive=p:
if not %realdrive%==none goto :foundrealdrive
echo.
echo Can't find the USB stick's "real" drive letter.  I can't fix this so I've got
echo to exit.  Please ensure that you're running this command file from  WinPE-equipped
echo USB stick or CD that you have booted your PC from.
echo.
goto :badend
:foundrealdrive
echo.
echo Found the USB stick/CD's native drive=%realdrive%
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
echo Error:  I need a temporary drive letter, but could not find one between 
echo Q: and W:.  I can't do the job without a free drive letter, so I've got 
echo to stop.
echo.
goto :badend
:foundtdrive
echo Found an available drive letter=%tdrive%:
echo (Those are both good news.)
echo.
REM
REM Then check for an onboard copy of imagex.
REM
if exist x:\windows\system32\imagex.exe goto  :foundimagex

echo.
echo Error: the file imagex.exe is missing from your USB stick's \windows\system32
echo folder.  Please rebuild your Steadier State install USB stick or CD ISO with
echo buildpe.cmd and use that new device to boot this system and try again.
echo.
goto :badend

:foundimagex
REM
REM Create two diskpart scripts.
REM The first will wipe Drive 0 on the system, REM make a 1GB partition, format it, 
REM and assign the temporary drive letter to it.
REM The second will create a partition from the remaining space and make it C:,
REM rearranging the C: drive letter if it's currently being used.
REM 
echo select disk 0 >%drive%\wiperb.txt
echo clean >>%drive%\wiperb.txt
echo cre par pri size=1000  >> %drive%\wiperb.txt
echo active>>%drive%\wiperb.txt
echo format fs=ntfs quick label="System Reserved">>%drive%\wiperb.txt
echo assign letter=%tdrive%>>%drive%\wiperb.txt
echo rescan >>%drive%\wiperb.txt
echo exit>>%drive%\wiperb.txt

REM
REM wiperc.txt is phase two if there's currently a C:
REM
echo sel vol c >%drive%\wiperc.txt
echo assign >>%drive%\wiperc.txt
echo select disk 0 >>%drive%\wiperc.txt
echo cre par pri >> %drive%\wiperc.txt
echo format fs=ntfs quick label="Physical Drive">>%drive%\wiperc.txt
echo assign letter=c>>%drive%\wiperc.txt
echo exit>>%drive%\wiperc.txt

REM wipernoc.txt is phase two if there's NOT currently a C:
REM 

echo select disk 0 >%drive%\wipernoc.txt
echo cre par pri >> %drive%\wipernoc.txt
echo format fs=ntfs quick label="Physical Drive">>%drive%\wipernoc.txt
echo assign letter=c>>%drive%\wipernoc.txt
echo exit>>%drive%\wipernoc.txt





rem
rem with that done, give tdrive its colon
set tdrive=%tdrive%:
REM
REM Warnings
REM
echo        W A R N I N G !!!!!!       W A R N I N G !!!!!!
echo.
echo This command file prepares this PC to receive a Steadier State-ready image.vhd
echo file, and provides the support files to make Steadier State work. BUT...
echo as part of its job, this file WIPES THIS COMPUTER'S DRIVE 0 CLEAN.
echo.
echo I hope I now have your complete attention?
echo.
echo More specifically, this wipes drive 0, the first drive that you'd see if you
echo ran DISKPART and typed LIST DISK.  If you don't know what that means and/or
echo if you are even slightly unsure about whether there's data on your system that
echo you would regret losing, then please press ctrl-C and stop this command file.
echo Otherwise, just press any key.
pause
cls
echo After wiping disk 0, it will install a 1 GB Windows 7-type boot partition and
echo a copy of WinPE.  (This would be useful even if you DIDN'T want to run Steadier
echo State, as you could then just run the normal Win 7 or R2 install after this
echo runs and you'd end up with a copy of Windows, but with an extra "maintenance"
echo copy of WinPE that you can access to fix various "cannot boot" problems.)
echo Finally, this takes the remaining disk space and creates one big C: drive.
echo.
echo For this command file to work, you must run this from a WinPE-equipped USB
echo stick or CD created with the BUILDPE.CMD command file that accompanied
echo this file. 
echo.
echo If you're sure that you want to wipe drive 0 clean and install a WinPE-
echo equipped Win 7-type boot manager and partition then please type the eighth
echo word in this paragraph and then press Enter to start the wipe-and-rebuild 
echo process. (The 4-letter word starts with a "w.") Or type anything else 
echo and press Enter to stop the process.
echo.
set response=
set /p response=Please type the word in lowercase and press Enter.
echo.
if not s%response%==swipe ((echo Exiting.) & (goto :goodend))
cls
echo ===============================================================================
echo STEP ONE:  FORMAT AND PARTITION DRIVE ZERO
echo.
echo First, we'll use diskpart to wipe your system's drive 0.  Then it  creates a 
echo 1 GB partition, makes it bootable, labels it "System Reserved" and gives it a 
echo temporary drive letter of %tdrive%.  This will require two separate Diskpart
echo invocations.
echo ===============================================================================
echo.
REM
REM ASSUMPTIONS:
REM	you want to wipe and rebuild drive 0 in "list drive" in diskpart
REM	You are running this batch file from the root of your USB stick/CD
REM	I can set the new drive to tdrive:, that tdrive: is unused
REM

REM
REM wipe partitions on 0, build a new 1GB one that's active, give it drive letter %tdrive%
REM
diskpart /s %drive%\wiperb.txt
set dr1=%errorlevel%
if %dr1%==0 ((echo Diskpart phase 1 ended successfully, we now have a System Reserved)&(echo partition.  Checking to see that the large partition will have drive letter C:)  &(goto :dphase2))
echo.
echo Diskpart phase 1 failed, return code %dr1%.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart scripts (wiperb.txt, wiperc.txt, wipernoc.txt) on drive %drive%.

goto :eof

:dphase2

REM
REM tried bootsect %tdrive% /nt60 [/mbr] and no help there with multidrive scenarios 
REM
REM the point of this is to check that C: is, at the moment, not available.
REM If it IS available, then the new partition build of the remaining space
REM in disk 0 won't be C: for the rest of this run, and bcd's screwed up
REM among other things.  If diskpart were more automatable, I could fix that
REM by temporarily re-lettering anything that's currently C:, but it isn't.
REM

set noc=true
if exist c:\ ((set noc=false) & (echo C: exists, we'll have to rearrange drive letters.))

echo.
echo Running Diskpart phase 2.  We'll create the large partition, letter it C:
echo and give it a label of "Physical Drive."  That'll be the drive you'll copy
echo an image.vhd onto.  Here goes...
echo.
if %noc%==true ((diskpart /s %drive%\wipernoc.txt) & (set dr2=%errorlevel%))
if %noc%==false ((diskpart /s %drive%\wiperc.txt) & (set dr2=%errorlevel%))
if %dr2%==0 goto :dp2ok
echo.
echo Diskpart phase 2 failed.  Take a look at the Diskpart output to get
echo any clues about why it failed and try again.  The most common problem arises
echo from running PrepNewPC on a system with a bunch of extra drives attached
echo to the system, particularly extra drives with active partitions on them.
echo While it's not necessary, Steadier State's really aimed at systems that will
echo go into production with just one physical hard disk.
echo.
echo You may also get a clue from the diskpart scripts (wiperb.txt, wiperc.txt, 
echo wipernoc.txt) on drive %drive%.
echo
goto :eof
:dp2ok
echo.
echo Diskpart phase 2 successfuly completed.
echo Large drive formatted and labeled C:.
echo.


REM
echo.
echo =============================================================================
echo STEP TWO:  Install WinPE on System Reserved Partition
echo.
echo Next, we'll use ImageX to lay down a WinPE image our new System Reserved
echo partition, which has the (temporary only!) letter of %tdrive%.  The Steadier
echo State files will run atop WinPE (which is the main reason we're installing it)
echo AND -- bonus! -- serves as a "maintenance" copy of Windows that's very useful
echo for resolving various boot and storage problems.
echo =============================================================================
echo.
REM Now image the boot.wim from the PE drive to the new T:
REM
imagex /apply %realdrive%\sources\boot.wim 1 %tdrive% /check /verify
set irc=%errorlevel%
if %irc%==0 goto :imagex1ok
echo.
echo ERROR:  ImageX failed with return code %irc%.  Can't continue, exiting.
goto :eof
:imagex1ok
echo ImageX successfully imaged boot.wim onto %tdrive%.
echo.
echo ===============================================================
echo STEP THREE: Copy Boot Files to System Reserved Partition
echo.
echo With that out of the way, we'll need some extra boot files that
echo do not ship with WinPE, so we'll copy them from your existing
echo WinPE device with Robocopy to the System Reserved partition.
echo ===============================================================
echo.
REM
REM Grab a basic boot folder and BOOTMGR
REM

robocopy %realdrive%\boot %tdrive%\boot * /e /a-:ar
set rcp1=%errorlevel%
if %rcp1%==1 goto :rp1ok
echo.
echo ERROR:  Robocopy failed with return code %rcp1%.  Can't continue, exiting.
goto :eof
:rp1ok

copy %realdrive%\bootmgr %tdrive% /y

REM
REM the current BCD is of no value, so next we'll delete it and build a new
REM one from scratch
REM
echo.
echo ==============================================================================
echo STEP FOUR:  BUILD A NEW BOOT CONFIGURATION DATABASE
echo.
echo Now we'll need a new boot configuration database (BCD).  It's an essential
echo file that every copy of Windows since Vista requires, and we need one that
echo knows how to boot WinPE from your hard disk's System Reserved partition.
echo We do that with a dozen "bcdedit" commands.  First, though, we delete the
echo existing BCD.
echo.
echo You should see eleven responses that look like echo "The operation completed
echo successfully" with one response of "The entry {bootmgr} was 
echo successfully created."
echo ========================================================
echo.
del %tdrive%\boot\bcd 
%tdrive%

REM
REM The annoying part about this is that we can't just build a new BCD
REM We've got to build an offline BCD, then import it to the real BCD
REM
set guid=
md \temp
cd \temp
echo on
bcdedit /createstore bcd  
bcdedit /store bcd -create {bootmgr} /d "Boot Manager" 
bcdedit /store bcd -set {bootmgr} device boot 
for /f "tokens=2 delims={}" %%i in ('bcdedit /store bcd /create /d "Roll Back Windows" -application osloader') do (set guid={%%i%})
@echo off
REM
REM NOW we can import the bcd and knock off the "/store bcd" stuff 
REM
echo on
bcdedit /import bcd 
cd \ 
rd \temp /s /q
bcdedit /set %GUID% osdevice partition=%tdrive%
bcdedit /set %GUID% device partition=%tdrive% 
bcdedit /set %GUID% path \windows\system32\boot\winload.exe 
bcdedit /set %GUID% systemroot \windows 
bcdedit /set %GUID% winpe yes
bcdedit /set %GUID% detecthal yes 
bcdedit /displayorder %GUID% /addlast 
bcdedit /timeout 15 
@echo off
if exist %tdrive%\boot\bcd goto :bcdok
echo.
echo ++++++ BCD CREATION FAILURE +++++++++
echo.
echo I just tried to create the Windows Boot Configuration Database file,
echo %tdrive%\boot\bcd, but it's not there. That usually means that bcdedit, the
echo Windows tool for manipulating BCD files, got confused and it wrote to a drive
echo other than %tdrive%\boot, or tried writing it to a nonexistent drive.
echo. 
echo But don't worry, the fix is pretty simple.  It's usually caused when you have
echo an external drive -- USB, eSATA or the like -- and bcdedit gets it into its
echo head that noooo, you didn't want BCD on %tdrive%, you wanted it on some other
echo drive.  Having an already-attached, already-partitioned drive often confuses
echo BCDEDIT.
echo.
echo The best answer now is to just disconnect any other drives (and the CD or
echo USB stick that you booted from do NOT count), then reboot from that CD or USB
echo stick.  (It's important that you reboot, as WinPE's "stuck" on the wrong 
echo drive right now, and even a DISKPART "rescan" command won't fix that.)
echo Apologies, but we're up against basic Windows limitations in this case.
echo.
echo Ending PREPNEWPC.
echo.
goto :eof
:bcdok
echo.
echo ===============================================================================
echo STEP FIVE: INSTALL STEADY STATE FILES AND IMAGEX IN WINPE
echo.
echo Finally, we'll a create a folder \SDRState inside the copy of WinPE that we've
echo just installed in your System Reserved partition and then copy the Steadier 
echo State support.  While we're at it, we'll add ImageX to the System32 folder of
echo that copy of WinPE so that CVT2VHD can employ it.  (And because it's useful
echo to have a copy of ImageX close to hand for re-imaging sometimes.)
echo ===============================================================================
echo.
REM
REM copy over the Steadier State files from the USB stick
REM
robocopy %drive%\sdrstate %tdrive%\sdrstate
REM
REM and the updated startnet.cmd
REM
copy %drive%\startnethd.cmd %tdrive%\windows\system32\startnet.cmd /y

copy %drive%\windows\system32\imagex.exe %tdrive%\windows\system32 /y

REM Change the background wallpaper to winpe1.bmp, showing it's a HD boot

copy %tdrive%\sdrstate\winpe1.bmp %tdrive%\windows\system32\winpe.bmp /y
REM done with it, delete
del %tdrive%\sdrstate\winpe1.bmp
REM
echo.
echo.
echo ==============================================================================
echo PREPNEWPC COMPLETED SUCCESSFULLY; NEXT STEPS TO DEPLOY AN IMAGE.VHD:
ECHO ==============================================================================
echo.
echo   1) Assuming you've created the image.vhd file containing your desired
echo      Windows image, please copy that file to C:\.  (If you don't have
echo	  an image.vhd, look at the cvt2vhd tool in Steadier State.)
echo.
echo   2) Reboot -- just remove the USB stick, disconnect any external drives,
echo      close all windows, and the system will reboot.
echo.
echo   Once rebooted, Steadier State will automatically create your first
echo   snapshot file AND reboot so that you can start using Windows 7 with
echo   Steadier State.  (So when you reboot this, don't worry when it does
echo   a little work and then reboots.)  
echo.
echo   If you plan to modify the image further before final deployment, then take
echo   a look in the documentation about using the "merge" command.
echo.
echo I hope you find this useful! 
echo -- Mark Minasi help@minasi.com www.steadierstate.com
echo.
goto :goodend

:pleasebootfromUSBfirst
echo.
echo This command file only runs from a WinPE-equipped USB
echo stick, and only when you've booted from that USB stick.
echo.
echo Please set up your bootable WinPE USB stick as explained
echo in the documentation, and run prepnewpc.cmd from that USB
echo stick.
echo.
echo Thanks, and I hope you find Steadier State useful.
goto :badend

:wrongdrive
echo.
echo If you saw this message, it probably means that you've got a copy
echo of this build-a-new-boot-partition command file, but not its
echo other necessary files.  
echo Be sure to run this from a USB stick created with the "buildpe.cmd"
echo file.
echo.
echo.
goto :badend 


:badend
goto :eof
:goodend
goto :eof
