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
   Set-DellBIOSBootOrder cmdlet used to configure Boot order
.DESCRIPTION
   NOTE: Configuring boot order is supported for LEGACY and UEFI boot sequences.
   - NewBootOrder: REQUIRED, pass in the New Boot order to set e.g. Windows Boot Manager, UEFI Hard Drive, UEFI HTTPs Boot, USB NIC (IPV6)" 
   - BootListType: REQUIRED, pass in the BootListType e.g. 'LEGACY' or 'UEFI' 
   - AdminPwd, OPTIONAL, Dell BIOS Admin password, if set on the client
   IMPORTANT: You must execute and view the current boot order at least once using Get-DellBIOSBootOrder before trying to configure Boot Order.
   IMPORTANT: make sure to pass correct list for "NewBootOrder" argument otherwise INCORRECT PARAMETER error will be thrown.
   IMPORTANT: Make sure direct WMI capabilities are supported on the system.
   
.EXAMPLE
   This example shows how to configure configure UEFI BootOrder, when Dell BIOS Admin Password is not set
   Get-DellBIOSBootOrder -BootListType UEFI
   [string[]]$NewBO = @("Windows Boot Manager", "USB NIC (IPV4)", "USB NIC (IPV6)", "UEFI HTTPs Boot")
   Set-DellBIOSBootOrder -NewBootOrder $NewBO -BootListType UEFI 
.EXAMPLE
   This example shows how to configure configure UEFI BootOrder, when Dell BIOS Admin Password is set
   Get-DellBIOSBootOrder -BootListType UEFI
   [string[]]$NewBO = @("Windows Boot Manager", "USB NIC (IPV6)", "USB NIC (IPV4)", "UEFI HTTPs Boot")
   Set-DellBIOSBootOrder -NewBootOrder $NewBO -BootListType UEFI -AdminPwd "P@ssword"
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


Function Get-DellBIOSBootOrder
{
    param(

	[parameter(Mandatory=$true, HelpMessage="Enter BootListType e.g. 'LEGACY' or 'UEFI' ")]
	[ValidateSet("UEFI","LEGACY")]
	[string]$BootListType
    )

    try
    {
        $BootOrder = Get-CimInstance -Namespace root\dcim\sysman\biosattributes -ClassName BootOrder | Where-Object BootListType -eq $BootListType -EA Stop
		Write-Host $BootListType "BootOrder count:" $BootOrder.BOCount
		Write-Host $BootListType "BootOrder isActive:" $BootOrder.IsActive
        return $BootOrder
    }
    catch
    {
        $Exception = $_
		Write-Error "Exception:" $Exception
    }
    Finally
    {
        Write-Host "Function Get-DellBIOSBootOrder Executed"
    }
}


Function Set-DellBIOSBootOrder
{
    #Set BootOrder

    param(

        [parameter(Mandatory=$true, HelpMessage="Enter New Boot order to set e.g. Windows Boot Manager, UEFI Hard Drive, UEFI HTTPs Boot, USB NIC (IPV6)")]
		[ValidateNotNullOrEmpty()]
		[string[]]$NewBootOrder,
		
        [parameter(Mandatory=$true, HelpMessage="Enter BootListType e.g. 'LEGACY' or 'UEFI' ")]
		[ValidateSet("UEFI","LEGACY")]
		[string]$BootListType,
		
		[parameter(Mandatory=$false, HelpMessage="Enter BIOS Admin Password if applicable. e.g. dell_admin ")]
        [ValidateNotNullOrEmpty()]
        [string]$AdminPwd

    )
	try
	{
			
		$BOI = Get-CimInstance -Namespace root\dcim\sysman\biosattributes -ClassName SetBootOrder -EA stop	
		
		$BootOrder = Get-DellBIOSBootOrder -BootListType $BootListType -EA stop
		
		#check if Admin password is set on the box
	    $IsBIOSAdminPasswordSet = Is-DellBIOSPasswordSet -PwdType "Admin" -EA stop
			
		#Proceed Boot order operation only if BOCount member is greater than one
		if($BootOrder.BOCount -gt 1)
		{	
			[String]$CurrentBootOrder = $BootOrder | Select-Object -ExpandProperty BootOrder -EA stop
            Write-Host "Current Boot Order for" $BootListType "BootListType is" $CurrentBootOrder

			if($CurrentBootOrder -eq $NewBootOrder)
			{
				throw "Given Boot Order is already set"
			}
			
			if($IsBIOSAdminPasswordSet)
			{
				if(!([String]::IsNullOrEmpty($AdminPwd)))
				{
					#Get encoder for encoding password
					$encoder = New-Object System.Text.UTF8Encoding
   
					#encode the password
					$AdminBytes = $encoder.GetBytes($AdminPwd)
					
					$status = $BOI | Invoke-CimMethod -MethodName Set -Arguments @{BootListType=$BootListType; BootOrder=$NewBootOrder; BOCount=$NewBootOrder.Count; SecType=1; SecHndCount=$AdminBytes.Length; SecHandle=$AdminBytes;} | Select-Object -ExpandProperty Status -EA stop
				}
				else
				{
					throw "Admin Password is required for this operation"
				}
			}	
			else
			{
				$status = $BOI | Invoke-CimMethod -MethodName Set -Arguments @{BootListType=$BootListType; BootOrder=$NewBootOrder; BOCount=$NewBootOrder.Count; SecType=0; SecHndCount=0; SecHandle=@();} | Select-Object -ExpandProperty Status -EA stop
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
		else
		{
			throw "Cannot Configure BootOrder with Single Bootable device"
		}
    }
	catch
	{
		$Exception = $_
		Write-Host "Exception: $Exception "
	}
	finally
	{
        Write-Host $result
		Write-Host "Function Set-DellBIOSBootOrder Executed"		
	}
}
