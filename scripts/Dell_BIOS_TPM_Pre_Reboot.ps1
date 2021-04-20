<#
_author_ = Prateek Vishwakarma <Prateek_Vishwakarma@Dell.com>
_version_ = 1.0

Copyright © 2021 Dell Inc. or its subsidiaries. All Rights Reserved.

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
   Set-DellBIOSTPM Cmdlet used to Enable TpmSecurity BIOS attribute using Dell BIOS DirectWMI capabilities.
   IMPORTANT: Configuring TPM is handled using two scripts as Local System Restart is involved. These scripts in their order of execution are
				1. 4_1_Dell_BIOS_TPM.ps1 - enables TPMSecurity and Restarts the local system (optional)
				2. 4_2_Dell_BIOS_TPM.ps1 - activates TPM (TpmActivation) and Restarts the local system (optional)
	For more information on TPM, refer to the following Dell Whitepaper -
	http://downloads.dell.com/solutions/general-solution-resources/White%20Papers/Securing%20Dell%20Commercial%20Systems%20with%20Trusted%20Platform%20Module%20(TPM).pdf 
	
   IMPORTANT: Make sure you are using latest Powershell version 5 or newer to execute this cmdlet. Execute "Get-Host" to check the version.
   IMPORTANT: Make sure direct WMI capabilities are supported on the system.
   IMPORTANT: Scope of this Script is to configure TpmSecurity BIOS attribute and restart local machine (optional)
   IMPORTANT: TPM cannot be disabled or deactivated using Dell BIOS DirectWMI Capabilities. Disabling or deactivation
			  of the TPM can only be performed using the BIOS Setup.
	IMPORTANT: TPM can be activated or enabled in the following scenarios:
				- Administrator password is set on system.
				- TPM is not owned.
				- TPM is disabled or deactivated.
.DESCRIPTION
	Cmdlet used to Enable TpmSecurity BIOS attribute. 
   - AdminPwd, OPTIONAL, Dell BIOS Admin password, if set on the client
   - Restart, OPTIONAL, pass in -Restart switch if local system restart needs to be performed (recommended)
.EXAMPLE
	This example shows how to enable TpmSecurity. ( note - local system restart is required (manually or through Intune MDM) for the changes to take effect )
	Set-DellBIOSTPM -AdminPwd "P@ssword"
.EXAMPLE
    This example shows how to enable TpmSecurity and Restart the local system. 
	Set-DellBIOSTPM -AdminPwd "P@ssword" -Restart
#>


Function Is-DellBIOSPasswordSet
{
    param(
        [parameter(Mandatory=$true, 
			HelpMessage="Enter Password Type. e.g. Admin")]
        [ValidateNotNullOrEmpty()]
		[ValidateSet("Admin", "System")]
        [string]$PwdType
    )
	
	try
	{
		$IsPasswordSet = Get-CimInstance -Namespace root/dcim/sysman/wmisecurity -ClassName PasswordObject | Where-Object NameId -EQ $PwdType | Select-Object -ExpandProperty IsPasswordSet -ErrorAction stop
		if(1 -eq $IsPasswordSet) { Write-Host  $PwdType " password is set on the system" }
		else { Write-Host  $PwdType "password is not set on the system" }
		return $IsPasswordSet
	}
	Catch
	{
		$Exception = $_
		Write-Error "Exception:" $Exception
	}
	Finally
	{
		Write-Host "Function Is-PasswordSet Executed" 
	}
}


Function Get-DellBIOSAttributes
{
    try
	{
        #Fetch all Enumeration type Dell BIOS Attributes
        $EnumerationAttributes = Get-CimInstance -Namespace root\dcim\sysman\biosattributes -ClassName EnumerationAttribute -Select "AttributeName","CurrentValue","PossibleValue" -EA Stop

        #Fetch all Integer type Dell BIOS Attributes
        $IntegerAttributes = Get-CimInstance -Namespace root\dcim\sysman\biosattributes -ClassName IntegerAttribute -Select "AttributeName","CurrentValue","LowerBound","UpperBound" -EA Stop

        #Fetch all String type Dell BIOS Attributes
        $StringAttributes = Get-CimInstance -Namespace root\dcim\sysman\biosattributes -ClassName StringAttribute -Select "AttributeName","CurrentValue","MinLength","MaxLength" -EA Stop

        #Create a single list object
        $BIOSAttributes = $EnumerationAttributes + $IntegerAttributes + $StringAttributes | Sort-Object AttributeName

        return $BIOSAttributes
    }
    catch
    {
        $Exception = $_
		Write-Error "Exception:" $Exception
    }
    Finally
    {
        Write-Host "Function Get-DellBIOSAttribute Executed"
    }
}


Function Set-DellBIOSAttribute
{
    #Sets a Dell BIOS Attribute

    param(
        [Parameter(Mandatory=$true, HelpMessage="Enter Dell BIOS AttributeName. e.g. UefiNwStack")]
		[ValidateNotNullOrEmpty()]
        [String]$AttributeName,
        [Parameter(Mandatory=$true, HelpMessage="Enter Dell BIOS AttributeValueName. e.g. Disabled")]
		[ValidateNotNull()]
        [AllowEmptyString()]
        [String]$AttributeValueName,
        [Parameter(Mandatory=$false, HelpMessage="Enter Dell BIOS Admin Password (if applicable)")]
		[ValidateNotNullOrEmpty()]
        [String]$AdminPwd
    )
    
    try
    {
        #Get BIOSAttributeInterface Class Object
	    $BAI = Get-CimInstance -Namespace root/dcim/sysman/biosattributes -ClassName BIOSAttributeInterface -EA stop

        #check if Admin password is set on the box
	    $IsBIOSAdminPasswordSet = Is-DellBIOSPasswordSet -PwdType "Admin" -EA stop
		
	    #Perform a Get Operation to ensure that the given BIOS Attribute is applicable on the SUT and fetch the possible values
	    $BIOSAttributes = Get-DellBIOSAttributes

	    $CurrentValue = $BIOSAttributes | Where-Object AttributeName -eq $AttributeName | Select-Object -ExpandProperty CurrentValue -EA Stop

	    if($NULL -ne $CurrentValue)
	    {
		    #Check if Attribute is already set to given value
		    if($CurrentValue -eq $AttributeValueName)
		    {
			    Write-Host "Attribute "$AttributeName" is already set to "$AttributeValueName""
		    }

		    #Attribute is not set to given value
		    else
		    {
                if($IsBIOSAdminPasswordSet)
                {
                    if(!([String]::IsNullOrEmpty($AdminPwd)))
			        {
				        #Get encoder for encoding password
	                    $encoder = New-Object System.Text.UTF8Encoding
   
                        #encode the password
                        $AdminBytes = $encoder.GetBytes($AdminPwd)

                        #Configure BIOS Attribute
                        $status = $BAI | Invoke-CimMethod -MethodName SetAttribute -Arguments @{AttributeName=$AttributeName; AttributeValue=$AttributeValueName; SecType=1; SecHndCount=$AdminBytes.Length; SecHandle=$AdminBytes;} | Select-Object -ExpandProperty Status -EA stop
			        }
			        else
			        {
				        throw "Admin Password is required for this operation"
                    
			        }                
                }
                else
                {
                    #Configure BIOS Attribute
                    $status = $BAI | Invoke-CimMethod -MethodName SetAttribute -Arguments @{AttributeName=$AttributeName; AttributeValue=$AttributeValueName; SecType=0; SecHndCount=0; SecHandle=@()} | Select-Object -ExpandProperty Status -EA stop 
                }
           
               switch ( $status )
		        {
			        0 { $result = 'Success'
				        break
				        }
			        1 { $result = 'Failed'    
				        break
				        }
			        2 { $result = 'Invalid Parameter'   
				        break
				        }
			        3 { $result = 'Access Denied, Provide Correct Admin Password' 
				        break
				        }
			        4 { $result = 'Not Supported'  
				        break
				        }
			        5 { $result = 'Memory Error'    
				        break
				        }
			        6 { $result = 'Protocol Error'  
				        break
				        }
			        default { $result ='Unknown' 
				        break
				        }
		        }
          	
		    }
	    }
	    #BIOS Attribute not present
	    else
	    {
		    Write-Host "Attribute:" $AttributeName "not present on the system" 
	    }
    }
    catch
    {
        $Exception = $_
		Write-Host $Exception
    }
    finally
    {
        Write-Host $result
		Write-Host "Function Set-DellBIOSAttribute Executed"
    }
}


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
	catch
	{
		$Exception = $_
		Write-Host $Exception
	}
	finally
	{
		Write-Host "Restart-DellComputer Executed"
	}	
}


Function Set-DellBIOSTPM
{
		param(	
			[parameter(Mandatory=$true, HelpMessage="Enter BIOS Admin Password. e.g. dell_admin ")]
			[ValidateNotNullOrEmpty()]
			[string]$AdminPwd,

			[parameter(Mandatory=$false, HelpMessage="use -Restart switch if system Restart needs to be performed")]
			[switch]$Restart
		)
		try{
			
			#check if Admin password is set on the box
			$IsBIOSAdminPasswordSet = Is-DellBIOSPasswordSet -PwdType "Admin" -EA stop
			
			if(!($IsBIOSAdminPasswordSet))
			{
				throw "Admin Password should be set to configure TPM"
			}
			
			#Enable TpmSecurity to activate TPM later
			Set-DellBIOSAttribute -AttributeName "TpmSecurity" -AttributeValueName "Enabled" -AdminPwd $AdminPwd -EA stop
			
			#After that restart the device, using Intune MDM or using PowerShell script.
			#restart the system if required, using Powershell Script
            if($Restart)
            {
				#CAUTION: USER MIGHT LOSE UNSAVED WORK
			    Restart-DellComputer -Seconds 10
			}			
		}	
		catch
		{
			$Exception = $_
			Write-Host $Exception
		}
		finally
		{
			Write-Host $result
			Write-Host "Function Set-DellBIOSTPM Executed"	
		}
}



