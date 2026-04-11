# PaperMC Minecraft Server Setup for Windows

Automated PowerShell script to download, configure, and run a PaperMC Minecraft server with Amazon Corretto OpenJDK on Windows.

## Features

- ✅ Automatic download of Amazon Corretto OpenJDK
- ✅ Automatic download of PaperMC server
- ✅ Optimized JVM parameters (Aikar's Flags)
- ✅ Configurable Minecraft and Java versions
- ✅ Automatic EULA acceptance
- ✅ Configurable memory allocation
- ✅ Self-contained installation (all files in subdirectories)
- ✅ Easy to use start script

## Requirements

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or later
- Internet connection for downloads
- ~2GB free disk space

## Quick Start

1. **Download the script**
   ```powershell
   git clone "https://github.com/Cyclenerd/minecraft-windows.git"
   cd minecraft-windows
   ```

2. **Run the setup script**
   ```powershell
   .\setup-papermc.ps1
   ```

3. **Server will start automatically!**

## Configuration

### Command Line Parameters

```powershell
.\setup-papermc.ps1 `
    -JavaVersion "21" `
    -MinecraftVersion "1.21.11" `
    -MinMemoryMB 1024 `
    -MaxMemoryMB 2048
```

### Available Parameters

| Parameter          | Description                        | Default   |
|--------------------|------------------------------------|-----------|
| `JavaVersion`      | Amazon Corretto Java major version | `21`      |
| `MinecraftVersion` | Minecraft version                  | `1.21.11` |
| `MinMemoryMB`      | Minimum memory allocation (MB)     | `1024`    |
| `MaxMemoryMB`      | Maximum memory allocation (MB)     | `2048`    |

### Examples

**Run with 4GB RAM:**
```powershell
.\setup-papermc.ps1 -MinMemoryMB 2048 -MaxMemoryMB 4096
```

**Use a different Minecraft version:**
```powershell
.\setup-papermc.ps1 -MinecraftVersion "1.20.4"
```

**Use a specific Java version:**
```powershell
.\setup-papermc.ps1 -JavaVersion "17"
```

**Use a specific Java and Minecraft version:**
```powershell
.\setup-papermc.ps1 -JavaVersion "25" -MinecraftVersion "26.1.1"
```

## Directory Structure

After running the script, the following structure is created:

```text
minecraft-windows/
├── server-icon.ico            # Icon for the desktop shortcut
├── server-icon.png            # Server icon (automatically copied to server/)
├── setup-papermc.ps1          # Primary installation and setup script
├── start-server.cmd           # Server launch script (generated after first run)
├── Start Minecraft Server.lnk # Desktop shortcut (generated after first run)
├── README.md                  # This README file
├── java/                      # Embedded Java runtime (Amazon Corretto OpenJDK)
│   └── bin/
│       └── java.exe
└── server/                    # Folder for Minecraft server files and data
    ├── paper.jar
    ├── eula.txt
    ├── server.properties
    ├── server-icon.png
    ├── logs/
    ├── plugins/
    └── world/
```

## Usage

### First Time Setup

```powershell
# Run the setup script
.\setup-papermc.ps1
```

The script will:
1. Remove existing `java/` directory (if present) and create fresh directories
2. Download and extract Amazon Corretto Java
3. Download the latest PaperMC server
4. Accept the Minecraft EULA
5. Create a default `server.properties` file (if not exists)
6. Create a `start-server.cmd` script
7. Create a shortcut with custom icon (if `server-icon.ico` exists)
8. Start the server

**Important:**
- The `java/` folder is **always deleted** and re-downloaded to ensure a clean installation
- The `server/` folder is **preserved** - your worlds, plugins, and configurations are safe

### Re-running the Setup Script

You can safely re-run `setup-papermc.ps1` to:
- Update to a different Java version
- Update to a different Minecraft/PaperMC version
- Change memory allocation settings

Your existing server data (worlds, plugins, configurations) will be preserved.

### Starting the Server (After Initial Setup)

Use the generated start script:
```cmd
start-server.cmd
```

Or double-click `start-server.cmd` in Windows Explorer.

### Stopping the Server

Press `Ctrl+C` in the PowerShell window, or type `stop` in the server console.

### Server Configuration

Edit `server/server.properties` to configure:
- Server port (default: 25565)
- Game mode
- Difficulty
- Max players
- Message of the day (MOTD)
- And more...

More to read: https://docs.papermc.io/paper/reference/server-properties/

## Finding Java and Minecraft Versions

### Amazon Corretto Versions

Visit: https://aws.amazon.com/corretto/

Available major versions:
- Java 25 (Latest): `25`
- Java 21 (LTS, Recommended): `21`
- Java 17 (LTS): `17`
- Java 11 (LTS): `11`
- Java 8: `8`

The script automatically downloads the latest build of the specified major version.

### Minecraft/PaperMC Versions

Visit: https://papermc.io/downloads/paper

Check available versions and builds via API:
```powershell
# Get builds for a specific version
$version = "1.21.11"
$builds = Invoke-RestMethod -Uri "https://fill.papermc.io/v3/projects/paper/versions/$version/builds"

# Get the latest stable build
$stableBuild = $builds | Where-Object { $_.channel -eq "STABLE" } | Select-Object -First 1
if ($stableBuild) {
    Write-Host "Latest stable build: $($stableBuild.build)"
    Write-Host "Download URL: $($stableBuild.downloads.'server:default'.url)"
}
```

## Troubleshooting

### Script Execution Policy Error

If you get the error **"running scripts is disabled on this system"**, you have **two options**:

**Option 1: Bypass for Single Execution (Recommended)**
```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup-papermc.ps1
```

**Option 2: Unblock and Change Execution Policy**

The script is not signed, so you need to unblock it first:
```powershell
# Unblock the downloaded script
Unblock-File -Path .\setup-papermc.ps1

# Change execution policy (allows unblocked local scripts)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Then run the script normally.

### Download Fails

- Check your internet connection
- Verify the Java and Minecraft versions are valid
- Check if antivirus is blocking downloads

### Server Won't Start

- Verify Java is installed: Check `java/bin/java.exe` exists
- Check if port 25565 is already in use
- Review logs in `server/logs/latest.log`
- Increase memory allocation if server crashes

### Java Version Compatibility

| Paper Version  | Recommended Java Version |
|----------------|--------------------------|
| 1.7.10 to 1.11 | Java 8                   |
| 1.12 to 1.16.4 | Java 11                  |
| 1.16.5         | Java 16                  |
| 1.17 to 1.19   | Java 17                  |
| 1.20 to 1.21.1 | Java 21                  |
| 26.1+          | Java 25                  |

**Examples:**
```powershell
# For Minecraft 1.20.4
.\setup-papermc.ps1 -MinecraftVersion "1.20.6" -JavaVersion "21"

# For Minecraft 1.19.4
.\setup-papermc.ps1 -MinecraftVersion "1.19.4" -JavaVersion "17"

# For Minecraft 1.16.5
.\setup-papermc.ps1 -MinecraftVersion "1.16.5" -JavaVersion "16"
```

## Advanced Configuration

### JVM Performance Tuning

The script uses **Aikar's Flags**, a set of optimized JVM parameters designed specifically for Minecraft servers. These flags improve:
- Garbage collection efficiency
- Memory management
- Overall server performance and TPS (ticks per second)

**Reference:** https://docs.papermc.io/paper/aikars-flags

### Port Forwarding

To allow external connections:
1. Forward port 25565 (TCP/UDP) on your router
2. Configure Windows Firewall:
   ```powershell
   New-NetFirewallRule -DisplayName "Minecraft Server" -Direction Inbound -Protocol TCP -LocalPort 25565 -Action Allow
   ```

### Installing Plugins

PaperMC supports Bukkit, Spigot, and Paper plugins:

1. **Find plugins** at:
   - https://hangar.papermc.io/ (Official PaperMC plugin repository)
      - `/tpa`: https://hangar.papermc.io/JustPlayer/JustPlayer-TPA
      - `/nv`: https://hangar.papermc.io/samurainumber1/SimpleFullbright
   - https://dev.bukkit.org/bukkit-plugins
      - `/tpa`: https://dev.bukkit.org/projects/just-tpa
   - https://www.spigotmc.org/resources/


2. **Download** the plugin `.jar` file (make sure it's compatible with your Minecraft version)

3. **Install** the plugin:
   ```powershell
   # Place the .jar file in the plugins directory
   Copy-Item -Path "path\to\plugin.jar" -Destination "server\plugins\"
   ```
   Or simply drag and drop the `.jar` file into the `server\plugins\` folder

4. **Restart** the server to load the plugin

5. **Configure** the plugin (if needed) by editing files in `server\plugins\<plugin-name>\`

### Backup Your World

```powershell
# Create a backup
Compress-Archive -Path "server/world*" -DestinationPath "backup-$(Get-Date -Format 'yyyy-MM-dd').zip"
```

## CI/CD

This repository includes GitHub Actions workflow that tests the script on Windows:
- `.github/workflows/test.yml`

The workflow runs on every push and pull request to verify the script works correctly.

## Resources

- [PaperMC Documentation](https://docs.papermc.io/)
- [Amazon Corretto](https://aws.amazon.com/corretto/)
- [Minecraft Server Properties](https://minecraft.fandom.com/wiki/Server.properties)

## License

### Code

This project's code is licensed under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for details.

### Icon

The server icon (`server-icon.ico` and `server-icon.png`) is sourced from [Windows 95 Network Neighborhood PNG Icon](https://www.deviantart.com/satellitedish555/art/Windows-95-Network-Neighborhood-PNG-Icon-1023088703) by SatelliteDish555 on DeviantArt. The icon is used under fair use and is **not** licensed under Apache License 2.0.
