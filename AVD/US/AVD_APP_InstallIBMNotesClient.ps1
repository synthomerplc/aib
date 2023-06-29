# Define Applications and directories
$appName = 'IBMNotesClient'
$drive = 'C:\AIBTemp'
$LocalPath = Join-Path $drive $appName
$LogDrive = 'C:\AIBAppLogs'
$LogPath = Join-Path $LogDrive "${appName}_install.log"
$unzippedInstaller = 'Notes 9.0.1 client\setup.exe' # THIS MAY NOT BE REQUIRED, ONLY SPECIFY IF SETUP FILE HAS BEEN UNZIPPED, REPOINT TO SETUP FILE IF APPLICABLE

# Create logging function
function LogWrite
{
    Param ([Parameter(Mandatory=$true)] [string] $logstring)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$timestamp - $logstring"
    Write-Output $logLine | Tee-Object -FilePath $LogPath -Append
}

# Install function
function Install-Application
{
    param(
        [Parameter(Mandatory=$true)] [string] $url,
        [Parameter(Mandatory=$true)] [string] $fileName,
        [Parameter(Mandatory=$true)] [string[]] $arguments,
        [Parameter(Mandatory=$false)] [string[]] $extraMsiArguments = @()
    )

    $outputPath = Join-Path $LocalPath $fileName
    LogWrite "Downloading application from $url"
    try
    {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $outputPath -UseBasicParsing
        LogWrite "Download completed"
    }
    catch
    {
        LogWrite "Error during download: $_"
        return
    }

    # Unzip if it's a zip file
    if($fileName -match "\.zip$")
    {
        LogWrite "Zip file detected, expanding $fileName"
        try
        {
            Expand-Archive -LiteralPath $outputPath -DestinationPath $LocalPath -Force -Verbose
            LogWrite "Zip file expanded"
            # Update $outputPath to unzipped installer
            $outputPath = Join-Path $LocalPath $unzippedInstaller
        }
        catch
        {
            LogWrite "Error during expansion: $_"
            return
        }
    }

    LogWrite "Starting Install of $appName via $outputPath"
    try
    {
        # Check if the file is an MSI file
        if($fileName -match "\.msi$")
        {
            # Install with msiexec
            $msiArgs = @("/i", "`"$outputPath`"", "/qn") + $extraMsiArguments
            Start-Process -FilePath 'msiexec' -ArgumentList $msiArgs -Wait
        }
        else
        {
            # Install with the setup file
            Start-Process -FilePath "`"$outputPath`"" -ArgumentList $arguments -Wait
        }
        LogWrite "Installation completed"
    }
    catch
    {
        LogWrite "Error during installation: $_"
    }
}

# Create Directory and Change Location
New-Item -Path $LocalPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
New-Item -Path $LogDrive -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
Set-Location $LocalPath

<## IMPORTANT - MSIEXEC Installations that require additional parameters other than the default of '/i /qn', you need to specify these with the $extraMsiArguments parameters, e.g:
Install-Application -url 'https://someurl.com' -fileName 'setup.msi' -extraMsiArguments @("/l*v", "install.log", "/norestart")
##>

# IBM Notes Client installation
LogWrite "AIB Customisation: Installing IBM Notes Client"
Install-Application -url 'https://staibsources002.blob.core.windows.net/applications/Live/IBM%20Notes/Notes%209.0.1%20client.zip' -fileName 'IBMClientInstall.zip' -arguments @('/s', '/v"SETMULTIUSER=1 /qn /norestart"')

# IBM Notes installation
LogWrite "AIB Customisation: Installing IBM Notes"
Install-Application -url 'https://staibsources002.blob.core.windows.net/applications/Live/IBM%20Notes/notes901FP7_win.exe' -fileName 'notes901FP7_win.exe' -arguments @('-s', '-a', '/s', '/v"/qn /norestart"')

# Cleanup temp directory
Set-location "c:\"
Remove-Item -Path $LocalPath -Force -Recurse -ErrorAction SilentlyContinue
LogWrite "Cleanup completed"

