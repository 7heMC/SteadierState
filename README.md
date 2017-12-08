# SteadierState
This is a modified version of steadier state to provide compatibility with Windows 10. See steadierstate.com for the original work developed by Mark Minasi.

## Instructions
Essentially there are four phases in the SteadierState model and they are as follows:

### Phase 1 -- Install and build the SteadierState live media toolchain.
  Note: This phase requires a usb flashdrive. **Warning: All data on the usb flashdrive used with this phase will be lost!**

  1. Clone the SteadierState repository **or** Download and Extract zip file from the github.com repository.
  2. Open a Command Prompt window **as an Administrator**.
  3. Change to the directory where you "*Clone **or** Download and Extract zip file*" in step 1.
  4. Initiate the toolchain build by running the `buildpe.cmd` command. Upon running the `buildpe.cmd` command you will be prompted for input to produce a bootable usb key (and if desired an .iso file).
  5. When the `buildpe.cmd` has completed, if all went well, you will have a bootable usb key (and if requested an .iso file).
  6. Should something go wrong during the `buildpe.cmd` execution, follow the suggestions offered by the error message.

### Phase 2 -- Create a SteadierState installable setup.
  Note: This phase requires an external drive or network drive to hold deployment files.

  1. Boot the live media created in **Phase 1** on a PC running Windows that you wish to use as the base install for your SteadierState deployment.
  2. Initiate the creation of the SteadierState installable setup with the `cvt2chd.cmd` command. Upon running the `cvt2vhd.cmd` command you will be prompted for input to produce the everything needed for deployment.
  3. Should something go wrong during the `cvt2vhd.cmd` execution, follow the suggestions offered by the error message.
  3. Reboot the computer by typing `exit`.

### Phase 3 -- Deploy SteadierState to a PC.
  Note: **Warning: This phase will erase all files on disk 0 of the target PC!**

  1. Boot the live media created in **Phase 1** on a PC you wish to deploy with SteadierState.
  2. Initiate the deployment of SteadierState to the PC with the `prepnewpc.cmd` command. Upon running the `prepnewpc.cmd` command you will be prompted for input to perform the installation of SteadierState to the PC.
  3. Should something go wrong during the `prepnewpc.cmd` execution, follow the suggestions offered by the error message.
  3. Reboot the computer by typing `exit`.

### Phase 4 -- Finalize the SteadierState deployment on the PC.

  1. Boot the PC which you deployed with SteadierState in **Phase 3**.
  2. Customize and make any further desired changes on the PC (see **Directives**, **Hooks**, and **Operating Modes** below).
  3. Open a Command Prompt window **as an Administrator**.
  4. In the Command Prompt window opened in **step 3.**, initiate the SteadierState rollback point with the `c:\srs\firstrun.cmd` command.
  3. Should something go wrong during the `C:\srs\firstrun.cmd` execution, follow the suggestions offered by the error message.
  5. Reboot the PC and the next boot should be to WindowsPE which will perform the final configurations of a snapshot.vhd and a corresponding boot entry.

## Directives
SteadierState target PC's which have completed **Phase 4** are essentially deployment ready. There are times which admins will need to perform some type of maintenance or configuration adjustments on these deployment ready PC's. SteadierState utilizes the local install of WindowsPE and what is called **Directives** to change the default deployment configurations. There are two primary **Directives** "*noauto*" and "*automerge*". To activate **Directives** simply place a file named appropriately ("*noauto.txt*" or "*automerge.txt*") in a directory named `\srsdirectives` on the drive containing the image.vhd and snapshot.vhd. Note: The contents of the **Directives** file does not matter only the name.

### Directive "*noauto*"
The noauto directive tells the WindowsPE install to take no automatic action. To enable the "*noauto*" directive perform the following steps:

  1. Assume that D: is the drive containing the image.vhd, snapshot.vhd, and the \srsdirectives folder.
  2. Open a Command Prompt window **as an Administrator**.
  3. In the Command Prompt window opened in **step 3.**, run the following command `echo > D:\srsdirectives\noauto.txt`.
  4. Reboot the PC and the next boot should be to WindowsPE with the "*noauto*" directive.

### Directive "*automerge*"
The automerge directive tells the WindowsPE install to take automerge the image.vhd and the snapshot.vhd to a new image.vhd. To enable the "*automerge*" directive perform the following steps:

  1. Assume that D: is the drive containing the image.vhd, snapshot.vhd, and the \srsdirectives folder.
  2. Open a Command Prompt window **as an Administrator**.
  3. In the Command Prompt window opened in **step 3.**, run the following command `echo > D:\srsdirectives\automerge.txt`.
  4. Reboot the PC and the next boot should be to WindowsPE with the "*automerge*" directive.


### Directive Examples
To provide an understanding of how these **Directives** can be used please examine the following examples.

#### Example: How can I boot my SteadierState PC to WindowsPE for diagnostics image running "*Rollback Mode*"?

  1. Assume that D: is the drive containing the image.vhd, snapshot.vhd, and the \srsdirectives folder.
  2. Boot the PC up which will be in the pristine state of deployment.
  3. Apply the configuration adjustments desired.
  4. Open a Command Prompt window **as an Administrator**.
  5. In the Command Prompt window opened in **step 3.**, run the following command `echo > D:\srsdirectives\noauto.txt`.
  6. Reboot the PC and the next boot should be to WindowsPE with the "*noauto*" directive.

#### Example: How can I boot my SteadierState PC to WindowsPE for diagnostics image running "*Delta Mode*"?

  1. Assume that D: is the drive containing the image.vhd, snapshot.vhd, and the \srsdirectives folder.
  2. Boot the PC up which will be in the pristine state of deployment.
  3. Apply the configuration adjustments desired.
  4. Open a Command Prompt window **as an Administrator**.
  5. In the Command Prompt window opened in **step 3.**, run the following command `echo > D:\srsdirectives\noauto.txt`.
  6. In the Command Prompt window opened in **step 3.**, run the following command `C:\srs\bcddefault.cmd`.
  7. Reboot the PC and the next boot should be to WindowsPE with the "*noauto*" directive.

#### Example: How can I upgrade my SteadierState PC base image running "*Rollback Mode*"?

  1. Assume that D: is the drive containing the image.vhd, snapshot.vhd, and the \srsdirectives folder.
  2. Boot the PC up which will be in the pristine state of deployment.
  3. Apply the configuration adjustments desired.
  4. Open a Command Prompt window **as an Administrator**.
  5. In the Command Prompt window opened in **step 3.**, run the following command `echo > D:\srsdirectives\automerge.txt`.
  6. Reboot the PC and the next boot should be to WindowsPE with the "*automerge*" directive.

#### Example: How can I upgrade my SteadierState PC base image running "*Delta Mode*"?

  1. Assume that D: is the drive containing the image.vhd, snapshot.vhd, and the \srsdirectives folder.
  2. Boot the PC up which will be in the pristine state of deployment.
  3. Apply the configuration adjustments desired.
  4. Open a Command Prompt window **as an Administrator**.
  5. In the Command Prompt window opened in **step 3.**, run the following command `echo > D:\srsdirectives\automerge.txt`.
  6. In the Command Prompt window opened in **step 3.**, run the following command `C:\srs\bcddefault.cmd`.
  7. Reboot the PC and the next boot should be to WindowsPE with the "*automerge*" directive.

## Hooks
SteadierState now has a new feature called first run hooks. First run hooks provide users a way to apply custom setting and configurations during **Phase 4** when the `C:\srs\firstrun.cmd` command is ran. Also please remember that the `C:\srs\firstrun.cmd` command in **Phase 4** is disigned to be ran **only once** on a target PC.

### How do first run hooks work?

  First run hooks work like this, there is now a folder called "*C:\srs\hooks\*", in this folder are commands (i.e.hooks) that are executed when the `C:\srs\firstrun.cmd` command is ran. So prior to running the `C:\srs\firstrun.cmd` command, you can provide custom instructions to be ran for your deployment environment.

### How do I write my own first run hook?

  As a starting place take a look at the hooks-samples folder for some ideas on how it works.


### How do I install a first run hook?

  Hooks are enabled by placing them in the `C:\srs\hooks` folder prior to running the `C:\srs\firstrun.cmd`.

## Operating Modes
SteadierState with the new first run hooks model can now offer two primary "*modes*" **Rollback Mode** (the default) and **Delta Mode** which are described below.

### **Rollback Mode**
  * The default deployment "*mode*" of SteadierState with the default set of first run hooks enabled when the `C:\srs\firstrun.cmd` command is ran on a target PC. Essentially this "*mode*" "*Rolls Back*" any changes that were made since the last reboot.

### **Delta Mode**
  * The deployment "*mode*" of SteadierState with the default hook of `hooks\1000-rollback.cmd` removed from the hooks folder prior to running the `C:\srs\firstrun.cmd` command on a target PC. Essentially this "*mode*" allows the target PC to run on the snapshot.vhd in **Delta Mode** without rolling back at reboot until instructed otherwise.
