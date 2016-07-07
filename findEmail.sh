#!/bin/bash

############################################
## Help/Usage Menu
#############################################
helpmenu () {

        echo "This script will retrieve LDAP user/group email addresses"
        echo ""
        echo "Usage:"
        echo "findemail -h                      |       findemail --help"
        echo "findemail -u <LDAP username>      |       findemail --user <LDAP username>"
        echo "findemail -g <LDAP groupname>     |       findemail --group <LDAP groupname>"
}

############################################
#
# User Lookup
#
############################################
userlookup () {

        useremail=( $(/usr/bin/ldapsearch -x "cn=$1" | grep mail | awk '{print $2}') )
        if [ ${#useremail[@]} == 0 ]; then
                echo "Invalid username or no email on record."
        else
                echo "${useremail[*]}"
        fi
}

############################################
## Group Lookup
#############################################
grouplookup () {

        members=( $(getent netgroup $1 | sed 's/[\(\,\)]*//g' ) )
        members=("${members[@]:1}")
        if [ ${#members[@]} == 0 ]; then
                membersP=( $(getent group $1 | sed 's/*//g; s/\,/ /g; s/\:/ /g') )
                membersP=("${membersP[@]:2}")
                        if [ ${#membersP[@]} == 0 ]; then
                                echo "Unable to find LDAP group."
                                exit
                        else
                                for username in ${membersP[*]}
                                do
                                        emails+=( $(/usr/bin/ldapsearch -x "cn=$username" | grep mail | awk '{print $2}') )
                                done
                        fi
        else
                for username in ${members[*]}
                do
                        emails+=( $(/usr/bin/ldapsearch -x "cn=$username" | grep mail | awk '{print $2}') )
                done
        fi
        echo ${emails[*]}
}

############################################
## Main Part of Script
#############################################
while [ ! $# -eq 0 ]
do
    case "$1" in
        --help | -h)
            helpmenu
            exit
            ;;
        --user | -u)
            userlookup $2
            exit
            ;;
        --group | -g)
            grouplookup $2
            exit
            ;;
        *)
            echo "Invalid script usage. Please run findemail -h or findemail --help"
            exit
            ;;
    esac
    shift
done
