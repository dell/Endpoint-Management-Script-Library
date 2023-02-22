<#
_author_ = Bulusu, SaiSameerKrishna <sai_sameer_krishna_b@dell.com>
_version_ = 1.0.0

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
   This PowerShell script retrieves the service tag of the system.
   IMPORTANT: This script need a client installation of Dell Command Monitor https://www.dell.com/support/kbdoc/en-us/000177080/dell-command-monitor
   IMPORTANT: WMI BIOS is supported only on devices which developed after 2018, older devices do not supported by this powershell script
   IMPORTANT: This script does not reboot the system to apply or query system.
.DESCRIPTION
   This Powershell script uses WMI call to retrieve the service tag in JSON format.
.EXAMPLE
	An example of the Service Tag retrived in JSON format:
	{"ServiceTag":"8GBK2A4"}  
#>

$ServiceTag= Get-CimInstance -Namespace root\dcim\sysman -ClassName DCIM_Chassis | Select -ExpandProperty Tag

if($ServiceTag -ne $null)
{
	$hash = @{ ServiceTag = $ServiceTag }

	return $hash | ConvertTo-Json -Compress
}
else
{
    exit 1
}