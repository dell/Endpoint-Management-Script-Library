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
   Set-DellBIOSAttribute cmdlet used to set single Dell BIOS attribute at a time.
   Set-DellBIOSAttributes cmdlet used to set multiple Dell BIOS attributes at a time.
   IMPORTANT: Make sure you are using latest Powershell version 5 or newer to execute this cmdlet. Execute "Get-Host" to check the version.
   IMPORTANT: Make sure direct WMI capabilities are supported on the system.
.DESCRIPTION
   Cmdlets used to either set single or multiple Dell BIOS attributes at a time, using Dell BIOS direct WMI capabilities. 
   Make sure you pass in exact name of the attribute and value since these are case sensitive. 
   Example: For attribute 'Camera', you must pass in "Camera". Passing in "camera" will fail.
   
   - AttributeName or AttributeNames[] , REQUIRED, single or list of Dell BIOS Attribute names to be configured (case sensitive values)
   - AttributeValueName or AttributeValueNames[], REQUIRED, corresponding single or list of Dell BIOS AttributeValue names to be configured into (case sensitive values)
   - AdminPwd, OPTIONAL, Dell BIOS Admin password, if set on the client
   
.EXAMPLE
    This example shows how to configure a single Dell BIOS attribute (EnumerationAttribute) at a time, when Dell BIOS Admin Password is not set
	Set-DellBIOSAttribute -AttributeName "Camera" -AttributeValueName "Disabled"
.EXAMPLE
	This example shows how to configure a single Dell BIOS attribute (IntegerAttribute) at a time, when Dell BIOS Admin Password is not set
	Set-DellBIOSAttribute -AttributeName "AutoOnHr" -AttributeValueName "10"
.EXAMPLE
	This example shows how to configure a single Dell BIOS attribute (StringAttribute) at a time, when Dell BIOS Admin Password is not set
	Set-DellBIOSAttribute -AttributeName "Asset" -AttributeValueName "DellProperty"
.EXAMPLE
	This example shows how to configure a single Dell BIOS attribute (EnumerationAttribute) at a time, when Dell BIOS Admin Password is set
	Set-DellBIOSAttribute -AttributeName "Camera" -AttributeValueName "Enabled" -AdminPwd "P@ssword"
.EXAMPLE
	This example shows how to configure a single Dell BIOS attribute (IntegerAttribute) at a time, when Dell BIOS Admin Password is set
	Set-DellBIOSAttribute -AttributeName "AutoOnHr" -AttributeValueName "0" -AdminPwd "P@ssword"
.EXAMPLE
	This example shows how to configure a single Dell BIOS attribute (StringAttribute) at a time, when Dell BIOS Admin Password is set
	Set-DellBIOSAttribute -AttributeName "Asset" -AttributeValueName " " -AdminPwd "P@ssword"
	
.EXAMPLE
	This example shows how to configure multiple Dell BIOS attributes at a time, when Dell BIOS Admin Password is not set
	Set-DellBIOSAttributes -AttributeNames @("Camera", "AutoOnHr", "Asset") -AttributeValueNames @("Enabled", "1", "DellProperty")
.EXAMPLE
	This example shows how to configure multiple Dell BIOS attributes at a time, when Dell BIOS Admin Password is set
	Set-DellBIOSAttributes -AttributeNames @("Camera", "AutoOnHr", "Asset") -AttributeValueNames @("Enabled", "1", "DellProperty") -AdminPwd "P@ssword"
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
    #Sets a single Dell BIOS Attribute at a time

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
	    $BIOSAttributes = Get-DellBIOSAttributes -EA stop

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


Function Set-DellBIOSAttributes
{
    #Sets multiple Dell BIOS Attributes at a time

    param(
        [Parameter(Mandatory=$true, HelpMessage="Enter a list of Dell BIOS AttributeNames. e.g. Camera, AutoOnHr, Asset ")]
		[ValidateNotNullOrEmpty()]
        [String[]]$AttributeNames,
        [Parameter(Mandatory=$true, HelpMessage="Enter a list of Dell BIOS AttributeValueNames. e.g. Disabled, 1, DellProperty ")]
		[ValidateNotNull()]
        [AllowEmptyString()]
        [String[]]$AttributeValueNames,
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
	    
        $AttributeCount = $AttributeNames.Count

        if($IsBIOSAdminPasswordSet)
        {
            if(!([String]::IsNullOrEmpty($AdminPwd)))
			{
				#Get encoder for encoding password
	            $encoder = New-Object System.Text.UTF8Encoding
   
                #encode the password
                $AdminBytes = $encoder.GetBytes($AdminPwd)

                #Configure BIOS Attribute
                $status = $BAI | Invoke-CimMethod -MethodName SetAttributes -Arguments @{AttributeCount=$AttributeCount; AttributeNames=$AttributeNames; AttributeValueNames=$AttributeValueNames; SecType=1; SecHndCount=$AdminBytes.Length; SecHandle=$AdminBytes;} | Select-Object -ExpandProperty Status -EA stop
			}
			else
			{
				throw "Admin Password is required for this operation"
                    
			}                
        }
        else
        {
            #Configure BIOS Attribute
            $status = $BAI | Invoke-CimMethod -MethodName SetAttributes -Arguments @{AttributeCount=$AttributeCount; AttributeNames=$AttributeNames; AttributeValueNames=$AttributeValueNames; SecType=0; SecHndCount=0; SecHandle=@()} | Select-Object -ExpandProperty Status -EA stop 
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
    catch
    {
        $Exception = $_
		Write-Host $Exception
    }
    finally
    {
        Write-Host $result
		Write-Host "Function Set-DellBIOSAttributes Executed"
    }
}

