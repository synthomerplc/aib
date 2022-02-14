### NOTE: If resubmitting an AIB template to the existing resource group then the managed identity, gallery and gallery definition steps do not need to be reran.

# Log In
Connect-AzAccount

# View current subscription
Get-AzContext

# Set subscription (use this to change subscription, if needed - Note: Window appears in background)
Get-AzSubscription | Out-Gridview -PassThru | Select-AzSubscription

# Step 1: Import module
Import-Module Az.Accounts

#### Setting Variables - STEP 1

# get existing context
$currentAzContext = Get-AzContext

# destination image resource group
$imageResourceGroup="rg-aib-wus-001"

# AIB location (see possible locations in main docs - https://docs.microsoft.com/en-us/azure/virtual-machines/image-builder-overview#regions)
$location="westcentralus"

# what regions should the image be distribtued to?
$regions="centralus"

# your subscription, this will get your current subscription
$subscriptionID=$currentAzContext.Subscription.Id

# image template name
$imageTemplateName="AVDWin10MultiImage"

# distribution properties object name (runOutput), i.e. this gives you the properties of the managed image on completion
$runOutputName="sigOutput"

# Define Tags
$tags = @{"ApplicationName"="AVD"; "BusinessUnit"="Shared" ; "Env"="Prod" ; "DR"="Essential" ; "Owner"="someone@synthomer.com"}

# create resource group
New-AzResourceGroup -Name $imageResourceGroup -Location $location -Tag $tags

#### Creating the User Identity (Service Account) - STEP 2
# setup role def names, these need to be unique
$imageRoleDefName="Azure Image Builder Image Def"
$idenityName="AIBIdentity"

## Add AZ PS modules to support AzUserAssignedIdentity and Az AIB
'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object {Install-Module -Name $_ -AllowPrerelease}

# create identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName -Tag $Tags

$idenityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).Id
$idenityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).PrincipalId

#### Assign permissions to Identity created previously - Step three.

$aibRoleImageCreationUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
$aibRoleImageCreationPath = "aibRoleImageCreation.json"

# download config
Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

# create role definition
New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json

# grant role definition to image builder service principal (Note: if you see an error on this, wait 10 minutes and try again!)
New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve:
https://docs.microsoft.com/en-us/azure/role-based-access-control/troubleshooting

#### Create Azure Compute Gallery - Step five.

$sigGalleryName= "ACGWUS001"
$imageDefName ="Win10AVD"

# create gallery
New-AzGallery -GalleryName $sigGalleryName -ResourceGroupName $imageResourceGroup -Location $location -Tag $tags

# create gallery definition
New-AzGalleryImageDefinition -GalleryName $sigGalleryName -ResourceGroupName $imageResourceGroup -Location $location -Name $imageDefName -Tag $tags -HyperVGeneration "V2" -OsState generalized -OsType Windows -Publisher 'Synthomer' -Offer 'Windows' -Sku 'Win10MultiAVD'

#### Configure Templates - Step six

<## Remember to update the Image SKU within the template before proceeding (You can grab the image skus from attempting to build a machine from the marketplace
 and then downloading the template approx lines 116 onwards) /##>

$templateUrl="https://raw.githubusercontent.com/synthomerplc/aib/main/AVD/US/armTemplateAVDV1.0.json"
$templateFilePath = "armTemplateAVDV1.0.json"

Invoke-WebRequest -Uri $templateUrl -OutFile $templateFilePath -UseBasicParsing

# NOTE: Make sure to run lines 50 and 51 before resubmitting template to Azure

((Get-Content -path $templateFilePath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<rgName>',$imageResourceGroup) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region>',$location) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<runOutputName>',$runOutputName) | Set-Content -Path $templateFilePath

((Get-Content -path $templateFilePath -Raw) -replace '<imageDefName>',$imageDefName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<sharedImageGalName>',$sigGalleryName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<regions>',$regions)| Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>',$idenityNameResourceId) | Set-Content -Path $templateFilePath

#### Submit the template - Part seven
New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -api-version "2021-10-01" -imageTemplateName $imageTemplateName -svclocation $location

# Optional - if you have any errors running the above, run:
$getStatus=$(Get-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName)
$getStatus.ProvisioningErrorCode 
$getStatus.ProvisioningErrorMessage

#### Build the image - Part Eight
Start-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName -NoWait

# Query the status of the image build
$getStatus=$(Get-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName)

# this shows all the properties
$getStatus | Format-List -Property *

# these show the status the build
$getStatus.LastRunStatusRunState 
$getStatus.LastRunStatusMessage
$getStatus.LastRunStatusRunSubState
