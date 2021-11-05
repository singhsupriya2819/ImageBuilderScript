#Function1 - Disable Enhanced Security for Internet Explorer
Function Disable-InternetExplorerESC
{
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force -ErrorAction SilentlyContinue -Verbose
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force -ErrorAction SilentlyContinue -Verbose
    #Stop-Process -Name Explorer -Force
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green -Verbose
}

#Function2 - Enable File Download on Windows Server Internet Explorer
Function Enable-IEFileDownload
{
    $HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
    $HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
    Set-ItemProperty -Path $HKLM -Name "1803" -Value 0 -ErrorAction SilentlyContinue -Verbose
    Set-ItemProperty -Path $HKCU -Name "1803" -Value 0 -ErrorAction SilentlyContinue -Verbose
    Set-ItemProperty -Path $HKLM -Name "1604" -Value 0 -ErrorAction SilentlyContinue -Verbose
    Set-ItemProperty -Path $HKCU -Name "1604" -Value 0 -ErrorAction SilentlyContinue -Verbose
}

#Function3 - Enable Copy Page Content in IE
Function Enable-CopyPageContent-In-InternetExplorer
{
    $HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
    $HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
    Set-ItemProperty -Path $HKLM -Name "1407" -Value 0 -ErrorAction SilentlyContinue -Verbose
    Set-ItemProperty -Path $HKCU -Name "1407" -Value 0 -ErrorAction SilentlyContinue -Verbose
}

#Function Install Chocolatey
Function4 InstallChocolatey
{   
    #[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
    #[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
    $env:chocolateyUseWindowsCompression = 'true'
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -Verbose
    choco feature enable -n allowGlobalConfirmation

}

#Function5 Disable PopUp for network configuration

Function DisableServerMgrNetworkPopup
{
    Set-Location -Path HKLM:\
    New-Item -Path HKLM:\System\CurrentControlSet\Control\Network -Name NewNetworkWindowOff -Force 

    Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
}

#Function6
Function CreateLabFilesDirectory
{
    New-Item -ItemType directory -Path C:\LabFiles -force
}

#Function7
Function DisableWindowsFirewall
{
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

}

#Function8
Function Show-File-Extension
{
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Set-ItemProperty $key HideFileExt 0
    Stop-Process -processname explorer
}



#Function9 - InstallPowerBIDesktop
Function InstallPowerBiDesktopChoco
{
    choco install powerbi -y -force

}

#Function10
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

#Function11 Create Azure Credential File on Desktop
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

#Function12 Install Cloudlabs Modern VM (Windows Server 2012,2016,2019, Windows 10) Validator
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

#Function13 Install Cloudlabs Legacy VM (Windows Server 2008R2) Validator
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

#Function13 Install SQl Server Management studio
Function InstallSQLSMS
{
    choco install sql-server-management-studio -y -force
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Microsoft SQL Server Management Studio 18.lnk")
    $Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"
    $Shortcut.Save()

}

#Function14- Install Azure Powershell Az Module
Function InstallAzPowerShellModule
{
    choco install az.powershell -y -force

}

#Function 15
Function InstallAzCLI
{
    choco install azure-cli -y -force
}

#Function 16
Function InstallGoogleChrome
{

    choco install googlechrome -y -force

}

#Function 17
Function InstallVSCode
{

    choco install vscode -y -force

}

#Function 18
Function InstallGitTools
{

    choco install git.install -y -force

}

#Function 19
Function InstallPutty
{

    choco install putty.install -y -force

}

#Function 20
Function InstallAdobeReader
{

    choco install adobereader -y -force

}

#Function 21

Function InstallFirefox
{

    choco install firefox -y -force

}

#Function 22
Function Install7Zip
{

    choco install 7zip.install -y -force

}

#Function 23
Function Installvisualstudio2019community
{

    choco install visualstudio2019community -y -force

}

#Function 24
Function InstallEdgeChromium
{

    choco install microsoft-edge -y -force
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Azure Portal.lnk")
    $Shortcut.TargetPath = """C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"""
    $argA = """https://portal.azure.com"""
    $Shortcut.Arguments = $argA 
    $Shortcut.Save()

}


Function Install-dotnet3.1
{

    choco install dotnetcore-sdk -y -force

}

#Function Install-dotnet3.1
#{
#$WebClient = New-Object System.Net.WebClient
#$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/software/dotnet-install.ps1","C:\Packages\dotnet-install.ps1")
#Set-Location C:\Packages
#./dotnet-install.ps1 -Channel 3.1 -Runtime dotnet -Version 3.1.4 -InstallDir 'C:\Program Files\dotnet'

#}


#Function 25
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

#Function 26
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

#Function 27     
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

#Function 28   
Function SoftwarePolicies   
{
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\" -Name "Reliability" –Force
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability' `
                    -Name ShutdownReasonOn `
                    -Value 0x00000000 `
                    -PropertyType DWORD `
                    -Force 
    New-Item -Path "HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Windows NT\" -Name "Reliability" –Force
    New-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Windows NT\Reliability' `
                    -Name ShutdownReasonOn `
                    -Value 0x00000000 `
                    -PropertyType DWORD `
                    -Force
}                    

#Function 29
Function WindowsServerCommon
{
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
Disable-InternetExplorerESC
Enable-IEFileDownload
Enable-CopyPageContent-In-InternetExplorer
InstallChocolatey
DisableServerMgrNetworkPopup
CreateLabFilesDirectory
DisableWindowsFirewall
InstallEdgeChromium
}
