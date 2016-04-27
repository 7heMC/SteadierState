@echo off
cls
REM BUILDPE.CMD
REM
REM Function: automates creating the USB stick or CD
REM used to deploy Steadier State to a system
REM End product:  an ISO folder and optionally puts
REM it on a USB stick.
REM
REM Inputs and Assumptions
REM Assumes:	WAIK installed in default location
REM		Can create and delete a folder %temp%\SDRSTATE
REM Inputs:	Which architecture to use, 32 or 64 bit
REM		Where to write the ISO for a CD (or not to)
REM		Drive letter of the USB stick to create
REM		(or not to create a USB stick)
REM
REM WAIK LOCATION
REM Needs the WAIK installed in its default location
REM If that's an issue, change the next line to point
REM to the top level folder in wherever you installed
REM the WAIK.
REM

set WAIKBase=C:\Program Files\Windows AIK\Tools
if not exist "C:\Program Files\Windows AIK\Tools" ((Echo For this to work, you MUST have the Windows Automated Installation Kit downloaded and installed in its default location, or modify the "set WAIKBASE=" line in the command file with the WAIK's alternate location; exiting.)&(goto :badend))
set makeiso=true
set madeiso=
set makeusb=true
set usbdriveletter=none
set logdir=C:\windows\logs\buildpelogs


REM
REM Check that we're running as an admin
REM

del temp.txt 2> nul
whoami /groups |find /c "High Mandatory">temp.txt
set total=
set /p total= <temp.txt
del temp.txt 2>nul

if %total%==1 goto :youreanadmin

echo.
echo I'm sorry, but you must be running from an elevated 
echo command prompt to run this command file.  Start a new 
echo command prompt by right-clicking the Command Prompt icon, and
echo then choose "Run as administrator" and click "yes" if you see
echo a UAC prompt.
goto :done
:youreanadmin

REM
REM Set up and test logging
REM
rd %logdir% /q /s  2>nul
md %logdir%\test
if exist %logdir%\test ((rd %logdir%\test /q /s) & (goto :canlog))
rem
rem 
echo.
echo I can't seem to delete the old logs; continuing anyway.
echo.
:canlog



echo.
echo ___________________________________________________________
echo     B U I L D   U S B / I S O  T O O L
echo ___________________________________________________________
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
:usbquestions
echo.
echo =========================================================
echo Question 1: Where's the USB stick (if any)?
echo.
echo Would you like me to set up the Steadier State install tool on a bootable
echo USB stick (or any other UFD device, for that matter)?
echo.
echo     REMINDER: I'M GOING TO WIPE THAT DEVICE CLEAN!!!
echo.
echo Type "y"  (without the quotes) to set up a USB stick.  Enter anything 
echo else to NOT create a USB stick, or "end" to end this program.
set /p resp=What's your answer? 
echo.
if a%resp%==aend ((echo.) & (echo Exiting as requested.) & (goto :done))
if not a%resp%==ay goto :nousbstick
echo.
echo Okay, what is that USB stick's drive letter?
echo Enter its drive letter -- just the letter, don't
set /p usbdriveletter=add a colon (":") after it -- and press Enter.
if a%usbdriveletter%==aend ((echo.) & (echo Exiting as requested.) & (goto :done))
echo.
if not exist %usbdriveletter%:\ ((echo.)&(echo ---- ERROR ----)&(echo.)&(echo.)&(echo There doesn't seem to be a USB stick at %usbdriveletter%:.  Let's try again.)&(echo.)&(goto :usbquestions))
REM
REM If not, there's a USB stick there.
rem I need this to be uppercase so now I'll have to uppercase it.
rem
if %usbdriveletter%==C set usbdriveletter=C
if %usbdriveletter%==d set usbdriveletter=D
if %usbdriveletter%==e set usbdriveletter=E
if %usbdriveletter%==f set usbdriveletter=F
if %usbdriveletter%==g set usbdriveletter=G
if %usbdriveletter%==h set usbdriveletter=H
if %usbdriveletter%==i set usbdriveletter=I
if %usbdriveletter%==j set usbdriveletter=J
if %usbdriveletter%==k set usbdriveletter=K
if %usbdriveletter%==l set usbdriveletter=L
if %usbdriveletter%==m set usbdriveletter=M
if %usbdriveletter%==n set usbdriveletter=N
if %usbdriveletter%==o set usbdriveletter=O
if %usbdriveletter%==p set usbdriveletter=P
if %usbdriveletter%==q set usbdriveletter=Q
if %usbdriveletter%==r set usbdriveletter=R
if %usbdriveletter%==s set usbdriveletter=S
if %usbdriveletter%==t set usbdriveletter=T
if %usbdriveletter%==u set usbdriveletter=U
if %usbdriveletter%==v set usbdriveletter=V
if %usbdriveletter%==w set usbdriveletter=W
if %usbdriveletter%==x set usbdriveletter=X
if %usbdriveletter%==y set usbdriveletter=Y
if %usbdriveletter%==z set usbdriveletter=Z
REM
echo Found a device at %usbdriveletter%:.
rem
goto :Isoquestions
:nousbstick
echo.
echo Okay, no need to create a bootable USB stick.
echo.
set makeusb=false
:ISOquestions
echo.
echo.
echo =========================================================
echo Question 2: ISO File or no?
echo.
echo Would you like me to create an ISO file of a bootable CD image
echo (equipped with the Steadier State install files) that you can burn to a
echo CD or use in a virtual machine environment?  This will be useful
echo in situations where you don't have a USB stick or perhaps one 
echo might not work.  To create the ISO, please respond "y" and Enter.
set /p resp=Type y to make the ISO, end to exit, anything else to skip making the ISO?
if a%resp%==aend ((echo.) & (echo Exiting as requested.) & (goto :done))
if not a%resp%==ay goto :noiso
set makeiso=true
echo.
echo Okay, I will create an ISO file in your Documents folder.
echo.
goto :archquestion
:noiso
echo.
echo Okay, I won't create an ISO file.
set makeiso=false
:archquestion
REM
REM test to see if neither output desired
REM
if not %makeiso%%makeusb%==falsefalse goto :askarch
echo.
echo You've selected that you want neither a USB stick nor an ISO
echo file, so there'd be no point in continuing.  Exiting...
echo.
goto :done


:askarch

echo.
echo.
echo =========================================================
echo Question 3: 32 bit or 64 bit?
echo.
echo Next, will you be putting this on a 32-bit or 64-bit
echo system?  Please enter either "32" or "64" and press Enter.
set /p resp=Your response?
if a%resp%==aend ((echo.) & (echo Exiting as requested.) & (goto :done))
set arch=nothing
set len=48
if a%resp% == a64 ((set arch=amd64)&(set len=64)& (goto :sdrstatefiles))
if a%resp% == a32 ((set arch=x86)&(set len=32) &(goto :sdrstatefiles))
echo.
echo -------- ERROR -----------
echo.
echo Sorry, that didn't match either "32" or "64."
echo.
goto :askarch


:sdrstatefiles

echo.
echo =========================================================
echo Question 4: Where are the Steadier State files?
echo.
echo Finally, where is the folder with the Steadier State command files,
echo the folder containing rollback.cmd, merge.cmd, startnethd.cmd,
echo startnetusb.cmd and prepnewpc.cmd?  Please enter the 
echo folder name here and press Enter; again, to stop this program
echo just type "end" and press Enter:
echo.
set /p sourcename=Your response (folder name for Steadier State files)? 
if a%sourcename%==aend ((echo Exiting at your request.)&(echo.)& (goto :done))
echo.


echo Checking for the files in folder "%sourcename%"...

if not exist %sourcename%\rollback.cmd ((echo rollback.cmd not found in %sourcename%.)&(goto :sdrstatefiles))
if not exist %sourcename%\prepnewpc.cmd ((echo prepnewpc.cmd not found in %sourcename%.)&(goto :sdrstatefiles))
if not exist %sourcename%\merge.cmd ((echo merge.cmd not found in %sourcename%.)&(goto :sdrstatefiles))
if not exist %sourcename%\startnethd.cmd ((echo startnethd.cmd not found in %sourcename%.)&(goto :sdrstatefiles))
if not exist %sourcename%\cvt2vhd.cmd ((echo cvt2vhd.cmd not found in %sourcename%.)&(goto :sdrstatefiles))

:confirm
echo.
echo Now I'm ready to prepare your USB stick and/or ISO.
echo Confirming, you chose:
echo.
echo Architecture=%len% bit.
echo Make a USB stick=%makeusb%
if %makeusb%==true echo Drive for USB stick=%usbdriveletter%:
echo Make an ISO file=%makeiso%
echo WAIK installed:  verified
REM
REM Set temp name of WinPE folder
set fname=%temp%\BuildPE
echo WinPE workspace folder=%fname%
echo (Folder will be automatically deleted once we're finished.)
set volname=ROLLB%len%INST
echo USB/CD volume name=%volname%
set isofilespec=%userprofile%\documents\SDRSTATE%len%Inst.iso
if %makeiso%==true echo File name and location of ISO file=%isofilespec%
echo Location of Steadier State command files=%sourcename%
set nousbdrive=true
if %makeusb%==true set nousbdrive=false

echo Architecture=%len% bit.>%logdir%\startlog.txt
echo Make a USB stick=%makeusb% >>%logdir%\startlog.txt
if %makeusb%==true echo Drive for USB stick=%usbdriveletter%: >>%logdir%\startlog.txt
echo Make an ISO file=%makeiso% >>%logdir%\startlog.txt
echo WAIK installed:  verified >>%logdir%\startlog.txt
echo WinPE workspace folder=%fname% >>%logdir%\startlog.txt
echo USB/CD volume name=%volname% >>%logdir%\startlog.txt
if %makeiso%==true echo File name and location of ISO file=%isofilespec% >>%logdir%\startlog.txt
echo Location of Steadier State command files=%sourcename% >>%logdir%\startlog.txt


echo.
echo Please press "y" and Enter to confirm that you want to
set /p resp=do this, or anything else and Enter to stop.
echo.
if not a%resp%==ay goto :done
if a%resp%==aend ((echo.) & (echo Exiting as requested.) & (goto :done))

echo.
echo Buildpe started.  This may take about five to ten minutes in total.
echo.
echo If this fails, look in %logdir% for detailed output and logs
echo of the each stage of the process.
echo.
echo First, clean up any mess from previous BUILDPE runs.
echo.

REM
REM Let's get to work
REM
REM First, delete any existing WinPE folders or ISO files
REM
rd %fname% /s /q 2>NUL
del %isofilespec% 2>NUL


REM create DL, drive letter, add colon
set dl=%usbdriveletter:~0,1%:

echo Then, create a WinPE workspace, using the WAIK tools.
echo.

REM To work!  Create WinPE workspace
REM
REM add WAIK path stuff

pushd
echo Setting WAIK environment variables >>%logdir%\startlog.txt
call "%WAIKBase%\PETools\pesetenv.cmd" >%logdir%\01setpcmdprompt.txt
popd

echo Creating WinPE workspace >>%logdir%\startlog.txt

call copype %arch% %fname% >%logdir%\02createwinpeworkspace.txt
popd

echo Next, mount that WinPE so we can install some Steadier State files
echo into that WinPE.  This can take a minute or two.
echo.
REM
REM Mount the folder
echo Mounting Winpe.wim >>%logdir%\startlog.txt
imagex /mountrw %fname%\winpe.wim 1 %fname%\mount  >%logdir%\03imagexmount.txt

set imagexrc=%errorlevel%

If %imagexrc%==0 goto :imagexok

echo.
echo ********** ERROR:  Imagex mount attempt failed ******************
echo
echo The answer may simply be an incompletely dismounted previous run
echo and in that case a simple reboot may clear things up. Here's the 
echo output from the attempted mount:
echo ============= OUTPUT STARTS=====================================
type %logdir%\imagexmount.txt
echo ============== OUTPUT ENDS ======================================
echo.
echo Exiting.
goto :badend


:imagexok
echo.
echo WinPE space created with copype and WinPE's boot.wim mounted with ImageX.
echo.

echo Winpe.wim mounted, imagex rc=%errorlevel% >>%logdir%\startlog.txt
echo Creating and copying scripts to the USB stick and/or ISO image...

md %fname%\mount\SDRState  >nul
copy %sourcename%\prepnewpc.cmd %fname%\mount /y >nul
copy %sourcename%\winpe.bmp %fname%\mount\windows\system32 /y >nul
copy %sourcename%\startnethd.cmd %fname%\mount /y >nul
REM copy %sourcename%\startnetusb.cmd %fname%\mount /y >nul
copy %sourcename%\merge.cmd %fname%\mount\sdrstate /y >nul
copy %sourcename%\rollback.cmd %fname%\mount\sdrstate /y >nul
copy %sourcename%\cvt2vhd.cmd %fname%\mount /y >nul
copy %sourcename%\winpe1.bmp %fname%\mount\sdrstate /y >nul
rem different WinPE to differentiate if you booted USB or hard disk
copy "%WAIKBase%\%arch%\imagex.exe" "%fname%\mount\windows\system32" /y >>%logdir%\04sdrstatecopy.txt
echo @cd \ >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @cls  >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @echo WinPE 3.0 booted from USB stick. >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @echo. >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @echo You may type the command "prepnewpc" to wipe this computer's >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @echo hard disk, install WinPE and get it ready to deploy a new >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @echo rollback-able copy of Windows.  >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @echo. >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @echo Or, if you're using this to create your image.vhd, then  >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @echo hook up your system to some external storage -- image.vhd can   >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @echo be large! -- and use cvt2vhd to create that image.vhd. >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @echo .  >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @echo In any case, I hope that Steadier State is proving useful. >> "%fname%\mount\windows\system32\startnet.cmd" 
echo @echo -- Mark Minasi help@minasi.com, www.steadierstate.com >> "%fname%\mount\windows\system32\startnet.cmd" 
echo Copied Steadier State files. >>%logdir%\startlog.txt

REM
REM Unmount, we're done
REM
imagex /unmount %fname%\mount /commit >%logdir%\05imagexunmount.txt
set imagexrc=%errorlevel%

If %imagexrc%==0 goto :imagexok2

echo.
echo ********** ERROR:  Imagex unmount attempt failed ******************
echo
echo The answer may simply be an incompletely dismounted previous run
echo and in that case a simple reboot may clear things up. Here's the 
echo output from the attempted mount:
echo ============= OUTPUT STARTS=====================================
type %logdir%\imagexunmount.txt
echo ============== OUTPUT ENDS ======================================
echo.
echo Exiting.
goto :badend

:imagexok2
echo Successfully copied files and unmounted boot.wim.
echo Unmounted winpe.wim, imagex RC=%errorlevel% >>%logdir%\startlog.txt
echo.
REM
REM Install boot.wim
REM
move %fname%\winpe.wim %fname%\iso\sources\boot.wim >>%logdir%\startlog.txt
REM 
REM add a noauto.txt so the CD can get you to WinPE
REM
echo for convenience>%fname%\iso\noauto.txt
REM
REM The ISO folder is now ready
REM


echo Moved winpe.wim to ISO folder, folder is ready >>%logdir%\startlog.txt



REM Time to make the USB drive
REM 
if %makeusb%==false goto :donecreatingusb

echo Starting to create USB stick. >>%logdir%\startlog.txt

REM
REM WIPE AND REBUILD USB STICK
REM Sets up DISKPART to be able to create our USB stick.
REM In the process, we'll have to run DISKPART three times
REM
REM STEP ONE: RETRIEVE VOLUME NUMBER
REM Given a drive letter in %usbdriveletter%, find its volume number
REM And then given a volume name in %volname%, set the volume up

set founddisk=false
set foundvolume=false
set volwewant=
set disknum=

REM Create script to get volume list in diskpart
echo lis vol >%logdir%\diskpartscript1.txt
echo exit >>%logdir%\diskpartscript1.txt
echo Running Diskpart to retrieve volume numbers, this may take a minute... 
diskpart /s %logdir%\diskpartscript1.txt > %logdir%\dpout1.txt
set dr1=%errorlevel%
if %dr1%==0 ((echo Diskpart phase 1 ended successfully, analyzing output.)&(goto :dphase1))
echo Diskpart phase 1 failed, return code %dr1%.
echo It's not really safe to continue -- I'd hate to blow away the wrong
echo disk! -- so I'm stopping here and here's the Diskpart output -- there
echo should be a clue in there.
echo DISKPART OUTPUT:
type %logdir%\dpout1.txt
echo ================================
goto :donecreatingusb
:dphase1
REM
REM Analyzing first diskpart results
REM 
 
for /f "tokens=1-4" %%i in (%logdir%\dpout1.txt) do (if %%i%%k==Volume%usbdriveletter% ((set volwewant=%%j) & (set foundvolume=true)))
if %foundvolume%==false ((Echo unable to find drive %usbdriveletter%: in this Diskpart output:)&(type diskpartout.txt)&(echo Unable to set USB stick to "active" automatically.)&(echo Consult the documentation for instructions on doing it manually.)&(goto :badend))

if %foundvolume%==true (echo Success; drive %usbdriveletter% is on volume number %volwewant%.) 

REM
REM Now build script #2: given a volume number, what's the number of the disk that it is on?
REM

echo sel vol %volwewant% > %logdir%\diskpartscript2.txt
echo det vol >> %logdir%\diskpartscript2.txt
echo exit >> %logdir%\diskpartscript2.txt

REM
REM Run the script
REM

diskpart /s %logdir%\diskpartscript2.txt > %logdir%\dpout2.txt

set t=%errorlevel%
if a%t%==a0 ((echo Diskpart phase 2 completed successfully. Now analyzing output.)&(goto :findusbdisk))
echo Diskpart failed with return code %t%.  Unable to retrieve disk number for USB stick, USB prep failed.
goto :donecreatingusb

:findusbdisk
REM
REM Second results
REM
for /f "tokens=1-3" %%i in (%logdir%\dpout2.txt) do ( if *Disk==%%i%%j ( (set disknum=%%k) & (set founddisk=true) ) )
if %founddisk%==false ((Echo ERROR: failed to identify the volume's disk number, can't build the USB stick.  Consult the documentation or build an ISO and use a CD) & (echo.) & (goto :badend))
echo Success; drive %usbdriveletter%: is on disk number %disknum%.
echo Formatting the USB stick now.
REM
REM Write the final diskpart script now
REM 

echo select disk %disknum% > %logdir%\diskpartscript3.txt
echo clean >> %logdir%\diskpartscript3.txt
echo create partition primary >> %logdir%\diskpartscript3.txt
echo active >> %logdir%\diskpartscript3.txt
echo format fs=fat32 quick label=%volname% >> %logdir%\diskpartscript3.txt
echo assign letter=%usbdriveletter% >> %logdir%\diskpartscript3.txt
echo exit >> %logdir%\diskpartscript3.txt

REM
REM Final Diskpart run
REM

diskpart /s %logdir%\diskpartscript3.txt > %logdir%\dpout3.txt

set t=%errorlevel%
if a%t%==a0 ((echo Diskpart phase 3 completed successfully, USB stick formatted.)&(goto :copytousb))
echo Diskpart failed with return code %t%.  USB stick build failed.
goto :donecreatingusb

:copytousb
echo.
echo Next, I'll copy the WinPE source to the USB stick and/or
echo ISO file, using Robocopy.  It's a big file, so this may take a
echo minute.
echo.
robocopy %fname%\ISO\ %dl% /e > %logdir%\05robocopyout.txt
set t=%errorlevel%
if a%t%==a1 ((echo Robocopy completed successfully.)&(goto :donecreatingusb))

echo Robocopy failed with return code %t.  USB stick NOT successfully created.


:usbok
echo.
echo USB drive at %usbdriveletter%: now ready.
echo.

echo USB stick completed. >>%logdir%\startlog.txt
:skipsetactive


rem
Echo USB stick created.
:donecreatingusb

if %makeiso%==false goto :donewithiso

REM this should work, as we should still be in the
REM WinPE workspace folder

echo Creating ISO with oscdimg... >>%logdir%\startlog.txt

oscdimg -h -n -betfsboot.com ISO %isofilespec%  >%logdir%\06oscdimgoutput.txt

set oscdrc=%errorlevel%
if %oscdrc%==0 ((echo OSCDIMG succeeded, return code 0.) &(goto :oscdok))
echo.
echo Warning: OSCDIMG returned error code %oscdrc%, ISO may not have been
echo written right.
:oscdok
echo OSCDIMG complete with rc=%errorlevel% >>%logdir%\startlog.txt

set madeiso=true

:donewithiso

rem finished without problems.

echo BuildPE finished successfully.  Cleaning up... >>%logdir%\startlog.txt

REM change path so we can delete the WinPE workspace
c:
pushd c:\


REM
REM get rid of old WinPE workspace
REM

echo Deleting WinPE workspace. >>%logdir%\startlog.txt

if not a%fname%==a rd %fname% /s /q 2>nul
popd
echo.
echo Done.  Now that you have a USB stick and/or an ISO, you can use them
echo either to convert a working Windows system into one that can be 
echo protected by Steadier State's "Roll Back Windows" feature, or you can
echo use them to prepare a system to get a Steadier State-equipped image
echo deployed to it.
echo.
echo In both cases, start by booting the system with the USB stick/CD.
echo Then, to convert a working Windows system to an SS-ready image, run
echo "cvt2vhd."  Alternatively, to get a system ready for deployment, run
echo "prepnewpc."  There are more detailed instructions for using those
echo command files in the documentation, or they also include some built-
echo in documentation.
echo.
if a%madeiso%==atrue echo Your ISO is in %isofilespec%.
echo.
echo Thanks for trying Steadier State, I hope it's useful.
echo -- Mark Minasi help@minasi.com www.steadierstate.com
echo.

set fname=
set arch=
set sourcename=
set dl=
set nousbdrive=
set len=
set makeusb=
set makeiso=
set madeiso=
set isofilespec=
set usbdriveletter=
set foundvolume=
set volwewant=
set usbok=
set t=

goto :eof


:badend
Echo.
echo Buildpe failed and terminated for some reason.  If you'd like to look
echo further into what might have failed, back up the folder
echo "%logdir% and the files in it and examine them for clues
echo about what went wrong.  Cleaning up temporary files...

echo.
imagex /unmount mount > %logdir%\badendimagexunmount.txt


REM change path so we can delete the WinPE workspace
c:
cd\

REM
REM get rid of old WinPE workspace
REM

echo Deleting WinPE workspace. >>%logdir%\startlog.txt

if not a%fname%==a rd %fname% /s /q 2>nul
set fname=
set arch=
set sourcename=
set dl=
set nousbdrive=
set len=
set makeusb=
set makeiso=
set madeiso=
set isofilespec=
set drvletter=
set foundvolume=
set volwewant=

goto :eof





:done
