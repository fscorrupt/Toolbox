# Check and Remidiate Machines that have a pending reboot.

## Exported Configuration Item + Scripts Used in that CI.

This CI will run on desired collection, it checks if a reboot is pending.
If a reboot is pending, the machine is uncompliant and the remediation script starts.

The remidiation script will check if the machine is currently in maintenance.
If the machine is in maintenance, it will check if there are currently updates installing and if a user is logged on.

If both are false and server is in maintenance, the script will trigger a reboot.
