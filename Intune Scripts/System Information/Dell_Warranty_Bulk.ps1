<#
_author_ = Prateek Vishwakarma <Prateek_Vishwakarma@Dell.com>
_version_ = 1.0

Copyright © 2023 Dell Inc. or its subsidiaries. All Rights Reserved.

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
	IT Administrators need a way to retrieve the warranty entitlement information of 
	list of client systems.
	For example - A list of client systems for which warranty expires in next 30 days.
	This helps with proactive plans of warranty renewal and inventory/audits.

.DESCRIPTION
	Get-DellWarrantyInBulk cmdlet can be used to fetch warranty entitlement information 
	of list of client systems.
	This cmdlet can be executed on a single windows endpoint, and need not deployed to 
	all the client systems.

	Scenario A : Using Get-DellWarrantyInBulk cmdlet, An Intune based IT Administrative 
	user can just use their Intune UPN and Password to fetch a list of service tags
	of their Dell IntuneManagedDevices and then bulk query the warranty entitlement 
	status using Dell Command | Warranty. 

	Scenario B : Using Get-DellWarrantyInBulk cmdlet, A Microsoft Endpoint Manager / 
	Configuration Manager (MEMCM) based IT Administrative user can fetch the list
	of service tags from the MEMCM Database in a CSV format and then pass the same 
	as input to Get-DellWarrantyInBulk cmdlet.

   	IMPORTANT: 
		1. Make sure you are using latest Powershell version 5 or newer to execute 
			this cmdlet. Execute "Get-Host" to check the version.
		2. Make sure Dell Command | Warranty application is installed on the endpoint.
			https://www.dell.com/support/kbdoc/en-us/000146749/dell-command-warranty
		3. Make sure you have working internet connection to query warranty information.
		4. This script installs "Microsoft.Graph.Intune" powershell module from 
			PSGallery, if user wishes to fetch Dell service tags from Intune environment.
   
	Following is description of Get-DellWarrantyInBulk cmdlet parameters -

	- AdminUPN, 	[string],       REQUIRED (Scenario A),  
		User Principal Name of Intune Administrative user.

	- AdminPwd, 	[SecureString], REQUIRED (Scenario A),  
		Password of adminUPN user (in a SecureString format).

	- InputCSV, 	[string],       REQUIRED (Scenario B),  
		Full path to CSV file (containing list of Dell service tags).

	- OutputDir,	[string],       OPTIONAL,				
		Path of Output directory (where warranty details will be exported).
		The cmdlet generates output in $PSScriptRoot path, in case user does not sets 
		OutputDir.

	- Filter,		[string],       OPTIONAL,				
		Optional filters that can be used while querying warranty information.
		 e.g. 
		 - ActiveWarranty - Exports active warranty entitlement information.
		 - WarrantyExpiringIn30Days - Exports warranty entitlement information where 
		 								entitlement expires in 30 days.
		 - ExpiredWarranty - Exports expired warranty entitlement information. 
		Default: AnyWarranty - Exports all warranty entitlement information. 

	- ProxyServer,	[string],       OPTIONAL,				
		Proxy server URL without port e.g., https://<proxy_url>.

	- ProxyPort,	[string],       OPTIONAL,				
		Proxy server port e.g., 80.

	- ProxyUser,	[string],       OPTIONAL,				
		Proxy user name.

	- ProxyPassword,[SecureString],	OPTIONAL,				
		Proxy user password (in a SecureString format).

	
	NOTE: 
		Following commands can be used to convert plaintext password to SecureString:

		$password = "<your_password>"
		[Security.SecureString]$securePassword = ConvertTo-SecureString $password `
		-AsPlainText -Force	

.EXAMPLE
	This example shows how to fetch bulk warranty in an intune environment (Scenario A).
    Get-DellWarrantyInBulk -AdminUPN "user@company.com" -AdminPwd $securePassword

.EXAMPLE
	This example shows how to fetch bulk warranty (Scenario A) WarrantyExpiringIn30Days
	 entitlements.
    Get-DellWarrantyInBulk -AdminUPN "user@company.com" -AdminPwd $securePassword `
	-Filter WarrantyExpiringIn30Days

.EXAMPLE
	This example shows how to fetch bulk warranty (Scenario A) behind Proxy.
    Get-DellWarrantyInBulk -AdminUPN "user@company.com" -AdminPwd $securePassword `
	-ProxyServer https://<proxy_url> -ProxyPort 80 -ProxyUser "proxy_user_name" `
	-ProxyPassword $secureProxyUserPassword

.EXAMPLE
	This example shows how to fetch bulk warranty in a MEMCM envronment (Scenario B).
    Get-DellWarrantyInBulk -InputCSV <Full path to input csv file `
	containing dell service tags>

.EXAMPLE
	This example shows how to fetch bulk warranty (Scenario B) ExpiredWarranty. 
	entitlements
    Get-DellWarrantyInBulk -InputCSV <Full path to input csv file `
	containing dell service tags> -Filter ExpiredWarranty

.EXAMPLE
	This example shows how to fetch bulk warranty (Scenario B) behind proxy.
    Get-DellWarrantyInBulk -InputCSV <Full path to input csv file `
	containing dell service tags> `
	-ProxyServer https://<proxy_url> -ProxyPort 80 -ProxyUser "proxy_user_name" `
	-ProxyPassword $secureProxyUserPassword

#>

Function Get-DellWarrantyInBulk
{	
	[CmdletBinding(DefaultParameterSetName = 'UsingGraph')]
    param(		
		[parameter(Mandatory=$true,
					ParameterSetName = 'UsingGraph',
		 			HelpMessage="Enter User Principal Name of Intune Administrative user ")]
        [ValidateNotNullOrEmpty()]
        [string]$AdminUPN,
		
		[parameter(Mandatory=$true,
					ParameterSetName = 'UsingGraph', 
					HelpMessage="Enter password for adminUPN in a SecureString format ")]
        [ValidateNotNullOrEmpty()]
		[Security.SecureString]$AdminPwd,

		[parameter(Mandatory=$true,
					ParameterSetName = 'UsingCSV', 
					HelpMessage="Enter full path to CSV file with list of Dell service tags ")]	
		[ValidateNotNullOrEmpty()]
		[string]$InputCSV,

		[parameter(Mandatory=$false, 
					HelpMessage="Enter output directory for warranty details ")]
        [ValidateNotNullOrEmpty()]
		[string]$OutputDir,

		[parameter(Mandatory=$false, 
					HelpMessage="Enter optional filter e.g. WarrantyExpiringIn30Days. `
					Default: AnyWarranty ")]
        [ValidateNotNullOrEmpty()]
		[ValidateSet("ActiveWarranty", "ExpiredWarranty", "WarrantyExpiringIn30Days")]
		[string]$Filter,

		[parameter(Mandatory=$false, 
					HelpMessage="Enter the Proxy Server to use custom proxy settings. `
					/<proxy_url> ")]
        [ValidateNotNullOrEmpty()]		
        [string]$ProxyServer,
        
        [parameter(Mandatory=$false, 
					HelpMessage="Enter the Proxy Port. e.g. 80 ")]
        [ValidateNotNullOrEmpty()]		
        [int]$ProxyPort,
        
        [parameter(Mandatory=$false, 
					HelpMessage="Enter the Proxy User Name. ")]
        [ValidateNotNullOrEmpty()]		
        [string]$ProxyUser,
        
        [parameter(Mandatory=$false, 
					HelpMessage="Enter the Proxy Password in a SecureString format. ")]
        [ValidateNotNullOrEmpty()]		
        [SecureString]$ProxyPassword
    )
	
	try
	{	
		# ** Pre-requisite validation. ***
		
		$ProgramFilesx86Path = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)") 
		$DCWPath = Join-Path $ProgramFilesx86Path -ChildPath "Dell" `
					| Join-Path -ChildPath "CommandIntegrationSuite" `
					| Join-Path -ChildPath "DellWarranty-CLI.exe"
		
		if (-not(Test-Path $DCWPath))
		{
			Write-Error "Dell Command | Warranty is not installed. `
						Please retry after installation."
			exit(1)
		}

		# ** Input validation. ***

        If (-not((-not($ProxyServer) -and -not($ProxyPort) -and -not($ProxyUser) -and -not($ProxyPassword)) -or 
			  ($ProxyServer -and $ProxyPort -and -not($ProxyUser) -and -not($ProxyPassword)) -or 
			  ($ProxyServer -and $ProxyPort -and $ProxyUser -and $ProxyPassword)
			))        
			{
				Write-Error "Mandatory proxy arguments missing"
				exit(1)
			} 
		
		If(-not($OutputDir))
		{
			$OutputDir = $PSScriptRoot
		}
		
		If(-not(Test-Path -Path $OutputDir))
        {           
            Try
		    {
                Write-Host Creating output directory: $OutputDir `n
			    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
				
				# Apply ACL

				Write-Host Applying ACL to Folder: $OutputDir `n
				$ACL = Get-Item $OutputDir | get-acl
				# Remove inheritance
				$ACL.SetAccessRuleProtection($true,$true)
				$ACL | Set-Acl
				# Remove Users
				$accessrule = New-Object system.security.AccessControl.FileSystemAccessRule("users","Read",,,"Allow")
				$ACL.RemoveAccessRuleAll($accessrule)
				Set-Acl -Path $OutputDir -AclObject $ACL                
		    }
		    Catch
		    {
                Write-Host Error creating output directory $OutputDir `n
			    Write-Error "$($_.Exception)"
                exit(1)
		    }
        }
        else
        {            
            $OutputDirObj = Get-Item $OutputDir -Force -ea SilentlyContinue
            if([bool]($OutputDirObj.Attributes -band [IO.FileAttributes]::ReparsePoint))
            { 
                Write-Error "Directory reparse point exists for $OutputDir. `
				 Select another directory and retry... "
                exit(1)
            }
        }

		$InputCSVFilePath = $InputCSV

		If($InputCSVFilePath)
		{
			if(-not(Test-Path -Path $InputCSVFilePath -PathType Leaf))
			{
				Write-Error "Input CSV file not found"
				exit(1)
			}
		}
		else
		{
			$RemoveModule = $false
			
			# Prepare the input filename

			$FileName = "Input.csv"
			$FileTimeStamp = (get-date -format yyyyMMdd_HHmmss) + "_" + $FileName
			$FilePath = Join-Path $PSScriptRoot -ChildPath $FileTimeStamp
			Write-Host "FilePath: $FilePath"

			# Install the PowerShell module for Microsoft Graph from PS gallery.

			if (Get-Module -ListAvailable -Name "Microsoft.Graph.Intune") 
			{
				Write-Host "Microsoft.Graph.Intune PowerShell module exists"
			} 
			else 
			{
				# MIT License 
				# https://www.powershellgallery.com/packages/Microsoft.Graph.Intune/6.1907.1.0/Content/LICENSE.txt
				Install-Module -Name Microsoft.Graph.Intune `
								-Repository PSGallery `
								-AllowClobber `
								-Scope CurrentUser `
								-Force `
								-ErrorAction stop
			
				$RemoveModule = $true
			}

			# Verify Installation

			If (-not(Get-InstalledModule Microsoft.Graph.Intune -ErrorAction silentlycontinue)) 
			{
				Write-Error "Microsoft.Graph.Intune PowerShell module installation failed"
				exit(1)
			}
			
			# Import the Microsoft.Graph.Intune module
			Import-Module Microsoft.Graph.Intune -ErrorAction SilentlyContinue	

			# Authenticate with Microsoft Graph.
			# Create the PSCredential object.
			
			$AdminCred = New-Object System.Management.Automation.PSCredential ($adminUPN, $adminPwd)

			# Log in with these credentials
			Connect-MSGraph -PSCredential $AdminCred | Out-Null


			# Retrieve list of device serial number.

			#$ServiceTags = Get-IntuneManagedDevice -Filter "startswith(deviceName,'DELL_')" | | Select-Object -Property serialNumber
			$ServiceTags = Get-IntuneManagedDevice | Select-Object -Property serialNumber

			if($RemoveModule -eq $true)
			{
				Write-Host "Removing Microsoft.Graph.Intune module"
                Remove-Module -Name Microsoft.Graph.Intune -Force
			}

			[System.Collections.ArrayList]$ValidServiceTags = @()
			foreach ($serviceTag in $ServiceTags)
			{
				if (($serviceTag.serialNumber -ne "") `
					-and ($null -ne $serviceTag.serialNumber) `
					-and ($serviceTag.serialNumber -match '.*\b[A-Z\d]{7}\b.*'))
				{
					[void]$ValidServiceTags.Add($serviceTag.serialNumber)
				}
			}

			$ValidServiceTags | Out-File $FilePath
			$InputCSVFilePath = $FilePath
        }


		# Prepare the output filename

		$OutputCSVFileName = "WarrantyOutput.csv"
		$FileTimeStamp = (get-date -format yyyyMMdd_HHmmss) + "_" + $OutputCSVFileName
		$OutputCSVFilePath = Join-Path $OutputDir -ChildPath $FileTimeStamp


		
		# Create the list of arguments to invoke Dell Command | Warranty

		$OptionalArguments = " "
		
		if($Filter)
		{
			$OptionalArguments = $OptionalArguments + " /F=" + $Filter
		}

		if($ProxyServer -and $ProxyPort)
		{
			$ProxyServerPort = $ProxyServer.Trim() + ":" + $ProxyPort
			$OptionalArguments = $OptionalArguments + " /Ps=" + $ProxyServerPort
		}

		if($ProxyUser -and $ProxyPassword)
		{
			$UnsecureProxyPassword = [System.Net.NetworkCredential]::new("", $ProxyPassword).Password
			$OptionalArguments = $OptionalArguments + " /Pu=" + $ProxyUser + " /Pd=" + $UnsecureProxyPassword
		}

        $arglist = @((" /I=" + $InputCSVFilePath + " /E=" + $OutputCSVFilePath + $OptionalArguments ))
	
		# Invoke Dell Command | Warranty

		Start-Process -FilePath $DCWPath -ArgumentList $arglist -WindowStyle Hidden 
		
	}
	Catch
	{
		$Exception = $_
		Write-Error "Exception:" $Exception
	}
	Finally
	{
		Write-Host "Function Get-DellWarrantyInBulk Executed"
		Write-Host "Observe Dell | Command Warranty log files for more information" 
	}
}




