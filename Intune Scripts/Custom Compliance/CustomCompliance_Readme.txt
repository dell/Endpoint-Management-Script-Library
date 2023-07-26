The scripts in this folder need to be uploaded with JSON file in the Intune Compliance policies and scripts. 
The folder contains the following scripts:

1. Intune_Compliance_Sensor_Battery_Health.ps1:
This Powershell script uses Dell Command | Monitor to make WMI request of mobile battery health status on the device. This script must be uploaded in Intune Compliance or Script and needs an additional JSON file for reporting.
This script is limited to laptops with a single battery. It verifies if the system is compliant or not as per the rules that are mentioned in the JSON file (Intune_Compliance_Battery_Health.json).

2. Intune_Compliance_Sensor_DCM_Warranty_expire.ps1
This Powershell script uses Dell Command | Monitor to check the support contract time of the device. This script must be uploaded in Intune Compliance or Script and needs an additional JSON file for reporting.
This script looks for the last ending warranty and checks if the warranty is active. It does not look for multiple warranties with different expiry dates.
This script verifies if the system is compliant or not as per the rules that are mentioned in the JSON file (Intune_Compliance_Battery_Health.json).

3. Intune_Compliance_Sensor_WMI_Chassis_Intrusion.ps1
This Powershell script uses WMI to check the BIOS settings - chassisintrusion and ChassisIntrusionStatus. The script must be uploaded in Intune Compliance or Script and needs an additional JSON file for reporting.
It verifies if the system is compliant or not as per the rules that are mentioned in the JSON file (Intune_Compliance_Chassis_Intrusion.json). 
It checks if the BIOS setting Intrusion detection is Silentenabled currently and Intrusion Status is Door Closed.

4. Intune_Compliance_Sensor_WMI_HDD_Health.ps1
This Powershell script uses WMI to check the Hard Drive health status on the device. The script must be uploaded in Intune Compliance or Script and needs an additional JSON file for reporting.
It verifies if the system is compliant or not as per the rules that are mentioned in the JSON file (Intune_Compliance_HDD_Health.json). 

5. Intune_Compliance_Sensor_Memory_Health.ps1
This Powershell script uses Dell Command | Monitor to make WMI request of memory health status on the device. This script must be uploaded in Intune Compliance or Script and needs an additional JSON file for reporting.
It verifies if the system is compliant or not as per the rules that are mentioned in the JSON file (Intune_Compliance_Memory_Health.json).