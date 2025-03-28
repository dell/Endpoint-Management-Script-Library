# *Script Usage*
The Dell_Intune_App_Publish.ps1 script has been created to help IT administrators to download and publish the Dell Supported application to there respective intune tenants.

# *Prerequisites*
In order to run the script the following pre-requistes needs to be met:
1) Need to install GetMSAL powershell library using below command:
        Command - Install-Module -Name MSAL.PS
        Site Link - https://www.powershellgallery.com/packages/MSAL.PS/4.2.1.3

2) Enable power shell script execution policy

# *Parameters supported:*
        -help                      : displays this help content
        -supportedapps             : List the application names, supported versions and its AppName that needs to be passed to script
        -ClientId                  : Microsoft Intune Client identification string that needs to be passed to the script
        -TenantId                  : Microsoft Intune Tenant identification string that needs to be passed to the script
        -ClientSecret              : Microsoft Intune Client Secret string that needs to be passed to the script
        -CertificateThumbprint     : Microsoft Intune Certificate Thumbprint string that needs to be passed to the script
        -CabPath                   : Path of the cab file that needs to be published to Microsft Intune
        -AppName                   : Application Name that needs to be published to Microsft Intune
        -proxy                     : Proxy URL that needs to be passed to the script for downloading the files
        -logpath                   : FolderPath To store log Files.


# *Script Execution:*
The Script can be run in the below ways:
1) The below command display the help content of the script and different parameters that are supported:
    powershell.exe -file .\Dell_Intune_App_Publish.ps1 -help
2) In order to know the different Dell Apps supported and that can be published:
    powershell.exe -file .\Dell_Intune_App_Publish.ps1 -supportedapps -proxy "http://proxy.local:80"
4) To publish a particular dell app by downloading and deploying to Intune Tenant using client ID, Tenant ID, Client Secret:
    powershell.exe -file "Dell_Intune_App_Publish_V1.0.ps1" -ClientId "12345678-1234-1234-1234-123456789012" -TenantId "d66b5b8b-8b60-4b0f-8b60-123456789012" -ClientSecret "z98b5b8b8b604b0f8b60123456789012" -AppName "dcu" -proxy "http://proxy.local:80"
5) To publish a particular dell app by downloading and deploying to Intune Tenant using client ID, Tenant ID, Certificate Thumprint:
    powershell.exe -file "Dell_Intune_App_Publish_V1.0.ps1" -ClientId "12345678-1234-1234-1234-123456789012" -TenantId "d66b5b8b-8b60-4b0f-8b60-123456789012" -CertificateThumbprint "z98b5b8b8b604b0f8b60123456789012" -AppName "dcu" -proxy "http://proxy.local:80"
6) To publish a downloaded Dell App publish to Intune Tenant using client ID, Tenant ID, Client Secret:
    powershell.exe -file "Dell_Intune_App_Publish_V1.0.ps1" -ClientId "12345678-1234-1234-1234-123456789012" -TenantId "d66b5b8b-8b60-4b0f-8b60-123456789012" -ClientSecret "z98b5b8b8b604b0f8b60123456789012" -CabPath "C:\temp\dcu.cab" -proxy "http://proxy.local:80"
7) To publish a downloaded Dell App publish to Intune Tenant using client ID, Tenant ID, Certificate Thumprint:
    powershell.exe -file "Dell_Intune_App_Publish_V1.0.ps1" -ClientId "12345678-1234-1234-1234-123456789012" -TenantId "d66b5b8b-8b60-4b0f-8b60-123456789012" -ClientSecret "z98b5b8b8b604b0f8b60123456789012" -CabPath "C:\temp\dcu.cab" -CertificateThumbprint "z98b5b8b8b604b0f8b60123456789012" -proxy "http://proxy.local:80"
    
Note: if the environment from which this script is being run and does not need a proxy to download files from internet then the same parameter can be removed from the command line.

# *Error Code Mapping:*
    Below are the diffrent error codes that are returned by the script:
    -  0 : Success
    -  0 : Invalid Application Name
    -  2 : Invalid Parameters passed to the script
    -  3 : File Download Failure
    -  4 : Content Extraction Failure
    -  5 : json file parsing failure
    -  6 : MSAL Token Generation error
    -  7 : Win32 LOB App creation error
    -  8 : Win32 file version creation error
    -  9 : Win32 Lob App Place holder ID creation error
    - 10 : Azure Storage URI creation error
    - 11 : file chunk calculating uploading error
    - 12 : upload chunks failure
    - 13 : committing file upload error
    - 14 : Win32 App file version updation error
    - 15 : Sig verification failure
    - 16 : Prerequisite check failure
    - 17 : Admin Privilege Required
    - 18 : Directory path not Exist
    - 19 : dependency update failure in intune
    - 20 : Certificate Not Found with the given thumbprint
    - 21 : Section Not present in JSON
    