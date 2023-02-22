<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_version_ = 1.0.1
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
1.0.1   The BIOS setting "chassis intrusion" is retrieved using DCM -"DCIM_BIOSEnumeration" class instead of WMI Namespace root/dcim/sysman/biosattributes and class "EnumerationAttribute".


#>

<#
.Synopsis
   This PowerShell is for custom compliance scans and is checking this device of BIOS setting Intrusion detection was enabled and Intrusion Status.
   IMPORTANT: This script need a client installation of Dell Command Monitor https://www.dell.com/support/kbdoc/en-us/000177080/dell-command-monitor
   IMPORTANT: WMI BIOS is supported only on devices which developed after 2018, older devices do not supported by this powershell script.
   IMPORTANT: This script does not reboot the system to apply or query system.
.DESCRIPTION
   Powershell using WMI to check the BIOS value of chassis intrusion and ChassisIntrusionStatus. This script needs to be uploaded in Intune Compliance / Script and needs a JSON file additional for reporting this value.
   NOTE: This script verifies if the system is compliant or not as per the rules mentioned in the JSON file. 
#>

# check chassis intrusion with WMI
$CheckChassisSetting = Get-CimInstance -Namespace root/dcim/sysman -ClassName DCIM_BIOSEnumeration -Filter "AttributeName like 'Chassis Intrusion'" | select -ExpandProperty CurrentValue
$CheckIntrusion = Get-CimInstance -Namespace root/dcim/sysman -ClassName DCIM_BIOSEnumeration -Filter "AttributeName like 'Chassis Intrusion Status'" | select -ExpandProperty CurrentValue

<#
ChasIntrusion
1 == Disabled = no logging
2 == Enabled = logging with post boot alert
3 == SilentEnable =logging without post boot alert



Chassis Intrusion Status

1 = Tripped
2 = Door open
3 = Door closed
4 = Trip reset

#>

#prepare variable for Intune
$hash = @{ IntrusionSetting = $CheckChassisSetting; IntrusionStatus = $CheckIntrusion }

#convert variable to JSON format
return $hash | ConvertTo-Json -Compress