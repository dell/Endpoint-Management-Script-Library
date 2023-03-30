The scripts in this folder must be run from the Intune Proactive Remediations. The scripts are only for detection and do not contain any remediation script. 
The folder contains the following scripts:

1. Intune_Retreive_BIOS_version.ps1:
This script uses the DCIM_BIOSElement class to retrieve the BIOS version in JSON format. An example of the BIOS version retrieved in JSON format is- {"Version":"1.2.2"}

2. Intune_Retreive_Manufacturer.ps1:
This script uses the DCIM_Chassis class to retrieve the manufacturer’s information in JSON format. An example of the manufacturer’s details retrieved in JSON format is- {"Manufacturer":"Dell Inc."}

3. Intune_Retreive_serviceTag.ps1:
This script uses the DCIM_Chassis class to retrieve the Service Tag of the system in JSON format. An example of the Service Tag retrieved in JSON format is- {"ServiceTag":"8GBK2A4"}

4. Intune_Retreive_CPUInfo.ps1:
This script uses the DCIM_Processor class to retrieve the CPU information of the system in JSON format. An example of the CPU information retrieved in JSON format is- {"UniqueID":"PortProcessorObj",
 "ProcessorName":"Processor 1 : Genuine Intel(R) CPU 0000 @ 2.60GHz Stepping 0","NumberOfEnabledCores":8,"SystemName":"nb:W47Y0WN","CPUStatus":"CPU Enabled",
 "CurrentClockSpeed":4059,"RequestedState":"Not Applicable","PrimaryStatus":"OK","Family":1,"EnabledState":"Enabled","TransitioningToState":"Not Applicable",
 "OperationalStatus":"OK","HealthState":"OK","Stepping":"","ExternalBusClockSpeed":100,"EnabledDefault":"Enabled","UpgradeMethod":1,"MaxClockSpeed":3100}


