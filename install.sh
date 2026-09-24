#!/usr/bin/env bash
#
# install.sh - Installationsscript fuer die hvim Neovim-Config
#
# - installiert Systemabhaengigkeiten (git, ripgrep, fd, Compiler, Node, Python, JDK)
# - installiert Neovim >= 0.11 (falls noetig aus dem offiziellen Tarball)
# - sichert eine vorhandene Config und kopiert diese Config nach ~/.config/nvim
# - synchronisiert die Plugins und installiert die LSP-Server headless
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
BACKUP_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim.bak.$(date +%Y%m%d-%H%M%S)"
NVIM_MIN="0.11"
NVIM_DIR="$HOME/.local/opt/nvim"
NVIM_BIN="$HOME/.local/bin/nvim"

# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }

nvim_version() {
    have nvim || return 1
    nvim --version | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1
}

nvim_is_ok() {
    local v
    v="$(nvim_version)" || return 1
    version_ge "$v" "$NVIM_MIN"
}

# ---------------------------------------------------------------------------
# 1. Systemabhaengigkeiten installieren
# ---------------------------------------------------------------------------
install_deps() {
    log "Erkenne Paketmanager und installiere Abhaengigkeiten..."

    if have apt-get; then
        $SUDO apt-get update
        $SUDO apt-get install -y \
            git curl unzip tar gzip xclip \
            ripgrep fd-find \
            build-essential pkg-config \
            nodejs npm python3 python3-venv python3-pip \
            openjdk-21-jdk-headless
    elif have dnf; then
        $SUDO dnf install -y \
            git curl unzip tar gzip xclip \
            ripgrep fd-find \
            gcc gcc-c++ make pkgconf-pkg-config \
            nodejs npm python3 python3-pip \
            java-21-openjdk-devel
    elif have pacman; then
        $SUDO pacman -Sy --noconfirm \
            git curl unzip tar gzip xclip \
            ripgrep fd \
            base-devel pkgconf \
            nodejs npm python python-pip \
            jdk21-openjdk
    elif have zypper; then
        $SUDO zypper --non-interactive install \
            git curl unzip tar gzip xclip \
            ripgrep fd \
            gcc gcc-c++ make pkg-config \
            nodejs npm python3 python3-pip \
            java-21-openjdk-devel
    elif have nix; then
        log "NixOS/Nix erkannt - installiere Abhaengigkeiten ins User-Profil..."
        nix profile install \
            nixpkgs#git nixpkgs#curl nixpkgs#unzip nixpkgs#gzip nixpkgs#xclip \
            nixpkgs#ripgrep nixpkgs#fd \
            nixpkgs#gcc nixpkgs#gnumake nixpkgs#pkg-config \
            nixpkgs#nodejs nixpkgs#python3 nixpkgs#jdk21 \
            || warn "nix profile install fehlgeschlagen (Flakes aktiviert?). Abhaengigkeiten ggf. manuell installieren."
    else
        warn "Kein bekannter Paketmanager gefunden. Bitte Abhaengigkeiten manuell installieren:"
        warn "  git curl unzip ripgrep fd gcc make nodejs npm python3 java-21"
    fi

    # Debian/Ubuntu liefert fd als "fdfind" aus -> Symlink fuer telescope
    if have fdfind && ! have fd; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

# ---------------------------------------------------------------------------
# 2. Neovim >= 0.11 sicherstellen
# ---------------------------------------------------------------------------
install_nvim() {
    if nvim_is_ok; then
        log "Neovim $(nvim_version) gefunden (>= $NVIM_MIN)."
        return
    fi

    log "Installiere Neovim >= $NVIM_MIN aus dem offiziellen Tarball..."

    local arch url tmp
    case "$(uname -m)" in
        x86_64|amd64)   arch="x86_64" ;;
        aarch64|arm64)  arch="arm64"  ;;
        *) die "Nicht unterstuetzte Architektur: $(uname -m)" ;;
    esac

    url="https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${arch}.tar.gz"
    tmp="$(mktemp -d)"

    curl -fL "$url" -o "$tmp/nvim.tar.gz"
    tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"

    rm -rf "$NVIM_DIR"
    mkdir -p "$(dirname "$NVIM_DIR")"
    mv "$tmp"/nvim-linux* "$NVIM_DIR"
    mkdir -p "$(dirname "$NVIM_BIN")"
    ln -sf "$NVIM_DIR/bin/nvim" "$NVIM_BIN"
    rm -rf "$tmp"

    export PATH="$(dirname "$NVIM_BIN"):$PATH"

    if ! nvim_is_ok; then
        die "Neovim-Installation fehlgeschlagen. Bitte PATH pruefen: $NVIM_BIN"
    fi
    log "Neovim $(nvim_version) installiert nach $NVIM_DIR."
}

# ---------------------------------------------------------------------------
# 3. Config installieren (vorhandene Config sichern)
# ---------------------------------------------------------------------------
install_config() {
    if [ "$REPO_DIR" = "$CONFIG_DIR" ]; then
        log "Config liegt bereits in $CONFIG_DIR, ueberspringe Kopieren."
        return
    fi

    if [ -e "$CONFIG_DIR" ] || [ -L "$CONFIG_DIR" ]; then
        log "Sichere vorhandene Config nach $BACKUP_DIR"
        mkdir -p "$(dirname "$BACKUP_DIR")"
        mv "$CONFIG_DIR" "$BACKUP_DIR"
    fi

    log "Kopiere Config nach $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
    if have rsync; then
        rsync -a --exclude '.git' --exclude 'install.sh' "$REPO_DIR/" "$CONFIG_DIR/"
    else
        tar -C "$REPO_DIR" --exclude '.git' --exclude 'install.sh' -cf - . | tar -C "$CONFIG_DIR" -xf -
    fi
}

# ---------------------------------------------------------------------------
# 4. Plugins synchronisieren und LSP-Server installieren
# ---------------------------------------------------------------------------
setup_plugins() {
    log "Synchronisiere Plugins (lazy.nvim restore)..."
    nvim --headless "+Lazy! restore" +qa || warn "lazy restore meldete Fehler."

    log "Installiere LSP-Server (mason)..."
    local mason_lua
    mason_lua="$(mktemp --suffix=.lua)"
    cat > "$mason_lua" <<'LUA'
local servers = {
    "jdtls",
    "lua-language-server",
    "json-languageserver",
    "yaml-language-server",
    "bash-language-server",
    "clangd",
    "basedpyright",
}

local ok, registry = pcall(require, "mason-registry")
if not ok then
    vim.notify("mason-registry nicht verfuegbar, ueberspringe LSP-Installation", vim.log.levels.WARN)
    return
end

pcall(registry.refresh, function() end)
vim.wait(3000, function() return false end, 200)

local pending = {}
for _, name in ipairs(servers) do
    local pok, pkg = pcall(registry.get_package, name)
    if pok and not pkg:is_installed() then
        pkg:install()
        table.insert(pending, pkg)
    end
end

if #pending == 0 then
    vim.notify("Alle LSP-Server bereits installiert.", vim.log.levels.INFO)
    return
end

vim.notify(("Installiere %d LSP-Server..."):format(#pending), vim.log.levels.INFO)
local finished = vim.wait(900000, function()
    for _, p in ipairs(pending) do
        if not p:is_installed() then return false end
    end
    return true
end, 500)

if not finished then
    vim.notify("LSP-Installation nicht abgeschlossen. Beim naechsten Start erneut versuchen.", vim.log.levels.WARN)
end
LUA

    nvim --headless "+luafile $mason_lua" +qa || warn "mason-Installation meldete Fehler."
    rm -f "$mason_lua"
}

# ---------------------------------------------------------------------------
main() {
    log "hvim Installation gestartet (Quelle: $REPO_DIR)"
    install_deps
    install_nvim
    install_config
    setup_plugins

    log "Fertig!"
    printf '\n'
    printf '  Config:     %s\n' "$CONFIG_DIR"
    if [ -n "${BACKUP_DIR:-}" ] && [ -e "${BACKUP_DIR:-/nonexistent}" ]; then
        printf '  Backup:     %s\n' "$BACKUP_DIR"
    fi
    printf '  Neovim:     %s\n' "$(command -v nvim)"
    printf '\n'
    printf 'Starte Neovim mit: nvim\n'
    if ! printf '%s' ":$PATH:" | grep -q ":$HOME/.local/bin:"; then
        printf 'Hinweis: Fuege %s zum PATH hinzu (z.B. in ~/.bashrc).\n' "$HOME/.local/bin"
    fi
}

main "$@"
