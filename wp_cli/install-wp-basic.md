## Install `WordPress` USING CLI

```php
#!/bin/bash

set -e

# =========================================================
# Simple WordPress Installer
# - Installs WordPress only
# - Optional /etc/hosts + Apache/Nginx vhost setup
# - No themes
# - No plugins
# - No CPTs / ACF / templates / menus
# =========================================================

prompt_var () {
  local __var_name="$1"
  local __prompt="$2"
  local __default="$3"
  local __secret="${4:-0}"
  local __current_val="${!__var_name}"
  local __input=""

  if [ "${SKIP_PROMPTS:-0}" = "1" ] || [ -n "$__current_val" ]; then
    if [ -z "$__current_val" ] && [ -n "$__default" ]; then
      eval "$__var_name=\"\$__default\""
    fi
    return
  fi

  if [ "$__secret" = "1" ]; then
    read -r -s -p "$__prompt [$__default]: " __input
    echo
  else
    read -r -p "$__prompt [$__default]: " __input
  fi

  if [ -z "$__input" ]; then
    __input="$__default"
  fi

  eval "$__var_name=\"\$__input\""
}

is_yes() {
  case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
    y|yes|1|true) return 0 ;;
    *) return 1 ;;
  esac
}

echo "🔧 WordPress setup — press Enter to accept defaults."

# ---------- DB ----------
prompt_var DB_NAME        "Database name"       "wp_db_cli"
prompt_var DB_USER        "Database user"       "root"
prompt_var DB_PASS        "Database password"   "admin123" 1
prompt_var DB_HOST        "Database host"       "localhost"

# ---------- WordPress ----------
prompt_var WP_URL         "Site URL"            "http://wp_cli.local"
prompt_var WP_TITLE       "Site title"          "My WordPress Site"
prompt_var WP_ADMIN_USER  "WP admin username"   "admin"
prompt_var WP_ADMIN_PASS  "WP admin password"   "Admin123$" 1
prompt_var WP_ADMIN_EMAIL "WP admin email"      "admin@example.com"

# ---------- Path ----------
prompt_var WP_PATH        "WordPress path"      "/var/www/html/wordpress-cli"

# ---------- Vhost ----------
prompt_var CREATE_VHOST   "Create/update local hosts + web server vhost? yes/no" "yes"
prompt_var WEB_SERVER     "Web server type: auto/apache/nginx" "auto"

if is_yes "$CREATE_VHOST"; then
  if [ "$(echo "$WEB_SERVER" | tr '[:upper:]' '[:lower:]')" = "apache" ] || [ "$(echo "$WEB_SERVER" | tr '[:upper:]' '[:lower:]')" = "auto" ]; then
    prompt_var APACHE_VHOST_MODE "Apache vhost mode: site/default_conf" "site"
  fi
fi

echo
echo "📋 Config summary:"
echo "  DB_NAME=$DB_NAME"
echo "  DB_USER=$DB_USER"
echo "  DB_HOST=$DB_HOST"
echo "  WP_URL=$WP_URL"
echo "  WP_TITLE=$WP_TITLE"
echo "  WP_ADMIN_USER=$WP_ADMIN_USER"
echo "  WP_ADMIN_EMAIL=$WP_ADMIN_EMAIL"
echo "  WP_PATH=$WP_PATH"
echo "  CREATE_VHOST=$CREATE_VHOST"
echo "  WEB_SERVER=$WEB_SERVER"
if [ -n "${APACHE_VHOST_MODE:-}" ]; then
  echo "  APACHE_VHOST_MODE=$APACHE_VHOST_MODE"
fi
echo

# ---------- SUDO helper ----------
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
  export WP_CLI_ALLOW_ROOT=1
else
  SUDO="sudo"
fi

# ---------- Package installer ----------
install_pkgs() {
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -y
    $SUDO apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    $SUDO yum install -y "$@"
  elif command -v apk >/dev/null 2>&1; then
    $SUDO apk add --no-cache "$@"
  else
    echo "❌ Could not detect package manager."
    exit 1
  fi
}

# ---------- Ensure WP-CLI ----------
ensure_wp_cli() {
  if command -v wp >/dev/null 2>&1; then
    echo "✅ WP-CLI found: $(command -v wp)"
    return
  fi

  echo "⬇️ Installing WP-CLI..."

  command -v php >/dev/null 2>&1 || install_pkgs php-cli || install_pkgs php
  command -v curl >/dev/null 2>&1 || install_pkgs curl

  tmp="/tmp/wp-cli.phar"

  curl -sSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o "$tmp" || {
    echo "❌ Failed to download WP-CLI."
    exit 1
  }

  chmod +x "$tmp"

  if $SUDO mv "$tmp" /usr/local/bin/wp 2>/dev/null; then
    echo "✅ WP-CLI installed at /usr/local/bin/wp"
  else
    mkdir -p "$HOME/.local/bin"
    mv "$tmp" "$HOME/.local/bin/wp"
    export PATH="$HOME/.local/bin:$PATH"
    echo "✅ WP-CLI installed at $HOME/.local/bin/wp"
  fi
}

# ---------- Detect web server ----------
detect_web_server() {
  local selected
  selected="$(echo "${WEB_SERVER:-auto}" | tr '[:upper:]' '[:lower:]')"

  if [ "$selected" = "apache" ] || [ "$selected" = "nginx" ]; then
    echo "$selected"
    return
  fi

  if command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1 || ps -A | grep -Eq 'apache2|httpd'; then
    echo "apache"
    return
  fi

  if command -v nginx >/dev/null 2>&1 || ps -A | grep -q nginx; then
    echo "nginx"
    return
  fi

  echo "none"
}

# ---------- Extract host from WP_URL ----------
get_wp_host() {
  echo "$WP_URL" | sed -E 's~^[a-zA-Z]+://~~; s~/.*$~~; s~:.*$~~'
}

# ---------- Update /etc/hosts ----------
update_hosts_file() {
  local host="$1"

  if [ -z "$host" ]; then
    echo "❌ Could not detect host from WP_URL=$WP_URL"
    exit 1
  fi

  case "$host" in
    localhost|127.0.0.1)
      echo "ℹ️ Host is $host, no /etc/hosts update needed."
      return
      ;;
  esac

  if echo "$host" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ℹ️ Host is an IP address, no /etc/hosts update needed."
    return
  fi

  HOSTS_FILE="/etc/hosts"

  if grep -Eq "^[[:space:]]*127\.0\.0\.1[[:space:]].*\b${host}\b" "$HOSTS_FILE"; then
    echo "ℹ️ /etc/hosts already has: 127.0.0.1 $host"
    return
  fi

  echo "🧾 Updating /etc/hosts → 127.0.0.1 $host"

  if [ -n "$($SUDO tail -c1 "$HOSTS_FILE" 2>/dev/null)" ]; then
    $SUDO sh -c "printf '\n' >> '$HOSTS_FILE'"
  fi

  TMP_H="$(mktemp)"

  $SUDO awk -v host="$host" '
    /^[[:space:]]*#/ { print; next }
    {
      drop=0
      for (i=1;i<=NF;i++) {
        if ($i==host) {
          drop=1
          break
        }
      }
      if (!drop) print
    }
  ' "$HOSTS_FILE" > "$TMP_H"

  $SUDO cp "$TMP_H" "$HOSTS_FILE"
  rm -f "$TMP_H"

  $SUDO sh -c "printf '127.0.0.1\t%s\n' '$host' >> '$HOSTS_FILE'"

  echo "✅ /etc/hosts updated."
}

# ---------- Apache vhost ----------
configure_apache_vhost() {
  local host="$1"
  local safe_host
  local mode

  safe_host="$(echo "$host" | tr -cd '[:alnum:]._-')"
  mode="$(echo "${APACHE_VHOST_MODE:-site}" | tr '[:upper:]' '[:lower:]')"

  echo "🌐 Configuring Apache for $host → $WP_PATH"

  $SUDO a2enmod rewrite >/dev/null 2>&1 || true

  if [ "$mode" = "default_conf" ]; then
    VHOST_FILE="/etc/apache2/sites-available/000-default.conf"

    if [ ! -f "$VHOST_FILE" ]; then
      echo "❌ $VHOST_FILE not found."
      exit 1
    fi

    TS="$(date +%Y%m%d-%H%M%S)"
    $SUDO cp "$VHOST_FILE" "${VHOST_FILE}.bak.${TS}"
    echo "🗄️ Backup created: ${VHOST_FILE}.bak.${TS}"

    BLOCK_BEGIN="# BEGIN wp-cli ${host}"
    BLOCK_END="# END wp-cli ${host}"

    TMP_BLOCK="$(mktemp)"

    cat > "$TMP_BLOCK" <<EOF
${BLOCK_BEGIN}
<VirtualHost *:80>
    ServerName ${host}
    DocumentRoot ${WP_PATH}

    ErrorLog \${APACHE_LOG_DIR}/${safe_host}.error.log
    CustomLog \${APACHE_LOG_DIR}/${safe_host}.access.log combined

    <Directory ${WP_PATH}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
${BLOCK_END}
EOF

    TMP_FILE="$(mktemp)"

    if grep -qF "$BLOCK_BEGIN" "$VHOST_FILE"; then
      echo "✏️ Updating existing block inside 000-default.conf"

      awk -v start="$BLOCK_BEGIN" -v end="$BLOCK_END" '
        BEGIN { inblk=0 }
        $0==start { inblk=1; next }
        $0==end { inblk=0; next }
        !inblk { print }
      ' "$VHOST_FILE" > "$TMP_FILE"

      $SUDO cp "$TMP_FILE" "$VHOST_FILE"
    fi

    $SUDO sh -c "printf '\n\n' >> '$VHOST_FILE'"
    $SUDO sh -c "cat '$TMP_BLOCK' >> '$VHOST_FILE'"

    rm -f "$TMP_BLOCK" "$TMP_FILE"

  else
    VHOST_FILE="/etc/apache2/sites-available/${safe_host}.conf"

    cat > "/tmp/${safe_host}.conf" <<EOF
<VirtualHost *:80>
    ServerName ${host}
    DocumentRoot ${WP_PATH}

    ErrorLog \${APACHE_LOG_DIR}/${safe_host}.error.log
    CustomLog \${APACHE_LOG_DIR}/${safe_host}.access.log combined

    <Directory ${WP_PATH}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

    $SUDO mv "/tmp/${safe_host}.conf" "$VHOST_FILE"
    $SUDO a2ensite "${safe_host}.conf" >/dev/null 2>&1 || true

    echo "✅ Apache site file created: $VHOST_FILE"
  fi

  echo "🧪 Testing Apache config..."
  if $SUDO apache2ctl configtest; then
    $SUDO systemctl reload apache2 2>/dev/null || $SUDO service apache2 reload
    echo "✅ Apache reloaded."
  else
    echo "❌ Apache config test failed."
    exit 1
  fi
}

# ---------- Nginx vhost ----------
configure_nginx_vhost() {
  local host="$1"
  local safe_host
  local php_sock

  safe_host="$(echo "$host" | tr -cd '[:alnum:]._-')"

  echo "🌐 Configuring Nginx for $host → $WP_PATH"

  php_sock="${PHP_FPM_SOCK:-}"

  if [ -z "$php_sock" ]; then
    php_sock="$(find /run/php -maxdepth 1 -type s -name 'php*-fpm.sock' 2>/dev/null | sort -V | tail -n1)"
  fi

  if [ -z "$php_sock" ]; then
    echo "❌ PHP-FPM socket not found."
    echo "Set it manually like:"
    echo "PHP_FPM_SOCK=/run/php/php8.2-fpm.sock ./install-wp.sh"
    exit 1
  fi

  VHOST_FILE="/etc/nginx/sites-available/${safe_host}"

  cat > "/tmp/${safe_host}.nginx" <<EOF
server {
    listen 80;
    server_name ${host};

    root ${WP_PATH};
    index index.php index.html index.htm;

    access_log /var/log/nginx/${safe_host}.access.log;
    error_log /var/log/nginx/${safe_host}.error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${php_sock};
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

  $SUDO mv "/tmp/${safe_host}.nginx" "$VHOST_FILE"
  $SUDO ln -sf "$VHOST_FILE" "/etc/nginx/sites-enabled/${safe_host}"

  echo "🧪 Testing Nginx config..."
  if $SUDO nginx -t; then
    $SUDO systemctl reload nginx 2>/dev/null || $SUDO service nginx reload
    echo "✅ Nginx reloaded."
  else
    echo "❌ Nginx config test failed."
    exit 1
  fi
}

# ---------- Start ----------
ensure_wp_cli

echo "📁 Creating WordPress directory..."
$SUDO mkdir -p "$WP_PATH"

if [ "$(id -u)" -ne 0 ]; then
  $SUDO chown -R "$USER:$USER" "$WP_PATH"
fi

cd "$WP_PATH" || exit 1

# ---------- Database ----------
echo "🛢️ Creating database if not exists..."
mysql -u"$DB_USER" -p"$DB_PASS" -e "
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
"

# ---------- Download WordPress ----------
echo "⬇️ Downloading WordPress core..."
wp core download --path="$WP_PATH" --allow-root

# ---------- Create wp-config.php ----------
echo "⚙️ Creating wp-config.php..."
wp config create \
  --dbname="$DB_NAME" \
  --dbuser="$DB_USER" \
  --dbpass="$DB_PASS" \
  --dbhost="$DB_HOST" \
  --path="$WP_PATH" \
  --skip-check \
  --allow-root

# ---------- Install WordPress ----------
echo "📝 Installing WordPress..."
wp core install \
  --url="$WP_URL" \
  --title="$WP_TITLE" \
  --admin_user="$WP_ADMIN_USER" \
  --admin_password="$WP_ADMIN_PASS" \
  --admin_email="$WP_ADMIN_EMAIL" \
  --path="$WP_PATH" \
  --allow-root

# ---------- Permalinks ----------
echo "🔗 Setting permalink structure..."
wp rewrite structure '/%postname%/' --path="$WP_PATH" --allow-root
wp rewrite flush --hard --path="$WP_PATH" --allow-root || true

# ---------- Optional vhost ----------
if is_yes "$CREATE_VHOST"; then
  WP_HOST="$(get_wp_host)"

  echo "🔎 Derived host from WP_URL: $WP_HOST"

  update_hosts_file "$WP_HOST"

  DETECTED_SERVER="$(detect_web_server)"

  if [ "$DETECTED_SERVER" = "apache" ]; then
    configure_apache_vhost "$WP_HOST"
  elif [ "$DETECTED_SERVER" = "nginx" ]; then
    configure_nginx_vhost "$WP_HOST"
  else
    echo "❌ Could not detect Apache or Nginx."
    echo "Run again with WEB_SERVER=apache or WEB_SERVER=nginx."
    exit 1
  fi
else
  echo "⏭️ Skipping /etc/hosts and web server vhost configuration."
fi

# ---------- Cache flush BEFORE locking permissions ----------
wp cache flush --path="$WP_PATH" --allow-root || true

# ---------- Permissions ----------
if [ "${INSECURE_PERMS:-0}" = "1" ]; then
  echo "⚠️ Setting 777 permissions — local dev only."
  $SUDO chmod -R 777 "$WP_PATH"
else
  if [ -z "${WEB_USER:-}" ]; then
    WEB_USER="$(ps -o user= -C apache2 2>/dev/null | awk '$1!="root"{print $1; exit}')"
  fi

  if [ -z "$WEB_USER" ]; then
    WEB_USER="$(ps -o user= -C httpd 2>/dev/null | awk '$1!="root"{print $1; exit}')"
  fi

  if [ -z "$WEB_USER" ]; then
    WEB_USER="$(ps -o user= -C nginx 2>/dev/null | awk '$1!="root"{print $1; exit}')"
  fi

  WEB_USER="${WEB_USER:-www-data}"

  if [ "$WEB_USER" = "root" ]; then
    WEB_USER="www-data"
  fi

  echo "🔐 Setting recommended permissions. Owner: $WEB_USER"

  $SUDO chown -R "$WEB_USER:$WEB_USER" "$WP_PATH"

  $SUDO find "$WP_PATH" -type d -exec chmod 755 {} \;
  $SUDO find "$WP_PATH" -type f -exec chmod 644 {} \;

  $SUDO chmod -R 775 "$WP_PATH/wp-content"
  $SUDO find "$WP_PATH/wp-content" -type f -exec chmod 664 {} \;

  $SUDO chmod 640 "$WP_PATH/wp-config.php" 2>/dev/null || true

  echo "✅ Permissions done."
fi

echo
echo "✅ WordPress installed successfully!"
echo "🌐 Site URL: $WP_URL"
echo "👤 Admin user: $WP_ADMIN_USER"
```

## For your case
### Use:
```php
chmod +x install-wp.sh
./install-wp.sh
```
### When it asks:
```php
Create/update local hosts + web server vhost? yes/no [yes]:
```
## Press Enter.
### Then:
```php
Web server type: auto/apache/nginx [auto]:
```
### Press Enter, or type:
```php
apache
```
### Then:
```php
Apache vhost mode: site/default_conf [site]:
```
### Use:
```php
site
```
### That creates a clean file like:
```php
/etc/apache2/sites-available/wp_cli_pol.local.conf
```
### If you specifically want it inside:
```php
/etc/apache2/sites-available/000-default.conf
```
### then choose:
```php
default_conf
```
>#### For normal local development, I recommend site, not default_conf. It is cleaner and easier to remove later.