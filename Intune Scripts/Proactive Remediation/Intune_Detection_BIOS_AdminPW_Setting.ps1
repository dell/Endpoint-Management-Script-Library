<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_version_ = 1.0
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

<#
.Synopsis
   This PowerShell script checks if BIOS AdminPW is set on this machine using WMI
   IMPORTANT: This script needs a client which supports the WMI Namespace "root/dcim/sysman/wmisecurity" and the WMI class "PasswordObject".
   IMPORTANT: WMI BIOS is supported only on devices which developed after 2018, older devices do not supported by this powershell script.
   IMPORTANT: This script does not reboot the system to apply or query system.

.DESCRIPTION
   PowerShell to import as Dection Script for Microsoft Endpoint Manager. This Script need to be imported in Reports/Endpoint Analytics/Proactive remediation. This File is for detection only and need a seperate script for remediation additional.
   NOTE: The pre-remediation detection script output is available in Intune reports in the "Pre-remediation detection output" column.
   NOTE: The post-remediation detection script output is available in Intune reports in the "Post-remediation detection output" column.
   NOTE: The remediation script log message are available on the endpoint at this path: "C:\Temp\BIOS_Profile.txt" 
#>

try{
   
    # Check BIOS AttributName AdminPW is set
    $BIOSAdminPW = Get-CimInstance -Namespace root/dcim/sysman/wmisecurity -ClassName PasswordObject -Filter "NameId='Admin'" | Select-Object -ExpandProperty IsPasswordSet
    
    if($BIOSAdminPW -eq $null)
	{
		Write-Error -Category ResourceUnavailable -CategoryTargetName "root/dcim/sysman/wmisecurity" -CategoryTargetType "PasswordObject" -Message "Unable to get the 'Admin' object in class 'PasswordObject' in the Namespace 'root/dcim/sysman/wmisecurity'" 
		exit 1
	}
    elseif ($BIOSAdminPW -match "1")
        {
            write-host "BIOS Admin password is set on this machine."
    	    exit 0  
        }
    else
        {
            Write-Host "No BIOS Admin PW is set on this machine. Running the remediation script to set the password.."
            exit 1
        }
    }
catch
{
    $errMsg = $_.Exception.Message
    write-Error $errMsg
    exit 1
}