<#
.SYNOPSIS
    Setup and run a PaperMC Minecraft Server with Amazon Corretto OpenJDK
.DESCRIPTION
    This script downloads Amazon Corretto OpenJDK and PaperMC Paper server,
    then configures and starts the Minecraft server.
.NOTES
    Author: GitHub Copilot with Claude and human supervision
    Date: 2026-04-08
#>

param(
    [string]$JavaVersion = "21",
    [string]$MinecraftVersion = "1.21.11",
    [int]$MinMemoryMB = 1024,
    [int]$MaxMemoryMB = 2048
)

# Configuration
$BaseDir = $PSScriptRoot
$JavaDir = Join-Path $BaseDir "java"
$ServerDir = Join-Path $BaseDir "server"
$JavaExecutable = Join-Path $JavaDir "bin\java.exe"
$PaperJar = Join-Path $ServerDir "paper.jar"

# Color output functions
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Warning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }

# Create directories
Write-Info "Creating directory structure..."
# Remove existing Java directory to ensure clean installation
if (Test-Path $JavaDir) {
    Write-Info "Removing existing Java directory..."
    Remove-Item -Path $JavaDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $JavaDir | Out-Null
New-Item -ItemType Directory -Force -Path $ServerDir | Out-Null
Write-Success "Directories created"

# Download and extract Amazon Corretto Java
Write-Info "Downloading Amazon Corretto Java $JavaVersion..."

$JavaDownloadUrl = "https://corretto.aws/downloads/latest/amazon-corretto-$JavaVersion-x64-windows-jdk.zip"
$JavaZipPath = Join-Path $BaseDir "corretto.zip"

try {
    # Set timeout for download (10 minutes max)
    Invoke-WebRequest -Uri $JavaDownloadUrl -OutFile $JavaZipPath -UseBasicParsing -TimeoutSec 600
    Write-Success "Java downloaded successfully"

    Write-Info "Extracting Java..."
    Expand-Archive -Path $JavaZipPath -DestinationPath $JavaDir -Force

    # Move files from nested directory to java root
    $ExtractedDir = Get-ChildItem -Path $JavaDir -Directory | Select-Object -First 1
    if ($ExtractedDir) {
        Get-ChildItem -Path $ExtractedDir.FullName | Move-Item -Destination $JavaDir -Force
        Remove-Item -Path $ExtractedDir.FullName -Recurse -Force
    }

    Remove-Item -Path $JavaZipPath -Force
    Write-Success "Java extracted and ready"
}
catch {
    Write-Error "Failed to download or extract Java: $_"
    Write-Error "This may be due to a network timeout or unavailable download server"
    exit 1
}

# Verify Java installation
if (-not (Test-Path $JavaExecutable)) {
    Write-Error "Java executable not found at $JavaExecutable"
    exit 1
}

$JavaVersionOutput = & $JavaExecutable -version 2>&1 | Select-Object -First 1
Write-Success "Java verified: $JavaVersionOutput"

# Download PaperMC
Write-Info "Downloading PaperMC for Minecraft $MinecraftVersion..."

try {
    # Get builds for the requested version
    $BuildsUrl = "https://fill.papermc.io/v3/projects/paper/versions/$MinecraftVersion/builds"
    Write-Info "Fetching builds from: $BuildsUrl"

    $BuildsResponse = Invoke-RestMethod -Uri $BuildsUrl -UseBasicParsing

    # Check for API error
    if ($BuildsResponse.ok -eq $false) {
        $ErrorMsg = if ($BuildsResponse.message) { $BuildsResponse.message } else { "Unknown error" }
        throw "API Error: $ErrorMsg"
    }

    # Try to find a stable build, fallback to any build
    $StableBuild = $BuildsResponse | Where-Object { $_.channel -eq "STABLE" } | Select-Object -First 1

    if ($StableBuild) {
        $PaperDownloadUrl = $StableBuild.downloads.'server:default'.url
        $BuildNumber = $StableBuild.build
        Write-Info "Found stable build: $BuildNumber"
    } else {
        # Fallback to first available build
        $FirstBuild = $BuildsResponse | Select-Object -First 1
        if ($FirstBuild) {
            $PaperDownloadUrl = $FirstBuild.downloads.'server:default'.url
            $BuildNumber = $FirstBuild.build
            Write-Warning "No stable build found, using build: $BuildNumber"
        } else {
            throw "No builds available for version $MinecraftVersion"
        }
    }

    if (-not $PaperDownloadUrl) {
        throw "Could not determine download URL for version $MinecraftVersion"
    }

    Write-Info "Downloading from: $PaperDownloadUrl"
    # Set timeout for download (10 minutes max)
    Invoke-WebRequest -Uri $PaperDownloadUrl -OutFile $PaperJar -UseBasicParsing -TimeoutSec 600
    Write-Success "PaperMC downloaded successfully"
}
catch {
    Write-Error "Failed to download PaperMC: $_"
    exit 1
}

# Accept EULA
Write-Info "Accepting Minecraft EULA..."
$EulaPath = Join-Path $ServerDir "eula.txt"
"eula=true" | Out-File -FilePath $EulaPath -Encoding ASCII
Write-Success "EULA accepted"

# Create server.properties with basic configuration
$ServerPropertiesPath = Join-Path $ServerDir "server.properties"
if (-not (Test-Path $ServerPropertiesPath)) {
    Write-Info "Creating default server.properties..."
    @"
#Minecraft server properties
accepts-transfers=false
allow-flight=false
broadcast-console-to-ops=true
broadcast-rcon-to-ops=true
bug-report-link=https://github.com/Cyclenerd/minecraft-windows/issues
debug=false
difficulty=normal
enable-code-of-conduct=false
enable-jmx-monitoring=false
enable-query=false
enable-rcon=false
enable-status=true
enforce-secure-profile=true
enforce-whitelist=false
entity-broadcast-range-percentage=100
force-gamemode=true
function-permission-level=2
gamemode=survival
generate-structures=true
generator-settings={}
hardcore=false
hide-online-players=false
initial-disabled-packs=
initial-enabled-packs=vanilla
level-name=world
level-seed=
level-type=minecraft\:normal
log-ips=true
max-chained-neighbor-updates=1000000
max-players=10
max-tick-time=60000
max-world-size=29999984
motd=A Minecraft Server on Windows
network-compression-threshold=256
online-mode=true
op-permission-level=4
pause-when-empty-seconds=-1
player-idle-timeout=0
prevent-proxy-connections=false
pvp=true
query.port=25565
rate-limit=0
rcon.password=
rcon.port=25575
region-file-compression=deflate
require-resource-pack=false
resource-pack=
resource-pack-id=
resource-pack-prompt=
resource-pack-sha1=
server-ip=
server-port=25565
simulation-distance=10
spawn-protection=16
status-heartbeat-interval=0
sync-chunk-writes=true
text-filtering-config=
text-filtering-version=0
use-native-transport=true
view-distance=32
white-list=false
"@ | Out-File -FilePath $ServerPropertiesPath -Encoding ASCII
    Write-Success "server.properties created"
}

# Copy server icon if it exists
$ServerIconSource = Join-Path $BaseDir "server-icon.png"
$ServerIconDest = Join-Path $ServerDir "server-icon.png"
if (Test-Path $ServerIconSource) {
    Write-Info "Copying server icon..."
    Copy-Item -Path $ServerIconSource -Destination $ServerIconDest -Force
    Write-Success "Server icon copied to server directory"
} else {
    Write-Info "No server-icon.png found in root directory (optional)"
}

# Create start script (CMD batch file)
$StartScriptPath = Join-Path $BaseDir "start-server.cmd"
@"
@echo off
REM Start PaperMC Server with Aikar's Flags (Optimized JVM Parameters)
REM See: https://docs.papermc.io/paper/aikars-flags

cd /d "%~dp0server"

"%~dp0java\bin\java.exe" -Xms${MinMemoryMB}M -Xmx${MaxMemoryMB}M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar paper.jar --nogui

pause
"@ | Out-File -FilePath $StartScriptPath -Encoding ASCII
Write-Success "Start script created at $StartScriptPath"

# Create shortcut with custom icon
$ShortcutPath = Join-Path $BaseDir "Start Minecraft Server.lnk"
$IconPath = Join-Path $BaseDir "server-icon.ico"

if (Test-Path $IconPath) {
    Write-Info "Creating desktop shortcut with custom icon..."
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $StartScriptPath
    $Shortcut.WorkingDirectory = $BaseDir
    $Shortcut.IconLocation = $IconPath
    $Shortcut.Description = "Start PaperMC Minecraft Server"
    $Shortcut.Save()
    Write-Success "Shortcut created: $ShortcutPath"
} else {
    Write-Info "No server-icon.ico found, skipping shortcut creation"
}

# Start the server
Write-Info "Starting PaperMC server..."
Write-Info "Memory: ${MinMemoryMB}MB - ${MaxMemoryMB}MB"
Write-Info "Using Aikar's optimized JVM flags"
Write-Info "Server directory: $ServerDir"
Write-Warning "Press Ctrl+C to stop the server"
Write-Info "You can also use start-server.cmd to start the server later"

Start-Sleep -Seconds 2

Set-Location $ServerDir

# Start server with optimized flags (Aikar's Flags)
$javaArgs = @(
  "-Xms${MinMemoryMB}M"
  "-Xmx${MaxMemoryMB}M"
  "-XX:+AlwaysPreTouch"
  "-XX:+DisableExplicitGC"
  "-XX:+ParallelRefProcEnabled"
  "-XX:+PerfDisableSharedMem"
  "-XX:+UnlockExperimentalVMOptions"
  "-XX:+UseG1GC"
  "-XX:G1HeapRegionSize=8M"
  "-XX:G1HeapWastePercent=5"
  "-XX:G1MaxNewSizePercent=40"
  "-XX:G1MixedGCCountTarget=4"
  "-XX:G1MixedGCLiveThresholdPercent=90"
  "-XX:G1NewSizePercent=30"
  "-XX:G1RSetUpdatingPauseTimePercent=5"
  "-XX:G1ReservePercent=20"
  "-XX:InitiatingHeapOccupancyPercent=15"
  "-XX:MaxGCPauseMillis=200"
  "-XX:MaxTenuringThreshold=1"
  "-XX:SurvivorRatio=32"
  "-Dusing.aikars.flags=https://mcflags.emc.gs"
  "-Daikars.new.flags=true"
  "-jar"
  $PaperJar
  "--nogui"
)
& $JavaExecutable @javaArgs
