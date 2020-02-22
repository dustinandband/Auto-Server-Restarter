#!/bin/bash

#######################
#	auto-restart.sh
#   This script should be launched every minute from a cron job task 
#	& should be run from the same location steam is installed.
#
#   Session Names should be unique, one shouldn't overlap entirely from another.
#   e.g. L4D2_server & L4D2_server2 would be problematic.
#	However, L4D2_server1 & L4D2_server2 would be fine
#
#	==========================================================================
#	You should manually test the following before launching this script:
#
#	Auto-update functionality:
#		"screen --help", make sure the "-logfile" option is listed, otherwise set EnableUpdateCheck to 'no'
#		The -logfile screen option will be in later versions of screen (e.g. 4.06.02)
#
#	==========================================================================
#	FYI
#
#	1)
#	Workshop Collection ID # is the number at the very end of a workshop collection URL
#	e.g. 1381380872 would be the ID from
#	https://steamcommunity.com/sharedfiles/filedetails/?id=1381380872
#
#	2)
#	The fields for server #1 are filled in for demonstration.
#
#######################

#how many game servers?
num_of_servers=1

SessionName=(
'left4dead2_server'	#server 1
''					#server 2
)

# Path to /srcds_run
srcds_run=(
'/root/L4D2/srcds_run'	#server 1
''						#server 2 etc..
)

# Edit IP
Parameters=(
'-game left4dead2 -ip 144.202.87.239 -port 27015 +map c1m4_atrium +mp_gamemode survival'
''
)

#auto-update functionality:
UpdateScript=(
'./steamcmd.sh +login anonymous +force_install_dir /root/L4D2/ +app_update 222860 validate +quit'
''
)

#Allow auto-update check? 
#Not recommended if your update script triggers steam guard authentication, or your version of screen doesn't include the -logfile option.
#yes or no
EnableUpdateCheck=(
'yes'
''
)

#Enable full system reboot @3am (if all servers are detected as empty).?
#Note: regardless if this is on or off, all empty servers will be taken offline every hour to keep them refreshed
#yes or no
RebootAt3am=yes

ServerIP=144.202.87.239

ServerPort=(
'27015'
''
)

# Needed for Take_Empty_Servers_Offline() function, to detect if they're empty
RconPassword=(
'rcon_pass_here'
''
)

#optional
WorkShopDirectory=(
'/root/L4D2/left4dead2/addons/workshop'
''
)

#optional
#auto-update functionality with steam workshop collections
WorkshopCollection=(
'1381380872'
''
)

# Customization ends here

scriptcheck=`pgrep -c auto-restart.sh`
if [ $scriptcheck -gt 1 ]; then
	echo "auto-restart.sh script already in use. Terminating.."
	exit
fi

#########################
#    	functions    #
#########################

Python_Dependency_Test()
{
	if [ ! -e "IsServerEmpty.py" ]; then
		curl -o IsServerEmpty.py 'https://raw.githubusercontent.com/dustinandband/Auto-Server-Restarter/master/sh%20and%20python%20scripts/IsServerEmpty.py'
		chmod +x IsServerEmpty.py
	fi
	
	for ((j=0;j<$num_of_servers;j++)); do
		
		# workshop dependency test
		if [ -n "${WorkShopDirectory[$j]}" ] && [ -n "${WorkshopCollection[$j]}" ]; then
			if [ ! -e "workshop.py" ]; then
				# This version of the workshop DLer caps failed downloads at 25,
				# so it won't get hung up forever if valve server is down..
				curl -o workshop.py 'https://raw.githubusercontent.com/nosoop/steam_workshop_downloader/commed-patch/workshop.py'
				chmod +x workshop.py
			fi
			
			# make sure the workshop folder exists in addons directory
			if [ ! -d ${WorkShopDirectory[$j]} ]; then
				echo "'workshop' folder doesn't exist yet within your addons/ directory."
				echo "Manually creating 'workshop' folder:"
				echo "${WorkShopDirectory[$j]}"
				sleep 4
				mkdir -p ${WorkShopDirectory[$j]}
			fi
		fi
		
		# IsServerEmpty.py dependency test
		# TODO I think this would give a false positive if python3 wasn't installed. The user will prob figure it out if that's the case..
		test_IsServerEmpty=$(./IsServerEmpty.py $ServerIP ${ServerPort[$j]} ${RconPassword[$j]}) || {
			echo " "
			echo "Missing python valve module (needed for empty server check)"
			echo "Commands to install"
			echo "sudo apt install python3-pip"
			echo "pip3 install setuptools"
			echo "pip3 install Python-valve"
			
			exit 1
		}
		
		#TODO this won't actually test the rcon password if the server's offline.
		if [[ $test_IsServerEmpty =~ "exception" ]] && [[ $test_IsServerEmpty =~ "password" ]]; then
			echo " "
			echo "IsServerEmpty.py threw exeption, please update your rcon password:"
			echo $test_IsServerEmpty
			exit 1
		fi
	done
	
	echo "python dependencies passed"
}

Launch_Any_Offline_Servers()
{
	for ((j=0;j<$num_of_servers;j++)); do
		echo
		echo "---------------------------------------------"
		echo "Determining if ${SessionName[$j]} is offline."
		
		# This method can (rarely) return a false positive ( https://i.imgur.com/UDsFTil.png )
		# hence 3 seperate checks.
		
		alive=`ps ux | grep "${SessionName[$j]}" | wc -l | awk '{ print $1 }'`
		sleep 2s
		alive2=`ps ux | grep "${SessionName[$j]}" | wc -l | awk '{ print $1 }'`
		sleep 2s
		alive3=`ps ux | grep "${SessionName[$j]}" | wc -l | awk '{ print $1 }'`
		
		if [ $alive -lt 2 ] && [ $alive2 -lt 2 ] && [ $alive3 -lt 2 ]; then
		
			#Server's definitely offline. Check for any workshop updates before launching server
			echo "Server is offline. Checking for updates before launching server.."
			echo " "
			if [ -n "${WorkShopDirectory[$j]}" ] && [ -n "${WorkshopCollection[$j]}" ]; then
				./workshop.py -o "${WorkShopDirectory[$j]}" "${WorkshopCollection[$j]}"
			fi
			echo " "
			
			#auto-update check
			if [ -e ${SessionName[$j]}.output ] && [ ${EnableUpdateCheck[$j]} = "yes" ]; then
				#check for the word 'MasterRequestRestart' from last screen session
				if [ $(grep -c "MasterRequestRestart" "${SessionName[$j]}.output") -gt 0 ]; then
					echo "Update Needed, Updating server.."
					${UpdateScript[$j]}
				fi
				#Remove previous screen session log so it doesn't keep finding that word from past sessions.
				rm ${SessionName[$j]}.output
			fi
			
			# Finally, launch server
			if [ ${EnableUpdateCheck[$j]} = "yes" ]; then
				screen -mdSL ${SessionName[$j]} -Logfile ${SessionName[$j]}.output ${srcds_run[$j]} ${Parameters[$j]}
			else
				screen -mdS ${SessionName[$j]} ${srcds_run[$j]} ${Parameters[$j]}
			fi
			
			# check if server actually got launched
			sleep 1
			alive4=`ps ux | grep "${SessionName[$j]}" | wc -l | awk '{ print $1 }'`
			if [ $alive4 -lt 2 ]; then
				echo "Something went wrong. Make sure you have this script configured correctly."
				exit 1
			fi
			
			echo "${SessionName[$j]} is now running."
		else
			echo "Server already online. Skipping.."
		fi
	done
	echo "Server Check Complete"
}

Check_Input()
{
	if [ -z "${num_of_servers}" ] || [ -z "${ServerIP}" ] || [ -z "${RebootAt3am}" ]; then
		echo "Error: One of following left blank: 'num_of_servers', 'ServerIP', 'RebootAt3am'."
		exit 1
	fi

	#Make sure all non-optional fields are completed.
	typeset -n x
	for x in SessionName srcds_run Parameters UpdateScript EnableUpdateCheck ServerPort RconPassword; do
		for((j=0;j<$num_of_servers;j++)); do
			if [ -z "${x[$j]}" ]; then
				echo "Error: One or more non-optional items left blank."
				exit 1
			fi
		done
	done
	echo "Initialization Check successfull."
}

Take_Empty_Servers_Offline()
{
	EmptyCount=0
	for ((j=0;j<$num_of_servers;j++)); do
		
		# verify that the server's alive so we don't get banned for too many refused rcon attempts..
		alive=`ps ux | grep "${SessionName[$j]}" | wc -l | awk '{ print $1 }'`
		sleep 2s
		alive2=`ps ux | grep "${SessionName[$j]}" | wc -l | awk '{ print $1 }'`
		
		if [ $alive -gt 1 ] && [ $alive2 -gt 1 ]; then
			Result=$(./IsServerEmpty.py $ServerIP ${ServerPort[$j]} ${RconPassword[$j]})
			if [[ $Result =~ "The server is empty" ]]; then
				sleep 10s
				#check one more time JUST TO BE SURE
				Result2=$(./IsServerEmpty.py $ServerIP ${ServerPort[$j]} ${RconPassword[$j]})
				if [[ $Result2 =~ "The server is empty" ]]; then
					# Quit screen session and increment count.
					screen -r ${SessionName[$j]} -X quit
					((EmptyCount++))
				fi
			else
				echo "${SessionName[$j]} is not empty."
			fi
		fi
	done
	
	# if any servers where offline this won't pass
	# keeping it here for now in case i want to fix this later
	if [ $EmptyCount -eq $num_of_servers ] && [ $RebootAt3am = "yes" ] && [ $Time_Var == 300 ];then
		/sbin/shutdown -r now
	fi
	
	sleep 40s #To prevent this function from launching again within the  same minute
}

#########################
#        Script
#########################

Check_Input
Python_Dependency_Test

Time_Var=$(date +%-H%M)

# empty servers get rebooted every hour (2am, 3am, 4am, etc..) to keep them refreshed
if (( ${Time_Var#0} % 100 == 0 )); then
	Take_Empty_Servers_Offline
else
	Launch_Any_Offline_Servers
fi