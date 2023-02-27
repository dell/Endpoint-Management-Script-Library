<#
_author_ = Supreeth Dayananda <Supreeth_D1@Dell.com>
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
   Install-DellDriverFiles cmdlet used to download and install the driver pack for the individual system.
   This script can be used by an administrative user to download and install all the drivers for a particular system.
   IMPORTANT: Make sure you are using latest PowerShell version 5 or newer to execute this cmdlet. Execute "Get-Host" to check the version.
   IMPORTANT: Make sure to run this script in 64-bit PowerShell Host only. As PNPUtil command to install drivers is supported only on 64-bit. 
              While deploying the script via Intune, make sure to select "Yes" - "Run Script in 64-bit PowerShell Host".    
.DESCRIPTION
   Cmdlet used to download and install driver pack for the individual system. 
   - DownloadDir, REQUIRED, the download path where all the driver files will be downloaded and installed from.
   - Restart, OPTIONAL, pass in -Restart switch if local system restart needs to be performed after driver installation (recommended)
   - ProxyServer, OPTIONAL, the custom proxy server address.
   - ProxyPort, OPTIONAL, the custom proxy server port.
   - ProxyUser, OPTIONAL, the custom proxy Username.
   - ProxyPassword, OPTIONAL, the custom Proxy Password
     The ProxyPassword is a SecureString parameter, user must convert to SecureString before passing the ProxyPassword parameter to 
     Install-DellDriverFiles cmdlet.
     e.g. $ProxyPass = "Password"
          $SecureProxyPassword = ConvertTo-SecureString $ProxyPass -AsPlainText -Force
     NOTE:
     1. This Script will create a Log File - "DellDriverInstaller_Log.txt" under the DownloadDir to track the driver installation data.
     
.EXAMPLE
	This example shows how to download and install the Driver packages using Download-Directory
	Install-DellDriverFiles -DownloadDir "LocalPath"
.EXAMPLE
	This example shows how to download and install the Driver packages using Download-Directory and restart switch
	Install-DellDriverFiles -DownloadDir "LocalPath" -Restart
.EXAMPLE
	This example shows how to download and install the Driver packages using the custom proxy settings
	Install-DellDriverFiles -DownloadDir "LocalPath" -ProxyServer "http://<proxy_url>" -ProxyPort "80"
.EXAMPLE
	This example shows how to download and install the Driver packages using the custom proxy settings using user credentials
	$ProxyPass = "Password"
    $SecureProxyPassword = ConvertTo-SecureString $ProxyPass -AsPlainText -Force
    Install-DellDriverFiles -DownloadDir "LocalPath" -ProxyServer "http://<proxy_url>" -ProxyPort "80" -ProxyUser "Username" -ProxyPassword $SecureProxyPassword
#>

Function Restart-DellComputer
{	
	param(	
		[parameter(Mandatory=$true, HelpMessage="Enter time in seconds")]
		[ValidateNotNullOrEmpty()]
		[int]$Seconds
	)
	try
	{
	Write-Host "Following will happen during restart"
	$WhatIf = Restart-Computer -WhatIf	
	Write-Host $WhatIf
	
	Write-Host "Waiting for" $Seconds "before restart"
	Start-Sleep -Seconds $Seconds
	Write-Host "Attempting system restart at " $(Get-Date) -EA stop
	
	Restart-Computer -ComputerName . -Force -EA stop
	}
	catch [Exception]
	{		
		Write-Error "$($_.Exception)"
	}
	finally
	{
		Write-Host "Restart-DellComputer Executed"
	}	
}

Function Install-DellDriverFiles
{
    param(
        [parameter(Mandatory=$true, HelpMessage="Enter the download folder location where the files will be downloaded. ")]
        [ValidateNotNullOrEmpty()]		
        [string]$DownloadDir,

        [parameter(Mandatory=$false, HelpMessage="use -Restart switch if system Restart needs to be performed")]
	    [switch]$Restart,
        
        [parameter(Mandatory=$false, HelpMessage="Enter the Proxy Server to use custom proxy settings. e.g. http://<proxy_url> ")]
        [ValidateNotNullOrEmpty()]		
        [string]$ProxyServer,
        
        [parameter(Mandatory=$false, HelpMessage="Enter the Proxy Port. e.g. 80 ")]
        [ValidateNotNullOrEmpty()]		
        [int]$ProxyPort,
        
        [parameter(Mandatory=$false, HelpMessage="Enter the Proxy User Name. ")]
        [ValidateNotNullOrEmpty()]		
        [string]$ProxyUser,
        
        [parameter(Mandatory=$false, HelpMessage="Enter the Proxy Password. ")]
        [ValidateNotNullOrEmpty()]		
        [SecureString]$ProxyPassword	
		
	)
	
	try
	{
        # ** If PowerShell process is running as 32-bit process exit the script, as PNPUtil is supported only as 64-bit process.
        
        if(![Environment]::Is64BitProcess)
        {
            Write-Host Error: Script is not supported in 32-bit PowerShell Host `n -BackgroundColor Red
            Write-Host Run Script in 64-bit PowerShell Host `n -BackgroundColor Red
            exit(1)
        }
            
        # ** Mandatory Proxy Arguments Validation. ***
        
        If(!((!$ProxyServer -and !$ProxyPort -and !$ProxyUser -and !$ProxyPassword) -or 
           ($ProxyServer -and $ProxyPort -and !$ProxyUser -and !$ProxyPassword) -or 
           ($ProxyServer -and $ProxyPort -and $ProxyUser -and $ProxyPassword)))        
        {
            Write-Host Error: Missing Mandatory Proxy Arguments `n -BackgroundColor Red
            exit(1)
        }
        # Driver installation status flag
        $DriverInstallSuccess = $false 
        # To get the current date and time to write onto log-file.      
        $Date = Get-Date
        # DriverCabCatalog File Name
        $DriverCabCatalogFileName = "DriverPackCatalog.cab"
        # DriverCabCatalog XML File Name
        $DriverCabCatalogXMLFileName = "DriverPackCatalog.xml"
        # DriverPackCatalog.cab file URL
		$DriverCabCatalog = "https://downloads.dell.com/catalog/DriverPackCatalog.cab"      
        # Platform System ID or BIOS ID
        $SystemID = (Get-CimInstance Win32_ComputerSystem).SystemSKUNumber
        # Platform System OS
        $PlatformSystemOS = (Get-CimInstance Win32_OperatingSystem).Caption
        #Platform OS Architecture
        $PlatformSystemOSArch = [Environment]::Is64BitOperatingSystem
        # Check OS architecture, supports only 64-bit architecture 
        if($PlatformSystemOSArch -ne "True")
        {
            Write-Host Error: Supports only 64-bit architecture! `n -BackgroundColor Red
            exit(1)
        }

        # Supported for only Windows 10 and Windows 11 OS
        if($PlatformSystemOS -match "Windows 10")
        {
            $SystemOS = "Windows 10 x64"
        }
        elseif($PlatformSystemOS -match "Windows 11")
        {
            $SystemOS = "Windows 11 x64"
        }
        else
        {
            Write-Host Error: Supports only Windows 10 and Windows 11 platforms `n -BackgroundColor Red            
            exit(1)
        }

        # Download directory name (System_ID_System_OS)
        $DownloadDirName = $SystemID.Trim() + " " + $SystemOS.Trim()                                        
        $DownloadDirName = $DownloadDirName.Replace(" ","_")
        # Download folder path                                    
        $DriverDownloadFolder = Join-Path -Path $DownloadDir -ChildPath $DownloadDirName 
        # DriverPackCatalog.cab download path                       
        $DriverCabCatalogFile = Join-Path -Path $DriverDownloadFolder -ChildPath $DriverCabCatalogFileName 
        # DriverPackCatalog.xml extraction path
        $DriverCatalogXMLFile = Join-Path -Path $DriverDownloadFolder -ChildPath $DriverCabCatalogXMLFileName    
        # Log-File Path
        $LogFileName = "DellDriverInstaller_Log.txt"
        $LogFilePath = Join-Path -Path $DriverDownloadFolder -ChildPath $LogFileName
                    
        # *** Check if download directory exists, if it does not exist create download directory ***
        Try
        {
            $DownloadDir = Resolve-Path -Path $DownloadDir
        }
        Catch [Exception]
		{
            Write-Host Error resolving path $DownloadDir `n
			Write-Error "$($_.Exception)"
            Try
		    {
                Write-Host Creating Download Directory: $DownloadDir `n
			    New-Item -Path $DownloadDir -ItemType Directory -Force | Out-Null                
		    }
		    Catch [Exception]
		    {
                Write-Host Error creating download directory $DownloadDir `n
			    Write-Error "$($_.Exception)"
                exit(1)
		    }
		}
        If(!(Test-Path -Path $DownloadDir))
        {           
            Try
		    {
                Write-Host Creating Download Directory: $DownloadDir `n
			    New-Item -Path $DownloadDir -ItemType Directory -Force | Out-Null                
		    }
		    Catch [Exception]
		    {
                Write-Host Error creating download directory $DownloadDir `n
			    Write-Error "$($_.Exception)"
                exit(1)
		    }
        }
        else
        {            
            $DownloadDirFile = Get-Item $DownloadDir -Force -ea SilentlyContinue
            if([bool]($DownloadDirFile.Attributes -band [IO.FileAttributes]::ReparsePoint))
            { 
                Write-Host "Directory Reparse Point Exists for $DownloadDir. Select another directory and re-run script..." `n -BackgroundColor Red
                exit(1)
            }
        }

        # *** If the System_Model_System_OS folder exists in the Download directory, delete the folder. ***

        If(Test-Path -Path $DriverDownloadFolder)
        {           
            Try
		    {
                Write-Host Deleting Folder: $DriverDownloadFolder `n
			    Remove-Item -Path $DriverDownloadFolder -Recurse -Force | Out-Null                
		    }
		    Catch [Exception]
		    {
                Write-Host Error deleting directory $DriverDownloadFolder `n
			    Write-Error "$($_.Exception)"
                exit(1)
		    }
        }
         
        # *** Create System_Model_System_OS folder under Download directory. ***   
               
        Try
		{
            Write-Host Creating Folder: $DriverDownloadFolder `n
			
            New-Item -Path $DriverDownloadFolder -ItemType Directory -Force | Out-Null
            
            # Apply ACL
            
            Write-Host Applying ACL to Folder: $DriverDownloadFolder `n
            
            $ACL = Get-Item $DriverDownloadFolder | get-acl
            # Remove inheritance
            $ACL.SetAccessRuleProtection($true,$true)
            $ACL | Set-Acl
            # Remove Users
            $accessrule = New-Object system.security.AccessControl.FileSystemAccessRule("users","Read",,,"Allow")
            $ACL.RemoveAccessRuleAll($accessrule)
            Set-Acl -Path $DriverDownloadFolder -AclObject $ACL
            # Create Log File
            New-Item -ItemType File -Path $LogFilePath -Force                
		}
		Catch [Exception]
		{
            Write-Host Error creating directory $DriverDownloadFolder `n
			Write-Error "$($_.Exception)"            
            exit(1)
		}

        # *** Adding contents into Log-File. ***

        Add-Content -Path $LogFilePath -Value "===================================="

        Add-Content -Path $LogFilePath -Value " Script - Dell_Install_Driver_Files.ps1 "

        Add-Content -Path $LogFilePath -Value " $Date "

        Add-Content -Path $LogFilePath -Value " System ID - $SystemID "

        Add-Content -Path $LogFilePath -Value " System OS - $SystemOS "

        Add-Content -Path $LogFilePath -Value "===================================="
        
        
        # *** To Download the Driver Cab Catalog. ***

        try {
              Write-Host Downloading DriverPackCatalog file... `n 
              Add-Content -Path $LogFilePath -Value "Downloading DriverPackCatalog file..."         
              $WebClient = New-Object -TypeName System.Net.WebClient
              # *** Check if Custom Proxy Settings is passed and set the custom proxy settings. ***
              if($ProxyServer -and $ProxyPort -and $ProxyUser -and $ProxyPassword)
              {
                $ProxyServerAddress = $ProxyServer.Trim() + ":" + $ProxyPort.ToString()
                Write-Host Downloading DriverPackCatalog File using Custom Proxy Settings using Proxy Credentials. `n
                $WebProxy = New-Object System.Net.WebProxy($ProxyServerAddress,$true)           
                $WebProxyCredentials = (New-Object Net.NetworkCredential($ProxyUser.Trim(),$ProxyPassword)).GetCredential($ProxyServer.Trim(),$ProxyPort,"KERBEROS") 
                $WebProxy.Credentials = $WebProxyCredentials            
                $WebClient.Proxy = $WebProxy                 
              }
              elseif($ProxyServer -and $ProxyPort)
              {
                $ProxyServerAddress = $ProxyServer.Trim() + ":" + $ProxyPort.ToString()
                Write-Host Downloading DriverPackCatalog File using Custom Proxy Settings. `n
                $WebProxy = New-Object System.Net.WebProxy($ProxyServerAddress,$true)         
                $WebClient.Proxy = $WebProxy                         
              }

              $WebClient.DownloadFile($DriverCabCatalog, "$DriverCabCatalogFile")
              
              if (Test-Path "$DriverCabCatalogFile")
			  {                   
                 Write-Host DriverPackCatalog file downloaded successful. `n
                 Add-Content -Path $LogFilePath -Value "DriverPackCatalog file downloaded successful."
              }
              else
              {
                    Write-Host DriverPackCatalog file is not downloaded! `n -BackgroundColor Red 
                    Add-Content -Path $LogFilePath -Value "DriverPackCatalog file download failed!"
                    exit(1)
              }              
            }
        catch [System.Net.WebException]
            {
                Write-Error "$($_.Exception)"
                Add-Content -Path $LogFilePath -Value "$($_.Exception)"
                exit(1)
            }


        # *** To Extract the DriverPackCatalog file. ***
        
        try {
                Write-Host Extracting DriverPackCatalog file... `n 
                Add-Content -Path $LogFilePath -Value "Extracting DriverPackCatalog file..."  
                expand -r $DriverCabCatalogFile $DriverDownloadFolder
                if (Test-Path "$DriverCatalogXMLFile")
			    {
                   Write-Host DriverPackCatalog file extraction successful. `n
                   Add-Content -Path $LogFilePath -Value "DriverPackCatalog file extraction successful."
                }
                else
                {
                    Write-Host DriverPackCatalog XML file extraction failed! `n -BackgroundColor Red 
                    Add-Content -Path $LogFilePath -Value "DriverPackCatalog XML file extraction failed!"
                    exit(1)
                }               	                        
            }
        catch [Exception] 
            {
                Write-Error "$($_.Exception)"
                Add-Content -Path $LogFilePath -Value "$($_.Exception)"
                exit(1)
            }

        try {
            [xml]$CatalogXML = Get-Content -Path $DriverCatalogXMLFile -ErrorAction Ignore
            [array]$DriverPackages = $CatalogXML.DriverPackManifest.DriverPackage
            $urlBase = "https://downloads.dell.com/"
            $NoDriverMatchFound = $true
            foreach ($DriverPackage in $DriverPackages)
	        {
                # Driver Package Name
                $DriverPackageName = $DriverPackage.Name.Display.'#cdata-section'.Trim()           
                # Driver Match Found Flag
                $DriverMatchFound = $false                                                         
                # Driver Download url
                $DriverDownloadPath = -join($urlBase, $DriverPackage.path)                         
                # Driver Download Path
                $DriverDownloadDestPath = -join($DriverDownloadFolder,"\$DriverPackageName")       

                foreach ($SupportedSystems in $DriverPackage.SupportedSystems.Brand)
			    {
                    $SystemIDFromCatalog = $SupportedSystems.Model.systemID  
			        
                    # Check for System ID Match
				    if ($SystemIDFromCatalog -eq $SystemID)
				    {                            
                        # Check for System OS Match
                        foreach ($SupportedOS in $DriverPackage.SupportedOperatingSystems)
			            {
				            if ($SupportedOS.OperatingSystem.Display.'#cdata-section'.Trim() -match $SystemOS)
				            {  
                                $NoDriverMatchFound = $false                                  
					            $DriverMatchFound = $true
				            }				
			            }
				    }				
			    }           		           
   
		        # *** Download the driver if both System ID and System OS match found. ***
		            
		        if ($DriverMatchFound)
		        {     
                    Write-Host Downloading driver file! `n The download might take some time... `n Make sure the internet is not disconnected! `n -BackgroundColor Gray
                    Add-Content -Path $LogFilePath -Value "Downloading driver file..."
                    # Adding stopwatch to get the total time taken to download the driver.
                    $StopWatch = [system.diagnostics.stopwatch]::StartNew() 
                    $WebClient = New-Object -TypeName System.Net.WebClient

                    # *** Check if Custom Proxy Settings is passed and set the custom proxy settings. ***
                    if($ProxyServer -and $ProxyPort -and $ProxyUser -and $ProxyPassword)
                    {
                        $ProxyServerAddress = $ProxyServer.Trim() + ":" + $ProxyPort.ToString()
                        Write-Host Downloading Driver using Custom Proxy Settings using Proxy Credentials. `n
                        $WebProxy = New-Object System.Net.WebProxy($ProxyServerAddress,$true)           
                        $WebProxyCredentials = (New-Object Net.NetworkCredential($ProxyUser.Trim(),$ProxyPassword)).GetCredential($ProxyServer.Trim(),$ProxyPort,"KERBEROS") 
                        $WebProxy.Credentials = $WebProxyCredentials            
                        $WebClient.Proxy = $WebProxy                 
                    }
                    elseif($ProxyServer -and $ProxyPort)
                    {
                        $ProxyServerAddress = $ProxyServer.Trim() + ":" + $ProxyPort.ToString()
                        Write-Host Downloading Driver using Custom Proxy Settings. `n
                        $WebProxy = New-Object System.Net.WebProxy($ProxyServerAddress,$true)         
                        $WebClient.Proxy = $WebProxy                         
                    }

                    $WebClient.DownloadFile($DriverDownloadPath, $DriverDownloadDestPath)
                    $StopWatch.Stop()
                    $TotalDriverDownloadTime = $StopWatch.Elapsed    
                    
                    # *** Once Driver Download is completed Check if the SHA256 hash matches with the downloaded driver. ***
                    if (Test-Path "$DriverDownloadDestPath")
					{   
                        Write-Host "Driver download successful: $DriverPackageName `n"
                        Add-Content -Path $LogFilePath -Value "Driver download successful: $DriverPackageName"
                        Write-Host "Total time taken to download driver $DriverPackageName (hh:mm:ss.ms): $TotalDriverDownloadTime `n"
                        Add-Content -Path $LogFilePath -Value "Total time taken to download driver $DriverPackageName (hh:mm:ss.ms): $TotalDriverDownloadTime"    
                        # MD5 hash from the xml file           		
		                $MD5Hash = $DriverPackage.Cryptography.Hash | Where-Object { $_.algorithm -eq 'SHA256' } | Select-Object -ExpandProperty "#text"       
                        # MD5 hash of the downloaded driver file
                        $DriverFileMD5Hash = Get-FileHash $DriverDownloadDestPath -Algorithm SHA256                                                        
		                if($MD5Hash -eq $DriverFileMD5Hash.Hash)
                        {
                            Write-Host "MD5 hash match successful - $DriverPackageName. `n"
                            Add-Content -Path $LogFilePath -Value "MD5 hash match successful - $DriverPackageName."
                            # Extract downloaded driver file
                            Write-Host "Extracting driver file - $DriverPackageName. `n"
                            Add-Content -Path $LogFilePath -Value "Extracting driver file - $DriverPackageName."
                            Write-Host "The extraction might take some time... `n Please wait for the extraction to complete... " -BackgroundColor Gray
                            $DriverPackageLocation = Join-Path -Path $DriverDownloadFolder -ChildPath $DriverPackageName
                            $DriverPackageExtractFolderName = [System.IO.Path]::GetFileNameWithoutExtension($DriverPackageName)
                            $DriverPackExtractLocation = Join-Path -Path $DriverDownloadFolder -ChildPath $DriverPackageExtractFolderName
                            try 
                            {
                                if($DriverPackageName -match ".exe")
                                {
                                    Start-Process -FilePath $DriverPackageLocation -ArgumentList "/s /e=$DriverPackExtractLocation" -Wait -NoNewWindow -PassThru
                                }
                                else
                                {
                                    # Create extraction folder for .cab extraction
                                    New-Item -Path $DriverPackExtractLocation -ItemType Directory -Force | Out-Null
                                    # Extract all contents into the extraction folder
                                    expand -r -F:* $DriverPackageLocation $DriverPackExtractLocation | Out-Null
                                }
                            }
                            catch [Exception] 
                            {
                                Write-Host "Extraction of DriverPack $DriverPackageName failed! `n"
                                Add-Content -Path $LogFilePath -Value "Extraction of DriverPack $DriverPackageName failed!"
                                Write-Error "$($_.Exception)"
                                Add-Content -Path $LogFilePath -Value "$($_.Exception)"
                                exit(1)
                            }
                            Write-Host "Driver extraction successful - $DriverPackageName. `n"
                            Add-Content -Path $LogFilePath -Value "Driver extraction successful - $DriverPackageName." 
                            # Install the Driver using PNPUTIL command
                            $DriverFilestoInstall = Join-Path -Path $DriverPackExtractLocation -ChildPath "*.inf"
                            Write-Host "Installing driver - $DriverPackageName. `n"
                            Add-Content -Path $LogFilePath -Value "Installing driver - $DriverPackageName."
                            Write-Host "The installation might take some time... `n Please wait for the installation to complete... " -BackgroundColor Gray
                            try
                            {
                                PNPUtil.exe /add-driver $DriverFilestoInstall /subdirs /install | Tee-Object -Append -File $LogFilePath
                            }
                            catch [Exception] 
                            {
                                Write-Host "$DriverPackageName Installation failed! `n"
                                Add-Content -Path $LogFilePath -Value "$DriverPackageName Installation failed!"
                                Write-Error "$($_.Exception)"
                                Add-Content -Path $LogFilePath -Value "$($_.Exception)"
                                exit(1)
                            }
                            Write-Host "$DriverPackageName Installation Completed. `n"
                            Add-Content -Path $LogFilePath -Value "$DriverPackageName Installation Completed."
                            $DriverInstallSuccess = $true                     
                        }
                        else
                        {
                            Write-Host "MD5 has match failed. Hence, deleting the driver file $DriverPackageName. `n"
                            Add-Content -Path $LogFilePath -Value "MD5 has match failed. Hence, deleting the driver file $DriverPackageName."
                            Write-Host "Driver installation was not successful! `n"
                            Add-Content -Path $LogFilePath -Value "Driver installation was not successful!"
                            Remove-Item -Path $DriverDownloadDestPath -Recurse -Force | Out-Null
                        }
                    }
                    else
                    {
                        Write-Host "Driver download failed: $DriverPackageName `n"
                        Add-Content -Path $LogFilePath -Value "Driver download failed: $DriverPackageName"
                    }                  
			                                  
		        }		            
		
	        }
            
            if($NoDriverMatchFound -eq $true)
            {
                Write-Host "No Driver Match found for the SystemID: $SystemID, OS: $SystemOS. `n"
                Write-Host "Contact Dell Support. `n"
                Add-Content -Path $LogFilePath -Value "No Driver Match found for the SystemID: $SystemID, OS: $SystemOS."
                Add-Content -Path $LogFilePath -Value "Contact Dell Support."
            }	

            }
        catch [Exception] 
            {
                Write-Error "$($_.Exception)"
                Add-Content -Path $LogFilePath -Value "$($_.Exception)"
            }
		
	}	
	catch [Exception]
	{
		Write-Error "$($_.Exception)"
        Add-Content -Path $LogFilePath -Value "$($_.Exception)"
	}
	Finally
	{
        # Delete all contents from DownloadFolder except Log file
        if($LogFilePath)
        {
            if($DriverDownloadFolder)
            {
                try
                {
                    Get-ChildItem -Path  $DriverDownloadFolder -Recurse -exclude $LogFileName |
                    Select -ExpandProperty FullName |
                    Where {$_ -notlike $LogFilePath} |
                    sort length -Descending |
                    Remove-Item -Recurse -Force | Out-Null
                }
                catch [Exception]
	            {
                    Write-Host "Deleting files from $DriverDownloadFolder failed! Manual clean-up is required!"
		            Write-Error "$($_.Exception)"
                    Add-Content -Path $LogFilePath -Value "Deleting files from $DriverDownloadFolder failed! Manual clean-up is required!"
                    Add-Content -Path $LogFilePath -Value "$($_.Exception)"
	            }
            }
		    Write-Host "Function Install-DellDriverFiles Executed"        
            $FinishTime = Get-Date
            Add-Content -Path $LogFilePath -Value "------------------------------------"

            Add-Content -Path $LogFilePath -Value "Function Install-DellDriverFiles Executed"

            Add-Content -Path $LogFilePath -Value " $FinishTime "
                
            Add-Content -Path $LogFilePath -Value "------------------------------------"
            #restart the system if required, using Powershell Script
            if($Restart -and $DriverInstallSuccess)
            {
                Write-Host "Restarting System... `n"
                Add-Content -Path $LogFilePath -Value "Restarting System..."
			    #CAUTION: USER MIGHT LOSE UNSAVED WORK
			    Restart-DellComputer -Seconds 10
		    }
        }
	}
}

