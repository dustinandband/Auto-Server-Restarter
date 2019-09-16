#!/bin/bash

# Simple shell script for automating new server installation.
# Saving this here cause I wanted it to be accessable online.

# Installs game server as well as start.sh, quit.sh, and update.sh script all at once

# NEED TO INSTALL DEPENDENCIES MANUALLY BEFORE EXECUTING THIS SCRIPT
# https://linuxgsm.com/lgsm/l4d2server/

# In addition to LinuxGSM dependency list, this is needed for plugins to connect to databases. If you're on linux it's lib32z1
# apt-get install lib32z1
# Without the extension any database plugin will return this error:
# [SM] Unable to load extension "dbi.mysql.ext": libz.so.1: cannot open shared object file: No such file or directory
# [dbtest.smx] Error connecting to database: Could not find driver "mysql"

#screen name
screen_name=left4dead2_server

#name of bootup script
StartScript=start.sh

#name of quit script
QuitScript=quit.sh

#name of update script
Update_Script=update.sh

#ip address
IpAddr=xxx.xxx.xxx.xxx

#port (default is 27015)
Port=xxxxx

#Directory path
#(Leave out the dash on the very end, e.g. "/root/L4D2")
Dir_Path=/root/L4D2

#contents of start-up script
Start_Contents="screen -mdS ${screen_name} ${Dir_Path}/srcds_run -game left4dead2 -ip ${IpAddr} -port ${Port}"

#contents of quit script
Quit_Contents="screen -r ${screen_name} -X quit"

# update script
Update_Contents="./steamcmd.sh +login anonymous +force_install_dir ${Dir_Path}/ +app_update 222860 validate +quit"

echo
echo "creating start, quit, and update scripts.."
sleep 3s

echo $Start_Contents > $StartScript
echo $Quit_Contents > $QuitScript
echo $Update_Contents > $Update_Script

chmod +x $StartScript
chmod +x $QuitScript
chmod +x $Update_Script

echo
echo "Installing Steam"
wget http://media.steampowered.com/client/steamcmd_linux.tar.gz
tar -xvzf steamcmd_linux.tar.gz

echo
echo "Installing game server.."
sleep 3s
./$Update_Script
