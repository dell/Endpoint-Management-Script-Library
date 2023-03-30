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
1.0.1   Replacing WMI commands with Dell | Command Monitor commands to get/set the BIOS Thermal Management setting.
        Additionally, registry check is performed  to get the right BIOS admin password.
        
#>

<#
.Synopsis
   This PowerShell script is for remediation by MS Endpoint Manager. This script checks if the client BIOS Thermal Management and sets it to "Quiet" using Dell | Command Monitor.
   IMPORTANT: This script needs a client installation of Dell | Command Monitor https://www.dell.com/support/kbdoc/en-us/000177080/dell-command-monitor
   IMPORTANT: This script does not reboot the system to apply or query any settings.
   IMPORTANT: Thi script checks if any BIOS admin password exists using a WMI query and uses the same as an authorization token while setting the BIOS Thermal management using DCM.
   IMPORTANT: WMI BIOS is supported only on devices which developt after 2018, older devices does not supported by this powershell
.DESCRIPTION
   This Powershell script using Dell | Command Monitor for setting Thermal Management to 'Quiet' on the machine. 
   This script needs to be imported in Reports/Endpoint Analytics/Proactive remediation. This File is for remediation only.
   NOTE: The remediation script errors if any will be available in Intune reports in the "Remediation Errors" column.

#>

$AdminPw = ""

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
    else
    {
        $CheckAdminPW = Get-CimInstance -Namespace root/dcim/sysman/wmisecurity -ClassName PasswordObject -Filter "NameId='Admin'" | Select-Object -ExpandProperty IsPasswordSet
        if($CheckAdminPW -eq $null)
	    {
		    Write-Error -Category ResourceUnavailable -CategoryTargetName "root/dcim/sysman/wmisecurity" -CategoryTargetType "PasswordObject" -Message "Unable to get the 'Admin' object in class 'PasswordObject' in the Namespace 'root/dcim/sysman/wmisecurity'" 
		    exit 1
	    }
        elseif($CheckAdminPW -match "1")
        {
            #BIOS admin password is set. Verifying if the registry path exists.
            $RegKeyexist = Test-Path 'HKLM:\SOFTWARE\Dell\BIOS'
            if($RegKeyexist -eq "True")
		    {
                # Get BIOS AdminPW for this device
                $PWKey = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name BIOS | Select-Object -ExpandProperty BIOS
                $serviceTag = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name ServiceTag | Select-Object -ExpandProperty ServiceTag
                $AdminPw = "$serviceTag$PWKey"
            }
            else 
            {
                Write-Error "Unknown BIOS admin password on the system. This password needs to be cleared by the user."
                exit 1
            }
        }

        $ThermalModeSetStatus = Get-CimInstance -Namespace root\dcim\sysman -ClassName DCIM_ThermalInformation | Invoke-CimMethod -MethodName ChangeThermalMode -Arguments @{AttributeName=@("Thermal Mode");AttributeValue=@("2");AuthorizationToken=$AdminPw}

        if($ThermalModeSetStatus[0].SetResult[0] -eq 0)
        {
            Write-Host "BIOS Thermal Mode is set to 'Quiet' mode."
            exit 0
        }
        elseif($ThermalModeSetStatus[0].SetResult[0] -eq 2)
        {
            # incorrect BIOS admin pw
            Write-Error "Authentication Failure : The BIOS password used is incorrect."
            exit 1
        }
        else
        {
            # failure - possible value out is out of range or invalid or readonly.
            Write-Error "Set Failure : The possible value is out of range or invalid or read-only."
            exit 1
        }
    }
}
catch
{
    $errMsg = $_.Exception.Message
    write-host $errMsg
    exit 1
}