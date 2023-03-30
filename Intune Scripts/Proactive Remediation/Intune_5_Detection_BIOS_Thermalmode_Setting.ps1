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

1.0.0   Initial version
1.0.1   Replacing WMI query with Dell | Command Monitor query to get the BIOS Thermal Management setting.

#>

<#
.Synopsis
   This PowerShell script checks if the client BIOS Thermal Management is set to "Quiet" using Dell | Command Monitor.
   IMPORTANT: This script needs a client installation of Dell | Command Monitor https://www.dell.com/support/kbdoc/en-us/000177080/dell-command-monitor
   IMPORTANT: This script does not reboot the system to apply or query any settings.
.DESCRIPTION
   This script needs to be imported in Reports/Endpoint Analytics/Proactive remediation. This File is for detection only and needs a seperate script for remediation.
   NOTE: The pre-remediation detection script output is available in Intune reports in the "Pre-remediation detection output" column.
   NOTE: The post-remediation detection script output is available in Intune reports in the "Post-remediation detection output" column.
#>

try
{
    # Check BIOS AttributName ThermalSetting is Value Quiet
    $BIOSThermalMode= Switch ( Get-CimInstance -Namespace root/dcim/sysman -ClassName DCIM_ThermalInformation -Filter "AttributeName='Thermal Mode'"| Select-Object -ExpandProperty CurrentValue)
    {
        0 {"Optimized"}
        1 {"Cool"}
        2 {"Quiet"}
        3 {"Performance"}
    }
    if($BIOSThermalMode -eq $null)
    {
        Write-Error -Category ResourceUnavailable -CategoryTargetName "root/dcim/sysman" -CategoryTargetType "DCIM_ThermalInformation" -Message "Unable to enumerate the class 'DCIM_ThermalInformation' in the namespace 'root/dcim/sysman'" 	
        exit 1
    }
    elseif ($BIOSThermalMode -match "Quiet")
    {
        Write-host "BIOS Thermal Mode is set to 'Quiet' mode."
    	exit 0  
    }
    else
    {
        Write-Host "BIOS Thermal Mode is not set to 'Quiet' mode. Running the remediation script.."
        exit 1
    }
}
catch
{
    $errMsg = $_.Exception.Message
    write-host $errMsg
    exit 1
}