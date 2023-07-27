<#
_author_ = Mahesh AC <mahesh_a_c@Dell.com>
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
   This PowerShell is for custom compliance scans and is checking Heath Status of the Memory in the Device.
   IMPORTANT: This script need a client installation of Dell Command Monitor https://www.dell.com/support/kbdoc/en-us/000177080/dell-command-monitor
   IMPORTANT: WMI BIOS is supported only on devices which developed after 2018, older devices do not supported by this powershell script.
   IMPORTANT: This script does not reboot the system to apply or query system.
.DESCRIPTION
   Powershell script using Dell Command Monitor to check the Health Status of the Memory. This script needs to be uploaded in Intune Compliance / Script and needs a JSON file additional for reporting this value.
   NOTE: This script verifies if the system is compliant or not as per the rules mentioned in the JSON file. 
#>


#checking the Health Status of the Memory in the device through WMI 
$health = Get-CimInstance -Namespace root/DCIM/SYSMAN -ClassName dcim_memory | select ElementName,DeviceID,HealthState
$errorcheck = 0

if($health -eq $null)
{
 write-host " Memory Detection is failed - System Does not have any RAMs/DCM is Not Installed"
 exit 1
}
else
{
$instances = $health.ElementName
foreach($x in 0..($instances.count - 1))
{
if ($health.HealthState[$x] -eq 5)
{ 
Write-host "PASS- Memory Health State is Good for",$health.ElementName[$x]
}
else
{
Write-host "FAIL- Memory Health State is BAD for",$health.ElementName[$x]
$errorcheck=1
}
}
}
if ($errorcheck -eq 0)
{

Write-Host "Overall Status is Good"
}
else
{
Write-Host "There is failure with one of the RAMS"

}
write-host "MAHESH"

$MemoryHealth = switch($errorcheck)
{
    0 {"Healthy"}
    1 {"Not Healthy"}
}

#prepare variable for Intune
$hash = @{ HealthStatus = $MemoryHealth }

#convert variable to JSON format
return $hash | ConvertTo-Json -Compress

