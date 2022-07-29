<#
_author_ = Mazahir Ahmad Khan <Mazahir_Ahmad_Khan@Dell.com>
_version_ = 1.0

Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.

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
   Set-UEFIforcedNetworkFlag is used to set FORCED_NETWORK_FLAG value.
   UnComment Last three lines or add EXAMPLE lines at bottom to run the script.
.DESCRIPTION
   FORCED_NETWORK_FLAG is set to 1 using this script.

.EXAMPLE
$bytes = New-Object Byte[](4)
$bytes[0]=1
Set-UEFIforcedNetworkFlag -VariableName FORCED_NETWORK_FLAG -Namespace "{616e2ea6-af89-7eb3-f2ef-4e47368a657b}" -ByteArray $bytes
#>

$definition = @'
 using System;
 using System.Runtime.InteropServices;
 using System.Text;
   
 public class UEFINative
 {
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern UInt32 GetFirmwareEnvironmentVariableA(string lpName, string lpGuid, [Out] Byte[] lpBuffer, UInt32 nSize);
 
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern UInt32 SetFirmwareEnvironmentVariableA(string lpName, string lpGuid, Byte[] lpBuffer, UInt32 nSize);
 }
'@

$uefiNative = Add-Type $definition -PassThru


function Set-UEFIforcedNetworkFlag
{
    [cmdletbinding()]  
    Param(
        [Parameter(Mandatory=$true, HelpMessage="Enter {616e2ea6-af89-7eb3-f2ef-4e47368a657b} GUIID for FORCED_NETWORK_FLAG")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("{616e2ea6-af89-7eb3-f2ef-4e47368a657b}")]
        [String]$Namespace,

        [Parameter(Mandatory=$true, HelpMessage="Enter FORCED_NETWORK_FLAG")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("FORCED_NETWORK_FLAG")]
        [String]$VariableName,

        [Parameter()]
        [String]$Value = "",

        [Parameter()]
        [Byte[]]$ByteArray = $null
    )

    BEGIN {
        $rc = Set-Privilege -Privilege SeSystemEnvironmentPrivilege
        if ($rc -eq 0)
        {
            Write-Error "Unable to change privilege"
            return ""
        }
    }
    PROCESS {
        if ($Value -ne "")
        {
            $enc = [System.Text.Encoding]::ASCII
            $bytes = $enc.GetBytes($Value)
            Write-Verbose "Setting variable $VariableName to a string value with $($bytes.Length) characters"
            $rc = $uefiNative[0]::SetFirmwareEnvironmentVariableA($VariableName, $Namespace, $bytes, $bytes.Length)
        }
        else
        {
            Write-Verbose "Setting variable $VariableName to a byte array with $($ByteArray.Length) bytes"
            $rc = $uefiNative[0]::SetFirmwareEnvironmentVariableA($VariableName, $Namespace, $ByteArray, $ByteArray.Length)
        }
        if ($rc -eq 0)
        {
            Write-Error "Unable to set variable $VariableName from namespace $Namespace"
        }
    }
    END {
        $rc = Set-Privilege -Privilege SeSystemEnvironmentPrivilege -Disable
        if ($rc -eq 0)
        {
            Write-Error "Unable to change privilege"
            return ""
        }
    }

}


function Set-Privilege
{   
[cmdletbinding(  
    ConfirmImpact = 'low',
    SupportsShouldProcess = $false
)]  

[OutputType('System.Boolean')]

Param(

    [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$False,HelpMessage='pass SeSystemEnvironmentPrivilege')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("SeSystemEnvironmentPrivilege")]
    [String]$Privilege,

    [Parameter(Position=1)]
    [ValidateNotNullOrEmpty()]
    $ProcessId = $pid,

    [Switch]$Disable
   )

BEGIN {

    ${CmdletName} = $Pscmdlet.MyInvocation.MyCommand.Name

$definition = @'
 using System;
 using System.Runtime.InteropServices;
   
 public class AdjPriv
 {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
   
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
 
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
 
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid
  {
   public int Count;
   public long Luid;
   public int Attr;
  }
   
  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
 
  public static bool EnablePrivilege(long processHandle, string privilege, bool disable)
  {
   bool retVal;
   TokPriv1Luid tp;
   IntPtr hproc = new IntPtr(processHandle);
   IntPtr htok = IntPtr.Zero;
   retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
   tp.Count = 1;
   tp.Luid = 0;
   if(disable)
   {
    tp.Attr = SE_PRIVILEGE_DISABLED;
   }
   else
   {
    tp.Attr = SE_PRIVILEGE_ENABLED;
   }
   retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
   retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
   return retVal;
  }
 }
'@



} # end BEGIN

PROCESS {

    $processHandle = (Get-Process -id $ProcessId).Handle
    if ($processHandle -eq 0)
    {
        Write-Error "Unable to get process"
        return ""
    }
    
    $adjprivobj = Add-Type $definition -PassThru
    $adjprivobj[0]::EnablePrivilege($processHandle, $Privilege, $Disable)

} # end PROCESS

END { Write-Verbose "Function ${CmdletName} finished." }

} # end Function Set-Privilege

#$bytes = New-Object Byte[](4)
#$bytes[0]=1
#Set-UEFIforcedNetworkFlag -VariableName FORCED_NETWORK_FLAG -Namespace "{616e2ea6-af89-7eb3-f2ef-4e47368a657b}" -ByteArray $bytes
