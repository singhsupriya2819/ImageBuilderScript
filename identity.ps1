# Set Variables for the commands
# Destination image resource group name
$imageResourceGroup = 'Images'
# Azure region
# Supported Regions East US, East US 2, West Central US, West US, West US 2, North Europe, West Europe
$location = 'East US'
# Name of the image to be created
$imageTemplateName = 'myWinImages'

# Distribution properties of the managed image upon completion
$runOutputName = 'myDistResults'
# Get the subscription ID
$subscriptionID = (Get-AzContext).Subscription.Id
Write-Output $subscriptionID

# Get the PowerShell modules
#'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object {Install-Module -Name $_ -AllowPrerelease}
Install-Module -Name Az.ImageBuilder -RequiredVersion 0.1.0 -Scope Currentuser
Install-Module -Name Az.ManagedServiceIdentity -RequiredVersion 0.7.1 -Scope Currentuser

# Start by creating the Resource Group
# the identity will need rights to this group
New-AzResourceGroup -Name $imageResourceGroup -Location $location

#download RoleImageDefination
#$imageRoleDef = "https://raw.githubusercontent.com/singhsupriya2819/ImageBuilderScript/main/RoleImageCreation.json"

# Create the role defination and Managed Identity names
# Use current time to verify names are unique
[int]$timeInt = $(Get-Date -UFormat '%s')
$imageRoleDefName = "Azure Image Builder Image Def $timeInt"
$identityName = "myIdentity$timeInt"

# Create the User Identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName

# Assign the identity resource and principle ID's to a variable
$identityNameResourceId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId

# Assign permissions for identity to distribute images
# downloads a .json file with settings, update with subscription settings
$RoleImageCreationUrl = 'https://raw.githubusercontent.com/singhsupriya2819/ImageBuilderScript/main/RoleImageCreation.json'
$RoleImageCreationPath = ".\RoleImageCreation.json"
# Download the file
Invoke-WebRequest -Uri $RoleImageCreationUrl -OutFile $RoleImageCreationPath -UseBasicParsing

# Update the file
$Content = Get-Content -Path $RoleImageCreationPath -Raw
$Content = $Content -replace '<subscriptionID>', $subscriptionID
$Content = $Content -replace '<rgName>', $imageResourceGroup
$Content = $Content -replace 'AIB-Role', $imageRoleDefName
$Content | Out-File -FilePath $RoleImageCreationPath -Force

# Create the Role Definition
New-AzRoleDefinition -InputFile $RoleImageCreationPath

# Grant the Role Definition to the Image Builder Service Principle
$RoleAssignParams = @{
    ObjectId = $identityNamePrincipalId
    RoleDefinitionName = $imageRoleDefName
    Scope = "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"
  }
New-AzRoleAssignment @RoleAssignParams

# Verify Role Assignment
Get-AzRoleAssignment -ObjectId $identityNamePrincipalId | Select-Object DisplayName,RoleDefinitionName


#Create Azure compute gallery
$myGalleryName = 'myImageGallerys'
$imageDefName = 'winSvrImages'

New-AzGallery -GalleryName $myGalleryName -ResourceGroupName $imageResourceGroup -Location $location

#create gallery definition
$GalleryParams = @{
  GalleryName = $myGalleryName
  ResourceGroupName = $imageResourceGroup
  Location = $location
  Name = $imageDefName
  OsState = 'generalized'
  OsType = 'Windows'
  Publisher = 'myCo'
  Offer = 'Windows'
  Sku = 'Win2019'
}
New-AzGalleryImageDefinition @GalleryParams

#create an image- src object
$SrcObjParams = @{
  SourceTypePlatformImage = $true
  Publisher = 'MicrosoftWindowsServer'
  Offer = 'WindowsServer'
  Sku = '2019-Datacenter'
  Version = 'latest'
}
$srcPlatform = New-AzImageBuilderSourceObject @SrcObjParams

#distributor object
$disObjParams = @{
  SharedImageDistributor = $true
  ArtifactTag = @{tag='dis-share'}
  GalleryImageId = "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup/providers/Microsoft.Compute/galleries/$myGalleryName/images/$imageDefName"
  ReplicationRegion = $location
  RunOutputName = $runOutputName
  ExcludeFromLatest = $false
}
$disSharedImg = New-AzImageBuilderDistributorObject @disObjParams

# Add customizer step
$imgCustomParams = @{
  PowerShellCustomizer = $true
  CustomizerName       = 'CloudLabsImageCustomizer'
  RunElevated          = $true
  scriptUri            = 'https://raw.githubusercontent.com/singhsupriya2819/ImageBuilderScript/main/BaseFunction.ps1'
}
$customizer = New-AzImageBuilderCustomizerObject @imgCustomParams



$ImgTemplateParams = @{
  ImageTemplateName = $imageTemplateName
  ResourceGroupName = $imageResourceGroup
  Source = $srcPlatform
  Distribute = $disSharedImg
  Customize = $customizer
  Location = $location
  UserAssignedIdentityId = $identityNameResourceId
}
New-AzImageBuilderTemplate @ImgTemplateParams

#verify imagebuilder creation
Get-AzImageBuilderTemplate -ImageTemplateName $imageTemplateName -ResourceGroupName $imageResourceGroup |
  Select-Object -Property Name, LastRunStatusRunState, LastRunStatusMessage, ProvisioningState

Get-AzImageBuilderTemplate -ImageTemplateName  $imageTemplateName -ResourceGroupName $imageResourceGroup | Select-Object ProvisioningState, ProvisioningErrorMessage  
