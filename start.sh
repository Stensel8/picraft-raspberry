#!/bin/bash
# This script sets up and starts your customized PaperMC server.
# It performs several tasks:
#   1. Checks for Java and optionally installs Azul Zulu 21 if missing.
#   2. Downloads and verifies the PaperMC jar if not already present.
#   3. Dynamically calculates RAM allocation based on system memory.
#   4. Cleans the server.properties file in the background.
#   5. Creates or attaches to a tmux session to run the server.

# --------------- CONFIG SECTION ---------------
# Download links for Azul Zulu 21 (OpenJDK 21) for different architectures.
# x86_64 architecture:
ZULU21_X86_DEB="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_amd64.deb"
ZULU21_X86_RPM="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux.x86_64.rpm"
ZULU21_X86_TAR="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_x64.tar.gz"

# ARM64 (aarch64) architecture:
ZULU21_ARM_DEB="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_arm64.deb"
ZULU21_ARM_RPM="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux.aarch64.rpm"
ZULU21_ARM_TAR="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_aarch64.tar.gz"

# URL and expected SHA-256 hash for the Paper server jar file.
JAR_URL="https://api.papermc.io/v2/projects/paper/versions/1.21.4/builds/225/downloads/paper-1.21.4-225.jar"
JAR_HASH="120c3c160768e9f7c968bda3f3e5c36a2a172ae30d3a3935148c45667d758590"
JAR_FILE_NAME="paper-1.21.4-225.jar"
# --------------- END CONFIG SECTION -----------

# Function to detect the system architecture (x86_64 or aarch64).
function detect_arch {
    local ARCH
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            # For other architectures, just return the detected value.
            echo "$ARCH"
            ;;
    esac
}

# Function to offer installation of Azul Zulu 21 if Java is not found.
function offer_install_java {
    local ARCH="$(detect_arch)"
    echo "Java not found on this system!"
    echo "We can attempt to install Azul Zulu 21 (OpenJDK 21)."
    read -p "Proceed with automatic installation? (y/n): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        echo "Skipping Java installation. Exiting."
        exit 1
    fi

    # Select the correct download links based on architecture.
    local DEB_LINK=""
    local RPM_LINK=""
    local TAR_LINK=""
    if [ "$ARCH" == "x86_64" ]; then
        DEB_LINK="$ZULU21_X86_DEB"
        RPM_LINK="$ZULU21_X86_RPM"
        TAR_LINK="$ZULU21_X86_TAR"
    elif [ "$ARCH" == "aarch64" ]; then
        DEB_LINK="$ZULU21_ARM_DEB"
        RPM_LINK="$ZULU21_ARM_RPM"
        TAR_LINK="$ZULU21_ARM_TAR"
    else
        echo "Unsupported architecture: $ARCH"
        echo "Cannot auto-install Azul Zulu for your architecture. Please install Java manually."
        exit 1
    fi

    # Let the user choose which installer format to use.
    echo "Select an installer format:"
    echo "1) .deb (Debian/Ubuntu-based)"
    echo "2) .rpm (RedHat-based)"
    echo "3) .tar.gz (Manual install)"
    read -p "Enter 1, 2, or 3: " format_choice

    case "$format_choice" in
        1)
            echo "Downloading .deb package for $ARCH..."
            wget -O zulu21.deb "$DEB_LINK"
            echo "Installing .deb package..."
            sudo dpkg -i zulu21.deb
            ;;
        2)
            echo "Downloading .rpm package for $ARCH..."
            wget -O zulu21.rpm "$RPM_LINK"
            echo "Installing .rpm package..."
            sudo rpm -i zulu21.rpm
            ;;
        3)
            echo "Downloading .tar.gz for $ARCH..."
            wget -O zulu21.tar.gz "$TAR_LINK"
            echo "Extracting to /opt/zulu21..."
            sudo mkdir -p /opt/zulu21
            sudo tar -xzf zulu21.tar.gz -C /opt/zulu21 --strip-components=1
            echo "Azul Zulu 21 extracted to /opt/zulu21"
            echo "Add it to your PATH by adding:"
            echo "  export PATH=\"/opt/zulu21/bin:\$PATH\""
            echo "Temporarily adding to PATH for this script."
            export PATH="/opt/zulu21/bin:$PATH"
            ;;
        *)
            echo "Invalid selection. Exiting."
            exit 1
            ;;
    esac
}

# Function to check if Java is installed; if not, call the installation function.
function check_java {
    if ! command -v java &> /dev/null; then
        offer_install_java
        sudo apt-get update -y
        sudo apt-get install -f -y
        sudo apt autoremove -y

        # Check again after installation.
        if ! command -v java &> /dev/null; then
            echo "Java still not found after attempted installation."
            exit 1
        fi
    fi
}

# --- MAIN SCRIPT STARTS HERE ---
check_java

# Set the server's root directory to the current working directory.
SERVER_ROOT_DIR=$(pwd)

# Try to detect an existing valid PaperMC jar in the current directory.
SERVER_JAR_NAME=$(ls "${SERVER_ROOT_DIR}" | grep -E "^(paper)-[0-9.]+-[0-9]+\.jar$" | sort -V | tail -n 1)
SERVER_JAR_PATH="${SERVER_ROOT_DIR}/${JAR_FILE_NAME}"

# If no valid jar is found, download it and verify its SHA-256 hash.
if [ -z "${SERVER_JAR_NAME}" ]; then
    echo "No valid server jar found. Downloading ${JAR_FILE_NAME}..."
    wget -O "${SERVER_JAR_PATH}" "${JAR_URL}"
    DOWNLOADED_HASH=$(sha256sum "${SERVER_JAR_PATH}" | awk '{ print $1 }')
    if [ "${DOWNLOADED_HASH}" != "${JAR_HASH}" ]; then
        echo "Jar file hash mismatch! (${DOWNLOADED_HASH} != ${JAR_HASH})"
        exit 1
    fi
    echo "Jar file downloaded and verified!"
    SERVER_JAR_NAME="${JAR_FILE_NAME}"
fi
SERVER_JAR_PATH="${SERVER_ROOT_DIR}/${SERVER_JAR_NAME}"

# Calculate dynamic RAM allocation based on total system memory.
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(( TOTAL_RAM_KB / 1024 / 1024 ))  # Convert KB to integer GB

if [ "$TOTAL_RAM_GB" -lt 4 ]; then
    echo "Insufficient memory: ${TOTAL_RAM_GB}G available, at least 4G needed!"
    exit 1
fi

if [ "$TOTAL_RAM_GB" -lt 8 ]; then
    # Use 75% of total RAM if less than 8GB is available.
    ALLOCATED_RAM_GB=$(( TOTAL_RAM_GB * 75 / 100 ))
else
    # Reserve 4GB for the system if 8GB or more is available.
    ALLOCATED_RAM_GB=$(( TOTAL_RAM_GB - 4 ))
fi

ALLOCATED_RAM="${ALLOCATED_RAM_GB}G"
echo "Total system RAM detected: ${TOTAL_RAM_GB}G"
echo "Allocating ${ALLOCATED_RAM} for the Minecraft server..."

# Function to clean the server.properties file after 2 minutes (runs in background).
function clean_server_properties {
    sleep 2m
    SERVER_PROPERTIES_FILE_PATH="${SERVER_ROOT_DIR}/server.properties"
    # Remove comment lines and sort the file.
    sed '/^#/d' -i "${SERVER_PROPERTIES_FILE_PATH}"
    sort -o "${SERVER_PROPERTIES_FILE_PATH}" "${SERVER_PROPERTIES_FILE_PATH}"
}
clean_server_properties &

# Prepare the Java command with optimized flags.
# The flags below are largely based on Aikar's recommendations.
# For your Raspberry Pi 5 quad-core ARM system (~5GB allocated), consider:
JAVA_CMD="java \
    -Xms${ALLOCATED_RAM} \
    -Xmx${ALLOCATED_RAM} \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:ParallelGCThreads=4 \
    -XX:ConcGCThreads=2 \
    -XX:MaxGCPauseMillis=300 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:G1NewSizePercent=30 \
    -XX:G1MaxNewSizePercent=40 \
    -XX:G1ReservePercent=20 \
    -XX:G1HeapWastePercent=5 \
    -XX:G1MixedGCCountTarget=4 \
    -XX:InitiatingHeapOccupancyPercent=25 \
    -XX:G1MixedGCLiveThresholdPercent=90 \
    -XX:G1RSetUpdatingPauseTimePercent=5 \
    -XX:SurvivorRatio=32 \
    -XX:+PerfDisableSharedMem \
    -XX:MaxTenuringThreshold=1 \
    -XX:+UseStringDeduplication \
    -Dusing.aikars.flags=https://mcflags.emc.gs \
    -Daikars.new.flags=true \
    -Dpaper.maxChunkThreads=3 \
    --add-modules=jdk.incubator.vector \
    -jar ${SERVER_JAR_PATH} nogui"

# Function to create a new tmux session and start the server (detached mode).
function create_new_session {
    echo "No active sessions found."
    echo "Creating a new tmux session 'mc-server' in detached mode..."
    /usr/bin/tmux new-session -d -s mc-server bash -c "${JAVA_CMD}"
    sleep 2
    if tmux has-session -t mc-server 2>/dev/null; then
        echo "Minecraft server is now running with ${ALLOCATED_RAM} RAM allocated."
        echo "To attach later, use: tmux attach -t mc-server"
        echo "Server logs: ${SERVER_ROOT_DIR}/logs/latest.log"
    else
        echo "Error: Failed to create tmux session 'mc-server'."
        exit 1
    fi
}

# Check if a tmux session named 'mc-server' already exists.
EXISTING_SESSION=$(tmux ls 2>/dev/null | grep "^mc-server:")

if [ -n "${EXISTING_SESSION}" ]; then
    read -p "Existing tmux session 'mc-server' found. Attach to it? (y/n): " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        tmux attach -t mc-server
        echo "Minecraft server session ended."
        echo "Server logs: ${SERVER_ROOT_DIR}/logs/latest.log"
        exit 0
    else
        echo "Not attaching to the existing session. Exiting."
        exit 0
    fi
else
    create_new_session
fi
