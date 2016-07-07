##replacing company specific info with ###CHANGEME###
#!/bin/bash
####################################################################
# Author: Tina 
#
# This script will fix tripwire installs for RHEL 6
# servers to the new RH Satellite deployment of Tripwire.
#
# Before you run this:
# Make sure the server is in the els tripwire 6 configuration channel
#
####################################################################


###############
# Variables
###############

FILES=(
    /Admin/tmp/fix-tripwire.sh
    /Admin/bin/runtw.sh
    /Admin/bin/monday_only.runtw.sh
    /etc/cron.daily/tripwire-check
    /etc/cron.daily/tripwire-watch
    /etc/cron.weekly/tripwire-report
    /etc/tripwire/twcfg.txt
    /etc/tripwire/twpol.txt
    /usr/local/nagios/libexec/check_tw
    /usr/local/sbin/siggen
    /usr/local/sbin/tripwire
    /usr/local/sbin/tripwire-setup-keyfiles
    /usr/local/sbin/twadmin
    /usr/local/sbin/twprint
    /usr/local/doc/tripwire
    /home/unv/tripwire-2.4.2.2-src
    /usr/local/share/man/man4/twconfig.4.gz
    /usr/local/share/man/man4/twpolicy.4.gz
    /usr/local/share/man/man5/twfiles.5.gz
    /usr/local/share/man/man8/siggen.8.gz
    /usr/local/share/man/man8/tripwire.8.gz
    /usr/local/share/man/man8/twadmin.8.gz
    /usr/local/share/man/man8/twintro.8.gz
    /usr/local/share/man/man8/twprint.8.gz
    /usr/local/lib/tripwire
    /usr/local/lib/tripwire/report
)

GETFILES=(
    /Admin/bin/runtw.sh
    /Admin/bin/monday_only.runtw.sh
    /etc/tripwire/twcfg.txt
    /etc/tripwire/twpol.txt
    /usr/local/nagios/libexec/check_tw
)
###############
# Start Script
###############

while true; do
    read -p "Is `hostname -s` subscribed to 'els tripwire 6' config channel and 'Extra Packages'? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer [y]es or [n]o. ";;
    esac
done

if grep -i "Red Hat Enterprise Linux Server release 6" /etc/redhat-release
    then
        echo "`hostname -s` is running RHEL 6. Please have the Site and Local keys handy..."
    else
        echo "Sorry `hostname -s` is not running RHEL 6. Make sure the host is in the correct config channel. Exiting..."
        exit
fi

if [ -f /usr/local/sbin/tripwire ]
    then
        echo "Found previous version of Tripwire installed (from tar).  Removing files..."
        rm -rf ${FILES[@]}
        echo "Getting new files from the Satellite server..."
        rhncfg-client get ${GETFILES[@]}

        echo "Installing and setting up Tripwire..."
        yum install tripwire -y && /usr/sbin/tripwire-setup-keyfiles
                read -p "Would you like to run tripwire --init (y/n) " ny
        while true; do
            case $ny in
                [Yy]* ) /usr/sbin/tripwire --init
                        break;;
                [Nn]* ) exit;;
                * ) echo "Please answer [y]es or [n]o. ";;
            esac
        done
elif [ -f /usr/sbin/tripwire ]
    then
        echo "Tripwire has been found in the expected path."
        read -p "Would you like to [1]Reinstall Tripwire, [2]Reinitalize Tripwire, [Q]Quit? " q12
        while true; do
            case $q12 in
                [1]* )  yum remove tripwire -y
                        rhncfg-client get ${GETFILES[@]}
                        yum install tripwire -y && /usr/sbin/tripwire-setup-keyfiles && /usr/sbin/tripwire --init
                        break;;
                [2]* )  /usr/sbin/tripwire --init
                        break;;
                [Qq]* ) exit;;
                * ) echo "Invalid Answer - Select 1, 2, or Q ";;
            esac
        done
else
        echo "Tripwire is not installed."
        read -p "Would you like to install Tripwire (y/n) " in1
        while true; do
        read -p "Would you like to run tripwire --init (y/n) " ny
            case $in1 in
                [Yy]* ) yum remove tripwire -y
                        rhncfg-client get ${GETFILES[@]}
                        yum install tripwire -y && /usr/sbin/tripwire-setup-keyfiles && /usr/sbin/tripwire --init
                        break;;
                [Nn]* ) exit;;
                * ) echo "Please answer [y]es or [n]o. ";;
            esac
        done
fi

rm -f /etc/cron.daily/tripwire-check
rm -f /etc/cron.monthly/tripwire*

while true; do
        read -p "Would you like to send out a test report? (y/n) " nY
        case $nY in
                [Yy]* ) /Admin/bin/runtw.sh
                          break;;
                [Nn]* ) exit;;
                * ) echo "Please answer [y]es or [n]o. ";;
        esac
done
