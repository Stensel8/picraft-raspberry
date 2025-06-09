#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Docker entrypoint for PaperMC:
#  1) cd into /mc-data (world, logs, configs)
#  2) Download & verify Java (Azul Zulu) if missing
#  3) Download & verify PaperMC JAR if missing
#  4) Allocate RAM based on available memory
#  5) Spawn a background task to clean server.properties
#  6) Auto-accept EULA via EULA=true
#  7) Launch the Minecraft server with optional extra JVM flags
# -----------------------------------------------------------------------------

cd /mc-data

#── defaults (all can be overridden via ENV) ─────────────────────────────────
: "${JAR_URL:=https://api.papermc.io/v2/projects/paper/versions/1.21.5/builds/112/downloads/paper-1.21.5-112.jar}"
: "${JAR_HASH:=7e023f14ed82cd3bd49b9f06d032a2ae741ae73b449713881b0d6be026f30b83}"
: "${JAR_NAME:=paper-1.21.5-112.jar}"

# Azul Zulu download URLs & checksums
declare -A ZULU_URL=(
  [x86_64]="https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_x64.tar.gz"
  [aarch64]="https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_aarch64.tar.gz"
)
declare -A ZULU_HASH=(
  [x86_64]="12f6957c3a2a74d36d692cfee3aeeb949f15b5d80dad08bf0d3ed930d66d8659"
  [aarch64]="e11e4ae574e0a51f64abd5961374a0bea553abc085bf26fde37cc0892b2ade4d"
)

#─ helper: detect CPU arch ───────────────────────────────────────────────────
detect_arch() {
  case "$(uname -m)" in
    x86_64)    echo "x86_64"   ;;
    aarch64|arm64) echo "aarch64" ;;
    *) echo "unsupported" ;;
  esac
}

#─ helper: download & verify SHA256 ──────────────────────────────────────────
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

#─ helper: ensure Java is available ─────────────────────────────────────────
ensure_java() {
  if ! command -v java &>/dev/null; then
    echo ">>> Java not found, installing Azul Zulu..."
    local arch=$(detect_arch)
    [[ "$arch" != "unsupported" ]] || { echo "ERROR: unsupported arch $(uname -m)"; exit 1; }

    download_and_verify "${ZULU_URL[$arch]}" "${ZULU_HASH[$arch]}" zulu.tar.gz
    mkdir -p /opt/zulu24
    tar -xzf zulu.tar.gz -C /opt/zulu24 --strip-components=1
    rm -f zulu.tar.gz

    export PATH="/opt/zulu24/bin:$PATH"
    echo 'export PATH="/opt/zulu24/bin:$PATH"' >> /root/.bashrc

    command -v java &>/dev/null \
      || { echo "ERROR: Java installation failed."; exit 1; }
  fi
}

#─ helper: clean server.properties after startup ────────────────────────────
clean_properties() {
  sleep 120
  [[ -f server.properties ]] || return
  echo ">>> Cleaning server.properties"
  sed -i '/^#/d' server.properties
  sort -o server.properties server.properties
  echo "✔ server.properties cleaned"
}

#─────────────────────────────────────────────────────────────────────────────
ensure_java

# Download PaperMC JAR if missing
if [[ ! -f "$JAR_NAME" ]]; then
  download_and_verify "$JAR_URL" "$JAR_HASH" "$JAR_NAME"
fi

# RAM allocation logic
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

# Clean up server.properties in the background
clean_properties &

# Auto-accept EULA
: "${EULA:=false}"
if [[ "${EULA,,}" != "true" ]]; then
  echo "ERROR: You must accept the EULA (set EULA=true)" >&2
  exit 1
fi
echo "eula=true" > eula.txt
echo "✔ EULA accepted"

# Finally, launch the server with any extra JVM flags
echo ">>> Starting PaperMC..."
exec java ${JAVA_OPTS:-} \
  -Xms"$alloc" -Xmx"$alloc" \
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
  -Dpaper.maxChunkThreads=3 --add-modules=jdk.incubator.vector \
  -jar "$JAR_NAME" nogui
