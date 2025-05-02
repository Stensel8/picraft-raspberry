#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Docker entrypoint for PaperMC:
#   - Download & verify Java (Azul Zulu) if needed
#   - Download & verify PaperMC JAR
#   - Allocate RAM based on available memory
#   - Clean server.properties in the background
#   - Auto-accept EULA via EULA=true
#   - Start the Minecraft server
# -------------------------------------------------------------------

# 1) Switch to the data directory (world, logs, configs live here)
cd /mc-data

# 2) Default configuration (all can be overridden via ENV)
: "${JAR_URL:=https://api.papermc.io/v2/projects/paper/versions/1.21.5/builds/59/downloads/paper-1.21.5-59.jar}"
: "${JAR_HASH:=45c63efe065a6ee9f0a261800f2700589e0dc3a3d4f69d3425608ed9c15401ca}"
: "${JAR_NAME:=paper-1.21.5-59.jar}"

# Azul Zulu download URLs and checksums
declare -A ZULU_URL=(
  [x86_64]="https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_x64.tar.gz"
  [aarch64]="https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_aarch64.tar.gz"
)
declare -A ZULU_HASH=(
  [x86_64]="12f6957c3a2a74d36d692cfee3aeeb949f15b5d80dad08bf0d3ed930d66d8659"
  [aarch64]="e11e4ae574e0a51f64abd5961374a0bea553abc085bf26fde37cc0892b2ade4d"
)

# Detect machine architecture
detect_arch() {
  case "$(uname -m)" in
    x86_64)    echo "x86_64"   ;;
    aarch64|arm64) echo "aarch64" ;;
    *) echo "unsupported" ;;
  esac
}

# Download a file & verify its SHA256 checksum
download_and_verify() {
  local url=$1 checksum=$2 out=$3
  echo ">>> Downloading $out"
  wget -q --show-progress -O "$out" "$url"
  echo ">>> Verifying checksum for $out"
  local actual
  actual=$(sha256sum "$out" | cut -d' ' -f1)
  if [[ "$actual" != "$checksum" ]]; then
    echo "ERROR: checksum mismatch for $out"
    echo "  expected: $checksum"
    echo "  actual:   $actual"
    exit 1
  fi
  echo "✔ Checksum OK for $out"
}

# Ensure Java is installed, otherwise download & install Azul Zulu
ensure_java() {
  if ! command -v java &>/dev/null; then
    echo ">>> Java not found, installing Azul Zulu..."
    local arch=$(detect_arch)
    [[ "$arch" != "unsupported" ]] || { echo "Unsupported arch $(uname -m)"; exit 1; }

    local tarball="zulu.tar.gz"
    download_and_verify "${ZULU_URL[$arch]}" "${ZULU_HASH[$arch]}" "$tarball"
    mkdir -p /opt/zulu24
    tar -xzf "$tarball" -C /opt/zulu24 --strip-components=1
    rm -f "$tarball"

    export PATH="/opt/zulu24/bin:$PATH"
    echo 'export PATH="/opt/zulu24/bin:$PATH"' >> /root/.bashrc

    command -v java >/dev/null \
      || { echo "ERROR: Java installation failed."; exit 1; }
  fi
}

# Clean out comments & sort server.properties after a short delay
clean_properties() {
  sleep 120
  [[ -f server.properties ]] || return
  echo ">>> Cleaning server.properties"
  sed -i '/^#/d' server.properties
  sort -o server.properties server.properties
  echo "✔ server.properties cleaned"
}

# ---------------------------- MAIN ----------------------------

ensure_java

# Download PaperMC if not already present
if [[ ! -f "$JAR_NAME" ]]; then
  download_and_verify "$JAR_URL" "$JAR_HASH" "$JAR_NAME"
fi

# Dynamically allocate RAM: ≥4 GB system → use all minus 4; else 75%
total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
total_gb=$(( total_kb / 1024 / 1024 ))
if (( total_gb < 4 )); then
  echo "ERROR: At least 4 GB RAM required (found ${total_gb} GB)"
  exit 1
elif (( total_gb < 8 )); then
  alloc_gb=$(( total_gb * 75 / 100 ))
else
  alloc_gb=$(( total_gb - 4 ))
fi
alloc="${alloc_gb}G"
echo ">>> Allocating $alloc for Minecraft"

# Clean up properties in the background
clean_properties &

# Auto-accept EULA via environment variable
: "${EULA:=false}"
if [[ "${EULA,,}" != "true" ]]; then
  echo "ERROR: You must accept the EULA (set EULA=true)" >&2
  exit 1
fi
echo "eula=true" > eula.txt
echo "✔ EULA accepted"

# Launch PaperMC
echo ">>> Starting PaperMC..."
exec java -Xms"$alloc" -Xmx"$alloc" \
  -XX:+UseG1GC -XX:+ParallelRefProcEnabled \
  -XX:ParallelGCThreads=4 -XX:ConcGCThreads=2 \
  -XX:MaxGCPauseMillis=300 -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC -XX:+AlwaysPreTouch \
  -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 \
  -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 \
  -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=25 \
  -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 \
  -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem \
  -XX:MaxTenuringThreshold=1 -XX:+UseStringDeduplication \
  -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true \
  -Dpaper.maxChunkThreads=3 \
  --add-modules=jdk.incubator.vector \
  -jar "$JAR_NAME" nogui
