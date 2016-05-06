@echo off
setlocal ENABLEDELAYEDEXPANSION
REM
REM Check that we're running from the root of the boot device
REM Use the pseudo-variable ~d0 to get the job done
REM actdrive = this currently active drive
REM
set actdrive=%~d0
if not '%actdrive%'=='X:' goto :pleasebootfromUSBfirst
%actdrive%
cd \
echo.
echo Here is the list of current volumes on your computer. This will hopefully
echo help you answer the following questions.
echo.
for /f "delims={}" %%a in ('diskpart /s %actdrive%\srs\listvolume.txt') do (echo %%a)
echo.

:extdrivequestion
REM
REM extdrive = external drive letter where we'll write the wim and then vhd (should include colon)
REM
echo.
echo =========================================================
echo Question 1: Where is the image stored?
echo.
echo What is the external drive and folder where the vhd file is stored.
echo If the vhd file is stored at the root of a drive you can simply enter the
echo drive letter with a colon. If it is stored in a directory
echo please enter the path. For example, E:\images. Type 'end' to quit.
set /p extdrive=What is your response?
if '%extdrive%'=='end' ((echo.)&(echo Exiting as requested.)&(goto :end))
if '%extdrive%'=='' ((echo.)&(echo ---- ERROR ----)&(echo.)&(echo There doesn't seem to be anything at %extdrive%.  Let's try again.)&(echo.)&(goto :extdrivequestion))
REM
REM Then check for an onboard copy of imagex and Dism.
REM
if exist x:\windows\system32\imagex.exe ((set osversion=7)&(goto :warnings))
if exist x:\windows\system32\Dism.exe ((set osversion=10)&(if not exist %extdrive%\scratch mkdir %extdrive%\scratch)&(goto :warnings))
echo.
echo Error: imagex.exe and Dism.exe are missing from your USB stick's \windows\system32
echo folder.  Please rebuild your Steadier State install USB stick or CD ISO with
echo buildpe.cmd and use that new device to boot this system and try again.
echo.
goto :badend

:warnings
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

:findusbdrive
REM
REM Next, find the USB drive's "real" drive letter
REM (The USB or CD boots from a drive letter like C: or
REM the like, mounting and expanding a single file named
REM boot.wim into an X: drive.  As I want to image WinPE
REM onto the hard disk, I need access to non-expanded
REM version of the \sources\boot.wim image.  This tries to
REM find that by checking drive letters C: through P: for 
REM the sources\boot.wim file.)
REM usbdrive = The USB drive's "real" drive letter
REM listvolume.txt = The script to find the volumes
REM
for /f "tokens=3,4" %%a in ('diskpart /s %actdrive%\srs\listvolume.txt') do (if %%b==WINPE set usbdrive=%%a:)
set usbdriverc=!errorlevel!
if '!usbdrive!'=='' ((echo.)&(echo Unable to find any mounted volume name "WINPE")&(echo Are you booting from the USB?)&(goto :background))
if !usbdriverc!==0 ((echo The Real USB drive is letter !usbdrive!.)&(echo Now checking to make sure boot.wim exists.)&(goto :findbootwim))
echo.
echo Can't find the USB stick's "real" drive letter.  I can't fix this so I've got
echo to exit.  Please ensure that you're running this command file from  WinPE-equipped
echo USB stick or CD that you have booted your PC from.
echo.
echo Diskpart failed when looking for the USB drive letter, return code !usbdriverc!.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart script %actdrive%\srs\listvolume.txt.
goto :eof

:findbootwim
if exist %usbdrive%\sources\boot.wim ((echo.)&(echo Found the USB stick/CD's native drive=%usbdrive%)&(goto :findsrsdrive))
echo.
echo Found what should have been the USB drive, but was unable to locate the
echo boot.wim file. Make sure that the Steadier State USB is the only drive
echo with a label of WINPE.
echo.
goto :badend

:findsrsdrive
REM
REM Find an available drive letter for the Steadier State Tools Partition
REM srsdrive = Partition for the Steadier State Tools (SrS tools)
REM
for %%a in (d e f g h i j k l m n o p q r s t u v w y z) do (if not exist %%a:\ ((set srsdrive=%%a)&(goto :createsrsdrive)))
echo.
echo Error:  I need a drive letter for the Steadier State Tools (SrS tools)
echo but could not find one in the following range C-W,Y,Z.  I can't do the
echo job without a free drive letter, so I've got to stop.
echo.
goto :badend

:createsrsdrive
if %osversion%==7 goto :drivesok
REM
REM == 1. Create SrS tools partition ===============
REM
echo select disk 0 >%actdrive%\diskpartsrs.txt
echo clean >>%actdrive%\diskpartsrs.txt
echo convert gpt >>%actdrive%\diskpartsrs.txt
echo create partition primary size=1000 >>%actdrive%\diskpartsrs.txt
echo format quick fs=ntfs label="SrS tools" >>%actdrive%\diskpartsrs.txt
echo assign letter=%srsdrive% >>%actdrive%\diskpartsrs.txt
echo set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac" >>%actdrive%\diskpartsrs.txt
echo gpt attributes=0x8000000000000001 >>%actdrive%\diskpartsrs.txt
echo rescan >>%actdrive%\diskpartsrs.txt
echo exit >>%actdrive%\diskpartsrs.txt
diskpart /s %actdrive%\diskpartsrs.txt
set dispartsrsrc=%errorlevel%
if %dispartsrsrc%==0 ((set srsdrive=%srsdrive%:)&(echo Diskpart successfully created SrS Tools Partition.)&(echo We will use !srsdrive!)&(goto :findefidrive))
echo.
echo Diskpart failed to create the SrS Tools Partition, return code %dispartsrsrc%.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart script: %actdrive%\diskpartsrs.txt.
goto :eof

:findefidrive
echo.
REM
REM Find an available drive letter for the System Partition
REM efidrive = System Partition for uefi boot
REM
for %%a in (d e f g h i j k l m n o p q r s t u v w y z) do (if not exist %%a:\ ((set efidrive=%%a)&(goto :createefidrive)))
echo.
echo Error:  I need a drive letter for the UEFI System Partition,
echo but could not find one in the following range C-W,Y,Z.
echo I can't do the job without a free drive letter, so I've got to stop.
echo.
goto :badend

:createefidrive
REM
REM == 2. System partition =========================
REM
echo select disk 0 >%actdrive%\diskpartefi.txt
echo create partition efi size=100 >>%actdrive%\diskpartefi.txt
echo format quick fs=fat32 label="System_UEFI" >>%actdrive%\diskpartefi.txt
echo assign letter=%efidrive% >>%actdrive%\diskpartefi.txt
echo rescan >>%actdrive%\diskpartefi.txt
echo exit >>%actdrive%\diskpartefi.txt
diskpart /s %actdrive%\diskpartefi.txt
set dispartefirc=%errorlevel%
if %dispartefirc%==0 ((set efidrive=%efidrive%:)&(echo Diskpart successfully created UEFI System Partition.)&(echo We will use !efidrive!)&(goto :createmsrdrive))
echo.
echo Diskpart failed to create the UEFI System Partition, return code %dispartefirc%.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart script: %actdrive%\diskpartefi.txt.
goto :eof

:createmsrdrive
REM
REM == 3. Microsoft Reserved (MSR) partition =======
REM
echo select disk 0 >%actdrive%\diskpartmsr.txt
echo create partition msr size=128 >>%actdrive%\diskpartmsr.txt
echo exit >>%actdrive%\diskpartmsr.txt
diskpart /s %actdrive%\diskpartmsr.txt
set dispartmsrrc=%errorlevel%
if %dispartmsrrc%==0 ((echo Diskpart successfully created MSR Partition.)&(goto :findphydrive))
echo.
echo Diskpart failed to create the MSR Partition, return code %dispartmsrrc%.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart script: %actdrive%\diskpartmsr.txt.

:findphydrive
echo.
REM
REM Find an available drive letter for the remaining space on the Hard Drive
REM phydrive = Physical Drive Partition
REM
for %%a in (d e f g h i j k l m n o p q r s t u v w y z) do (if not exist %%a:\ ((set phydrive=%%a)&(goto :createphydrive)))
echo.
echo Error:  I need a drive letter for the Physical Drive Partition,
echo but could not find one in the following range C-W,Y,Z.
echo I can't do the job without a free drive letter, so I've got to stop.
echo.
goto :badend

:createphydrive
REM
REM == 4. Physical Drive partition ========================
REM
echo select disk 0 >%actdrive%\diskpartphy.txt
echo create partition primary  >>%actdrive%\diskpartphy.txt
echo format quick fs=ntfs label="Physical Drive" >>%actdrive%\diskpartphy.txt
echo assign letter=%phydrive% >>%actdrive%\diskpartphy.txt
echo rescan >>%actdrive%\diskpartphy.txt
echo exit >>%actdrive%\diskpartphy.txt
diskpart /s %actdrive%\diskpartphy.txt
set dispartphyrc=%errorlevel%
if %dispartphyrc%==0 ((set phydrive=%phydrive%:)&(echo Diskpart successfully created Physical Disk Partition at !phydrive!)&(echo using the remaining space on the hard drive.)&(goto :findvhddrive))
echo.
echo Diskpart failed to create the Physical Disk Partition, return code %dispartphyrc%.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart script: %actdrive%\diskpartphy.txt.

:findvhddrive
echo.
REM
REM Find an available drive letter that can be used to mount the image.vhd
REM vhddrive = The drive letter used to mount image.vhd
REM
for %%a in (d e f g h i j k l m n o p q r s t u v w y z) do (if not exist %%a:\ ((set vhddrive=%%a)&(echo Found !vhddrive!: as an available drive letter for the vhd.)&(goto :copyvhd)))
echo.
echo Error:  I need a drive letter to mount image.vhd,
echo but could not find one in the following range C-W,Y,Z.
echo I can't do the job without a free drive letter, so I've got to stop.
echo.
goto :badend

:drivesok
set phydrive=c
echo select disk 0 >%actdrive%\wiperb.txt
echo clean >>%actdrive%\wiperb.txt
echo create partition primary size=1000  >>%actdrive%\wiperb.txt
echo active>>%actdrive%\wiperb.txt
echo format fs=ntfs quick label="System Reserved">>%actdrive%\wiperb.txt
echo assign letter=%srsdrive%>>%actdrive%\wiperb.txt
echo rescan >>%actdrive%\wiperb.txt
echo exit>>%actdrive%\wiperb.txt
REM
REM wiperc.txt is phase two if there's currently a C:
REM
echo select volume %phydrive% >%actdrive%\wiperc.txt
echo assign >>%actdrive%\wiperc.txt
echo select disk 0 >>%actdrive%\wiperc.txt
echo create partition primary >>%actdrive%\wiperc.txt
echo format fs=ntfs quick label="Physical Drive" >>%actdrive%\wiperc.txt
echo assign letter=%phydrive% >>%actdrive%\wiperc.txt
echo exit >>%actdrive%\wiperc.txt
REM
REM wipernoc.txt is phase two if there's NOT currently a C:
REM
echo select disk 0 >%actdrive%\wipernoc.txt
echo create partition primary >>%actdrive%\wipernoc.txt
echo format fs=ntfs quick label="Physical Drive" >>%actdrive%\wipernoc.txt
echo assign letter=%phydrive% >>%actdrive%\wipernoc.txt
echo exit >>%actdrive%\wipernoc.txt
REM
REM with that done, give srsdrive its colon
REM
set srsdrive=%srsdrive%:
set phydrive=%phydrive%:
cls
echo ===============================================================================
echo STEP ONE:  FORMAT AND PARTITION DRIVE ZERO
echo.
echo First, we'll use diskpart to wipe your system's drive 0.  Then it  creates a 
echo 1 GB partition, makes it bootable, labels it "System Reserved" and gives it a 
echo temporary drive letter of %srsdrive%.  This will require two separate Diskpart
echo invocations.
echo ===============================================================================
echo.
REM
REM ASSUMPTIONS:
REM	you want to wipe and rebuild drive 0 in "list drive" in diskpart
REM	You are running this batch file from the root of your USB stick/CD
REM	I can set the new drive to tdrive:, that tdrive: is unused
REM
REM wipe partitions on 0, build a new 1GB one that's active, give it drive letter %srsdrive%
REM
diskpart /s %actdrive%\wiperb.txt
set dispart1rc=%errorlevel%
if %dispart1rc%==0 ((echo Diskpart phase 1 ended successfully, we now have a System Reserved)&(echo partition.  Checking to see that the large partition will have drive letter %phydrive%)&(goto :diskpart1ok))
echo.
echo Diskpart phase 1 failed, return code %dispart1rc%.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart scripts (wiperb.txt, wiperc.txt, wipernoc.txt) on drive %actdrive%.
goto :eof

:diskpart1ok
REM
REM tried bootsect %srsdrive% /nt60 [/mbr] and no help there with multidrive scenarios 
REM
REM the point of this is to check that C: is, at the moment, not available.
REM If it IS available, then the new partition build of the remaining space
REM in disk 0 won't be C: for the rest of this run, and bcd's screwed up
REM among other things.  If diskpart were more automatable, I could fix that
REM by temporarily re-lettering anything that's currently %phydrive%, but it isn't.
REM
set noc=true
if exist %phydrive%\ ((set noc=false)&(echo %phydrive% exists, we'll have to rearrange drive letters.))
echo.
echo Running Diskpart phase 2.  We'll create the large partition, letter it %phydrive%
echo and give it a label of "Physical Drive."  That'll be the drive you'll copy
echo an image.vhd onto.  Here goes...
echo.
if %noc%==true ((diskpart /s %actdrive%\wipernoc.txt)&(set diskpart2rc=%errorlevel%))
if %noc%==false ((diskpart /s %actdrive%\wiperc.txt)&(set diskpart2rc=%errorlevel%))
if %diskpart2rc%==0 goto :copyvhd
echo.
echo Diskpart phase 2 failed.  Take a look at the Diskpart output to get
echo any clues about why it failed and try again.  The most common problem arises
echo from running PrepNewPC on a system with a bunch of extra drives attached
echo to the system, particularly extra drives with active partitions on them.
echo While it's not necessary, Steadier State's really aimed at systems that will
echo go into production with just one physical hard disk.
echo.
echo You may also get a clue from the diskpart scripts (wiperb.txt, wiperc.txt, 
echo wipernoc.txt) on drive %actdrive%.
echo
goto :eof

:copyvhd
echo.
echo Diskpart phases completed successfuly
echo.
echo ===============================================================
echo STEP TWO: Copy VHD File to the C: Partition
echo.
echo We'll use Robocopy to copy the image.vhd file on located in
echo %extdrive% to the %phydrive% partition.
echo ===============================================================
echo.
REM
REM Move the vhd on to the %phydrive% drive
REM
robocopy %extdrive% %phydrive% image.vhd /mt:50
set robocopy1rc=%errorlevel%
if %robocopy1rc%==1 ((echo.)&(echo VHD file successfully transferred to %phydrive%\image.vhd)&(goto :vhdcopyok))
echo.
echo ERROR:  Robocopy failed with return code %robocopy1rc%.  Can't continue, exiting.
goto :eof

:vhdcopyok
echo.
echo =============================================================================
echo STEP THREE:  Install WinPE on System Reserved Partition
echo.
echo Next, we'll use ImageX to lay down a WinPE image our new System Reserved
echo partition, which has the (temporary only!) letter of %srsdrive%.  The Steadier
echo State files will run atop WinPE (which is the main reason we're installing it)
echo AND -- bonus! -- serves as a "maintenance" copy of Windows that's very useful
echo for resolving various boot and storage problems.
echo =============================================================================
echo.
REM
REM Now image the boot.wim from the PE drive to the new T:
REM
if %osversion%==7 (
imagex /apply %usbdrive%\sources\boot.wim 1 %srsdrive% /check /verify
) else (
Dism /Apply-Image /ImageFile:%usbdrive%\sources\boot.wim /ApplyDir:%srsdrive% /ScratchDir:%extdrive%\scratch /Index:1 /CheckIntegrity /Verify
)
set applyrc=%errorlevel%
if %applyrc%==0 goto :applyok
echo.
echo ERROR: Failed to apply the image with return code %applyrc%.  Can't continue, exiting.
goto :eof

:applyok
if %osversion%==7 echo ImageX successfully imaged boot.wim onto %srsdrive%.
if %osversion%==10 echo Dism successfully imaged boot.wim onto %srsdrive%.
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
robocopy %usbdrive%\boot %srsdrive%\boot * /e /a-:ar
set robocopy2rc=!errorlevel!
if !robocopy2rc!==0 ((copy %usbdrive%\bootmgr %srsdrive% /y)&(goto :bcdcopyok))
echo.
echo ERROR:  Robocopy failed with return code !robocopy2rc!.  Can't continue, exiting.
goto :eof
) else (
REM
REM Attach the vhd
REM attachvhd.txt is the name of the script attach the vhd
REM
echo select vdisk file=%phydrive%\image.vhd >%actdrive%\attachvhd.txt
echo attach vdisk >>%actdrive%\attachvhd.txt
echo exit >>%actdrive%\attachvhd.txt
diskpart /s %actdrive%\attachvhd.txt
set diskpart3rc=!errorlevel!
if !diskpart3rc!==0 ((echo Diskpart phase 3 ended successfully, vhd was mounted.)&(goto :listvolume))
echo.
echo Diskpart phase 3 failed, return code !diskpart3rc!.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart scripts (attachvhd.txt, mountvhd.txt, listvolume.txt^) on drive %actdrive%.
goto :eof

:listvolume
REM
REM listvolume.txt is the name of the script to find the volumes
REM
for /f "tokens=2,4" %%a in ('diskpart /s %actdrive%\srs\listvolume.txt') do (if %%b==Windows_SrS set volnum=%%a)
set volnumrc=!errorlevel!
if '!volnum!'=='' ((echo.)&(echo Unable to find any mounted volume name "Windows_SrS")&(echo Have you already run the cvt2vhd command?)&(goto :background))
if !volnumrc!==0 ((echo Diskpart phase 4 ended successfully, vhd is volume !volnum!.)&(goto :foundvolume))
echo.
echo Diskpart phase 4 failed, return code !volnumrc!.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart scripts (attachvhd.txt, mountvhd.txt, listvolume.txt^) on drive %actdrive%.
goto :eof

:foundvolume
REM
REM mountvhd.txt is the name of the script to assign the drive letter
REM
echo select volume !volnum! >%actdrive%\mountvhd.txt
echo assign letter=%vhddrive% >>%actdrive%\mountvhd.txt
echo exit >>%actdrive%\mountvhd.txt
diskpart /s %actdrive%\mountvhd.txt
set diskpart4rc=!errorlevel!
if !diskpart4rc!==0 ((set vhddrive=%vhddrive%:)&(echo Diskpart phase 5 ended successfully, vhd is drive !vhddrive!.)&(goto :vhdok))
echo.
echo Diskpart phase 4 failed, return code !diskpart4rc!.
echo It's not really safe to continue so I'm stopping here.  Look at what Diskpart
echo just reported to see if there's a clue in there.  You may also get a clue from
echo the diskpart scripts (attachvhd.txt, mountvhd.txt, listvolume.txt^) on drive %actdrive%.
goto :eof

:vhdok
bcdboot !vhddrive!\windows /l en-us /s %efidrive% /f ALL
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
if %osversion%==7 (
%srsdrive%
REM
REM the current BCD is of no value, so next we'll delete it and build a new
REM one from scratch
REM
del %srsdrive%\boot\bcd 
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
set "bcdstore=/store %efidrive%\EFI\Microsoft\Boot\BCD"
)
for /f "tokens=2 delims={}" %%a in ('bcdedit %bcdstore% /create /d "Roll Back Windows" -application osloader') do (set guid={%%a})
if '%guid%'=='' ((echo.)&(echo Unable to create Roll Back Windows entry with bcdedit)&(goto :badend))
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
bcdedit %bcdstore% /set %guid% osdevice partition=%srsdrive%
bcdedit %bcdstore% /set %guid% device partition=%srsdrive% 
if %osversion%==7 bcdedit /set %guid% path \windows\system32\boot\winload.exe
if %osversion%==10 bcdedit %bcdstore% /set %guid% path \windows\system32\boot\winload.efi
bcdedit %bcdstore% /set %guid% systemroot \windows
bcdedit %bcdstore% /set %guid% winpe yes
bcdedit %bcdstore% /set %guid% detecthal yes 
bcdedit %bcdstore% /displayorder %guid% /addlast 
bcdedit %bcdstore% /timeout 1 
@echo off
if %osversion%==7 if exist %srsdrive%\boot\bcd goto :bcdok
if %osversion%==10 if exist %efidrive%\EFI\Microsoft\Boot\BCD goto :bcdok
echo.
echo ++++++ BCD CREATION FAILURE +++++++++
echo.
echo I just tried to create the Windows Boot Configuration Database file,
if %osversion%==7 echo %srsdrive%\boot\bcd, but it's not there. That usually means that bcdedit, the
if %osversion%==10 echo %efidrive%\EFI\Microsoft\Boot\BCD, but it's not there. That usually means that bcdedit, the
echo Windows tool for manipulating BCD files, got confused and it wrote to the
echo wrong drive, or tried writing it to a nonexistent drive.
echo. 
echo But don't worry, the fix is pretty simple.  It's usually caused when you have
echo an external drive -- USB, eSATA or the like -- and bcdedit gets it into its
echo head that you wanted it on some other drive. Having an already-attached,
echo already-partitioned drive often confuses BCDEDIT.
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
if %osversion%==7 echo STEP SIX: INSTALL STEADY STATE FILES AND IMAGEX IN WINPE
if %osversion%==10 echo STEP SIX: INSTALL STEADY STATE FILES IN WINPE
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
robocopy %actdrive%\srs %srsdrive%\srs
REM
REM and the updated startnet.cmd
REM
copy %actdrive%\startnethd.cmd %srsdrive%\windows\system32\startnet.cmd /y
if %osversion%==7 copy %actdrive%\windows\system32\imagex.exe %srsdrive%\windows\system32 /y
if %osversion%==10 copy %actdrive%\windows\system32\Dism.exe %srsdrive%\windows\system32 /y
REM
REM Change the background wallpaper to winpe1.bmp, showing it's a HD boot
REM
copy %srsdrive%\srs\winpe1.bmp %srsdrive%\windows\system32\winpe.bmp /y
REM
REM done with it, delete
REM
del %srsdrive%\srs\winpe1.bmp
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
goto :eof

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
