# After Installing Ubuntu.

### save this below code by creating a file with your desired name for example `bootstrap-webdev.sh` make sure extension should be `.sh`
```javascript
#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# Defaults (can be overridden by flags)
# ==========================================
STACK="apache"                 # apache|nginx
PHP_VERSIONS_CSV="8.1,8.2,8.3" # can include 8.4
DEFAULT_PHP="8.2"

INSTALL_MYSQL="yes"
INSTALL_REDIS="yes"
INSTALL_NODE="yes"
NODE_MAJOR="20"
INSTALL_YARN="yes"
INSTALL_OPENSEARCH="no"

# Magento/Laravel/WP-friendly PHP extensions per version
PHP_EXTENSIONS=(
  "cli" "common" "curl" "mbstring" "xml" "zip" "gd" "intl" "mysql"
  "bcmath" "soap" "readline" "opcache" "imagick" "redis"
)

# ==========================================
# Helpers
# ==========================================
log()  { echo -e "\n\033[1;32m[+] $*\033[0m"; }
warn() { echo -e "\n\033[1;33m[!] $*\033[0m"; }
err()  { echo -e "\n\033[1;31m[-] $*\033[0m"; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "Run as root (sudo). Example: sudo bash bootstrap-webdev.sh [options]"
    exit 1
  fi
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

# Try installing packages; if fail, return non-zero (caller decides how to handle)
apt_try_install() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@" || return 1
  return 0
}

usage() {
  cat <<EOF
Usage: sudo ./bootstrap-webdev.sh [options]

Options:
  --stack apache|nginx         Web stack (default: apache)
  --php "8.1,8.2,8.3,8.4"      PHP versions to install
  --default-php 8.2            Default PHP version for CLI + stack
  --mysql yes|no               Install MySQL (default: yes)
  --redis yes|no               Install Redis (default: yes)
  --node yes|no                Install Node.js (default: yes)
  --node-major 18|20           Node major version (default: 20)
  --yarn yes|no                Install Yarn (default: yes)
  --opensearch yes|no          Install OpenSearch (default: no)
  -h, --help                   Show help

Examples:
  sudo ./bootstrap-webdev.sh --stack apache --php "8.2,8.3" --default-php 8.3 --opensearch no
  sudo ./bootstrap-webdev.sh --stack nginx --php "8.2,8.3,8.4" --default-php 8.4 --opensearch yes
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --stack) STACK="${2:-}"; shift 2 ;;
      --php) PHP_VERSIONS_CSV="${2:-}"; shift 2 ;;
      --default-php) DEFAULT_PHP="${2:-}"; shift 2 ;;
      --mysql) INSTALL_MYSQL="${2:-}"; shift 2 ;;
      --redis) INSTALL_REDIS="${2:-}"; shift 2 ;;
      --node) INSTALL_NODE="${2:-}"; shift 2 ;;
      --node-major) NODE_MAJOR="${2:-}"; shift 2 ;;
      --yarn) INSTALL_YARN="${2:-}"; shift 2 ;;
      --opensearch) INSTALL_OPENSEARCH="${2:-}"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) err "Unknown option: $1"; usage; exit 1 ;;
    esac
  done

  if [[ "$STACK" != "apache" && "$STACK" != "nginx" ]]; then
    err "--stack must be 'apache' or 'nginx'"
    exit 1
  fi
}

update_upgrade() {
  log "Updating apt indexes"
  apt-get update -y
  log "Upgrading packages"
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
}

install_utils() {
  log "Installing common utilities"
  apt_install ca-certificates curl wget gnupg lsb-release unzip zip git nano vim build-essential \
             apt-transport-https software-properties-common
}

add_ondrej_php_ppa() {
  log "Adding ondrej/php PPA (multiple PHP versions)"
  add-apt-repository -y ppa:ondrej/php
}

# ==========================================
# Stack: Apache OR Nginx
# ==========================================
install_apache() {
  log "Installing Apache"
  apt_install apache2
  systemctl enable --now apache2
  a2enmod rewrite headers ssl >/dev/null || true
  systemctl restart apache2
}

install_nginx() {
  log "Installing Nginx"
  apt_install nginx
  systemctl enable --now nginx
}

# ==========================================
# MySQL / Redis
# ==========================================
install_mysql() {
  [[ "$INSTALL_MYSQL" != "yes" ]] && return 0
  log "Installing MySQL Server"
  apt_install mysql-server
  systemctl enable --now mysql
  warn "Optional hardening: run sudo mysql_secure_installation"
}

install_redis() {
  [[ "$INSTALL_REDIS" != "yes" ]] && return 0
  log "Installing Redis"
  apt_install redis-server
  systemctl enable --now redis-server
}

# ==========================================
# PHP (multi-version) + modules
# ==========================================
csv_to_array() {
  local csv="$1"
  csv="${csv// /}"         # remove spaces
  IFS=',' read -r -a PHP_VERSIONS <<< "$csv"
}

install_php_for_apache_version() {
  local v="$1"
  apt_try_install "php${v}" "libapache2-mod-php${v}" "php${v}-fpm" || return 1
  return 0
}

install_php_for_nginx_version() {
  local v="$1"
  # Nginx uses PHP-FPM (no libapache2-mod-php)
  apt_try_install "php${v}" "php${v}-fpm" || return 1
  return 0
}

install_php_versions_and_ext() {
  csv_to_array "$PHP_VERSIONS_CSV"

  for v in "${PHP_VERSIONS[@]}"; do
    log "Installing PHP $v base packages for stack=$STACK"

    if [[ "$STACK" == "apache" ]]; then
      if ! install_php_for_apache_version "$v"; then
        warn "Could not install PHP $v base packages (skipping this PHP version)."
        continue
      fi
    else
      if ! install_php_for_nginx_version "$v"; then
        warn "Could not install PHP $v base packages (skipping this PHP version)."
        continue
      fi
    fi

    log "Installing PHP $v extensions"
    pkgs=()
    for ext in "${PHP_EXTENSIONS[@]}"; do
      pkgs+=("php${v}-${ext}")
    done

    if ! apt_try_install "${pkgs[@]}"; then
      warn "Bulk install failed for PHP ${v} extensions; trying one-by-one..."
      for p in "${pkgs[@]}"; do
        apt_try_install "$p" || warn "Could not install: $p (skipping)"
      done
    fi

    systemctl enable --now "php${v}-fpm" || true
  done
}

set_default_php_cli() {
  log "Setting default PHP (CLI) to ${DEFAULT_PHP}"
  if ! has_cmd "php${DEFAULT_PHP}"; then
    err "php${DEFAULT_PHP} not found. Maybe that version didn't install. Check --php and Ubuntu compatibility."
    exit 1
  fi

  update-alternatives --set php "/usr/bin/php${DEFAULT_PHP}" || true
  update-alternatives --set phar "/usr/bin/phar${DEFAULT_PHP}" || true
  update-alternatives --set phar.phar "/usr/bin/phar.phar${DEFAULT_PHP}" || true
  update-alternatives --set phpize "/usr/bin/phpize${DEFAULT_PHP}" || true
  update-alternatives --set php-config "/usr/bin/php-config${DEFAULT_PHP}" || true

  php -v | head -n 1 || true
}

set_default_php_for_apache() {
  [[ "$STACK" != "apache" ]] && return 0
  log "Setting default PHP for Apache to ${DEFAULT_PHP}"

  csv_to_array "$PHP_VERSIONS_CSV"
  for v in "${PHP_VERSIONS[@]}"; do
    a2dismod "php${v}" >/dev/null 2>&1 || true
  done

  a2enmod "php${DEFAULT_PHP}" >/dev/null || true
  systemctl restart apache2
}

install_composer() {
  log "Installing Composer"
  if has_cmd composer; then
    log "Composer already installed: $(composer --version || true)"
    return 0
  fi

  EXPECTED_SIG="$(curl -fsSL https://composer.github.io/installer.sig)"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_SIG="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

  if [[ "$EXPECTED_SIG" != "$ACTUAL_SIG" ]]; then
    rm -f composer-setup.php
    err "Composer installer signature mismatch. Aborting."
    exit 1
  fi

  php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  rm -f composer-setup.php
  composer --version || true
}

# ==========================================
# Node.js + Yarn
# ==========================================
install_node() {
  [[ "$INSTALL_NODE" != "yes" ]] && return 0
  if has_cmd node; then
    log "Node already installed: $(node -v)"
    return 0
  fi

  log "Installing Node.js ${NODE_MAJOR}.x (NodeSource)"
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
  apt_install nodejs

  node -v || true
  npm -v || true
}

install_yarn() {
  [[ "$INSTALL_YARN" != "yes" ]] && return 0
  [[ "$INSTALL_NODE" != "yes" ]] && return 0

  if has_cmd yarn; then
    log "Yarn already installed: $(yarn -v)"
    return 0
  fi

  log "Installing Yarn (via corepack)"
  corepack enable || true
  corepack prepare yarn@stable --activate || true
  yarn -v || true
}

# ==========================================
# OpenSearch (optional)
# ==========================================
install_opensearch() {
  [[ "$INSTALL_OPENSEARCH" != "yes" ]] && return 0

  log "Installing OpenSearch (optional)"
  warn "OpenSearch can be heavy. 4GB+ RAM recommended. Default port: 9200"

  curl -fsSL https://artifacts.opensearch.org/publickeys/opensearch.pgp | gpg --dearmor -o /usr/share/keyrings/opensearch-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/opensearch-keyring.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" \
    > /etc/apt/sources.list.d/opensearch-2.x.list

  apt-get update -y
  apt_install opensearch

  systemctl enable --now opensearch || true

  warn "If you need to tune JVM heap: /etc/opensearch/jvm.options"
  warn "Config: /etc/opensearch/opensearch.yml"
}

print_summary() {
  log "Installed versions summary"
  echo "Stack:       $STACK"
  echo "Apache:      $(apache2 -v 2>/dev/null | head -n 1 || echo 'not installed')"
  echo "Nginx:       $(nginx -v 2>&1 || echo 'not installed')"
  echo "MySQL:       $(mysql --version 2>/dev/null || echo 'not installed')"
  echo "Redis:       $(redis-server --version 2>/dev/null || echo 'not installed')"
  echo "PHP (default): $(php -v 2>/dev/null | head -n 1 || echo 'not installed')"
  echo "Composer:    $(composer --version 2>/dev/null || echo 'not installed')"
  echo "Node:        $(node -v 2>/dev/null || echo 'not installed')"
  echo "npm:         $(npm -v 2>/dev/null || echo 'not installed')"
  echo "Yarn:        $(yarn -v 2>/dev/null || echo 'not installed')"
  echo "OpenSearch:  $(systemctl is-active opensearch 2>/dev/null || echo 'not installed')"

  warn "Projects path suggestion: /var/www/html/<project> (Apache) or /var/www/<project> (Nginx)"
}

main() {
  require_root
  parse_args "$@"

  update_upgrade
  install_utils

  add_ondrej_php_ppa
  apt-get update -y

  if [[ "$STACK" == "apache" ]]; then
    install_apache
  else
    install_nginx
  fi

  install_mysql
  install_redis

  install_php_versions_and_ext
  set_default_php_cli
  set_default_php_for_apache

  install_composer
  install_node
  install_yarn

  install_opensearch

  print_summary
  log "DONE ✅"
}

main "$@"
```

### Run command in your terminal.
> First run.
```
chmod +x bootstrap-webdev.sh
```
> Apache
```
sudo ./bootstrap-webdev.sh --stack apache --php "8.2,8.3" --default-php 8.3
```
> Nginx
```
sudo ./bootstrap-webdev.sh --stack nginx --php "8.2,8.3,8.4" --default-php 8.4 --opensearch yes
```
