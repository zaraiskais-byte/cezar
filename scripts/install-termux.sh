#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

REPO_URL="https://github.com/zaraiskais-byte/cezar.git"
INSTALL_DIR="$HOME/cezar"
LOG_DIR="${TMPDIR:-$HOME/tmp}"
LOG_FILE="$LOG_DIR/cezar-install.log"

mkdir -p "$LOG_DIR"

log() {
    printf '[cezar] %s\n' "$*"
}

die() {
    printf '[cezar] ERROR: %s\n' "$*" >&2
    printf '[cezar] Log: %s\n' "$LOG_FILE" >&2
    exit 1
}

exec > >(tee -a "$LOG_FILE") 2>&1

log "Starting Cezar Termux installer..."

if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ]; then
    die "This installer must be run inside Termux."
fi

command -v curl >/dev/null 2>&1 || die "curl is required."
command -v git >/dev/null 2>&1 || die "git is required."

if ! curl -fsI https://github.com >/dev/null; then
    die "Network access to GitHub is unavailable."
fi

log "Updating Termux packages..."
pkg update -y

log "Installing build dependencies..."
pkg install -y git clang make libcurl curl

for cmd in git clang make curl; do
    command -v "$cmd" >/dev/null 2>&1 || die "$cmd was not installed correctly."
done

command -v curl-config >/dev/null 2>&1 || die "curl-config was not installed correctly."

if [ -e "$INSTALL_DIR/.git" ]; then
    log "Existing Cezar checkout found at $INSTALL_DIR."

    cd "$INSTALL_DIR"

    if ! git diff --quiet || ! git diff --cached --quiet; then
        die "Local changes detected in $INSTALL_DIR. Refusing to overwrite them."
    fi

    log "Updating repository..."
    git fetch origin
    git checkout master
    git pull --ff-only origin master
else
    if [ -e "$INSTALL_DIR" ]; then
        die "$INSTALL_DIR exists but is not a Git repository."
    fi

    log "Cloning Cezar..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

log "Building Cezar..."
make

[ -x "./build/cezar" ] || die "Build completed but build/cezar was not created."

log "Running tests..."
make test

log "Checking executable..."
./build/cezar --help >/dev/null

log ""
log "========================================"
log "Cezar installation completed successfully."
log "========================================"
log ""
log "Project: $INSTALL_DIR"
log "Binary:  $INSTALL_DIR/build/cezar"
log "Log:     $LOG_FILE"
log ""
log "Run:"
log "  cd ~/cezar"
log "  ./build/cezar --help"
log ""
log "All installation checks passed."
