@echo off
setlocal ENABLEDELAYEDEXPANSION
REM
REM Check that we're running from the root of the boot device
REM Use the pseudo-variable ~d0 to get the job done
REM exdrive = external drive where the vhd is stored
REM
set drive=%~d0
if not '%drive%'=='X:' goto :pleasebootfromUSBfirst
%drive%
cd \
echo.
echo Here is the list of current volumes on your computer. This will hopefully
echo help you answer the following questions.
echo.
for /f "delims={}" %%a in ('diskpart /s \srs\listvolume.txt') do (echo %%a)
echo.

:exdrivequestion
REM
REM exdrive = external drive letter we'll write the wim and then vhd to (should include colon)
REM
echo.
echo =========================================================
echo Question 1: Where is the image stored?
echo.
echo What is the external drive and folder where the vhd file is stored.
echo If the vhd file is stored at the root of a drive you can simply enter the
echo drive letter with a colon. If it is stored in a directory
echo please enter the path. For example, E:\images. Type 'end' to quit.
set /p exdrive=What is your response?
if '%exdrive%'=='end' ((echo.)&(echo Exiting as requested.)&(goto :end))
if '%exdrive%'=='' ((echo.)&(echo ---- ERROR ----)&(echo.)&(echo There doesn't seem to be anything at %exdrive%.  Let's try again.)&(echo.)&(goto :exdrivequestion))
REM
REM Next, find the USB drive's "real" drive letter
REM (The USB or CD boots from a drive letter like C: or
REM the like, mounting and expanding a single file named
REM boot.wim into an X: drive.  As I want to image WinPE
REM onto the hard disk, I need access to non-expanded
REM version of the \sources\boot.wim image.  This tries to
REM find that by checking drive letters C: through P: for 
REM the sources\boot.wim file.)
REM
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
REM Find an available drive letter for the vhd drive
REM
set vdrive=none
if not exist W:\ if not %tdrive%==w set vdrive=w
if not exist V:\ if not %tdrive%==v set vdrive=v
if not exist U:\ if not %tdrive%==u set vdrive=u
if not exist T:\ if not %tdrive%==t set vdrive=t
if not exist S:\ if not %tdrive%==s set vdrive=s
if not exist R:\ if not %tdrive%==r set vdrive=r
if not exist Q:\ if not %tdrive%==q set vdrive=q
if not %vdrive%==none goto :foundvdrive
echo.
echo Error:  I need a vhd drive letter, but could not find one between 
echo Q: and W:.  I can't do the job without a free drive letter, so I've got 
echo to stop.
echo.
goto :badend

:foundvdrive
REM
REM Then check for an onboard copy of imagex and Dism.
REM
if exist x:\windows\system32\imagex.exe ((set osversion=7)&(goto :drivesok))
if exist x:\windows\system32\Dism.exe ((set osversion=10)&(if not exist %exdrive%\scratch mkdir %exdrive%\scratch)&(goto :drivesok))
echo.
echo Error: imagex.exe and Dism.exe are missing from your USB stick's \windows\system32
echo folder.  Please rebuild your Steadier State install USB stick or CD ISO with
echo buildpe.cmd and use that new device to boot this system and try again.
echo.
goto :badend

:drivesok
REM
REM Create two diskpart scripts.
REM The first will wipe Drive 0 on the system, make a 1GB partition, format it, 
REM and assign the temporary drive letter to it.
REM The second will create a partition from the remaining space and make it C:,
REM rearranging the C: drive letter if it's currently being used.
REM 
echo select disk 0 >%drive%\wiperb.txt
echo clean >>%drive%\wiperb.txt
echo create partition primary size=1000  >> %drive%\wiperb.txt
echo active>>%drive%\wiperb.txt
echo format fs=ntfs quick label="System Reserved">>%drive%\wiperb.txt
echo assign letter=%tdrive%>>%drive%\wiperb.txt
echo rescan >>%drive%\wiperb.txt
echo exit>>%drive%\wiperb.txt
REM
REM wiperc.txt is phase two if there's currently a C:
REM
echo select volume c >%drive%\wiperc.txt
echo assign >>%drive%\wiperc.txt
echo select disk 0 >>%drive%\wiperc.txt
echo create partition primary >>%drive%\wiperc.txt
echo format fs=ntfs quick label="Physical Drive" >>%drive%\wiperc.txt
echo assign letter=c >>%drive%\wiperc.txt
echo exit >>%drive%\wiperc.txt
REM
REM wipernoc.txt is phase two if there's NOT currently a C:
REM
echo select disk 0 >%drive%\wipernoc.txt
echo create partition primary >>%drive%\wipernoc.txt
echo format fs=ntfs quick label="Physical Drive" >>%drive%\wipernoc.txt
echo assign letter=c >>%drive%\wipernoc.txt
echo exit >>%drive%\wipernoc.txt
REM
REM with that done, give tdrive its colon
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
set /p wiperesponse=Please type the word in lowercase and press Enter.
echo.
if not %wiperesponse%==wipe ((echo Exiting.)&(goto :goodend))
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
REM wipe partitions on 0, build a new 1GB one that's active, give it drive letter %tdrive%
REM
diskpart /s %drive%\wiperb.txt
set dispart1rc=%errorlevel%
if %dispart1rc%==0 ((echo Diskpart phase 1 ended successfully, we now have a System Reserved)&(echo partition.  Checking to see that the large partition will have drive letter C:)&(goto :diskpart1ok))
echo.
echo Diskpart phase 1 failed, return code %dispart1rc%.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart scripts (wiperb.txt, wiperc.txt, wipernoc.txt) on drive %drive%.
goto :eof

:diskpart1ok
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
if exist c:\ ((set noc=false)&(echo C: exists, we'll have to rearrange drive letters.))
echo.
echo Running Diskpart phase 2.  We'll create the large partition, letter it C:
echo and give it a label of "Physical Drive."  That'll be the drive you'll copy
echo an image.vhd onto.  Here goes...
echo.
if %noc%==true ((diskpart /s %drive%\wipernoc.txt)&(set diskpart2rc=%errorlevel%))
if %noc%==false ((diskpart /s %drive%\wiperc.txt)&(set diskpart2rc=%errorlevel%))
if %diskpart2rc%==0 goto :diskpart2ok
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

:diskpart2ok
echo.
echo Diskpart phase 2 successfuly completed.
echo Large drive formatted and labeled C:.
echo.
echo ===============================================================
echo STEP TWO: Copy VHD File to the C: Partition
echo.
echo We'll use Robocopy to copy the image.vhd file on located in
echo %exdrive% to the C: partition.
echo ===============================================================
echo.
REM
REM Move the vhd on to the C drive
REM
robocopy %exdrive% c: image.vhd /mt:50
set robocopy1rc=%errorlevel%
if %robocopy1rc%==1 ((echo.)&(echo VHD file successfully transferred to C:\image.vhd)&(goto :vhdcopyok))
echo.
echo ERROR:  Robocopy failed with return code %robocopy1rc%.  Can't continue, exiting.
goto :eof

:vhdcopyok
echo.
echo =============================================================================
echo STEP THREE:  Install WinPE on System Reserved Partition
echo.
echo Next, we'll use ImageX to lay down a WinPE image our new System Reserved
echo partition, which has the (temporary only!) letter of %tdrive%.  The Steadier
echo State files will run atop WinPE (which is the main reason we're installing it)
echo AND -- bonus! -- serves as a "maintenance" copy of Windows that's very useful
echo for resolving various boot and storage problems.
echo =============================================================================
echo.
REM
REM Now image the boot.wim from the PE drive to the new T:
REM
if %osversion%==7 (
imagex /apply %realdrive%\sources\boot.wim 1 %tdrive% /check /verify
) else (
Dism /Apply-Image /ImageFile:%realdrive%\sources\boot.wim /ApplyDir:%tdrive% /ScratchDir:%exdrive%\scratch /Index:1 /CheckIntegrity /Verify
)
set applyrc=%errorlevel%
if %applyrc%==0 goto :applyok
echo.
echo ERROR: Failed to apply the image with return code %applyrc%.  Can't continue, exiting.
goto :eof

:applyok
if %osversion%==7 echo ImageX successfully imaged boot.wim onto %tdrive%.
if %osversion%==10 echo Dism successfully imaged boot.wim onto %tdrive%.
echo.
echo ===============================================================
echo STEP FOUR: Copy Boot Files to System Reserved Partition
echo.
echo With that out of the way, we'll need some extra boot files that
echo do not ship with WinPE, so we'll copy them from your existing
if %osversion%==7 echo WinPE device with Robocopy to the System Reserved partition.
if %osversion%==10 echo WinPE device with BCDBoot to the System Reserved partition.
echo ===============================================================
echo.
REM
REM Grab a basic boot folder and BOOTMGR
REM
if %osversion%==7 (
robocopy %realdrive%\boot %tdrive%\boot * /e /a-:ar
set robocopy2rc=!errorlevel!
if !robocopy2rc!==0 ((copy %realdrive%\bootmgr %tdrive% /y)&(goto :bcdcopyok))
echo.
echo ERROR:  Robocopy failed with return code !robocopy2rc!.  Can't continue, exiting.
goto :eof
) else (
REM
REM Attach the vhd
REM attachvhd.txt is the name of the script attach the vhd
REM
echo select vdisk file=C:\image.vhd >%drive%\attachvhd.txt
echo attach vdisk >>%drive%\attachvhd.txt
echo exit >>%drive%\attachvhd.txt
diskpart /s %drive%\attachvhd.txt
set diskpart3rc=!errorlevel!
if !diskpart3rc!==0 ((echo Diskpart phase 3 ended successfully, vhd was mounted.)&(goto :listvolume))
echo.
echo Diskpart phase 3 failed, return code !diskpart3rc!.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart scripts (attachvhd.txt, mountvhd.txt, listvhd.txt^) on drive %drive%.
goto :eof

:listvolume
REM
REM listvhd.txt is the name of the script to find the volumes
REM
for /f "tokens=2,4" %%a in ('diskpart /s %drive%\srs\listvhd.txt') do (if %%b==Windows_SRS set volnum=%%a)
set volnumrc=!errorlevel!
if !volnumrc!==0 ((echo Diskpart phase 4 ended successfully, vhd is volume !volnum!.)&(goto :foundvolume))
echo.
echo Diskpart phase 4 failed, return code !volnumrc!.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart scripts (attachvhd.txt, mountvhd.txt, listvhd.txt^) on drive %drive%.
goto :eof

:foundvolume
REM
REM mountvhd.txt is the name of the script to assign the drive letter
REM
echo select volume !volnum! >%drive%\mountvhd.txt
echo assign letter=%vdrive% >>%drive%\mountvhd.txt
echo exit >>%drive%\mountvhd.txt
diskpart /s %drive%\mountvhd.txt
set diskpart4rc=!errorlevel!
if !diskpart4rc!==0 ((set vdrive=%vdrive%:)&(echo Diskpart phase 5 ended successfully, vhd is drive !vdrive!.)&(goto :vhdok))
echo.
echo Diskpart phase 4 failed, return code !diskpart4rc!.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart scripts (attachvhd.txt, mountvhd.txt, listvhd.txt^) on drive %drive%.
goto :eof

:vhdok
bcdboot !vdrive!\windows /s %tdrive%
set bcdbootrc=!errorlevel!
if !bcdbootrc!==0 goto :bcdcopyok
echo.
echo ERROR:  BCDBoot failed with return code !bcdbootrc!.  Can't continue, exiting.
goto :eof
)

:bcdcopyok
echo.
echo ==============================================================================
echo STEP FIVE:  BUILD A NEW BOOT CONFIGURATION DATABASE
echo.
echo Now we'll need a new boot configuration database (BCD).  It's an essential
echo file that every copy of Windows since Vista requires, and we need one that
echo knows how to boot WinPE from your hard disk's System Reserved partition.
if %osversion%==7 echo We do that with a dozen "bcdedit" commands.  First, we delete the existing BCD.
if %osversion%==10 echo We do that with a dozen "bcdboot" and "bcdedit" commands.
echo.
echo You should see a series of responses that indicate they were completed
echo successfully. If they do not all complete successfully something went
echo wrong.
echo ========================================================
echo.
%tdrive%
set guid=
if %osversion%==7 (
REM
REM the current BCD is of no value, so next we'll delete it and build a new
REM one from scratch
REM
del %tdrive%\boot\bcd 
REM
REM The annoying part about this is that we can't just build a new BCD
REM We've got to build an offline BCD, then import it to the real BCD
REM
md \temp
cd \temp
echo on
bcdedit /createstore bcd
set "bcdstore=/store bcd"
bcdedit !bcdstore! -create {bootmgr} /d "Boot Manager"
bcdedit !bcdstore! -set {bootmgr} device boot
) else (
set "bcdstore=%tdrive%\EFI\Microsoft\Boot\BCD"
)
for /f "tokens=2 delims={}" %%i in ('bcdedit %bcdstore% /create /d "Roll Back Windows" -application osloader') do (set guid={%%i%})
@echo off
REM
REM Windows 7 can import the bcd and knock off the "/store bcd" stuff
REM Windows 10 will still need the /store parameter
REM
if %osversion%==7 (
set bcdstore=
bcdedit /import bcd 
cd \ 
rd \temp /s /q
)
echo on
bcdedit %bcdstore% /set %GUID% osdevice partition=%tdrive%
bcdedit %bcdstore% /set %GUID% device partition=%tdrive% 
if %osversion%==7 bcdedit /set %GUID% path \windows\system32\boot\winload.exe
if %osversion%==10 bcdedit %bcdstore% /set %GUID% path \windows\system32\boot\winload.efi
bcdedit %bcdstore% /set %GUID% systemroot \windows
bcdedit %bcdstore% /set %GUID% winpe yes
bcdedit %bcdstore% /set %GUID% detecthal yes 
bcdedit %bcdstore% /displayorder %GUID% /addlast 
bcdedit %bcdstore% /timeout 5 
@echo off
if %osversion%==7 if exist %tdrive%\boot\bcd goto :bcdok
if %osversion%==10 %tdrive%\EFI\Microsoft\Boot\BCD goto :bcdok
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
echo STEP SIX: INSTALL STEADY STATE FILES AND IMAGEX IN WINPE
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
robocopy %drive%\srs %tdrive%\srs
REM
REM and the updated startnet.cmd
REM
copy %drive%\startnethd.cmd %tdrive%\windows\system32\startnet.cmd /y
if %osversion%==7 copy %drive%\windows\system32\imagex.exe %tdrive%\windows\system32 /y
if %osversion%==10 copy %drive%\windows\system32\Dism.exe %tdrive%\windows\system32 /y
REM
REM Change the background wallpaper to winpe1.bmp, showing it's a HD boot
REM
copy %tdrive%\srs\winpe1.bmp %tdrive%\windows\system32\winpe.bmp /y
REM
REM done with it, delete
REM
del %tdrive%\srs\winpe1.bmp
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
echo This copy of SteadierState has been modified and the source
echo can be found at https://github.com/7heMC/SteadierState
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

:background
echo How and Why To Use PREPNEWPC in Steadier State
echo --------------------------------------------
echo.
echo Steadier State lets you create a "snapshot" of a Windows
echo installation so that you can choose at any time to reboot
echo your Windows system, choose "Roll Back Windows," and at
echo that point every change you've made to the system is un-done.
echo To do that, however, Steadier State requires you to prepare
echo your Windows system, and PREPNEWPC does that for you.
echo.
echo To get a system ready for conversion, first boot it from
echo your SDRState bootable USB stick or CD.  Then, connect
echo the system to some large external drive, whether it's a 
echo networked drive mapped to a drive letter or perhaps a large
echo external hard disk -- you'll need that because you're going
echo to take the VHD file that you created with CVT2VHD.
echo On the USB stick/CD, you'll see a file named
echo prepnewpc.cmd
echo.
echo That'll take a while, but when it's done, the vhd file
echo will be moved from the external drive to your C: drive.
echo Once you've got that image.vhd on the C: drive you can boot
echo a system to get it ready to be able to use that VHD.  You can
echo to it by simply restarting your computer.

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
