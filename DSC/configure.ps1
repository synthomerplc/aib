#    WVD Script Parameters   #
##############################
Param (
    [Parameter(Mandatory=$true)]
        [string]$RegistrationToken          
)

#    WVD Variables   #
$LocalWVDpath            = "c:\temp\wvd\"
$WVDBootURI              = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$WVDAgentURI             = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$WVDAgentInstaller       = 'WVD-Agent.msi'
$WVDBootInstaller        = 'WVD-Bootloader.msi'

#create directory
if((Test-Path c:\temp) -eq $false) {
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "Create C:\temp Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating temp directory"
    New-Item -Path c:\temp -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "C:\temp Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "temp directory already exists"
}
if((Test-Path $LocalWVDpath) -eq $false) {
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "Create C:\temp\WVD Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating c:\temp\wvd directory"
    New-Item -Path $LocalWVDpath -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\New-WVDSessionHost.log "C:\temp\WVD Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "c:\temp\wvd directory already exists"
}
New-Item -Path c:\ -Name New-WVDSessionHost.log -ItemType File
Add-Content `
-LiteralPath C:\New-WVDSessionHost.log `
"
ProfilePath       = $ProfilePath
RegistrationToken = $RegistrationToken
"

#download wvd components
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Downloading WVD Boot Loader"
    Invoke-WebRequest -Uri $WVDBootURI -OutFile "$LocalWVDpath$WVDBootInstaller"
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Downloading WVD Agent"
    Invoke-WebRequest -Uri $WVDAgentURI -OutFile "$LocalWVDpath$WVDAgentInstaller"

#    Install WVD Componants    #
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Installing WVD Bootloader"
$bootloader_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $WVDBootInstaller", `
        "/quiet", `
        "/qn", `
        "/norestart", `
        "/passive", `
        "/l* $LocalWVDpath\AgentBootLoaderInstall.txt" `
    -Wait `
    -Passthru
$sts = $bootloader_deploy_status.ExitCode
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Installing WVD Bootloader Complete"
Write-Output "Installing RDAgentBootLoader on VM Complete. Exit code=$sts`n"
Wait-Event -Timeout 5
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Installing WVD Agent"
Write-Output "Installing RD Infra Agent on VM $AgentInstaller`n"
$agent_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $WVDAgentInstaller", `
        "/quiet", `
        "/qn", `
        "/norestart", `
        "/passive", `
        "REGISTRATIONTOKEN=$RegistrationToken", "/l* $LocalWVDpath\AgentInstall.txt" `
    -Wait `
    -Passthru
Add-Content -LiteralPath C:\New-WVDSessionHost.log "WVD Agent Install Complete"
Wait-Event -Timeout 5

#    Enable Screen Capture Protection    #
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Enable Screen Capture Protection"
Push-Location 
Set-Location "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
New-ItemProperty `
    -Path .\ `
    -Name fEnableScreenCaptureProtection `
    -Value "1" `
    -PropertyType DWord `
    -Force
Pop-Location

#    Restart Computer    #
Add-Content -LiteralPath C:\New-WVDSessionHost.log "Process Complete - REBOOT"
Restart-Computer -Force 