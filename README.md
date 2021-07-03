# Auto-Server-Restarter  

Outdated. TODO: use serve queries instead of rcon password to check if server's empty.  

Tested on Ubuntu 18.04

## Features
### auto-restart.sh
- Checks for any updates to workshop collection maps before relaunching server.
- Also checks for official game server updates before relaunch.
- Every hour, it loops through all empty servers and shuts them off (they get rebooted within a minute) in order to keep them refreshed.

### resetonempty.sp
- In-game plugin that simply quits the server (aka screen session) once all players disconnect.

# Logic
A cron-job that runs once a minute launches the auto-restart.sh script, which then makes sure any offline servers are brought back online.

Before the server is brought back online, the auto-restart script optionally checks for any workshop collection (custom maps) and game updates.

Once every hour (at 1am, 2am, 3am, etc.) the script loops through all empty servers and shuts them down. I did this so that the servers can remain refreshed and also because if there where any game updates while a server was empty, it would never get rebooted.

There are two python scripts that get downloaded automatically - one for determining if the server is empty and another for checking for workshop map updates.

Certain in-game plugins claim to detect game updates update your server automatically, but unless you have your server to set to not hybernate, those callbacks never get executed.
Example:
[[ANY] SteamWorks.ext Update Check](https://forums.alliedmods.net/showthread.php?t=269826 "[ANY] SteamWorks.ext Update Check")
```c++
public OnMapStart()
{
    CreateTimer(120.0, OnCheckForUpdate, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}  

// never gets called if a game update happens while the server's empty
// unless sv_hibernate_when_empty convar is set to 0
public Action:OnCheckForUpdate(Handle:hTimer)
{
	// ...
}
```

Other in-game plugins work around the issue by setting the hybernate cvar manually:
[l4d2_server_restarter.sp](https://github.com/LuckyServ/sourcemod-plugins/blob/master/source/l4d2_server_restarter.sp "l4d2_server_restarter.sp")
```c++
public void OnPluginStart()
{
	new ConVar:cvarHibernateWhenEmpty = FindConVar("sv_hibernate_when_empty");
	SetConVarInt(cvarHibernateWhenEmpty, 0, false, false);
}
```

The resetonempty plugin detects whatever the servers cvars are, temporarily changes them when determining if a servers offline - then changes them back.

Since callbacks dont get executed when a servers in hybernation mode - it only made sense to have the auto-restart.sh script take care of any update functionality, as well as manually forcing any empty servers to go offline once every hour.

# Installation
1. Download the **auto-restart.sh** script
2. Edit it accordingly (if editing in Windows make sure EOL conversion is set to 'unix')
3. Compile and install the **resetonempty.sp** plugin.
4. After youre sure the script is working, set up a cron-job that runs every minute and launches the auto-restart.sh script.

e.g.
 ```sh
	# Check every minute to see if the server is down
    * * * * * /path/to/auto-restart.sh
```

If you want to have the script check for official game updates, you need to be sure your version of screen include the "**-logfile**" option (different than the -L option)

Id recommend running the script manually, twice, before setting up a cron job to launch it every minute. (Once to make sure its launching offline servers correctly - and a second time to make sure you set your rcon password correctly.)

There are some dependencies for the IsServerEmpty.py to work correctly, though it will print out instructions for downloading those dependencies and even download the python scripts (**IsServerEmpty.py **& **workshop.py**) automatically.

If you want to download the **IsServerEmpty.py** dependencies manually:

 ```sh
    sudo apt install python3-pip
    pip3 install setuptools
    pip3 install Python-valve
```

Easy download of the **auto-restart.sh** script:
 ```sh
curl -o auto-restart.sh 'https://raw.githubusercontent.com/dustinandband/Auto-Server-Restarter/master/sh%20and%20python%20scripts/auto-restart.sh'
chmod +x auto-restart.sh
```
