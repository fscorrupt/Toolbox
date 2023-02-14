# HuntHighPingChecker
This is a script that measures high ping to specific ip and their tracert targets.

# Configuration
I tried to make the scripts as easy to use as possible.

The script relys on 4 Variables.

| Setting      | Description |
| ----------- | ----------- |
| $whoispath      | The Folder where the script downloads&extract Sysinternal tool `WhoIs`       |
| $ExeToMonitor   | Huntgame.exe (must be running)        |
| $PortToMonitor    | Defaulted to 610        |
| $MaxPing  | Enter The reply ping  you are ok with, everything above that value will be shown as `Error`        |

# Script Flow

1. It will check if the defined process/exe is running, if not `Error`
2. It will start and capture a `netstat -ano`
3. A search in the `netstat` data with pattern like "Process PID and Port" is performed.
4. IPv4/IPv6 is detected because it has to be dealt with  differently
5. Public IP and ISP Name getting determined
6. A Tracert to the detected IP from Step 4 is made and the data is saved.
7. `WhoIs.zip` will be downloaded from Microsoft and extracted, after extraction the zip file gets removed.
8. Now the ping measurement starts with the captured hops from tracert in Step 6.
9. A nice output gets displayed to the user.

Hunt-HighPingChecker.ps1

![)

# Issues
Probably. Just let me know and I will try to correct.

# Enjoy
This one is simple.
