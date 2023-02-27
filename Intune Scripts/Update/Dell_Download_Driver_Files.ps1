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
   Get-DellDriverPack cmdlet used to retrieve the driver pack for the individual system.
   This script can be used by an administrative user to download all the drivers for a particular system that can be later deployed to that system.
   IMPORTANT: Make sure you are using latest PowerShell version 5 or newer to execute this cmdlet. Execute "Get-Host" to check the version.   
.DESCRIPTION
   Cmdlet used to retrieve driver pack for the individual system that is applicable and can installed for that particular system. 
   - SystemID, REQUIRED, the Platform System ID or BIOS ID of the system for which the drivers must be downloaded.
     Note: System ID can be found under System Information -> System Summary -> System SKU (System ID or BIOS ID)
           win + R, type msinfo32 to get the System Information. Under System Information look for System SKU. 
           PowerShell Command to get the Platform System ID or BIOS ID of the system -
                   (Get-CimInstance Win32_ComputerSystem).SystemSKUNumber
   - SystemOS, REQUIRED, the target Operating System on which the drivers will be installed.
   - DownloadDir, REQUIRED, the download path where all the driver files will be downloaded.
   - ProxyServer, OPTIONAL, the custom proxy server address.
   - ProxyPort, OPTIONAL, the custom proxy server port.
   - ProxyUser, OPTIONAL, the custom proxy Username.
   - ProxyPassword, OPTIONAL, the custom Proxy Password
     The ProxyPassword is a SecureString parameter, user must convert to SecureString before passing the ProxyPassword parameter to 
     Get-DellDriverPack cmdlet.
     e.g. $ProxyPass = "Password"
          $SecureProxyPassword = ConvertTo-SecureString $ProxyPass -AsPlainText -Force

.EXAMPLE
	This example shows how to download the Driver packages using SystemID, System-OS and Download-Directory
	Get-DellDriverFiles -SystemID "0A40" -SystemOS "Windows 10 x64" -DownloadDir "LocalPath"
.EXAMPLE
	This example shows how to download the Driver packages using the custom proxy settings
	Get-DellDriverFiles -SystemID "0A40" -SystemOS "Win 10 x64" -DownloadDir "LocalPath" -ProxyServer "http://<proxy_url>" -ProxyPort "80"
.EXAMPLE
	This example shows how to download the Driver packages using the custom proxy settings using user credentials
	$ProxyPass = "Password"
    $SecureProxyPassword = ConvertTo-SecureString $ProxyPass -AsPlainText -Force
    Get-DellDriverFiles -SystemID "0A40" -SystemOS "Win 10 x64" -DownloadDir "LocalPath" -ProxyServer "http://<proxy_url>" -ProxyPort "80" -ProxyUser "Username" -ProxyPassword $SecureProxyPassword
#>

Function Get-DellDriverFiles
{
    param(
        [parameter(Mandatory=$true, HelpMessage="Enter target System ID or BIOS ID for which the drivers must be downloaded. e.g. 0A40 ")]
        [ValidateNotNullOrEmpty()]
        [string]$SystemID,	

        [parameter(Mandatory=$true, HelpMessage="Enter the target Operating System on which the drivers will be installed. e.g. Windows 11 x64")]
        [ValidateNotNullOrEmpty()]
		[ValidateSet("Windows 10 x64", "Windows 11 x64")]
        [string]$SystemOS,
        
        [parameter(Mandatory=$true, HelpMessage="Enter the download folder location where the files will be downloaded. ")]
        [ValidateNotNullOrEmpty()]		
        [string]$DownloadDir,
        
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

        # ** Mandatory Proxy Arguments Validation. ***
        
        If(!((!$ProxyServer -and !$ProxyPort -and !$ProxyUser -and !$ProxyPassword) -or 
           ($ProxyServer -and $ProxyPort -and !$ProxyUser -and !$ProxyPassword) -or 
           ($ProxyServer -and $ProxyPort -and $ProxyUser -and $ProxyPassword)))        
        {
            Write-Host Error: Missing Mandatory Proxy Arguments `n -BackgroundColor Red
            exit(1)
        }           
        
        # DriverCabCatalog File Name
        $DriverCabCatalogFileName = "DriverPackCatalog.cab"
        # DriverCabCatalog XML File Name
        $DriverCabCatalogXMLFileName = "DriverPackCatalog.xml"
        # DriverPackCatalog.cab file URL
		$DriverCabCatalog = "https://downloads.dell.com/catalog/DriverPackCatalog.cab"          
        # Download directory name (System_ID_System_OS)
        $DownloadDirName = $SystemID.Trim() + " " + $SystemOS.Trim()                                        
        $DownloadDirName = $DownloadDirName.Replace(" ","_")
        # Download folder path                                    
        $DriverDownloadFolder = Join-Path -Path $DownloadDir -ChildPath $DownloadDirName 
        # DriverPackCatalog.cab download path                       
        $DriverCabCatalogFile = Join-Path -Path $DriverDownloadFolder -ChildPath $DriverCabCatalogFileName 
        # DriverPackCatalog.xml extraction path
        $DriverCatalogXMLFile = Join-Path -Path $DriverDownloadFolder -ChildPath $DriverCabCatalogXMLFileName                             
        
        # *** Check if download directory exists, if it does not exist create download directory ***
        Try
        {
            $DownloadDir = Resolve-Path -Path $DownloadDir
        }
        Catch
		{
            Write-Host Error resolving path $DownloadDir `n
			Write-Error "$($_.Exception)"            
            Try
		    {
                Write-Host Creating Download Directory: $DownloadDir `n
			    New-Item -Path $DownloadDir -ItemType Directory -Force | Out-Null                
		    }
		    Catch
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
		    Catch
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
		    Catch
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
		}
		Catch
		{
            Write-Host Error creating directory $DriverDownloadFolder `n
			Write-Error "$($_.Exception)"
            exit(1)
		}
        
        
        # *** To Download the Driver Cab Catalog. ***

        try {
              Write-Host Downloading DriverPackCatalog file... `n          
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
              }
              else
              {
                    Write-Host DriverPackCatalog file is not downloaded! `n -BackgroundColor Red 
                    exit(1)
              }              
            }
        catch [System.Net.WebException]
            {
                Write-Error "$($_.Exception)"
                exit(1)
            }


        # *** To Extract the DriverPackCatalog file. ***
        
        try {
                Write-Host Extracting DriverPackCatalog file... `n  
                expand -r $DriverCabCatalogFile $DriverDownloadFolder
                if (Test-Path "$DriverCatalogXMLFile")
			    {
                   Write-Host DriverPackCatalog file extraction successful. `n
                }
                else
                {
                    Write-Host DriverPackCatalog XML file extraction failed! `n -BackgroundColor Red 
                    exit(1)
                }               	                        
            }
        catch [Exception] 
            {
                Write-Error "$($_.Exception)"
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
                        Write-Host "Total time taken to download driver $DriverPackageName (hh:mm:ss.ms): $TotalDriverDownloadTime `n"    
                        # MD5 hash from the xml file           		
		                $MD5Hash = $DriverPackage.Cryptography.Hash | Where-Object { $_.algorithm -eq 'SHA256' } | Select-Object -ExpandProperty "#text"       
                        # MD5 hash of the downloaded driver file
                        $DriverFileMD5Hash = Get-FileHash $DriverDownloadDestPath -Algorithm SHA256                                                        
		                if($MD5Hash -eq $DriverFileMD5Hash.Hash)
                        {
                            Write-Host "MD5 hash match successful - $DriverPackageName. `n"
                        }
                        else
                        {
                            Write-Host "MD5 has match failed. Hence, deleting the driver file $DriverPackageName. `n"
                            Remove-Item -Path $DriverDownloadDestPath -Recurse -Force | Out-Null
                        }
                    }
                    else
                    {
                        Write-Host "Driver download failed: $DriverPackageName `n"
                    }                  
			                                  
		        }		            
		
	        }
            
            if($NoDriverMatchFound -eq $true)
            {
                Write-Host "No Driver Match found for the SystemID: $SystemID, OS: $SystemOS. `n"
                Write-Host "Contact Dell Support. `n"
            }	

            }
        catch [Exception] 
            {
                Write-Error "$($_.Exception)"
            }
		
	}	
	catch
	{
		Write-Error "$($_.Exception)"
	}
	Finally
	{
        # Delete DriverPackCatalog.cab file	
        if($DriverCabCatalogFile)
        {	
            if(Test-Path $DriverCabCatalogFile) 
            {
                Remove-Item -Path $DriverCabCatalogFile -Recurse -Force | Out-Null
            }
        }
        # Delete DriverPackCatalog.xml file
        if($DriverCatalogXMLFile)
        {
            if(Test-Path $DriverCatalogXMLFile)
            {
                Remove-Item -Path $DriverCatalogXMLFile -Recurse -Force | Out-Null
            }
        }
		Write-Host "Function Get-DellDriverFiles Executed"
	}
}

