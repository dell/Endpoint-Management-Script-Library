This folder contains the following scripts. These scripts need to be uploaded with JSON file in the Inutne Compliance policies & Compliance scripts.

1. Intune_Compliance_Sensor_Battery_Health.ps1:
This Powershell script uses Dell Command Monitor to made WMI request of mobile battery Health status on the device. This script need to be upload in Intune Compliance / Script and need a JSON file additional for reporting this value.
This script is limited to laptops with a single battery. This script verifies if the system is compliant or not as per the rules mentioned in the JSON file(Intune_Compliance_Battery_Health.json)

2. Intune_Compliance_Sensor_DCM_Warranty_expire.ps1
This Powershell script uses Dell Command Monitor WMI to check the support contract time of the device. This script need to be upload in Intune Compliance / Script and need a JSON file additional for reporting this value.
This script looks only for the last ending warranty and checks if this warranty is currently active. This script does not look for multiple warranties with different expiry dates.
This script verifies if the system is compliant or not as per the rules mentioned in the JSON file (Intune_Compliance_Battery_Health.json)
This script looks for the last ending warranty and checks if this   warranty is currently active.

3. Intune_Compliance_Sensor_WMI_Chassis_Intrusion.ps1
Powershell using WMI to check the BIOS value of chassis intrusion and ChassisIntrusionStatus. This script needs to be uploaded in Intune Compliance / Script and needs a JSON file additional for reporting this value.
This script verifies if the system is compliant or not as per the rules mentioned in the JSON file(Intune_Compliance_Chassis_Intrusion.json). 
This script checks if the BIOS setting Intrusion detection is "Silentenabled" currently and Intrusion Status is "Door Closed".

