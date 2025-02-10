# Define Applications and directories
$appName = 'Xearch' # Edit ME
$drive = 'C:\AIBTemp'
$LocalPath = Join-Path $drive $appName
$LogDrive = 'C:\AIBAppLogs'
$LogPath = Join-Path $LogDrive "${appName}_install.log"

# Create logging function
function LogWrite {
    param([string]$logstring)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$timestamp - $logstring"
    Write-Output $logLine | Tee-Object -FilePath $LogPath -Append
}

# Install function
function Install-Application {
    param(
        [string]$url,
        [string]$fileName,
        [string[]]$arguments = @(),  # Default to empty array
        [string[]]$extraMsiArguments = @()  # Default to empty array
    )

    $outputPath = Join-Path $LocalPath $fileName
    LogWrite "Downloading application from $url"
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $outputPath -UseBasicParsing
        LogWrite "Download completed"
    }
    catch {
        LogWrite "Error during download: $_"
        return
    }

    # Install process
    LogWrite "Starting Install of $appName via $outputPath"
    try {
        if ($fileName -match "\.msi$") {
            $msiArgs = @("/i", "`"$outputPath`"", "/qn") + $extraMsiArguments
            Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait
        }
        else {
            Start-Process -FilePath "`"$outputPath`"" -ArgumentList $arguments -Wait
        }
        LogWrite "Installation completed"
    }
    catch {
        LogWrite "Error during installation: $_"
    }
}

# Create directories if they don’t exist
New-Item -Path $LocalPath -ItemType Directory -Force | Out-Null
New-Item -Path $LogDrive -ItemType Directory -Force | Out-Null
Set-Location $LocalPath

# Client installation
LogWrite "AIB Customisation: Installing $appName"
Install-Application -url 'https://staibsources002.blob.core.windows.net/applications/Live/Xearch/Xearch.msi' -fileName 'Xearch.msi' -extraMsiArguments @("/norestart")
Start-Sleep 2

# Cleanup temp directory
Set-Location "C:\"
Remove-Item -Path $LocalPath -Force -Recurse -ErrorAction SilentlyContinue
LogWrite "Cleanup completed"
