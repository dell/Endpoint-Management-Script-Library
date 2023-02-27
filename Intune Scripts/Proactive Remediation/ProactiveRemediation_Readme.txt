The scripts in this folder need to be run from the Intune Proactive Remediations. These require both the detction script and remediation script.
The folder contains the following scripts:

1. Intune_Detection_BIOS_AdminPW_Setting.ps1:
The detection script checks if the BIOS admin password is set on the machine. It is followed by the execution of remediation script in case the BIOS password is not set. 

2. Intune_Detection_BIOS_AdminPW_Change.ps1: 
This detection script checks if the BIOS Admin password is older than 180 days and need to be changed.
Note: This script should be used only after the remediation script for setting the BIOS password(Intune_Remediation_BIOS_AdminPW_Setting.ps1) is executed, since this looks for the "Update" parameter from the registry key. 
Note: 180 days is the default time interval and can be changed as per the requirements.

3. Intune_Remediation_BIOS_AdminPW_Setting.ps1:
This remediation script sets the new BIOs admin password if the password is not already set and creates a registry key('HKLM:\SOFTWARE\Dell\BIOS').
Additionally, it also updates the password if the existing password from the registry key is older than the time interval set.

