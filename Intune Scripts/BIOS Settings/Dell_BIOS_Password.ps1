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
   Set-DellBIOSPassword cmdlet used to set, change or clear BIOS passwords (system or setup(admin))
   IMPORTANT: Make sure you are using latest Powershell version 5 or newer to execute this cmdlet. Execute "Get-Host" to check the version.
   IMPORTANT: Make sure direct WMI capabilities are supported on the system.
.DESCRIPTION
   Cmdlet used to either set, change or clear BIOS passwords (system or setup) using Dell BIOS direct WMI capabilities 
   - PwdType, REQUIRED, Set, Change or clear BIOS password, pass in the type of password you want to change. Supported values are: Admin or System. NOTE: Make sure to pass in exact string value as listed (case sensitive values)
   - NewPwd, REQUIRED, Change BIOS password, pass in the new password. If you are clearing the password, pass in "" for value
   - OldPwd, OPTIONAL, Change BIOS password, pass in the old password. If you are setting new password, pass in "" for value
   - AdminPwd, OPTIONAL, Change BIOS System password, pass in the AdminPwd, if set on the client
   
.DESCRIPTION
   - Supported PwdType can be retrieved using 
   - $Supported_password_types = Get-CimInstance -Namespace root/DCIM/SYSMAN/wmisecurity -ClassName PasswordObject | Select NameId
   
.EXAMPLE
	This example shows how to freshly set BIOS Admin password
	Set-DellBIOSPassword -PwdType "Admin" -NewPwd "admin_p@ssw0rd" -OldPwd ""
.EXAMPLE
	This example shows how to change BIOS Admin password
	Set-DellBIOSPassword -PwdType "Admin" -NewPwd "new_admin_p@ssW0rd" -OldPwd "admin_p@ssw0rd"
.EXAMPLE
	This example shows how to clear BIOS Admin password
    Set-DellBIOSPassword -PwdType "Admin" -NewPwd "" -OldPwd "admin_p@ssw0rd"

.EXAMPLE
	This example shows how to set BIOS System password when BIOS Admin password is set
	Set-DellBIOSPassword -PwdType "System" -NewPwd "system_p@ssw0rd" -OldPwd "" -AdminPwd "admin_p@ssw0rd" 
.EXAMPLE
    This example shows how to change BIOS System password when BIOS Admin password is set
	Set-DellBIOSPassword -PwdType "System" -NewPwd "new_system_p@ssW0rd" -OldPwd "system_p@ssw0rd" -AdminPwd "admin_p@ssw0rd"
.EXAMPLE
	This example shows how to clear BIOS System password when BIOS Admin password is set
    Set-DellBIOSPassword -PwdType "System" -NewPwd "" -OldPwd "system_p@ssw0rd" -AdminPwd "admin_p@ssw0rd"

.EXAMPLE
	This example shows how to set BIOS System password when BIOS Admin password is not set
	Set-DellBIOSPassword -PwdType "System" -NewPwd "system_p@ssw0rd" -OldPwd ""
.EXAMPLE
	This example shows how to change BIOS System password
	Set-DellBIOSPassword -PwdType "System" -NewPwd "new_system_p@ssW0rd" -OldPwd "system_p@ssw0rd"
.EXAMPLE
	This example shows how to clear BIOS System password
    Set-DellBIOSPassword -PwdType "System" -NewPwd "" -OldPwd "system_p@ssw0rd"
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


Function Set-DellBIOSPassword
{
    param(
        [parameter(Mandatory=$true, HelpMessage="Enter Password Type. e.g. Admin ")]
        [ValidateNotNullOrEmpty()]
		[ValidateSet("Admin", "System")]
        [string]$PwdType,
		
		[parameter(Mandatory=$true, HelpMessage="Enter New Password for given PwdType. e.g dell_new ")]
        [AllowEmptyString()]
        [ValidateNotNull()]
        [string]$NewPwd,
		
		[parameter(Mandatory=$false, HelpMessage="Enter Old Password for given PwdType. e.g. dell_old ")]
        [ValidateNotNull()]
        [string]$OldPwd,
		
		[parameter(Mandatory=$false, HelpMessage="Enter BIOS Admin Password if it is applied already. e.g. dell_admin 
		It is required when user wants to set System password, when Admin password is set ")]
        [ValidateNotNull()]
        [string]$AdminPwd
	)
	
	try
	{
		$status = 1;
		
		#check if Admin password is set on the box
		$IsBIOSAdminPasswordSet = Is-DellBIOSPasswordSet -PwdType "Admin" -EA stop
		
		#Get encoder for encoding password
		$encoder = New-Object System.Text.UTF8Encoding
		
		#Get SecurityInterface Class Object
		$SI = Get-CimInstance -Namespace root/dcim/sysman/wmisecurity -ClassName SecurityInterface -EA stop
		
		
		if($PwdType -EQ "Admin")
		{
			if($IsBIOSAdminPasswordSet)
			{
				#Modify or Clear
				
				#In case of Admin password modification, $AdminPwd and $OldPwd will have same value
				$AdminBytes = $encoder.GetBytes($OldPwd)
			 
				$status = $SI | Invoke-CimMethod -MethodName SetnewPassword -Arguments @{NameId=$PwdType; NewPassword=$NewPwd; OldPassword=$OldPwd; SecType=1; SecHndCount=$AdminBytes.Length; SecHandle=$AdminBytes;} | Select-Object -ExpandProperty Status -EA stop
			
			}
			else
			{
				#Set or Modify
							
				$status = $SI | Invoke-CimMethod -MethodName SetnewPassword -Arguments @{NameId=$PwdType; NewPassword=$NewPwd; OldPassword=""; SecType=0; SecHndCount=0; SecHandle=@();} | Select-Object -ExpandProperty Status -EA stop

			}
		}
		
		elseif($PwdType -EQ "System")
		{
			#check if system password is set on the box
			$IsBIOSSystemPasswordSet = Is-DellBIOSPasswordSet -PwdType "System"
			
			#If the BIOS Admin password is set, It will be required to System password operation 
			
            if($IsBIOSAdminPasswordSet)
			{	
				# Set BIOS System Password when BIOS Admin Password is already set
				
				#validate that $AdminPwd is not empty
					
				#parameter validation
				if(!($AdminPwd))
				{
					throw "Admin Password is required for this operation"
				}
			
				$AdminBytes = $encoder.GetBytes($AdminPwd)

                if($IsBIOSSystemPasswordSet)
			    {
				    #Modify or Clear
				
				    #parameter validation
				    if(!($OldPwd))
				    {
					    throw "Old System Password is required for this operation"
				    }
				
				    $status = $SI | Invoke-CimMethod -MethodName SetnewPassword -Arguments @{NameId=$PwdType; NewPassword=$NewPwd; OldPassword=$OldPwd; SecType=1; SecHndCount=$AdminBytes.Length; SecHandle=$AdminBytes;} | Select-Object -ExpandProperty Status -EA stop
			    }
			
			    else
			    {
                    #Set
				    $status = $SI | Invoke-CimMethod -MethodName SetNewPassword -Arguments @{NameId=$PwdType; NewPassword=$NewPwd; OldPassword=""; SecType=1; SecHndCount=$AdminBytes.Length; SecHandle=$AdminBytes;} | Select-Object -ExpandProperty Status -EA stop    
						
			    }
				
			}
			else
			{
				if($IsBIOSSystemPasswordSet)
			    {
				    #Modify or Clear
				
				    #parameter validation
				    if(!($OldPwd))
				    {
					    throw "Old System Password is required for this operation"
				    }
				
				    $status = $SI | Invoke-CimMethod -MethodName SetnewPassword -Arguments @{NameId=$PwdType; NewPassword=$NewPwd; OldPassword=$OldPwd; SecType=0; SecHndCount=0; SecHandle=@();} | Select-Object -ExpandProperty Status -EA stop
			    }
			
			    else
			    {
                    #Set
				    $status = $SI | Invoke-CimMethod -MethodName SetNewPassword -Arguments @{NameId=$PwdType; NewPassword=$NewPwd; OldPassword=""; SecType=0; SecHndCount=0; SecHandle=@();} | Select-Object -ExpandProperty Status -EA stop    
						
			    }
						
			}    
            
		}			
		
		else
		{
			#flow should not come here as we have parameter validation in place
			#this case can be extended for HDD passwords when supported
			throw "This Passwordtype is not supported."
			
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
			3 { $result = 'Access Denied, Please Provide Correct Old Password/Admin Password and also adhere to Strong Password parameters applied on the system for New Password 
                            (StrongPassword, PwdUpperCaseRqd, PwdLowerCaseRqd, PwdDigitRqd, PwdSpecialCharRqd, PwdMinLen, PwdMaxLen)' 
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
	Finally
	{
		
		Write-Host $result
		Write-Host "Function Set-Password Executed"
	}
}

