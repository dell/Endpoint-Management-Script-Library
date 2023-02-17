## *Script Migration*
The scripts are **migrated** as follows:

**Endpoint-Management-Script-Library/Intune Scripts/BIOS Settings/**
1. Dell_BIOS_Baseline.ps1
2. Dell_BIOS_Boot_Order.ps1
3. Dell_BIOS_Password.ps1 
4. Dell_BIOS_Persistence.ps1 
5. Dell_BIOS_Setting.ps1

**Endpoint-Management-Script-Library/Intune Scripts/TPM Activation and Security/**
1. Dell_BIOS_TPM_Post_Reboot.ps1
2. Dell_BIOS_TPM_Pre_Reboot.ps1

**Endpoint-Management-Script-Library/Intune Scripts/UEFI Variable Settings/**
1. Dell_GetForcedNetworkFlag.ps1 
2. Dell_SetForcedNetworkFlag.ps1

# *Intune client script library*
PowerShell scripting for Dell Client BIOS Direct WMI API with DMTF CIM or WMI.
Sample scripts are written in PowerShell that illustrates the usage of Dell Client BIOS Direct WMI API with WMI to manage Dell clients. These scripts can be deployed from Intune management console to manage the Dell commercial client systems.

## *Agentless BIOS manageablity*
You cannot configure the Dell client systems without installing a system management agent such as Dell Command Suite. These agents equip the system with the Dell interfaces, services, console UI, and CLI-based tools. When you introduce agent software into the system, updates and redeployment plans must be maintained.

There is another option to manage the Dell client devices without adding any agents in the system. Dell offers a PowerShell script library. This script library contains PowerShell samples on how to use the WMI interface to leverage the default namespaces that are available to manage the Dell client devices without any additional agents or tools.

Customers can experience zero-touch or agentless management aspects of the Dell commercial client platforms. The Direct WMI interface is available on the Dell commercial client systems (released to market after the calendar year 2018). You can manage the BIOS configurations on the Dell commercial client systems directly from WMI, without using additional agents or applications.

For more information about Agentless BIOS manageability, see [https://downloads.dell.com/manuals/common/dell-agentless-client-manageability.pdf]

## *Windows Management Instrumentation and PowerShell*
Windows Management Instrumentation (WMI) is the infrastructure to manage the data and operations on Windows based operating systems. 

PowerShell offers cross-platform task automation and configuration management framework through command-line instructions and scripting language. 

Most of the Dell commercial client systems are Windows-based, WMI and PowerShell are available in the IT infrastructure. This allows the IT professionals to integrate the scripts with their existing infrastructure or develop custom scripts based on their requirements. Microsoft has done a great job enhancing the PowerShell capabilities to integrate and manage WMI infrastructure.

The Dell commercial client BIOS offers configurable entities through WMI, and the script library provides sample scripts to accomplish the tasks. This method configures the Dell business client systems that contain the common interface across multiple brands, including Latitude, OptiPlex, Precision, and XPS laptops. It enhances the hardware management features and does not change across the various versions of the Windows operating systems.

## *Learning more about WMI and PowerShell*
For more details on WMI, see [https://docs.microsoft.com/en-us/windows/win32/wmisdk/wmi-start-page]
For more details on PowerShell, see [https://docs.microsoft.com/en-us/powershell/scripting/overview?view=powershell-7]
For more details on Agentless BIOS manageability, see [https://downloads.dell.com/manuals/common/dell-agentless-client-manageability.pdf]

## *Microsoft Intune*
Microsoft Intune is a cloud-based service that focuses on Mobile Device Management (MDM).
For more details on Microsoft Intune, see 
[https://docs.microsoft.com/en-us/mem/intune/fundamentals/what-is-intune]

## *Deploying a PowerShell script from Intune*
The Microsoft Intune management extension allows you to upload the PowerShell scripts in Intune. You can run these scripts on the systems which are running on Windows 10 operating systems. The management extension enhances the Mobile Device Management (MDM) capabilities. 
For more information about Deploying a PowerShell script from Intune, see 
[https://docs.microsoft.com/en-us/mem/intune/apps/intune-management-extension]

## *Intune client script library*

This GitHub library offers the PowerShell scripts that illustrate the usage of the agentless BIOS manageability to perform the following BIOS operations:
*	Configure BIOS passwords
*	Configure BIOS attribute(s)
*	Configure BIOS baseline (example, Reset BIOS to default factory settings)
*	Configure Trusted Platform Module (TPM)
*	Configure Persistence (Absolute)
*	Configure Boot Order

### *Prerequisites*
*	Dell commercial client systems that are released to market after calendar year 2018
*	Windows operating system
*	PowerShell 5.0 or later

## *Support*
This code is provided to help the open-source community and currently not supported by Dell.

## *Provide feedback or report an issue*
You can provide further feedback or report an issue by using the following link 
[https://github.com/dell/IntuneScriptLibrary]


