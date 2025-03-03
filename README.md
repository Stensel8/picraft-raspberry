# Raspberry Pi Minecraft Server

This repository contains a lightweight Minecraft server optimized for running on a Raspberry Pi 5. It uses a combination of the latest **PaperMC forks/flavored servers** to deliver a smooth and efficient experience on resource-constrained devices.

> **Note:** This project is still under development. Contributions and feedback are welcome!

## Features

- **Optimized for Raspberry Pi 5:** Pre-configured with settings adjusted to the Raspberry Pi's hardware.
- **Dynamic Dependency Management:** The `./start.sh` script auto-installs missing dependencies including:
  - The latest PaperMC server (currently version 1.21.4)
  - Azul Java JDK (auto-install if not found)
- **Modern Server Configuration:** Uses optimized Java flags for better performance. (Experimental)

## Prerequisites

Before using this server, ensure you have the following:

- A Raspberry Pi 5 (8GB or 16GB model)
- A compatible power supply
- An NVMe drive with a Linux-based OS installed (NVMe HAT recommended for performance)
- Java 21 or later installed on your Raspberry Pi (if not present, the `./start.sh` script can auto-install Azul Java JDK)

## Installation

### Automatic Setup

Simply clone the repository and run the `./start.sh` script. This script will check for Java, download and verify the latest PaperMC jar, and install any missing dependencies:

    git clone https://github.com/Stensel8/picraft-raspberry.git
    cd picraft-raspberry
    ./start.sh

### Manual Java Installation (Optional)

If you prefer to manually install Java, we recommend using **Azul Zulu OpenJDK**. Below are the download links for **ARM64** (recommended for Raspberry Pi 5) and **x86_64** (for other compatible systems).

#### .deb Package (Debian/Ubuntu)

- **ARM64** (Raspberry Pi 5):  
  Download from:  
  https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_arm64.deb  
  Then install:
  
      sudo apt-get update
      sudo apt-get install ./zulu21.40.17-ca-jdk21.0.6-linux_arm64.deb

- **x86_64**:  
  Download from:  
  https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_amd64.deb  
  Then install:
  
      sudo apt-get update
      sudo apt-get install ./zulu21.40.17-ca-jdk21.0.6-linux_amd64.deb

#### .rpm Package (RedHat-based distros)

- **ARM64** (Raspberry Pi 5):  
  Download from:  
  https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux.aarch64.rpm  
  Then install:
  
      sudo rpm -i zulu21.40.17-ca-jdk21.0.6-linux.aarch64.rpm

- **x86_64**:  
  Download from:  
  https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux.x86_64.rpm  
  Then install:
  
      sudo rpm -i zulu21.40.17-ca-jdk21.0.6-linux.x86_64.rpm

#### .tar.gz Archive (Manual Install)

- **ARM64** (Raspberry Pi 5):  
  Download from:  
  https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_aarch64.tar.gz  
  Then extract and add the `bin` folder to your PATH:
  
      tar -xzf zulu21.40.17-ca-jdk21.0.6-linux_aarch64.tar.gz
      export PATH="$(pwd)/zulu21.40.17-ca-jdk21.0.6-linux_aarch64/bin:$PATH"

- **x86_64**:  
  Download from:  
  https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_x64.tar.gz  
  Then extract and add the `bin` folder to your PATH:
  
      tar -xzf zulu21.40.17-ca-jdk21.0.6-linux_x64.tar.gz
      export PATH="$(pwd)/zulu21.40.17-ca-jdk21.0.6-linux_x64/bin:$PATH"


## Web Server (Under Development)

The repository includes a web server component intended for map plugins (such as DynMap or Pl3xMap). **However, this part is currently under development and not yet usable.** We are exploring faster and more modern solutions—potentially migrating to an **nginx**-based setup—but for now, focus on the `./start.sh` script for running your server.

## Configuration

The server is pre-configured with optimized settings files and dynamic configuration scripts:
- **Server Settings:** Optimized for best performance on a Raspberry Pi.
- **Java Flags:** Optimized for best performance on a Raspberry Pi.

# Configuration Guide

To update or customize your configurations:

- **server.properties**  
  Base Minecraft settings (port, MOTD, game mode, difficulty, etc.).

- **bukkit.yml**  
  General Bukkit options, including spawn limits and core server tweaks.

- **spigot.yml**  
  Spigot-specific settings like entity activation ranges, hopper timings, and more.

- **paper-global.yml**  
  Global PaperMC options for performance, chat limits, and packet settings.

- **paper-world-defaults.yml**  
  Default settings for all worlds (mob-spawning, view distance, simulation distance, etc.).

- **[worldname/foldername]/paper-world.yml** (optional)  
  World-specific configuration that overrides defaults for individual worlds.

Edit these files to change your server’s behavior and performance. For a vanilla-like experience or to optimize performance on devices like the Raspberry Pi, remove or adjust non-essential tweaks as needed. Always back up your files before making changes.

Happy customizing!

## Usage

### Starting the Server

Run the following command to start your server:

    ./start.sh

This script will:
- Check for and auto-install missing dependencies (including Azul Java JDK).
- Download and verify the PaperMC jar if not found.
- Start the server in a tmux session.
- Provide log file locations in case of errors.

### Stopping the Server

To stop the server, simply press `Ctrl+C` in the terminal where the server is running, or attach to the tmux session and then stop the server gracefully.

## Supported Minecraft Version

- Currently, this server supports **Minecraft 1.21.4**.

## Third-Party Plugins

This project uses a few third-party plugins. These plugins are owned by their respective creators, and we do not claim any rights or ownership over them. Below is a short overview of each plugin and its functionality:

1. **LuckPerms**  
   - **Description:** A powerful permissions management system for Minecraft servers.  
   - **Website:** [https://luckperms.net/](https://luckperms.net/)  

2. **Chunky**  
   - **Description:** A pre-generation plugin that helps generate chunks in advance to reduce lag.  
   - **Sources:**  
     - [Hangar](https://hangar.papermc.io/pop4959/Chunky)  
     - [GitHub](https://github.com/pop4959/Chunky)  

3. **EssentialsX**  
   - **Description:** Provides many essential server commands and features, including kits, warps, and economy support.  
   - **Sources:**  
     - [Official Website](https://essentialsx.net/)  
     - [GitHub](https://github.com/EssentialsX/Essentials/)  

4. **TAB**  
   - **Description:** "That" TAB plugin. Provides realtime information.  
   - **Sources:**  
     - [GitHub](https://github.com/NEZNAMY/TAB/)

5. **PlaceholderAPI**  
   - **Description:** The best and simplest way to add placeholders to your server!  
   - **Sources:**  
     - [Spigot page](https://www.spigotmc.org/resources/placeholderapi.6245/)  
     - [GitHub](https://github.com/PlaceholderAPI/PlaceholderAPI)

Please note that each plugin remains the property of its original authors. We are simply using these tools and do not hold any rights to them.

## Disclaimer

This project is experimental and still under active development. Expect bugs and incomplete features. Contributions, bug reports, and feedback are highly appreciated.
