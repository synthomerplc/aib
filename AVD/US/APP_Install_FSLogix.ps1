# Define Applications and directories
$appName = 'FSLogix'
$drive = 'C:\AIBTemp'
$LocalPath = Join-Path $drive $appName
$LogDrive = 'C:\AIBAppLogs'
$LogPath = Join-Path $LogDrive "${appName}_install.log"

# Specify the relative path to the setup file inside the unzipped folder (if applicable) - THIS MAY NOT BE REQUIRED, ONLY SPECIFY IF SETUP FILE HAS BEEN UNZIPPED, REPOINT TO SETUP FILE IF APPLICABLE
$unzippedInstallerRelativePath = 'x64\Release\FSLogixAppsSetup.exe'

# Create logging function
function LogWrite {
    Param ([Parameter(Mandatory=$true)] [string] $logstring)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$timestamp - $logstring"
    Write-Output $logLine | Tee-Object -FilePath $LogPath -Append
}

# Install function
function Install-Application {
    param(
        [Parameter(Mandatory=$true)] [string] $url,
        [Parameter(Mandatory=$true)] [string] $fileName,
        [Parameter(Mandatory=$false)] [string[]] $arguments,
        [Parameter(Mandatory=$false)] [string[]] $extraMsiArguments = @()
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

    # Unzip if it's a zip file
    if ($fileName -match "\.zip$") {
        LogWrite "Zip file detected, expanding $fileName"
        try {
            Expand-Archive -LiteralPath $outputPath -DestinationPath $LocalPath -Force
            LogWrite "Zip file expanded"
            # Assuming unzipped setup file is located according to the $unzippedInstallerRelativePath
            $outputPath = Join-Path $LocalPath $unzippedInstallerRelativePath
        }
        catch {
            LogWrite "Error during expansion: $_"
            return
        }
    }

    LogWrite "Starting Install of $appName via $outputPath"
    try {
        if ($fileName -match "\.msi$" -or $outputPath -match "\.msi$") {
            $msiArgs = @("/i", "`"$outputPath`"", "/qn", "/L*v", "`"$LogPath`"") + $extraMsiArguments
            Start-Process -FilePath 'msiexec' -ArgumentList $msiArgs -Wait -NoNewWindow
        }
        else {
            Start-Process -FilePath "`"$outputPath`"" -ArgumentList $arguments -Wait -NoNewWindow
        }
        LogWrite "Installation completed"
    }
    catch {
        LogWrite "Error during installation: $_"
    }
}

# Create Directory and set location.
if (-not (Test-Path $LocalPath)) {
    New-Item -Path $LocalPath -ItemType Directory -ErrorAction Stop | Out-Null
}
if (-not (Test-Path $LogDrive)) {
    New-Item -Path $LogDrive -ItemType Directory -ErrorAction Stop | Out-Null
}
Set-Location $LocalPath

# Install application
Install-Application -url 'https://aka.ms/fslogix_download' -fileName 'FSLogixAppsSetup.zip' -arguments @('/install', '/quiet', '/norestart')

# Cleanup temp directory
Set-location "c:\"
Remove-Item -Path $LocalPath -Force -Recurse -ErrorAction SilentlyContinue
LogWrite "Cleanup completed"
