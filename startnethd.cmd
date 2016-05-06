wpeinit
@echo off
REM
REM As we're (1) booting WinPE and (2) booting from a hard
REM disk image rather than a RAMdisk, we can be sure that 
REM the System Reserved partition -- which contains WinPE --
REM is running as X:.
REM It also means that the remaining large drive with the
REM label "Physical Drive" is probably lettered C:.
REM Use the drive letter %actdrive% to stop people from running the
REM script from Windows 7 accidentally
REM
set actdrive=%~d0
if not '%actdrive%'=='X:' goto :notwinpe
set path=%path%X:\srs;
set bootsource=Hard Drive
echo Windows PE 3.0 booted from local hard drive.
REM
REM listvolume.txt is the name of the script to find the volumes
REM
for /f "tokens=3-5" %%a in ('diskpart /s %actdrive%\srs\listvolume.txt') do (if "%%b %%c"=="Physical Dr" set phydrive=%%a:)
set phydriverc=%errorlevel%
if '%phydrive%'=='' ((echo.)&(echo Unable to find any volume named "Physical Drive")&(goto :badend))
if %phydriverc%==0 ((echo Physical Drive is mounted at %phydrive%.)&(echo Now checking to make sure imagex or dism exists.)&(goto :oscheck))
echo.
echo Can't find the Physical Drive's drive letter.  I can't fix this so I've got
echo to exit.  Please check the error message and try recreating steadier state
echo from the beginning.
echo.
goto :badend

:oscheck
REM
REM Verify the OS by checking which tool has been used
REM
if exist %actdrive%\windows\system32\imagex.exe ((set osversion=7)&(set "bcdstore=")&(echo Now checking to make sure the vhd files exist.)&(goto :vhdcheck))
if exist %actdrive%\windows\system32\Dism.exe ((set osversion=10)&(echo Now checking to make sure an efi partition exists.)&(goto :eficheck))
echo.
echo Error: imagex.exe and Dism.exe are missing from WinPE Please rebuild
echo your Steadier State install USB stick or CD ISO with buildpe.cmd and
echo use that new device to boot this system and try again.
echo.
goto :badend

:eficheck
REM
REM Then, check for UEFI partition and an onboard copy of imagex and Dism.
REM
for /f "tokens=3,4" %%a in ('diskpart /s %actdrive%\srs\listvolume.txt') do (if %%b==System_UEFI set efidrive=%%a:)
set efidriverc=%errorlevel%
if '%efidrive%'=='' ((echo.)&(echo Unable to find any mounted volume name "System UEFI")&(goto :badend))
if %efidriverc%==0 ((echo System_UEFI is mounted at %efidrive%.)&(echo Now checking to make sure the vhd files exist.)&(set "bcdstore=/store %efidrive%\EFI\Microsoft\Boot\BCD")&(goto :vhdcheck))
echo.
echo Can't find the Physical Drive's drive letter.  I can't fix this so I've got
echo to exit.  Please check the error message and try recreating steadier state
echo from the beginning.
echo.
goto :badend

:vhdcheck
REM
REM Verify there's a file \image.vhd and \snapshot.vhd on the current drive
REM
cd \srs
set noimage=false
If not exist %phydrive%\image.vhd set noimage=true
set nosnap=false
If not exist %phydrive%\snapshot.vhd set nosnap=true
REM
REM Find automerge.txt if it exists
REM
set automerge=false
if exist %phydrive%\automerge.txt set automerge=true
REM
REM Find noauto.txt if it exists
REM
set noauto=false
for %%a in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do ((if exist %%a:\noauto.txt ((set noauto=true)&(set noadrive=%%a:)))&(if exist %%a:\srs\noauto.txt ((set noauto=true)&(set noadrive=%%a:))))
echo.
REM
REM If noimage=false AND nosnap=false AND noauto=false, do auto rollback
REM
if %noimage%%nosnap%%noauto%%automerge%==falsefalsefalsefalse goto :autoroll 
REM
REM If noimage=true, show "next step" message and return to prompt, as
REM the user's in the middle of getting things going.
REM
if %noimage%==true goto :noimage
REM
REM If nosnap=true, we have an image but no snapshot, so just set up that snapshot
REM and tell the user what we did.  (Advise her about noauto.txt as well.)
REM
if %nosnap%==true goto :nosnap
REM
REM If automerge=true, we have to automatically merge the snapshot.vhd and image.vhd
REM
if %automerge%==true goto :automerge
REM
REM Otherwise, we're just invoking WinPE.
REM
goto :showshell

:autoroll
call rollback.cmd
REM
REM if something went wrong and the user needs to see it, there's
REM a "99" exit code; otherwise "exit" to cause an auto reboot
REM
if %rollbackrc%==99 goto :eof
exit
goto :eof

:noimage
REM
REM if here, \image.vhd wasn't found
REM
echo.
echo Hi.  I see that you've prepared this computer's hard disk to use Steadier
echo State, but haven't yet put an image on %phydrive%.
echo.
echo Steadier State depends on a system image named image.vhd residing on your
echo large partition, what is probably drive %phydrive%.  Please get an image.vhd and put
echo it on %phydrive% before going any further.
echo.
echo If you DON'T have an image.vhd yet, it's easy to make one.  Just get a
echo Windows 7 Ultimate/Enterprise or any version of Windows Server 2008 R2
echo exactly as you want it, then boot that system with your Steadier State USB
echo stick or CD.  Run the command "cvt2vhd" and follow the instructions that'll
echo appear on the screen.  Once you've got your image.vhd copied to %phydrive%\, then run
echo "rollback"  from the command line and it'll get your snapshot set up so that
echo you can use Steadier State to instantly roll back your computer to a 
echo snapshot.  Thanks!
echo.
echo Thanks for using Steadier State, I hope it's helpful.
echo -- Mark Minasi help@minasi.com www.steadierstate.com
echo This copy of SteadierState has been modified and the source
echo can be found at https://github.com/7heMC/SteadierState
echo.
goto :eof

:nosnap
echo.
echo ---- CREATING INITIAL SNAPSHOT FILE ---
echo  System will reboot automatically when done!
echo ---------------------------------------------
echo.
echo.
echo.
echo.
call rollback.cmd
echo.
exit
goto :eof

:automerge
echo.
echo ---- AUTOMATICALLY MERGING SNAPSHOT.VHD AND IMAGE.VHD ----
echo        System will reboot automatically when done!
echo ----------------------------------------------------------
echo.
echo.
echo.
echo.
call merge.cmd
echo.
exit
goto :eof

:showshell
REM
REM otherwise, offer options
REM
echo.
echo Hi.  You're here because you booted your system and chose "Roll Back Windows."
echo To roll back your copy of Windows to when you created its last snapshot, type
echo.
echo rollback and hit enter.
echo.
echo If you want to keep the changes that you've made to your system since the last
echo snapshot (which deletes the current snapshot and creates a new one), type
echo.
echo merge and hit enter.
echo.
echo Type anything else to exit this script and use the command prompt.
set /p set %response1%=What is your answer?
echo.
REM Next, check with the human if not auto called by automerge.
REM
if '%response1%'=='' ((echo Exiting...)&(goto :eof))
if %response1%==merge goto :merge
if %response1%==rollback goto :rollback
echo Exiting...
goto :eof

:merge
echo.
echo        MERGE SNAPSHOT
echo.
echo Warning:  this routine will merge whatever's in your current snapshot 
echo (snapshot.vhd) into your base "image.vhd" file on this computer.  This change
echo isn't reversible, so I'm just double-checking to see that you mean it.  Please
echo enter "y" (lowercase only, please) and press enter to merge, or type anything
echo else and press enter to change your mind and NOT merge the files.
echo.
set /p mergeresponse=Enter "y" to merge, anything else to leave things untouched? 
echo.
if not '%mergeresponse%'=='y' ((echo Exiting...)&(goto :eof))
echo Okay, then let's continue.
echo.
call merge.cmd
echo.

:rollback
echo.
echo Running rollback.cmd and creating a new snapshot.vhd
call rollback.cmd
echo.
echo To make the system henceforth roll back and reboot AUTOMATICALLY the next time
echo someone reboots this and chooses "Roll Back Windows," ensure that no drive 
echo contains a file named "noauto.txt" in its root.  Inversely,  if you ever
echo DO want to see this command prompt window when "Roll Back Windows" is chosen,
echo create a file named "noauto.txt" in the root of any drive letter.
echo (See the documentation for more details on noauto.txt.)
echo.
echo Thanks for using Steadier State, I hope it's helpful.
echo -- Mark Minasi help@minasi.com www.steadierstate.com
echo This copy of SteadierState has been modified and the source
echo can be found at https://github.com/7heMC/SteadierState
echo.
goto :eof
