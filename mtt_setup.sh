#!/bin/bash

#check if mtt is already installed
check_install() {
        if [ -e /usr/bin/mtt ]
        then
                mtt_installed=true
        fi
}

#install mtt
install_mtt() {
        current_dir=$(dirname $(realpath $0))
        #check if mtt file is in the current directory
        if [ ! -e "$current_dir/mtt" ]
        then
                echo -e "mtt script not found. mtt script needs to be in the same location as this script at $current_dir\nExiting"
                exit 1
        fi

        sudo cp $current_dir/mtt /usr/bin/mtt
        sudo chmod 755 /usr/bin/mtt
        if [ -x /usr/bin/mtt ]; then
                echo "mtt installed"
        else
                echo "mtt installation failed"
        fi
}

#install manpage
install_man_page() {
#tee is used as using "sudo cat <<EOF > [directory]" will only apply sudo to the cat command, not the redirection
sudo tee /usr/share/man/man1/mtt.1 > /dev/null <<EOF
.TH MTT "August 2025" "1.0" "User Commands"
.SH NAME
mtt - move to trash
.SH SYNOPSIS
mtt [filename] will send the file to the trash directory
.SH DESCRIPTION
Installs the mtt script/command to /usr/bin/mtt. The command acts as a "recycle bin" function to temporarily store deleted items.
Running the mtt_setup script allows for configuration of this function. The function can be configured to automatically remove files from the trash directory on an automated schedule.
.SH OPTIONS
Option menus are displayed upon execution
mtt -u [filename] restores the file from the trash directory to its original directory
.SH AUTHOR
Ronald Li
EOF

if [ -e /usr/share/man/man1/mtt.1 ]; then
        echo "man page for mtt created"
else
        echo "Error: man page install failed"
fi
}

#configure settings: auto-removal, schedule, prompt
configure() {
        echo "Configure automatic removal of trash files after 30 days? Yy/Nn"
        read response
        if [ $(echo $response | grep -E "(^Y|^y).*") ]
        then
                echo "Choose a removal schedule option:"
                echo "1) Every day at 9 am"
                echo "2) First day of every month"
                read response
                case $response in
                        1) schedule="0 9 * * *";;
                        2) schedule="0 9 1 * *";;
                esac
                #remove existing cronjob
                crontab -l 2>/dev/null | grep -v trash_cleanup | crontab -
                #preserve existing cronjobs, adding new job, and piping results to crontab
                (crontab -l 2>/dev/null; echo "$schedule $HOME/bin/trash_cleanup") | crontab -
                #create removal script ##need to remove info file
cat <<EOF > $HOME/bin/trash_cleanup
#!/bin/bash
for file in \$(find \$HOME/.local/share/Trash/files -type f -mtime +30)
do
        filename=\$(basename \$file)
        rm \$HOME/.local/share/Trash/info/\$filename.trashinfo
        rm \$HOME/.local/share/Trash/files/\$filename
done
EOF
#other option: find $HOME/.local/share/Trash/files -type f -mtime +30 -exec rm -f {} \;
                chmod 755 $HOME/bin/trash_cleanup
                echo "Trash removal scheduled"
        else
                #remove the cronjob
                crontab -l 2>/dev/null | grep -v trash_cleanup | crontab -
        fi
}

#uninstall mtt script, man page, cron jobs
uninstall() {
        sudo rm /usr/bin/mtt
        sudo rm /usr/share/man/man1/mtt.1
        sudo rm -f /usr/bin/trash_cleanup
        crontab -l 2>/dev/null | grep -v trash_cleanup | crontab - #remove cronjob
        if [ ! -e /usr/bin/mtt ]; then
                echo "mtt uninstall complete"
        fi
        if [ ! -e /usr/share/man/man1/mtt.1 ]; then
                echo "mtt man page uninstall complete"
        fi
}

#main program
mtt_installed=false
check_install

if [ $mtt_installed = true ]
then
        #reconfigure or uninstall
        echo "mtt is already installed to /usr/bin/mtt, select from the following options:"
        echo "1) Uninstall the mtt script"
        echo "2) Reconfigure the mtt script"
        echo "3) Quit"
        read response
        case $response in
                1) uninstall ;;
                2) configure ;;
                3) echo "Exiting"
                        exit 0 ;;
        esac
else
        #install
        echo "Installing mtt script"
        install_mtt
        install_man_page
        configure
fi