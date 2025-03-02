#!/bin/bash
# This script sets up and starts your PaperMC server.
# It checks for Java (optionally installing Azul Zulu 21 if not found),
# verifies/gets the PaperMC jar, calculates dynamic RAM allocation,
# cleans server.properties in the background, and handles tmux session creation/attachment.

# --------------- CONFIG SECTION ---------------
# Links for Azul Zulu 21.0.6 (21.40.17) OpenJDK
# x86_64
ZULU21_X86_DEB="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_amd64.deb"
ZULU21_X86_RPM="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux.x86_64.rpm"
ZULU21_X86_TAR="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_x64.tar.gz"

# aarch64 / ARM64
ZULU21_ARM_DEB="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_arm64.deb"
ZULU21_ARM_RPM="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux.aarch64.rpm"
ZULU21_ARM_TAR="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_aarch64.tar.gz"

# URL and hash for the Paper server jar version 1.21.4 build 185
JAR_URL="https://api.papermc.io/v2/projects/paper/versions/1.21.4/builds/187/downloads/paper-1.21.4-187.jar"
JAR_HASH="e239dcce1837284e850e2049d7a0e6976b98b32dd8e55c0a7785750705324510"
JAR_FILE_NAME="paper-1.21.4-187.jar"
# --------------- END CONFIG SECTION -----------

# Detect system architecture: returns "x86_64" or "aarch64" (ARM64)
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
            # If we get here, user is on something else like armv7l, ppc64le, etc.
            echo "$ARCH"
            ;;
    esac
}

# Offer to install Azul Zulu 21 if Java is missing
function offer_install_java {
    local ARCH="$(detect_arch)"
    echo "Java not found on this system!"
    echo "We can attempt to install Azul Zulu 21 for you (OpenJDK 21)."
    read -p "Would you like to proceed with automatic installation? (y/n): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        echo "Skipping Java installation. Exiting."
        exit 1
    fi

    # Based on architecture, pick the correct links
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

    # Prompt user for which format they'd like
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
            echo "You can add it to your PATH by adding the following line to your ~/.bashrc:"
            echo "  export PATH=\"/opt/zulu21/bin:\$PATH\""
            echo "For now, we'll try to temporarily add it to PATH in this script."
            export PATH="/opt/zulu21/bin:$PATH"
            ;;
        *)
            echo "Invalid selection. Exiting."
            exit 1
            ;;
    esac
}

# Check for Java; if not found, offer to install Azul Zulu
function check_java {
    if ! command -v java &> /dev/null; then
        offer_install_java
        sudo apt-get update -y
        sudo apt-get install -f -y
        sudo apt autoremove -y

        # After installation attempt, check again
        if ! command -v java &> /dev/null; then
            echo "Java still not found after attempted installation."
            exit 1
        fi
    fi
}

# --- MAIN SCRIPT STARTS HERE ---
check_java

# Set working directory
SERVER_ROOT_DIR=$(pwd)

# Detect server jar: only files with valid jar filenames (avoid files with extra suffixes)
SERVER_JAR_NAME=$(ls "${SERVER_ROOT_DIR}" | grep -E "^(paper)-[0-9.]+-[0-9]+\.jar$" | sort -V | tail -n 1)

SERVER_JAR_PATH="${SERVER_ROOT_DIR}/${JAR_FILE_NAME}"

# If no valid server jar found, download it and verify its hash
if [ -z "${SERVER_JAR_NAME}" ]; then
    echo "No valid server jar found. Downloading ${JAR_FILE_NAME}..."
    wget -O "${SERVER_JAR_PATH}" "${JAR_URL}"
    DOWNLOADED_HASH=$(sha256sum "${SERVER_JAR_PATH}" | awk '{ print $1 }')
    if [ "${DOWNLOADED_HASH}" != "${JAR_HASH}" ]; then
        echo "Downloaded jarfile hash does not match! (${DOWNLOADED_HASH} != ${JAR_HASH})"
        exit 1
    fi
    echo "Jarfile downloaded and hash matches!"
    SERVER_JAR_NAME="${JAR_FILE_NAME}"
fi

SERVER_JAR_PATH="${SERVER_ROOT_DIR}/${SERVER_JAR_NAME}"

# Dynamic RAM allocation calculation
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(( TOTAL_RAM_KB / 1024 / 1024 ))  # convert to integer GB

if [ "$TOTAL_RAM_GB" -lt 4 ]; then
    echo "Insufficient memory: ${TOTAL_RAM_GB}G available, at least 4G needed!"
    exit 1
fi

if [ "$TOTAL_RAM_GB" -lt 8 ]; then
    # Allocate 75% of total RAM if less than 8G is available
    ALLOCATED_RAM_GB=$(( TOTAL_RAM_GB * 75 / 100 ))
else
    # Reserve 4G for the system and allocate the rest to the server
    ALLOCATED_RAM_GB=$(( TOTAL_RAM_GB - 4 ))
fi

ALLOCATED_RAM="${ALLOCATED_RAM_GB}G"

echo "Total system RAM detected: ${TOTAL_RAM_GB}G"
echo "Allocating ${ALLOCATED_RAM} for the Minecraft server..."

# Background function to clean server.properties file after 2 minutes
function clean_server_properties {
    sleep 2m
    SERVER_PROPERTIES_FILE_PATH="${SERVER_ROOT_DIR}/server.properties"
    sed '/^#/d' -i "${SERVER_PROPERTIES_FILE_PATH}"
    sort -o "${SERVER_PROPERTIES_FILE_PATH}" "${SERVER_PROPERTIES_FILE_PATH}"
}
clean_server_properties &

# Prepare the Java command (using a variable makes it easier to adjust/debug)
JAVA_CMD="java \
    -Xms${ALLOCATED_RAM} \
    -Xmx${ALLOCATED_RAM} \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:G1NewSizePercent=30 \
    -XX:G1MaxNewSizePercent=40 \
    -XX:G1HeapRegionSize=8M \
    -XX:G1ReservePercent=20 \
    -XX:G1HeapWastePercent=5 \
    -XX:G1MixedGCCountTarget=4 \
    -XX:InitiatingHeapOccupancyPercent=15 \
    -XX:G1MixedGCLiveThresholdPercent=90 \
    -XX:G1RSetUpdatingPauseTimePercent=5 \
    -XX:SurvivorRatio=32 \
    -XX:+PerfDisableSharedMem \
    -XX:MaxTenuringThreshold=1 \
    -Dusing.aikars.flags=https://mcflags.emc.gs \
    -Daikars.new.flags=true \
    -Dpaper.maxChunkThreads=3 \
    --add-modules=jdk.incubator.vector \
    -jar ${SERVER_JAR_PATH} nogui"

# Function to create a new tmux session and start the server (in detached mode)
function create_new_session {
    echo "No active sessions found."
    echo "Creating a new session 'mc-server' in detached mode..."
    tmux new-session -d -s mc-server bash -c "${JAVA_CMD}"
    sleep 2
    if tmux has-session -t mc-server 2>/dev/null; then
        echo "Minecraft server is now running with ${ALLOCATED_RAM} RAM allocated."
        echo "To attach to the session later, use: tmux attach -t mc-server"
        echo "Check your server logs in: ${SERVER_ROOT_DIR}/logs/latest.log"
    else
        echo "Error: Failed to create tmux session 'mc-server'."
        exit 1
    fi
}

# Check if an existing tmux session named 'mc-server' exists
EXISTING_SESSION=$(tmux ls 2>/dev/null | grep "^mc-server:")

if [ -n "${EXISTING_SESSION}" ]; then
    read -p "Existing tmux session 'mc-server' found. Do you want to attach to it? (y/n): " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        tmux attach -t mc-server
        echo "Minecraft server session ended."
        echo "Check your server logs in: ${SERVER_ROOT_DIR}/logs/latest.log"
        exit 0
    else
        echo "Not attaching to the existing session. Exiting."
        exit 0
    fi
else
    create_new_session
fi

# Optional: Automatically trigger Chunky pre-generation task via tmux.
echo "Waiting 30 seconds for the server to fully initialize. Once complete, the terminal will be returned to you."
sleep 30
tmux send-keys -t mc-server "chunky start world square 0 0 5000" ENTER
echo "Chunky pre-generation task triggered: /chunky start world square 0 0 5000"
