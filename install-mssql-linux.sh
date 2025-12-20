#!/usr/bin/env bash
set -euo pipefail

info()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" >&2; }

INTERACTIVE=1
UNATTENDED_SETUP=0
LOG_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes|--non-interactive)
      INTERACTIVE=0
      shift
      ;;
    --unattended-setup|--ci-setup)
      UNATTENDED_SETUP=1
      shift
      ;;
    --log)
      LOG_FILE="$HOME/install-mssql.log"
      shift
      ;;
    --log-file)
      LOG_FILE="$2"
      shift 2
      ;;
    --log-file=*)
      LOG_FILE="${1#*=}"
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: install-mssql-linux.sh [OPTIONS]

Installs:
  - SQL Server engine (mssql-server + FTS + Agent)
  - ODBC driver + tools (msodbcsql, mssql-tools on Arch / *18 on Ubuntu)

Modes:
  - full        = engine + tools
  - engine-only = engine only
  - client-only = tools only

Options:
  -y, --yes, --non-interactive   Use defaults, no interactive questions.
  --unattended-setup, --ci-setup
                                 Non-interactive mssql-conf setup. Requires:
                                   MSSQL_SA_PASSWORD
                                   MSSQL_PID (e.g. Developer)
  --log                          Log to ~/install-mssql.log
  --log-file PATH                Log to PATH
  -h, --help                     Show this help.

Examples:
  ./install-mssql-linux.sh
  MSSQL_SA_PASSWORD='YourStrong!Passw0rd' MSSQL_PID='Developer' \
    ./install-mssql-linux.sh --yes --unattended-setup --log
EOF
      exit 0
      ;;
    *)
      warn "Ignoring unknown option: $1"
      shift
      ;;
  esac
done

DISTRO=""
PRETTY=""
VERSION_ID="${VERSION_ID:-}"

MSSQL_DEPS_ARCH=(openssl-1.1 libldap24 libc++ sssd libatomic_ops)
MSSQL_SERVER_PKGS_ARCH=(mssql-server mssql-server-fts mssql-server-agent)
MSSQL_CLIENT_PKGS_ARCH=(msodbcsql mssql-tools)

MSSQL_DEPS_UBUNTU=(unixodbc-dev)
MSSQL_SERVER_PKGS_UBUNTU=(mssql-server)
MSSQL_CLIENT_PKGS_UBUNTU=(msodbcsql18 mssql-tools18)

INSTALL_MODE="full"      # full | engine-only | client-only
RUN_UPDATE="y"
INSTALL_DEPS="y"
RUN_SETUP="y"
ENABLE_SERVICE="y"
MODIFY_SHELL_RC="y"
USE_YAY="y"
ADD_MS_REPO="y"
MS_REPO_ADDED=0

require_not_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    error "Do not run this script as root. Use a normal user; sudo is used internally."
    exit 1
  fi
}

require_sudo() {
  if ! sudo -n true 2>/dev/null; then
    warn "Sudo password will be required."
    sudo true
  fi
}

require_network() {
  if ! ping -c1 archlinux.org &>/dev/null; then
    warn "Network check failed. Make sure you are online before continuing."
  fi
}

detect_distro() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
  else
    error "/etc/os-release not found; cannot detect distribution."
    exit 1
  fi

  if [[ "${ID,,}" == "ubuntu" ]] || [[ "${ID_LIKE:-}" == *"ubuntu"* ]] || [[ "${ID_LIKE:-}" == *"debian"* ]]; then
    DISTRO="ubuntu"
  elif [[ "${ID,,}" == "arch" ]] || [[ "${ID_LIKE:-}" == *"arch"* ]]; then
    DISTRO="arch"
  fi

  if [[ -z "$DISTRO" ]]; then
    error "Unsupported distro: ID='${ID:-unknown}' ID_LIKE='${ID_LIKE:-unknown}'."
    error "Supported: Ubuntu-like, Arch-like."
    exit 1
  fi

  PRETTY="${PRETTY_NAME:-$ID}"
  VERSION_ID="${VERSION_ID:-}"
  info "Detected distribution: $DISTRO ($PRETTY)"
}

download_file() {
  local url="$1" dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -sSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    error "Neither 'curl' nor 'wget' is installed. Please install one and rerun."
    exit 1
  fi
}

ask_yes_no() {
  local num="$1"; shift
  local question="$1"; shift
  local default="${1:-y}"
  local prompt default_letter answer

  if [[ "$default" == "y" ]]; then
    prompt="Y/n"; default_letter="y"
  else
    prompt="y/N"; default_letter="n"
  fi

  if [[ "$INTERACTIVE" -eq 0 ]]; then
    info "Q${num}) ${question} [auto: ${default_letter}]"
    echo "$default_letter"
    return 0
  fi

  while true; do
    printf "Q%s) %s [%s]: " "$num" "$question" "$prompt" >&2
    read -r answer
    answer="${answer:-$default_letter}"
    case "${answer,,}" in
      y|yes) echo "y"; return 0 ;;
      n|no)  echo "n"; return 0 ;;
      *) printf "Please answer y or n.\n" >&2 ;;
    esac
  done
}

ask_install_mode() {
  local num="$1"; shift
  local default_mode="$1"; shift

  if [[ "$INTERACTIVE" -eq 0 ]]; then
    info "Q${num}) SQL Server install mode [auto: ${default_mode}]"
    echo "$default_mode"
    return 0
  fi

  local default_choice="1"
  case "$default_mode" in
    full)        default_choice="1" ;;
    engine-only) default_choice="2" ;;
    client-only) default_choice="3" ;;
  esac

  local choice
  while true; do
    cat >&2 <<EOF
Q${num}) What do you want to install?

    1) Full SQL Server:
         - Engine (mssql-server)
         - Full-text search (FTS)
         - SQL Server Agent
         - ODBC driver + CLI tools (sqlcmd, bcp, etc.)

    2) Engine only:
         - Engine (mssql-server + FTS + Agent)
         - NO client tools

    3) Client tools only:
         - ODBC driver + CLI tools
         - NO engine/service on this machine

EOF
    printf "    Enter a number 1–3 [%s]: " "$default_choice" >&2
    read -r choice
    choice="${choice:-$default_choice}"

    case "$choice" in
      1) echo "full";        return 0 ;;
      2) echo "engine-only"; return 0 ;;
      3) echo "client-only"; return 0 ;;
      *) printf "    Invalid choice. Please enter 1, 2, or 3.\n" >&2 ;;
    esac
  done
}

install_yay() {
  if command -v yay &>/dev/null; then
    info "yay already installed."
    return
  fi

  [[ "$USE_YAY" == "y" ]] || {
    error "This script requires 'yay' to install SQL Server packages from AUR."
    error "Install 'yay' manually or allow automatic installation (Q4)."
    exit 1
  }

  info "Installing yay (AUR helper)..."
  sudo pacman -Sy --needed --noconfirm git base-devel

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
  pushd "$tmp_dir/yay" >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null

  info "yay installation complete."
}

validate_arch_pkgs() {
  local missing=() p
  for p in "$@"; do
    yay -Si "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if ((${#missing[@]} > 0)); then
    error "These AUR/Arch packages were not found:"
    printf '  - %s\n' "${missing[@]}" >&2
    error "Check package names (e.g., msodbcsql vs msodbcsql-bin) and adjust."
    exit 1
  fi
}

validate_ubuntu_pkgs() {
  local missing=() p
  for p in "$@"; do
    apt-cache show "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if ((${#missing[@]} > 0)); then
    error "These apt packages were not found in your repos:"
    printf '  - %s\n' "${missing[@]}" >&2
    error "Check package names or repo configuration and retry."
    exit 1
  fi
}

ensure_ms_repo_ubuntu() {
  if [[ -f /etc/apt/sources.list.d/microsoft-prod.list ]]; then
    return
  fi

  [[ "$ADD_MS_REPO" == "y" ]] || {
    error "Microsoft SQL Server apt repo is not configured and you chose not to add it."
    error "Add the repo manually (per MS docs) and rerun."
    exit 1
  }

  info "Adding Microsoft packages repository for SQL Server..."
  local tmp_deb
  tmp_deb="$(mktemp /tmp/packages-microsoft-prod.XXXXXX.deb)"
  local url="https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb"
  info "Downloading: $url"
  download_file "$url" "$tmp_deb"
  sudo dpkg -i "$tmp_deb"
  rm -f "$tmp_deb"
  MS_REPO_ADDED=1
}

install_mssql_arch() {
  install_yay

  local to_check=()
  if [[ "$INSTALL_DEPS" == "y" ]]; then
    to_check+=("${MSSQL_DEPS_ARCH[@]}")
  fi
  if [[ "$INSTALL_MODE" == "full" || "$INSTALL_MODE" == "engine-only" ]]; then
    to_check+=("${MSSQL_SERVER_PKGS_ARCH[@]}")
  fi
  if [[ "$INSTALL_MODE" == "full" || "$INSTALL_MODE" == "client-only" ]]; then
    to_check+=("${MSSQL_CLIENT_PKGS_ARCH[@]}")
  fi
  if ((${#to_check[@]} > 0)); then
    info "Validating Arch/AUR package names with yay -Si..."
    validate_arch_pkgs "${to_check[@]}"
  fi

  if [[ "$RUN_UPDATE" == "y" ]]; then
    info "Updating system and package databases via yay (pacman + AUR)..."
    yay -Syu --noconfirm
  else
    info "Skipping yay -Syu as requested."
  fi

  if [[ "$INSTALL_DEPS" == "y" ]]; then
    info "Installing SQL Server dependencies from AUR..."
    yay -S --needed --noconfirm "${MSSQL_DEPS_ARCH[@]}"
  else
    info "Skipping SQL Server dependency installation."
  fi

  if [[ "$INSTALL_MODE" == "full" || "$INSTALL_MODE" == "engine-only" ]]; then
    info "Installing SQL Server engine and components from AUR..."
    yay -S --needed --noconfirm "${MSSQL_SERVER_PKGS_ARCH[@]}"
  fi

  if [[ "$INSTALL_MODE" == "full" || "$INSTALL_MODE" == "client-only" ]]; then
    info "Installing ODBC driver and SQL Server tools from AUR..."
    ACCEPT_EULA=Y yay -S --needed --noconfirm "${MSSQL_CLIENT_PKGS_ARCH[@]}"
  fi

  info "Arch SQL Server-related packages installation complete."
}

install_mssql_ubuntu() {
  ensure_ms_repo_ubuntu

  local to_check=()
  if [[ "$INSTALL_DEPS" == "y" && ${#MSSQL_DEPS_UBUNTU[@]} -gt 0 ]]; then
    to_check+=("${MSSQL_DEPS_UBUNTU[@]}")
  fi
  if [[ "$INSTALL_MODE" == "full" || "$INSTALL_MODE" == "engine-only" ]]; then
    to_check+=("${MSSQL_SERVER_PKGS_UBUNTU[@]}")
  fi
  if [[ "$INSTALL_MODE" == "full" || "$INSTALL_MODE" == "client-only" ]]; then
    to_check+=("${MSSQL_CLIENT_PKGS_UBUNTU[@]}")
  fi
  if ((${#to_check[@]} > 0)); then
    info "Validating Ubuntu package names with apt-cache show..."
    validate_ubuntu_pkgs "${to_check[@]}"
  fi

  if [[ "$RUN_UPDATE" == "y" ]]; then
    info "Running: sudo apt-get update"
    sudo apt-get update
  elif [[ "$MS_REPO_ADDED" -eq 1 ]]; then
    error "Microsoft SQL Server repo was just added, but apt-get update was disallowed."
    error "Run 'sudo apt-get update' manually and rerun this script."
    exit 1
  else
    info "Skipping apt-get update as requested."
  fi

  if [[ "$INSTALL_DEPS" == "y" && ${#MSSQL_DEPS_UBUNTU[@]} -gt 0 ]]; then
    info "Installing extra SQL Server dependencies on Ubuntu: ${MSSQL_DEPS_UBUNTU[*]}"
    sudo apt-get install -y "${MSSQL_DEPS_UBUNTU[@]}"
  else
    info "Skipping extra dependency installation on Ubuntu."
  fi

  if [[ "$INSTALL_MODE" == "full" || "$INSTALL_MODE" == "engine-only" ]]; then
    info "Installing SQL Server engine (mssql-server) via apt..."
    sudo apt-get install -y "${MSSQL_SERVER_PKGS_UBUNTU[@]}"
  fi

  if [[ "$INSTALL_MODE" == "full" || "$INSTALL_MODE" == "client-only" ]]; then
    info "Installing ODBC driver and SQL Server tools via apt..."
    sudo ACCEPT_EULA=Y apt-get install -y "${MSSQL_CLIENT_PKGS_UBUNTU[@]}"
  fi

  info "Ubuntu SQL Server-related packages installation complete."
}

configure_mssql() {
  if [[ ! -x /opt/mssql/bin/mssql-conf ]]; then
    error "mssql-conf not found at /opt/mssql/bin/mssql-conf. Install likely failed."
    return 1
  fi

  if [[ "$UNATTENDED_SETUP" -eq 1 ]]; then
    [[ -n "${MSSQL_SA_PASSWORD:-}" ]] || { error "UNATTENDED_SETUP requires MSSQL_SA_PASSWORD env var."; exit 1; }
    local pid="${MSSQL_PID:-Developer}"
    info "Running non-interactive mssql-conf setup (accept-eula, PID=$pid)..."
    sudo MSSQL_SA_PASSWORD="$MSSQL_SA_PASSWORD" MSSQL_PID="$pid" \
      /opt/mssql/bin/mssql-conf -n setup accept-eula
    return 0
  fi

  info "Running interactive SQL Server configuration (mssql-conf setup)..."
  sudo /opt/mssql/bin/mssql-conf setup
}

enable_mssql_service() {
  info "Enabling and starting mssql-server systemd service..."
  sudo systemctl enable --now mssql-server

  info "Checking service status..."
  if systemctl is-active --quiet mssql-server; then
    info "mssql-server is running."
  else
    warn "mssql-server is not active. Check 'systemctl status mssql-server'."
  fi
}

add_mssql_tools_to_path() {
  local tools_dirs=(/opt/mssql-tools/bin /opt/mssql-tools18/bin)
  local existing_dirs=() d
  for d in "${tools_dirs[@]}"; do
    [[ -d "$d" ]] && existing_dirs+=("$d")
  done

  if ((${#existing_dirs[@]} == 0)); then
    warn "No mssql-tools directory found under: ${tools_dirs[*]}. Skipping PATH update."
    return
  fi

  local rc_files=()
  [[ -f "$HOME/.bashrc" ]] && rc_files+=("$HOME/.bashrc")
  [[ -f "$HOME/.zshrc"  ]] && rc_files+=("$HOME/.zshrc")

  if [[ ${#rc_files[@]} -eq 0 ]]; then
    warn "No .bashrc or .zshrc found. Add the following manually:"
    for d in "${existing_dirs[@]}"; do
      printf '  export PATH="$PATH:%s"\n' "$d"
    done
    return
  fi

  local rc already
  for rc in "${rc_files[@]}"; do
    already=0
    for d in "${existing_dirs[@]}"; do
      grep -Fq "$d" "$rc" 2>/dev/null && already=1
    done
    if [[ $already -eq 1 ]]; then
      info "mssql-tools already in PATH in $rc"
      continue
    fi

    info "Adding mssql-tools to PATH in $rc"
    {
      echo ""
      echo "# Added by install-mssql-linux.sh for Microsoft SQL Server tools"
      for d in "${existing_dirs[@]}"; do
        echo "export PATH=\"\$PATH:$d\""
      done
    } >> "$rc"
  done

  info "Restart your shell session (or 'source ~/.bashrc' / 'source ~/.zshrc') to use sqlcmd."
}

healthcheck_mssql() {
  if [[ "$INSTALL_MODE" == "client-only" ]]; then
    return
  fi
  if ! systemctl is-active --quiet mssql-server 2>/dev/null; then
    warn "Healthcheck skipped: mssql-server service is not active."
    return
  fi

  local sqlcmd_bin=""
  sqlcmd_bin="$(command -v sqlcmd 2>/dev/null || true)"
  if [[ -z "$sqlcmd_bin" ]]; then
    local d
    for d in /opt/mssql-tools/bin /opt/mssql-tools18/bin; do
      if [[ -x "$d/sqlcmd" ]]; then
        sqlcmd_bin="$d/sqlcmd"
        break
      fi
    done
  fi

  if [[ -z "$sqlcmd_bin" ]]; then
    warn "Healthcheck skipped: 'sqlcmd' not found."
    return
  fi

  if [[ -z "${MSSQL_SA_PASSWORD:-}" ]]; then
    info "Healthcheck: MSSQL_SA_PASSWORD not set; skipping automatic login."
    info "You can run manually:"
    info "  $sqlcmd_bin -S localhost -U SA -Q \"SELECT @@VERSION;\""
    return
  fi

  info "Running healthcheck query with sqlcmd (SELECT @@VERSION;)..."
  if "$sqlcmd_bin" -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -Q "SELECT @@VERSION;" >/dev/null 2>&1; then
    info "Healthcheck succeeded: SQL Server responded to SELECT @@VERSION."
  else
    warn "Healthcheck FAILED: sqlcmd could not connect or query with SA credentials."
  fi
}

print_summary() {
  local engine="no" client="no"
  if [[ "$INSTALL_MODE" == "full" || "$INSTALL_MODE" == "engine-only" ]]; then
    engine="yes"
  fi
  if [[ "$INSTALL_MODE" == "full" || "$INSTALL_MODE" == "client-only" ]]; then
    client="yes"
  fi

  cat <<EOF

------------------------------------------------------------
Microsoft SQL Server installation finished.

  Engine installed:        $engine
  Client tools installed:  $client
  Systemd service enabled: $([[ "$ENABLE_SERVICE" == "y" && "$engine" == "yes" ]] && echo "requested" || echo "not requested")

Service commands:
  sudo systemctl status mssql-server
  sudo systemctl restart mssql-server

CLI examples (if tools installed):
  sqlcmd -S localhost -U SA -P '<YourSAPassword>'

Config and logs:
  sudo /opt/mssql/bin/mssql-conf
  /var/opt/mssql/log
  sudo journalctl -u mssql-server
------------------------------------------------------------

EOF
}

run_questions() {
  local ans

  ans=$(ask_yes_no 1 "Continue with Microsoft SQL Server + tools installation?" "y")
  [[ "$ans" == "y" ]] || { info "Aborting by user request."; exit 0; }

  ans=$(ask_yes_no 2 "Detected distro is ${DISTRO} (${PRETTY}). Is this correct?" "y")
  [[ "$ans" == "y" ]] || { error "Distro detection not confirmed. Exiting."; exit 1; }

  INSTALL_MODE=$(ask_install_mode 3 "full")

  if [[ "$DISTRO" == "arch" ]]; then
    USE_YAY=$(ask_yes_no 4 "Allow this script to install and use 'yay' (AUR helper)?" "y")
  else
    ADD_MS_REPO=$(ask_yes_no 4 "Allow this script to add the Microsoft SQL Server apt repo if missing?" "y")
  fi

  RUN_UPDATE=$(ask_yes_no 5 "Is it OK to run a package database update (apt update / pacman -Sy[u])?" "y")
  INSTALL_DEPS=$(ask_yes_no 6 "Install extra OS dependencies required by SQL Server?" "y")
  RUN_SETUP=$(ask_yes_no 7 "Run 'mssql-conf setup' now?" "y")
  ENABLE_SERVICE=$(ask_yes_no 8 "Enable and start the 'mssql-server' systemd service?" "y")
  MODIFY_SHELL_RC=$(ask_yes_no 9 "Add /opt/mssql-tools*/bin to PATH in ~/.bashrc and ~/.zshrc?" "y")

  echo
  info "Configuration summary:"
  echo "  Distro:                   $DISTRO ($PRETTY)"
  echo "  Install mode:             $INSTALL_MODE"
  if [[ "$DISTRO" == "arch" ]]; then
    echo "  Use yay for AUR:          $USE_YAY"
  else
    echo "  Add Microsoft apt repo:   $ADD_MS_REPO"
  fi
  echo "  Run pkg update:           $RUN_UPDATE"
  echo "  Install extra deps:       $INSTALL_DEPS"
  echo "  Run mssql-conf setup:     $RUN_SETUP"
  echo "  Enable/start service:     $ENABLE_SERVICE"
  echo "  Modify shell rc PATH:     $MODIFY_SHELL_RC"
  echo

  ans=$(ask_yes_no 10 "Proceed with installation using these settings?" "y")
  [[ "$ans" == "y" ]] || { info "Aborting by user choice."; exit 0; }

  [[ "$UNATTENDED_SETUP" -eq 1 ]] && RUN_SETUP="y"
}

main() {
  detect_distro
  require_not_root
  require_sudo
  require_network
  run_questions

  info "Starting Microsoft SQL Server installation..."

  if [[ "$DISTRO" == "arch" ]]; then
    install_mssql_arch
  else
    install_mssql_ubuntu
  fi

  if [[ "$INSTALL_MODE" != "client-only" && "$RUN_SETUP" == "y" ]]; then
    configure_mssql || warn "mssql-conf setup did not complete successfully."
  else
    info "Skipping mssql-conf setup as requested or because engine not installed."
  fi

  if [[ "$INSTALL_MODE" != "client-only" && "$ENABLE_SERVICE" == "y" ]]; then
    enable_mssql_service
  else
    info "Skipping systemd service enable/start as requested or because engine not installed."
  fi

  if [[ "$MODIFY_SHELL_RC" == "y" && ( "$INSTALL_MODE" == "full" || "$INSTALL_MODE" == "client-only" ) ]]; then
    add_mssql_tools_to_path
  else
    info "Skipping PATH modification for mssql-tools as requested or because client tools not installed."
  fi

  healthcheck_mssql
  print_summary
}

if [[ -n "$LOG_FILE" ]]; then
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
  main 2>&1 | tee "$LOG_FILE"
  exit "${PIPESTATUS[0]}"
else
  main
fi
