#Reference
# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/image-builder-virtual-desktop

# Set Execution Policy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process

# Install Az PowerShell Module
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

# Log In
Connect-AzAccount

# View current subscription
Get-AzContext

# Set subscription (use this to change subscription, if needed - Note: Window appears in background)
Get-AzSubscription | Out-Gridview -PassThru | Select-AzSubscription

# Register for Azure Image Builder Feature
Register-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages

# Check status - wait until RegistrationState is set to 'Registered'
Get-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages

# Register resource providers if not already registered
Get-AzResourceProvider -ProviderNamespace Microsoft.Compute, Microsoft.KeyVault, Microsoft.Storage, Microsoft.VirtualMachineImages | Where-Object RegistrationState -ne Registered | Register-AzResourceProvider

# check you are registered for the providers, ensure RegistrationState is set to 'Registered'.
Get-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
Get-AzResourceProvider -ProviderNamespace Microsoft.Storage 
Get-AzResourceProvider -ProviderNamespace Microsoft.Compute
Get-AzResourceProvider -ProviderNamespace Microsoft.KeyVault

