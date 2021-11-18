#Lab Specific Functions 
#Function-1
Function DisableWindowsFirewall
{
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

}

#Function-2
Function InstallPowerBiDesktopChoco
{
    choco install powerbi -y -force

}

#Function-3
Function Enable-CloudLabsEmbeddedShadow($vmAdminUsername, $trainerUserName, [SecureString] $trainerUserPassword)
{
Write-Host "Enabling CloudLabsEmbeddedShadow"
#Created Trainer Account and Add to Administrators Group
$trainerUserPass = $trainerUserPassword | ConvertTo-SecureString -AsPlainText -Force

New-LocalUser -Name $trainerUserName -Password $trainerUserPass -FullName "$trainerUserName" -Description "CloudLabs EmbeddedShadow User" -PasswordNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member "$trainerUserName"

#Add Windows regitary to enable Shadow
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v Shadow /t REG_DWORD /d 2 -f

#Download Shadow.ps1 and Shadow.xml file in VM
$drivepath="C:\Users\Public\Documents"
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/Shadow.ps1","$drivepath\Shadow.ps1")
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/shadow.xml","$drivepath\shadow.xml")
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/ShadowSession.zip","C:\Packages\ShadowSession.zip")
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/executetaskscheduler.ps1","$drivepath\executetaskscheduler.ps1")
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/shadowshortcut.ps1","$drivepath\shadowshortcut.ps1")

# Unzip Shadow User Session Shortcut to Trainer Desktop
#$trainerloginuser= "$trainerUserName" + "." + "$($env:ComputerName)"
#Expand-Archive -LiteralPath 'C:\Packages\ShadowSession.zip' -DestinationPath "C:\Users\$trainerloginuser\Desktop" -Force
#Expand-Archive -LiteralPath 'C:\Packages\ShadowSession.zip' -DestinationPath "C:\Users\$trainerUserName\Desktop" -Force

#Replace vmAdminUsernameValue with VM Admin UserName in script content 
(Get-Content -Path "$drivepath\Shadow.ps1") | ForEach-Object {$_ -Replace "vmAdminUsernameValue", "$vmAdminUsername"} | Set-Content -Path "$drivepath\Shadow.ps1"
(Get-Content -Path "$drivepath\shadow.xml") | ForEach-Object {$_ -Replace "vmAdminUsernameValue", "$trainerUserName"} | Set-Content -Path "$drivepath\shadow.xml"
(Get-Content -Path "$drivepath\shadow.xml") | ForEach-Object {$_ -Replace "ComputerNameValue", "$($env:ComputerName)"} | Set-Content -Path "$drivepath\shadow.xml"
(Get-Content -Path "$drivepath\shadowshortcut.ps1") | ForEach-Object {$_ -Replace "vmAdminUsernameValue", "$trainerUserName"} | Set-Content -Path "$drivepath\shadowshortcut.ps1"
Start-Sleep 2

# Scheduled Task to Run Shadow.ps1 AtLogOn
schtasks.exe /Create /XML $drivepath\shadow.xml /tn Shadowtask

$Trigger= New-ScheduledTaskTrigger -AtLogOn
$User= "$($env:ComputerName)\$trainerUserName" 
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File $drivepath\shadowshortcut.ps1 -WindowStyle Hidden"
Register-ScheduledTask -TaskName "shadowshortcut" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force
}

#Function-4
#Create Azure Credential File on Desktop
Function CreateCredFile($AzureUserName, [SecureString] $AzurePassword, $AzureTenantID, $AzureSubscriptionID, $DeploymentID)
{
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/AzureCreds.txt","C:\LabFiles\AzureCreds.txt")
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/AzureCreds.ps1","C:\LabFiles\AzureCreds.ps1")
    
    New-Item -ItemType directory -Path C:\LabFiles -force

    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureUserNameValue", "$AzureUserName"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzurePasswordValue", "$AzurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureTenantIDValue", "$AzureTenantID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureSubscriptionIDValue", "$AzureSubscriptionID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "DeploymentIDValue", "$DeploymentID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
             
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureUserNameValue", "$AzureUserName"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzurePasswordValue", "$AzurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureTenantIDValue", "$AzureTenantID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureSubscriptionIDValue", "$AzureSubscriptionID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "DeploymentIDValue", "$DeploymentID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"

    Copy-Item "C:\LabFiles\AzureCreds.txt" -Destination "C:\Users\Public\Desktop"
}

#Function-5
#Add Service Principle details to Azure Credential Files
Function SPtoAzureCredFiles($SPDisplayName, $SPID, $SPObjectID, $SPSecretKey, $AzureTenantDomainName)
{
    Add-Content -Path "C:\LabFiles\AzureCreds.txt" -Value "AzureServicePrincipalDisplayName= $SPDisplayName" -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.txt" -Value "AzureServicePrincipalAppID= $SPID" -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.txt" -Value "AzureServicePrincipalObjectID= $SPObjectID" -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.txt" -Value "AzureServicePrincipalSecretKey= $SPSecretKey" -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.txt" -Value "AzureTenantDomainName= $AzureTenantDomainName" -PassThru

    Add-Content -Path "C:\LabFiles\AzureCreds.ps1" -Value '$AzureServicePrincipalDisplayName="SPDisplayNameValue"' -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.ps1" -Value '$AzureServicePrincipalAppID="SPIDValue"' -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.ps1" -Value '$AzureServicePrincipalObjectID="SPObjectIDValue"' -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.ps1" -Value '$AzureServicePrincipalSecretKey="SPSecretKeyValue"' -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.ps1" -Value '$AzureTenantDomainName="AzureTenantDomainNameValue"' -PassThru

    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "SPDisplayNameValue", "$SPDisplayName"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "SPIDValue", "$SPID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "SPObjectIDValue", "$SPObjectID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "SPSecretKeyValue", "$SPSecretKey"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureTenantDomainNameValue", "$AzureTenantDomainName"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"

    Copy-Item "C:\LabFiles\AzureCreds.txt" -Destination "C:\Users\Public\Desktop" -force
}

#Function-6
#Install Cloudlabs Modern VM (Windows Server 2012,2016,2019, Windows 10) Validator
Function InstallModernVmValidator
{   
    #Create C:\CloudLabs\Validator directory
    New-Item -ItemType directory -Path C:\CloudLabs\Validator -Force
    Invoke-WebRequest 'https://experienceazure.blob.core.windows.net/software/vm-validator/VMAgent.zip' -OutFile 'C:\CloudLabs\Validator\VMAgent.zip'
    Expand-Archive -LiteralPath 'C:\CloudLabs\Validator\VMAgent.zip' -DestinationPath 'C:\CloudLabs\Validator' -Force
    Set-ExecutionPolicy -ExecutionPolicy bypass -Force
    cmd.exe --% /c @echo off
    cmd.exe --% /c sc create "Spektra CloudLabs VM Agent" BinPath=C:\CloudLabs\Validator\VMAgent\Spektra.CloudLabs.VMAgent.exe start= auto
    cmd.exe --% /c sc start "Spektra CloudLabs VM Agent"
}

#Function-7
#Install Cloudlabs Legacy VM (Windows Server 2008R2) Validator
Function InstallLegacyVmValidator
{
    #Create C:\CloudLabs
    New-Item -ItemType directory -Path C:\CloudLabs\Validator -Force
    Invoke-WebRequest 'https://experienceazure.blob.core.windows.net/software/vm-validator/LegacyVMAgent.zip' -OutFile 'C:\CloudLabs\Validator\LegacyVMAgent.zip'
    Expand-Archive -LiteralPath 'C:\CloudLabs\Validator\LegacyVMAgent.zip' -DestinationPath 'C:\CloudLabs\Validator' -Force
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory('C:\CloudLabs\Validator\LegacyVMAgent.zip','C:\CloudLabs\Validator')
    Set-ExecutionPolicy -ExecutionPolicy bypass -Force
    cmd.exe --% /c @echo off
    cmd.exe --% /c sc create "Spektra CloudLabs Legacy VM Agent" binpath= C:\CloudLabs\Validator\LegacyVMAgent\Spektra.CloudLabs.LegacyVMAgent.exe displayname= "Spektra CloudLabs Legacy VM Agent" start= auto
    cmd.exe --% /c sc start "Spektra CloudLabs Legacy VM Agent"

}

#Function-8 -Install SQl Server Management studio
Function InstallSQLSMS
{
    choco install sql-server-management-studio -y -force
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Microsoft SQL Server Management Studio 18.lnk")
    $Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"
    $Shortcut.Save()
    Measure-Command { Get-EventLog "InstallSQLSMS" }

}

#Function-9
Function InstallGoogleChrome
{

    choco install googlechrome -y -force

}


#Function-10
Function InstallVSCode
{

    choco install vscode -y -force

}

#Function-11
Function InstallGitTools
{

    choco install git.install -y -force

}

#Function-12
Function InstallPutty
{

    choco install putty.install -y -force

}

#Function-13
Function InstallAdobeReader
{

    choco install adobereader -y -force

}

#Function-14
Function InstallFirefox
{

    choco install firefox -y -force

}

#Function-15
Function InstallNodeJS
{

    choco install nodejs -y -force

}

#Function-16
Function InstallDotNet4.5
{

    choco install dotnet4.5 -y -force

}
#Function-17
Function InstallDotNetFW4.8
{

    choco install dotnetfx -y -force

}

#Function-18
Function InstallPython
{

    choco install python -y -force

}
#Function-19
Function InstallWinSCP
{

    choco install winscp.install -y -force

}
#Function-20
Function InstalldockerforWindows
{

    choco install docker-for-windows -y -force

}



#Function-21
Function Expand-ZIPFile($file, $destination)
{
$shell = new-object -com shell.application
$zip = $shell.NameSpace($file)
foreach($item in $zip.items())
    {
        $shell.Namespace($destination).copyhere($item)
}
}

#Function-22
Function Download($fileurl, $destination)
{
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("$fileurl","$destination")
}

#Function-23
Function ResizeOSDiskMax()
{
# Iterate through all the disks on the Windows machine
foreach($disk in Get-Disk)
{
# Check if the disk in context is a Boot and System disk
if((Get-Disk -Number $disk.number).IsBoot -And (Get-Disk -Number $disk.number).IsSystem)
{
    # Get the drive letter assigned to the disk partition where OS is installed
    $driveLetter = (Get-Partition -DiskNumber $disk.Number | Where-Object {$_.DriveLetter}).DriveLetter
    Write-verbose "Current OS Drive: $driveLetter :\"

    # Get current size of the OS parition on the Disk
    $currentOSDiskSize = (Get-Partition -DriveLetter $driveLetter).Size        
    Write-verbose "Current OS Partition Size: $currentOSDiskSize"

    # Get Partition Number of the OS partition on the Disk
    $partitionNum = (Get-Partition -DriveLetter $driveLetter).PartitionNumber
    Write-verbose "Current OS Partition Number: $partitionNum"

    # Get the available unallocated disk space size
    $unallocatedDiskSize = (Get-Disk -Number $disk.number).LargestFreeExtent
    Write-verbose "Total Unallocated Space Available: $unallocatedDiskSize"

    # Get the max allowed size for the OS Partition on the disk
    $allowedSize = (Get-PartitionSupportedSize -DiskNumber $disk.Number -PartitionNumber $partitionNum).SizeMax
    Write-verbose "Total Partition Size allowed: $allowedSize"

    if ($unallocatedDiskSize -gt 0 -And $unallocatedDiskSize -le $allowedSize)
    {
        $totalDiskSize = $allowedSize
        
        # Resize the OS Partition to Include the entire Unallocated disk space
        $resizeOp = Resize-Partition -DriveLetter C -Size $totalDiskSize
        Write-verbose "OS Drive Resize Completed $resizeOp"
    }
    else {
        Write-Verbose "There is no Unallocated space to extend OS Drive Partition size"
    }
}   
}
}

#Function-24
Function Install-dotnet3.1
{
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/software/dotnet-install.ps1","C:\Packages\dotnet-install.ps1")
cd C:\Packages
./dotnet-install.ps1 -Channel 3.1 -Runtime dotnet -Version 3.1.4 -InstallDir 'C:\Program Files\dotnet'

}
#Function-25
Function InstallCloudLabsManualAgentFiles
{
#Download files to write deployment status
Set-Content -Path 'C:\WindowsAzure\Logs\status-sample.txt' -Value '{"ServiceCode" : "ManualStepService", "Status" : "ReplaceStatus", "Message" : "ReplaceMessage"}'
Set-Content -Path 'C:\WindowsAzure\Logs\validationstatus.txt' -Value '{"ServiceCode" : "ManualStepService", "Status" : "ReplaceStatus", "Message" : "ReplaceMessage"}'

#Download cloudlabsagent zip
Invoke-WebRequest 'https://experienceazure.blob.core.windows.net/software/cloudlabsagent/CloudLabsAgent.zip' -OutFile 'C:\Packages\CloudLabsAgent.zip'
Expand-Archive -LiteralPath 'C:\Packages\CloudLabsAgent.zip' -DestinationPath 'C:\Packages\' -Force
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
cmd.exe --% /c @echo off
cmd.exe --% /c sc create "Spektra.CloudLabs.Agent" BinPath=C:\Packages\CloudLabsAgent\Spektra.CloudLabs.Agent.exe start= auto
Start-Sleep 5
cmd.exe --% /c sc start "Spektra.CloudLabs.Agent"
Start-Sleep 5 
}

#Function-26
Function SetDeploymentStatus{
   Param(
     [parameter(Mandatory=$true)]
      [String] $ManualStepStatus,
       
       [parameter(Mandatory=$true)]
      [String] $ManualStepMessage    
       )  
  (Get-Content -Path "C:\WindowsAzure\Logs\status-sample.txt") | ForEach-Object {$_ -Replace "ReplaceStatus", "$ManualStepStatus"} | Set-Content -Path "C:\WindowsAzure\Logs\validationstatus.txt"
   (Get-Content -Path "C:\WindowsAzure\Logs\validationstatus.txt") | ForEach-Object {$_ -Replace "ReplaceMessage", "$ManualStepMessage"} | Set-Content -Path "C:\WindowsAzure\Logs\validationstatus.txt"
     }

#Function-27     
Function CloudLabsManualAgent{
<#
      SYNOPSIS
      This is a function for installing/starting the cloudlabsagent, and to send the deployment status    
#>

param(  
  #Task : to install or start the agent/ set the deployment status
      [parameter(Mandatory=$true)]
      [String]$Task      
   )
    #To install cloudlabsagent service files
    if($Task -eq 'Install')
    {
       Install-dotnet3.1
       InstallCloudLabsManualAgentFiles
    }
    #start the cloudlabs agent service
    elseif($Task -eq 'Start')
    {
      cmd.exe --% /c sc start "Spektra.CloudLabs.Agent"
      Start-Sleep 5 
    } 
   elseif($Task -eq 'setStatus')
    {
      SetDeploymentStatus -ManualStepStatus $Validstatus -ManualStepMessage $Validmessage
    }       
}

DisableWindowsFirewall
InstallPowerBiDesktopChoco
Enable-CloudLabsEmbeddedShadow
CreateCredFile
SPtoAzureCredFiles
InstallModernVmValidator
InstallLegacyVmValidator
InstallSQLSMS
InstallGoogleChrome
InstallVSCode
InstallGitTools
InstallPutty
InstallAdobeReader
InstallFirefox
InstallNodeJS
InstallDotNet4.5
InstallDotNet4.8
InstallPython
InstallWinSCP
InstalldockerforWindows
Expand-ZIPFile
Download
Resize-OSDiskMax
Install-dotnet3.1
InstallCloudLabsManualAgentFiles
SetDeploymentStatus
CloudLabsManualAgent
