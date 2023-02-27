<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_version_ = 1.0.2
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

1.0.1   Switch of BIOS Setting by Dell Command | Monitor to WMI agentless
1.0.2   Add new RegKey for date of update will be written to registry

#>

<#
.Synopsis
   This PowerShell script is for remediation by MS Endpoint Manager. This script will set/update the BIOS AdminPW on a Dell machine by using WMI.
   IMPORTANT: This script will SET/UPDATE BIOS ADMIN password if the password is not set or expired after 180 days. 
   IMPORTANT: This script needs a client which supports the WMI Namespace "root/dcim/sysman/wmisecurity" and the WMI class "PasswordObject".
   IMPORTANT: WMI BIOS is supported only on devices which developed after 2018, older devices do not supported by this powershell script.
   IMPORTANT: This script does not reboot the system to apply or query system.
   IMPORTANT: The parameters $PWKey and $PWTime can be changed as per the requirements.
   
.DESCRIPTION
   Powershell using WMI for setting AdminPW on the machine. The script checks if any PW is exist and can setup new and change PW. 
   This Script need to be imported in Reports/Endpoint Analytics/Proactive remediation. This File is for remediation only and need a seperate script for detection additional.
   NOTE: The remediation script log message are available on the endpoint at this path: "C:\Temp\BIOS_Profile.txt"
   
.EXAMPLE
	This example provides the BIOS admin password that will be set if its not previously set or expired. The admin password is set using the service tag of the system.
	Ex: $Servicetag= "FW2DLQ2"
        $PWkey = "Dell2023"
        The admin password set is "FW2DLQ2Dell2023"
   
#>


#Variable for change
$PWKey = "Dell2023" #Sure-Key of AdminPW
$PWTime = "180" # Days a password need exist before it will be change



#Variable not for change
$PWset = Get-CimInstance -Namespace root/dcim/sysman/wmisecurity -ClassName PasswordObject -Filter "NameId='Admin'" | Select-Object -ExpandProperty IsPasswordSet
$DateTransfer = (Get-Date).AddDays($PWTime)
$PWstatus = ""
#$DeviceName = Get-CimInstance -ClassName win32_computersystem | select -ExpandProperty Name
$serviceTag = Get-CimInstance -ClassName win32_bios | Select-Object -ExpandProperty SerialNumber
$AdminPw = "$serviceTag$PWKey"
$Date = Get-Date
$PWKeyOld = ""
$serviceTagOld = ""
$AdminPwOld = ""
$PATH = "C:\Temp\"


#check if c:\temp exist / check if RegKey exisit
if (!(Test-Path $PATH)) {New-Item -Path $PATH -ItemType Directory}
$RegKeyexist = Test-Path 'HKLM:\SOFTWARE\Dell\BIOS'

#Logging device data
Write-Output $env:COMPUTERNAME | out-file "$PATH\BIOS_Profile.txt" -Append
Write-Output "ServiceTag:         $serviceTag" | out-file "$PATH\BIOS_Profile.txt" -Append
Write-Output "Profile install at: $Date" | out-file "$PATH\BIOS_Profile.txt" -Append

#Connect to the SecurityInterface WMI class
$SecurityInterface = Get-WmiObject -Namespace root\dcim\sysman\wmisecurity -Class SecurityInterface

#Checking RegistryKey availbility
Write-Output "Starting the remediation script.."

if ($RegKeyexist -eq "True")
{
    $PWKeyOld = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name BIOS | Select-Object -ExpandProperty BIOS
    $serviceTagOld = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name ServiceTag | Select-Object -ExpandProperty ServiceTag
    $AdminPwOld = "$serviceTagOld$PWKeyOld"
    
    Write-Output "Registry Key exist"  | out-file "$PATH\BIOS_Profile.txt" -Append
    # Encoding BIOS Password
    $Encoder = New-Object System.Text.UTF8Encoding
    $Bytes = $Encoder.GetBytes($AdminPwOld)
}
else
{
    New-Item -path "hklm:\software\Dell\BIOS" -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "BIOS" -value "" -type string -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "ServiceTag" -value "" -type string -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Date" -value "" -type string -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "" -type string -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Update" -value (Get-Date -Format yyyy-MM-dd) -type string -Force

    Write-Output "Registry Key is set"  | out-file "$PATH\BIOS_Profile.txt" -Append
}

#Checking AdminPW is not set on the machine
Write-Output "Checking if the BIOS Password is set on the system"

if($PWset -eq $null)
{
    Write-Error -Category ResourceUnavailable -CategoryTargetName "root/dcim/sysman/wmisecurity" -CategoryTargetType "PasswordObject" -Message "Unable to get the 'Admin' object in class 'PasswordObject' in the Namespace 'root/dcim/sysman/wmisecurity'" 
	Exit 1
}
elseif ($PWset -eq $false)
{
    Write-Output "BIOS password is not set on the system."

    $PWstatus = $SecurityInterface.SetNewPassword(0,0,0,"Admin","",$AdminPw) | Select-Object -ExpandProperty Status

    #Setting of AdminPW was successful

    If ($PWstatus -eq 0)
        {
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "BIOS" -value $PWKey -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "ServiceTag" -value $serviceTag -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Date" -value $Date -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Ready" -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Update" -value (Get-Date $DateTransfer -Format yyyy-MM-dd) -type string -Force
        
            Write-Output "BIOS admin password is set successfully for first time."  | out-file "$PATH\BIOS_Profile.txt" -Append
            Write-Host "BIOS admin password is set successfully for first time."
            Exit 0
        }
    else
        {
            #Setting of AdminPW was unsuccessful
        
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Error" -type string -Force
            Write-Output "ERROR: BIOS admin password could not set." | out-file "$PATH\BIOS_Profile.txt" -Append
            Write-Error "ERROR: BIOS admin password could not set."
            Exit 1
        }
}
else
{
    Write-Output "BIOS password is already set on the system."
    #Check if AdminPW is the same if not it will change AdminPW to new AdminPW
    #Compare old and new AdminPW are equal
    If ($AdminPw -eq $AdminPwOld)
    {
        # Change the pwkey to generate a new password.
        Write-Output "The parameters PWKey and PWTime in the remediation script need to be updated for the BIOS Admin password update." | out-file "$PATH\BIOS_Profile.txt" -Append
        Write-Error "The parameters PWKey and PWTime in the remediation script need to be updated for the BIOS Admin password update."
        Exit 1
    }
    else
    {
        #Old and new AdminPW are different make AdminPW change
        $PWstatus = $SecurityInterface.SetNewPassword(1,$Bytes.Length,$Bytes,"Admin",$AdminPwOld,$AdminPw) | Select-Object -ExpandProperty Status

        #Checking if change was successful
        If($PWstatus -eq 0)
        {
            Write-Output "BIOS admin password is updated successfully." | out-file "$PATH\BIOS_Profile.txt" -Append
            Write-Host "BIOS admin password is updated successfully."
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Ready" -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "BIOS" -value $PWKey -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Update" -value (Get-Date $DateTransfer -Format yyyy-MM-dd) -type string -Force
            Exit 0
        }
        else
        {
            #Checking if change was unsuccessful. Most reason is there is a AdminPW is set by user or admin before the profile is enrolled or RegistryKey does not exist
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Unknown" -type string -Force
            Write-Output "Unknown BIOS admin password on this machine. This password needs to be cleared by the user." | out-file "$PATH\BIOS_Profile.txt" -Append
            Write-Error "Unknown BIOS admin password on this machine. This password needs to be cleared by the user."
            Exit 1
        }
    }
}