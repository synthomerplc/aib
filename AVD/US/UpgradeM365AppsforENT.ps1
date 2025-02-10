# Define the path to the log folder
$logFolderPath = "C:\AIBAppLogs"

# Ensure the log folder exists
if (-not (Test-Path -Path $logFolderPath)) {
    New-Item -ItemType Directory -Path $logFolderPath
    "$(Get-DateTimeUKFormat) - Created log folder at $logFolderPath" | Out-File -FilePath $logFilePath -Append
} else {
    "$(Get-DateTimeUKFormat) - Log folder already exists at $logFolderPath" | Out-File -FilePath $logFilePath -Append
}

# Function to get the current Office version
function Get-OfficeVersion {
    return Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\O365ProPlusRetail - en-us" -Name "DisplayVersion"
}

# Function to format the date and time in UK format
function Get-DateTimeUKFormat {
    return (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
}

# Define the log file path
$logFilePath = Join-Path -Path $logFolderPath -ChildPath "OfficeUpdateLog.txt"

# Log the start of the script
"$(Get-DateTimeUKFormat) - Starting the Office update script" | Out-File -FilePath $logFilePath -Append

# Get the current Office version before the update
$versionBeforeUpdate = Get-OfficeVersion

# Log the version before the update
"$(Get-DateTimeUKFormat) - Version before update: $versionBeforeUpdate" | Out-File -FilePath $logFilePath -Append

# Define the update command within a script block
$updateScriptBlock = {
    & "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe" /update user displaylevel=false forceappshutdown=true
}

# Log the start of the update process
"$(Get-DateTimeUKFormat) - Starting the Office update process" | Out-File -FilePath $logFilePath -Append

# Execute the update command
Invoke-Command -ScriptBlock $updateScriptBlock

# Log that the update command was executed
"$(Get-DateTimeUKFormat) - Update command executed" | Out-File -FilePath $logFilePath -Append

# Wait for 15 minutes
Start-Sleep -Seconds 900

# Get the current Office version after the update
$versionAfterUpdate = Get-OfficeVersion

# Log the version after the update
"$(Get-DateTimeUKFormat) - Version after update: $versionAfterUpdate" | Out-File -FilePath $logFilePath -Append

# Log the completion of the script
"$(Get-DateTimeUKFormat) - Office update script completed" | Out-File -FilePath $logFilePath -Append