# SteadierState
This is a modified version of steadier state to provide compatibility with Windows 10. See steadierstate.com for the original work developed by Mark Minasi.

## Instructions
Essentially there are four phases in the SteadierState model and they are as follows:

### **Phase 1** -- Install and build the SteadierState live media toolchain.
  Note: This phase requires a usb flashdrive. **Warning: All data on the usb flashdrive used with this phase will be lost!**

  1. Clone the SteadierState repository **or** Download and Extract zip file from the github.com repository.
  2. Open a Command Prompt window **as an Administrator**.
  3. Change to the directory where you "*Clone **or** Download and Extract zip file*" in step 1.
  4. Initiate the toolchain build by running the `buildpe.cmd` command. Upon running the `buildpe.cmd` command you will be prompted for input to produce a bootable usb key (and if desired an .iso file).
  5. When the `buildpe.cmd` has completed, if all went well, you will have a bootable usb key (and if requested an .iso file).
  6. Should something go wrong during the `buildpe.cmd` execution, follow the suggestions offered by the error message.

### **Phase 2** -- Create a SteadierState installable setup.
  Note: This phase requires an external drive or network drive to hold deployment files.

  1. Boot the live media created in **Phase 1** on a PC running Windows that you wish to use as the base install for your SteadierState deployment.
  2. Initiate the creation of the SteadierState installable setup with the `cvt2chd.cmd` command. Upon running the `cvt2vhd.cmd` command you will be prompted for input to produce the everything needed for deployment.
  3. Should something go wrong during the `cvt2vhd.cmd` execution, follow the suggestions offered by the error message.
  3. Reboot the computer by typing 'exit'.

### **Phase 3** -- Deploy SteadierState to a PC.
  Note: **Warning: This phase will erase all files on disk 0 of the target PC!**

  1. Boot the live media created in **Phase 1** on a PC you wish to deploy with SteadierState.
  2. Initiate the deployment of SteadierState to the PC with the `prepnewpc.cmd` command. Upon running the `prepnewpc.cmd` command you will be prompted for input to perform the installation of SteadierState to the PC.
  3. Should something go wrong during the `prepnewpc.cmd` execution, follow the suggestions offered by the error message.
  3. Reboot the computer by typing 'exit'.

### **Phase 4** -- Finalize the SteadierState deployment on the PC.

  1. Boot the PC which you deployed with SteadierState in **Phase 3**.
  2. Customize and make any further desired changes on the PC.
  3. Open a Command Prompt window **as an Administrator**.
  4. In the Command Prompt window opened in **step 3.**, initiate the SteadierState rollback point with the `c:\srs\firstrun.cmd` command.
  3. Should something go wrong during the `C:\srs\firstrun.cmd` execution, follow the suggestions offered by the error message.
  5. FIXME - Restart the computer. By default, from this point forward the computer will automatically create a new snapshot at every reboot.
