# Define the log file path
$logFile = "C:\AIBLogs\TeamsMeetingAddinInstall.log"

# Create or clear the log file
New-Item -Path $logFile -ItemType File -Force | Out-Null

# Log function
function Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append
    Write-Host "$timestamp - $message"
}

# Log start of the process
Log "Starting Teams Meeting Add-in installation."

# Store the full path of the MSI file in a variable
$msiPath = (Get-ChildItem -Path 'C:\Program Files\WindowsApps' -Filter 'MSTeams*' | Select-Object -ExpandProperty FullName) + "\MicrosoftTeamsMeetingAddinInstaller.msi"

# Check if the MSI file exists
if (Test-Path -Path $msiPath) {
    Log "MSI file found at path: $msiPath"
    
    # Execute the msiexec command with the silent install options
    Log "Executing msiexec command."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" Reboot=ReallySuppress ALLUSERS=1 TARGETDIR=`"C:\Program Files (x86)\Microsoft\TeamsMeetingAddin`" /qn /l*v `"C:\AIBTemp\TeamsMeetingAddinInstallMSI.log`"" -Wait -NoNewWindow
    
    # Check the exit code of the msiexec process
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        Log "MSI installation completed successfully."
        
        # Verify the installation
        $targetDir = "C:\Program Files (x86)\Microsoft\TeamsMeetingAddin"
        if (Test-Path -Path $targetDir) {
            Log "Target directory exists: $targetDir"
            
            # Check for expected files
            $expectedFiles = @("AddinInstaller.dll", "AddinInstaller.InstallState")
            $allFilesExist = $true
            foreach ($file in $expectedFiles) {
                if (-not (Test-Path -Path "$targetDir\$file")) {
                    Log "Expected file missing: $file"
                    $allFilesExist = $false
                }
            }
            if ($allFilesExist) {
                Log "All expected files are present. Installation verification successful."
            } else {
                Log "Some expected files are missing. Installation verification failed."
            }
        } else {
            Log "Target directory does not exist. Installation verification failed."
        }
    } else {
        Log "MSI installation failed with exit code: $exitCode"
    }
} else {
    Log "MSI file not found at path: $msiPath"
}

# Log end of the process
Log "Teams Meeting Add-in installation process completed."

# Add Registry Keys for loading the Add-in
Log "Adding registry keys for loading the Add-in."

try {
    New-Item -Path "HKLM:\Software\Microsoft\Office\Outlook\Addins" -Name "TeamsAddin.FastConnect" -Force -ErrorAction Stop
    Log "Registry key 'HKLM:\Software\Microsoft\Office\Outlook\Addins\TeamsAddin.FastConnect' created or already exists."
    
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Office\Outlook\Addins\TeamsAddin.FastConnect" -Type "DWord" -Name "LoadBehavior" -Value 3 -Force -ErrorAction Stop
    Log "Registry property 'LoadBehavior' set to 3."

    New-ItemProperty -Path "HKLM:\Software\Microsoft\Office\Outlook\Addins\TeamsAddin.FastConnect" -Type "String" -Name "Description" -Value "Microsoft Teams Meeting Add-in for Microsoft Office" -Force -ErrorAction Stop
    Log "Registry property 'Description' set to 'Microsoft Teams Meeting Add-in for Microsoft Office'."

    New-ItemProperty -Path "HKLM:\Software\Microsoft\Office\Outlook\Addins\TeamsAddin.FastConnect" -Type "String" -Name "FriendlyName" -Value "Microsoft Teams Meeting Add-in for Microsoft Office" -Force -ErrorAction Stop
    Log "Registry property 'FriendlyName' set to 'Microsoft Teams Meeting Add-in for Microsoft Office'."
} catch {
    Log "Error occurred while adding registry keys: $_"
}

Log "Registry key setup process completed."
