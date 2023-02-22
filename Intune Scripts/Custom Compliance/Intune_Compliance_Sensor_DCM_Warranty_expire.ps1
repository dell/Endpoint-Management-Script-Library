<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_version_ = 1.0.0
_Dev_Status_ = Test
Copyright © 2023 Dell Inc. or its subsidiaries. All Rights Reserved.

No implied support and test in test environment/device before using in any production environment.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

<#Version Changes

1.0.0   inital version


#>

<#
.Synopsis
   This PowerShell is for custom compliance scans and is checking the support contract time of this device by Dell Command Monitor (DCM)
   IMPORTANT: This script need a client installation of Dell Command Monitor https://www.dell.com/support/kbdoc/en-us/000177080/dell-command-monitor
   IMPORTANT: This script does not reboot the system to apply or query system.
.DESCRIPTION
   Powershell using Dell Command Monitor WMI to check the support contract time of the device. This script need to be upload in Intune Compliance / Script and need a JSON file additional for reporting this value.
   NOTE: This script looks only for the last ending warranty and checks if this warranty is currently active. This script does not look for multiple warranties with different expiry dates.
   NOTE: This script verifies if the system is compliant or not as per the rules mentioned in the JSON file. 
#>



# prepare Dell Warranty date for compare with actual date
$WarrantyEnd = Get-CimInstance -Namespace root\dcim\sysman -ClassName DCIM_AssetWarrantyInformation | Sort-Object WarrantyEndDate -Descending | select -ExpandProperty WarrantyEndDate 
$WarrantyEndSelect = $WarrantyEnd[0] -split ","
$WarrantyDate = $WarrantyEndSelect -split " "
[datetime]$FinalDate = $WarrantyDate.GetValue(0)

# Check availible support days
$Today = Get-Date
$Duration = New-TimeSpan -Start $Today -End $FinalDate
$last30Days = New-TimeSpan -Start $Today -End $FinalDate.AddDays(-30)

#prepare variable for Intune
$hash = @{ Support = $Duration.Days; Last30Days = $last30Days.Days }

#convert variable to JSON format
return $hash | ConvertTo-Json -Compress