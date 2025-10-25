# bash-recycle-bin
Bash script that sets up a recycle bin functionality for your UNIX environment

Author: Ronald Li

The recycle command sets up a 'recycle bin'-like functionality. This allows users to send documents to a recycle directory, which can then be restored in the future or permanently deleted after a set amount of time.

Run the recycle_setup file to install the recycle command. Running the recycle_setup file will automatically install recycle to the /usr/bin directory and the man page.

The recycle file should be in the same directory as the recycle_setup file for the installation to function correctly.

Rerunning recycle_setup will allow the user to uninstall the recycle command or to configure the automatic trash removal schedule.
