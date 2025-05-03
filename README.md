# Raspberry Pi Minecraft Server

![Raspberry Pi Minecraft Server](https://github.com/Stensel8/picraft-raspberry/blob/main/server-icon.jpg)

This repository contains a lightweight Minecraft server optimized for running on a Raspberry Pi 5. It uses a combination of the latest **PaperMC forks/flavored servers** to deliver a smooth and efficient experience on resource-constrained devices.

The idea of this project is to provide a one-click, single-deploy solution, making it extremely easy to set up and run your server with minimal effort.

> **Note:** This project is still under development. Contributions and feedback are welcome!

## Features

* **Optimized for Raspberry Pi 5:** Pre-configured with settings adjusted to the Raspberry Pi's hardware.
* **Dynamic Dependency Management:** The `./start.sh` script auto-installs missing dependencies including:

  * The latest PaperMC server build
  * Azul Java JDK (Preferred Java choice for good server performance)
* **Modern Server Configuration:** Uses optimized Java flags for better performance.

## Prerequisites

Before using this server, ensure you have the following:

* A Raspberry Pi 5 (8GB or 16GB model, because we need at least 5GB of RAM for the server)
* A compatible and good working power supply
* An NVMe drive with a Linux-based OS installed (NVMe HAT recommended for performance)
* **Azul Zulu Java 24** installed on your Raspberry Pi (if not present, the `./start.sh` script can auto-install Azul Java JDK)

## Installation

To prefetch and pre-generate the first 10,000 chunks, execute the `chunky_preloader.sh` bash script. This script sends instructions to `tmux` for chunk preloading.

**Note**: Performance will be significantly slower while chunk generation is running, but it is worth the wait. Once chunk generation is complete, you'll enjoy a fast and smooth server experience!

### Monitoring Chunk Generation

You can monitor chunk generation status within the `tmux` session. Simply attach to the session by running:

```bash
tmux attach -t mc-server
```

To detach from the tmux session while keeping it running in the background, press CTRL + B followed by the letter D on your keyboard.

### Automatic Setup

Simply clone the repository and run the `./start.sh` script. This script will check for existing Java installations, download and verify the latest PaperMC jar, and install any missing dependencies:

```
git clone https://github.com/Stensel8/picraft-raspberry.git
cd picraft-raspberry
./start.sh
```

## Docker

A ready‑to‑use Docker image is published on Docker Hub:  
`stensel8/picraft-raspberry:latest`

### Quick Start

Pull the image and run it with everything pre‑configured (chunk-caching, plugins, configs):

```bash
sudo docker pull stensel8/picraft-raspberry:latest
```

Then run the container with the following command:
```bash
sudo docker run -d \
  --name picraft \
  -p 25565:25565 \
  -e EULA=true \
  stensel8/picraft-raspberry:latest
```

### Manual Java Installation (Optional)

If you prefer to manually install Java, we recommend using **Azul Zulu OpenJDK 24**. Below are the download links for **ARM64** (recommended for Raspberry Pi 5) and **x86\_64** (for other compatible systems).

#### .deb Package (Debian/Ubuntu)

* **ARM64** (Raspberry Pi 5):
  Download from:
  [https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux\_arm64.deb](https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_arm64.deb)
  Then install:

  ```bash
  sudo apt-get update
  sudo apt-get install ./zulu24.30.11-ca-jdk24.0.1-linux_arm64.deb
  ```

* **x86\_64**:
  Download from:
  [https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux\_amd64.deb](https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_amd64.deb)
  Then install:

  ```bash
  sudo apt-get update
  sudo apt-get install ./zulu24.30.11-ca-jdk24.0.1-linux_amd64.deb
  ```

#### .rpm Package (RedHat-based distros)

* **ARM64** (Raspberry Pi 5):
  Download from:
  [https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux.aarch64.rpm](https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux.aarch64.rpm)
  Then install:

  ```bash
  sudo rpm -i zulu24.30.11-ca-jdk24.0.1-linux.aarch64.rpm
  ```

* **x86\_64**:
  Download from:
  [https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux.x86\_64.rpm](https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux.x86_64.rpm)
  Then install:

  ```bash
  sudo rpm -i zulu24.30.11-ca-jdk24.0.1-linux.x86_64.rpm
  ```

#### .tar.gz Archive (Manual Install)

* **ARM64** (Raspberry Pi 5):
  Download from:
  [https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux\_aarch64.tar.gz](https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_aarch64.tar.gz)
  Then extract and add the `bin` folder to your PATH:

  ```bash
  tar -xzf zulu24.30.11-ca-jdk24.0.1-linux_aarch64.tar.gz
  export PATH="$(pwd)/zulu24.30.11-ca-jdk24.0.1-linux_aarch64/bin:$PATH"
  ```

* **x86\_64**:
  Download from:
  [https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux\_x64.tar.gz](https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_x64.tar.gz)
  Then extract and add the `bin` folder to your PATH:

  ```bash
  tar -xzf zulu24.30.11-ca-jdk24.0.1-linux_x64.tar.gz
  export PATH="$(pwd)/zulu24.30.11-ca-jdk24.0.1-linux_x64/bin:$PATH"
  ```

## Web Server (Under Development)

The repository includes plans for a web server component, potentially useful for managing the server or supporting map plugins like DynMap or Pl3xMap. **At this time, this feature is still in early exploration and not stable or functional.** I’m considering adding and integrating a web server in the future to allow server management, but **I cannot guarantee** this will be implemented. For now, it’s best to focus on using the `./start.sh` script for running your server.

## Configuration

The server is pre-configured with optimized settings files and dynamic configuration scripts:

* **Server Settings:** Optimized for best performance on a Raspberry Pi.
* **Java Flags:** Optimized for best performance on a Raspberry Pi.

# Configuration Guide

To update or customize your configurations:

* **server.properties**
  Base Minecraft settings (port, MOTD, game mode, difficulty, etc.).

* **bukkit.yml**
  General Bukkit options, including spawn limits and core server tweaks.

* **spigot.yml**
  Spigot-specific settings like entity activation ranges, hopper timings, and more.

* **paper-global.yml**
  Global PaperMC options for performance, chat limits, and packet settings.

* **paper-world-defaults.yml**
  Default settings for all worlds (mob-spawning, view distance, simulation distance, etc.).

* **\[worldname/foldername]/paper-world.yml** (optional)
  World-specific configuration that overrides defaults for individual worlds.

Edit these files to change your server’s behavior and performance. Always back up your files before making changes.

## Usage

### Starting the Server

Run the following command to start your server:

```
./start.sh
```

This script will:

* Check for and auto-install missing dependencies (including Azul Java JDK).
* Download and verify the PaperMC jar if not found.
* Start the server in a tmux session.
* Provide log file locations in case of errors.

### Stopping the Server

To stop the server, simply press `Ctrl+C` in the terminal where the server is running, or attach to the tmux session and then stop the server gracefully.

## Supported Minecraft Version

* Currently, this server only supports **Minecraft 1.21.5**.

## Third-Party Plugins

This project uses a few third-party plugins. These plugins are owned by their respective creators, and we do not claim any rights or ownership over them. Below is a short overview of each plugin and its functionality:

1. **LuckPerms**

   * **Description:** A powerful permissions management system for Minecraft servers.
   * **Website:** [https://luckperms.net/](https://luckperms.net/)

2. **Chunky**

   * **Description:** A pre-generation plugin that helps generate chunks in advance to reduce lag.
   * **Sources:**

     * [Hangar](https://hangar.papermc.io/pop4959/Chunky)
     * [GitHub](https://github.com/pop4959/Chunky)

3. **EssentialsX**

   * **Description:** Provides many essential server commands and features, including kits, warps, and economy support.
   * **Sources:**

     * [Official Website](https://essentialsx.net/)
     * [GitHub](https://github.com/EssentialsX/Essentials/)

4. **TAB**

   * **Description:** "That" TAB plugin. Provides realtime information.
   * **Sources:**

     * [GitHub](https://github.com/NEZNAMY/TAB/)

5. **PlaceholderAPI**

   * **Description:** The best and simplest way to add placeholders to your server!
   * **Sources:**

     * [Spigot page](https://www.spigotmc.org/resources/placeholderapi.6245/)
     * [GitHub](https://github.com/PlaceholderAPI/PlaceholderAPI)

6. **WorldEdit**

   * **Description:** Minecraft map editor and mod.
   * **Sources:**

     * [Website](https://enginehub.org/worldedit)
     * [GitHub](https://github.com/enginehub/worldedit)

Please note that each plugin remains the property of its original authors. We are simply using these tools and do not hold any rights to them.

## Disclaimer

This project is experimental and still under active development. Expect bugs and incomplete features. Contributions, bug reports, and feedback are highly appreciated.
