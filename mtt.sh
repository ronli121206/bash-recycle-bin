#!/bin/bash

# part 1
# creating the directories
make_dir() {
        mkdir -p $HOME/.local/share/Trash/ #-p will create parent directories if req'd, and also not create the directories if they already exist
        mkdir -p $HOME/.local/share/Trash/files/
        mkdir -p $HOME/.local/share/Trash/info/
}

# check if filename is provided
check_arg_provided() {
        if [ $1 -lt 1 ]
        then
        echo "$0: missing operand"
        exit 1
        fi
}

# check if file exists
check_exist() {
        if [ ! -e "$1" ] #if argument 1 does not exist
        #quotes are necessary to protect against special characters and spaces
        then
        echo "$0: can not move '$1' to Trash. No such file or directory"
        exit 1
        fi
}

# check if the arg is a directory
check_dir() {
        if [ -d "$1" ]
        then
        echo "$0: cannot move to trash '$1' is a directory"
        exit 1
        fi
}

# check if it is the mtt script itself
check_mtt() {
        if [ $(realpath $1) = "$HOME/bin/mtt" ]
        then
        echo "$0: operation aborted. '$1' not moved to Trash"
        exit 2
        fi
}

# moving the file to trash
trash_file() {
        original_path="$(realpath "$1")"
        base_name="$(basename "$1")"
        inode="$(stat -c %i "$1")"
        mv "$1" "$HOME/.local/share/Trash/files/${base_name}_$inode"
        #echo "original path $original_path"
        #echo "base_name $base_name"
        #echo "inode $inode"

        # create the trash info file
        info_file="$HOME/.local/share/Trash/info/${base_name}_$inode.trashinfo"
        #echo "$info_file"
        echo "[Trash Info]" >> "$info_file"
        echo "Path=$original_path" >> "$info_file"
        echo "DeletionDate=$(date +%EY%m%d%Z%T)" >> "$info_file"
}

#part 2
#check for optional args
opts() {
        while getopts :u options
        do
                case $options in
                        u) restore_req=true ;;
                        *) echo "$0: invalid option -- '$OPTARG'" # optarg is an internal variable that holds the value of the urecognized option
                           echo "Usage: sh $0 -u filepath"
                           exit 1 ;;
                esac
        done
}

#restore file
restore() {
        #check if file exists in the trash
        if [ ! -e "$HOME/.local/share/Trash/files/$1" ]
        then
                echo "$1 does not exist in the Trash. Unable to restore."
                exit 1
        fi

        original_path=$(cat "$HOME/.local/share/Trash/info/$1.trashinfo" | grep Path= | cut -d "=" -f 2 ) #extract the second field, using = as delimiter
        #check if duplicate file exists and ask to overwrite
        #echo "$original_path"
        if [ -e "$original_path" ]
        then
                echo "Do you want to overwrite? Yy/Nn"
                read response
                if [ $(echo $response | grep -E "(^y|^Y).*") ]
                then
                        pass="pass" #do nothing
                else
                        echo "Operation aborted"
                        exit 0
                fi
        fi
        mv -f "$HOME/.local/share/Trash/files/$1" "$original_path"
        rm "$HOME/.local/share/Trash/info/$1.trashinfo"
}

#main script flow
restore_req=false # true if we're restoring a file instead of trash

opts $@ #check for -u argument
shift $((OPTIND - 1)) #removes only arguments. no shift if there's no arguments

make_dir
check_arg_provided $# # $# is the number of args passed to the script

if [ $restore_req = true ]
then
        restore $1
        exit 0
fi #if we're not restoring, then proceed to the trash portion of the script below

check_exist $1
check_dir $1
check_mtt $1
trash_file $1