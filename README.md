# SteadierState
This is a modified version of steadier state to provide compatibility with Windows 10. See steadierstate.com for the original work developed by Mark Minasi.

# Instructions
  1. Download and Extract zip file.
  2. Open a Command Prompt window as an Administrator
  3. Change to the directory where the files are saved (e.g. cd Dowloads\SteadierState)
  4. Run the 'buildpe.cmd' (e.g. .\buildpe.cmd)
  5. Follow the prompts on the screen. If any errors are encountered follow the suggestions offered by the error message.
  6. If the process succeeds boot from the USB or CD that was created.
  7. Type 'cvt2vhd.cmd' and follow the prompts to create the vhd file.
  8. If Successful, run the 'prepnewpc.cmd' and follow the prompts
  9. Reboot the computer by typing 'exit'
  10. Make any further desired changes and run the 'C:\srs\firstrun.cmd'
  11. Restart the computer. From this point forward the computer will automatically create a new snapshot at every reboot.
