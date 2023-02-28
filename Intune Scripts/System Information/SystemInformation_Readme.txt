The scripts in this folder must be run from the Intune Proactive Remediations. These scripts are only for detection and do not contain any remediation scripts. 
The folder contains the following scripts:

1. Intune_Retreive_BIOS_version.ps1:
This script uses the DCIM_BIOSElement class to retrieve the BIOS version in JSON format. An example of the BIOS version retrieved in JSON format:
{"Version":"1.2.2"}


2. Intune_Retreive_Manufacturer.ps1:
This script uses the DCIM_Chassis class to retrieve the manufacturer’s information in JSON format. An example of the manufacturer’s details retrieved in JSON format:
{"Manufacturer":"Dell Inc."}


3. Intune_Retreive_serviceTag.ps1:
This script uses the DCIM_Chassis class to retrieve the Service Tag of the system in JSON format. An example of the Service Tag retrieved in JSON format:
{"ServiceTag":"8GBK2A4"}

