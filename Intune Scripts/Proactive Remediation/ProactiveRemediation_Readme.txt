The scripts in this folder must be run from the Intune Proactive Remediations. It requires both the detection script and remediation script.
The folder contains the following scripts:

1. Intune_Detection_BIOS_AdminPW_Setting.ps1:
The detection script checks if the BIOS admin password is set on the system, followed by the remediation script if the BIOS password is not set. 

2. Intune_Detection_BIOS_AdminPW_Change.ps1: 
The detection script checks if the BIOS Admin password is older than 180 days and must be changed.
Note: This script must be used only after the remediation script for setting the BIOS password (Intune_Remediation_BIOS_AdminPW_Setting.ps1) is run, as it looks for the Update parameter from the registry key. 
Note: 180 days is the default time interval and can be changed as per the requirements.

3. Intune_Remediation_BIOS_AdminPW_Setting.ps1:
The remediation script sets the new BIOS admin password if the password is not already set and creates a registry key- HKLM:\SOFTWARE\Dell\BIOS.
Also, it updates the password if the existing password from the registry key is older than the time interval set.

4. Intune_5_Detection_BIOS_Thermalmode_Setting.ps1:
The detection script checks if the client BIOS Thermal Management setting is set as Quiet, using Dell | Command Monitor.
Note: This script needs a client installation of Dell | Command Monitor.

5. Intune_5_Remediation_BIOS_Thermalmode_Setting.ps1:
The remediation script sets the BIOS Thermal Management setting as Quiet if not already set, using Dell | Command Monitor.
Note: This script needs a client installation of Dell | Command Monitor.
