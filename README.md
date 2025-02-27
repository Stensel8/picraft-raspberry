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

    git clone https://github.com/Stensel8/picraft-raspberry5.git
    cd picraft-raspberry5
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
- **Plugin Settings:** Use the `scripts/configure-settings.sh` script to adjust server and plugin configurations as needed.

To update or customize your configurations:

    ./scripts/configure-settings.sh

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

## Disclaimer

This project is experimental and still under active development. Expect bugs and incomplete features. Contributions, bug reports, and feedback are highly appreciated.
