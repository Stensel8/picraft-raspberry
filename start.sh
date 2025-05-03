#!/usr/bin/env bash
set -euo pipefail

# --------------------- SET-WORKING-DIR ---------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/mc-data"
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# This script sets up and starts your customized PaperMC server on any Linux
# box. It:
#   1. Ensures Java (Azul Zulu 24) is installed, installing it with checksum
#      verification if needed (and auto-fixing deps).
#   2. Downloads & checks the PaperMC jar.
#   3. Dynamically allocates RAM based on total system memory.
#   4. Cleans server.properties in the background.
#   5. Ensures tmux is configured for scrollback.
#   6. Starts or attaches to a tmux session to run the server.
# -----------------------------------------------------------------------------

# --------------------- CONFIGURATION ---------------------
JAR_URL="https://api.papermc.io/v2/projects/paper/versions/1.21.5/builds/66/downloads/paper-1.21.5-66.jar"
JAR_HASH="52c272d92e34823bb116f7daa31984bab9e2f3da7f90169441fc0a7557e8ad90"
JAR_NAME="paper-1.21.5-66.jar"

declare -A ZULU_URL=(
  [x86_64_deb]="https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_amd64.deb"
  [x86_64_rpm]="https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux.x86_64.rpm"
  [x86_64_tar]="https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_x64.tar.gz"
  [aarch64_deb]="https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_arm64.deb"
  [aarch64_rpm]="https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux.aarch64.rpm"
  [aarch64_tar]="https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_aarch64.tar.gz"
)
declare -A ZULU_HASH=(
  [x86_64_deb]="2cd81fdd0ee62b2321e9c5256e5204f4d716afcd34ecc9d57f1ed3da8400f7e4"
  [x86_64_rpm]="b814a378ccb7d8913acf956fd6185da72b9c91f1657abf11d285da9865001cd8"
  [x86_64_tar]="12f6957c3a2a74d36d692cfee3aeeb949f15b5d80dad08bf0d3ed930d66d8659"
  [aarch64_deb]="d0dd7e40cff30c26e0d30449e7ac4b467b2f078cbf07d1194ebe8f75d0a061ab"
  [aarch64_rpm]="a4304ccf35457d98884393f6166fab9736031fd4521609be94ea10616d3b24e0"
  [aarch64_tar]="e11e4ae574e0a51f64abd5961374a0bea553abc085bf26fde37cc0892b2ade4d"
)

TMUX_SESSION="mc-server"

# --------------------- FUNCTIONS ---------------------

detect_arch() {
  case "$(uname -m)" in
    x86_64)    echo "x86_64"   ;;
    aarch64|arm64) echo "aarch64" ;;
    *)         echo "unsupported" ;;
  esac
}

download_and_verify() {
  local url=$1 checksum=$2 out=$3
  echo "Fetching $out..."
  wget -q --show-progress -O "$out" "$url"
  echo "Verifying checksum..."
  local actual
  actual=$(sha256sum "$out" | awk '{print $1}')
  if [[ "$actual" != "$checksum" ]]; then
    echo "ERROR: checksum mismatch for $out"
    echo "  expected: $checksum"
    echo "  actual:   $actual"
    exit 1
  fi
  echo "Checksum OK."
}

offer_install_java() {
  local arch key pkg fmt
  arch=$(detect_arch)
  if [[ "$arch" == "unsupported" ]]; then
    echo "Unsupported architecture: $(uname -m)"
    echo "Please install Java manually."
    exit 1
  fi

  read -rp "Java not found. Install Azul Zulu 24? (y/n) " choice
  [[ "$choice" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

  cat <<EOF
Choose package format:
  1) .deb
  2) .rpm
  3) .tar.gz
EOF
  read -rp "Enter 1, 2 or 3: " fmt
  case "$fmt" in
    1) key="${arch}_deb"; pkg="zulu24.deb" ;;
    2) key="${arch}_rpm"; pkg="zulu24.rpm" ;;
    3) key="${arch}_tar"; pkg="zulu24.tar.gz" ;;
    *) echo "Invalid choice."; exit 1 ;;
  esac

  download_and_verify "${ZULU_URL[$key]}" "${ZULU_HASH[$key]}" "$pkg"

  echo "Installing $pkg..."
  if [[ "$fmt" == "1" ]]; then
    # try dpkg, auto-fix deps if needed
    if ! sudo dpkg -i "$pkg"; then
      echo "Dependency issues detected. Attempting to fix…"
      sudo apt-get update -y
      sudo apt-get install -f -y
      sudo dpkg --configure -a
      sudo dpkg -i "$pkg"
    fi
  elif [[ "$fmt" == "2" ]]; then
    sudo rpm -i "$pkg"
  else
    sudo mkdir -p /opt/zulu24
    sudo tar -xzf "$pkg" -C /opt/zulu24 --strip-components=1
    echo 'export PATH="/opt/zulu24/bin:$PATH"' >> ~/.bashrc
    export PATH="/opt/zulu24/bin:$PATH"
  fi

  # final sanity-check
  if ! command -v java &>/dev/null; then
    echo "ERROR: Java still not usable after install."
    exit 1
  fi
}

ensure_java() {
  if ! command -v java &>/dev/null; then
    offer_install_java
  fi
}

clean_props() {
  sleep 120
  [[ -f server.properties ]] || return
  sed -i '/^#/d' server.properties
  sort -o server.properties server.properties
}

ensure_tmux_conf() {
  local conf="$HOME/.tmux.conf" marker="set -g mouse on"
  if [[ -f "$conf" ]]; then
    grep -qF "$marker" "$conf" && { echo "tmux scrollback already enabled."; return; }
    { echo ""; echo "# enable mouse scrollback"; echo "$marker"; } >>"$conf" \
      && echo "tmux config updated for scroll support." \
      || echo "Couldn't change tmux configuration, skipping."
  else
    { echo "# tmux config created by start.sh"; echo "$marker"; } >"$conf" \
      && echo "tmux config created with scroll support." \
      || echo "Couldn't create tmux configuration, skipping."
  fi
}

start_server() {
  if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    read -rp "Attach to existing '$TMUX_SESSION'? (y/n) " ans
    [[ "$ans" =~ ^[Yy]$ ]] && tmux attach -t "$TMUX_SESSION" && exit 0
    echo "Leaving existing session running."; exit 0
  fi

  echo "Starting tmux session '$TMUX_SESSION'..."
  tmux new-session -d -s "$TMUX_SESSION" "${JAVA_CMD[@]}"
  sleep 2
  tmux has-session -t "$TMUX_SESSION" 2>/dev/null \
    && echo "Server running! Attach with: tmux attach -t $TMUX_SESSION" \
    || { echo "Failed to start tmux session."; exit 1; }
}

# ------------------------ MAIN ------------------------

ensure_java

if [[ ! -f "$JAR_NAME" ]]; then
  download_and_verify "$JAR_URL" "$JAR_HASH" "$JAR_NAME"
fi

total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
total_gb=$(( total_kb / 1024 / 1024 ))
if (( total_gb < 4 )); then
  echo "Need ≥4 GB RAM (found ${total_gb} GB)."; exit 1
elif (( total_gb < 8 )); then
  alloc_gb=$(( total_gb * 75 / 100 ))
else
  alloc_gb=$(( total_gb - 4 ))
fi
alloc="${alloc_gb}G"
echo "Allocating $alloc for Minecraft."

JAVA_CMD=(
  java -Xms"$alloc" -Xmx"$alloc"
  -XX:+UseG1GC -XX:+ParallelRefProcEnabled
  -XX:ParallelGCThreads=4 -XX:ConcGCThreads=2
  -XX:MaxGCPauseMillis=300 -XX:+UnlockExperimentalVMOptions
  -XX:+DisableExplicitGC -XX:+AlwaysPreTouch
  -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40
  -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5
  -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=25
  -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5
  -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem
  -XX:MaxTenuringThreshold=1 -XX:+UseStringDeduplication
  -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true
  -Dpaper.maxChunkThreads=3 --add-modules=jdk.incubator.vector
  -jar "$JAR_NAME" nogui
)

clean_props & ensure_tmux_conf
start_server
