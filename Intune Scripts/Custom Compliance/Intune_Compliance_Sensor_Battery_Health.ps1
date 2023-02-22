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
   This PowerShell is for custom compliance scans and checking is mobile battery healthy.
   IMPORTANT: This script need a client installation of Dell Command Monitor first. https://www.dell.com/support/kbdoc/en-us/000177080/dell-command-monitor
   IMPORTANT: This script does not reboot the system to apply or query system.
.DESCRIPTION
   Powershell using Dell Command Monitor to made WMI request of mobile battery Health status on the device. This script need to be upload in Intune Compliance / Script and need a JSON file additional for reporting this value.
   NOTE: This script is limited to laptops with a single battery.
   NOTE: This script verifies if the system is compliant or not as per the rules mentioned in the JSON file. 
#>

#checking WMI status with Dell Command Monitor and switch value to a useful text.
$BatteryHealth = Switch (Get-CimInstance -Namespace root\dcim\sysman -ClassName DCIM_Battery | Select -ExpandProperty HealthState)
    {
    0 {"Unknown"}
    5 {"OK"}
    10 {"Degraded/Warning"}
    15 {"Minor failure"}
    20 {"Major failure"}
    25 {"Critical failure"}
    30 {"Non-recoverable error"}
    }

#prepare variable for Intune
$hash = @{ BatteryHealth = $BatteryHealth }

#convert variable to JSON format
return $hash | ConvertTo-Json -Compress

