# LogCommand
A Bash Script to make logging commands and their outputs easier - even where output may not be thrown to the Command Line


Written to make logging easier, especially as the outputs of commands I was using weren't showing output.

This script is especially better when used with https://github.com/FMallon/LogAppend

Although, one could use 'sudo tee -a' also, or whatever.

Usage (where alias of script is set to 'logcom':

  1) logcom "sudo blkdiscard $DISK_NAME" | sudo tee -a /log/logfile.log

or even better, using LogAppend:

  1) log --begin /log/logfile.log
  2) logcom "sudo blkdiscard $DISK_NAME" | log -a /logfile.log
  3) log --end /log/logfile.log


This will output the command, its output, and exit status to a logfile.  If the command doesn't output to the terminal as the one above, LogCommand will log success or failure based of the exit status.

This script was made because I was sanitizing disks that I needed to log, and nvme-cli and blkdiscard do not throw output upon running - output that I needed to prove that these commands have been successfully ran.  This script aids to mitigate that.

  
