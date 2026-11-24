#!/bin/bash

# =========================================================
# CONFIG (interactive prompts with defaults)
# - Set SKIP_PROMPTS=1 to use env vars / defaults silently (CI-friendly)
# - Any value already present in the environment is respected
# =========================================================

prompt_var () {
  # usage: prompt_var VAR "Prompt text" "default" [secret]
  local __var_name="$1"
  local __prompt="$2"
  local __default="$3"
  local __secret="${4:-0}"
  local __current_val="${!__var_name}"
  local __input=""

  # If SKIP_PROMPTS=1 or value already provided via env, keep it
  if [ "${SKIP_PROMPTS:-0}" = "1" ] || [ -n "$__current_val" ]; then
    # If empty AND we have a default, set default
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

echo "🔧 Interactive setup — press Enter to accept defaults."

# --- Capture original working dir + script dir BEFORE any cd ---
ORIGINAL_CWD="$(pwd)"

# Works if run with bash or sh; handles symlinks too
__src="${BASH_SOURCE[0]:-$0}"
while [ -h "$__src" ]; do
  __dir="$(cd -P "$(dirname "$__src")" && pwd)"
  __src="$(readlink "$__src")"
  case "$__src" in
    /*) ;; # absolute
    *) __src="$__dir/$__src" ;;
  esac
done
ORIGINAL_SCRIPT_DIR="$(cd -P "$(dirname "$__src")" && pwd)"
export ORIGINAL_SCRIPT_DIR ORIGINAL_CWD


# ---------- DB ----------
prompt_var DB_NAME              "Database name"                    "wp_db_cli"
prompt_var DB_USER              "Database user"                    "root"
prompt_var DB_PASS              "Database password"                "admin123" 1
prompt_var DB_HOST              "Database host"                    "localhost"

# prompt_var MYSQL_ROOT_USER      "MySQL root user"                  "root"
# prompt_var MYSQL_ROOT_PASS      "MySQL root password"              "admin123" 1

# ---------- WordPress ----------
prompt_var WP_URL               "Site URL"                         "http://wp_cli.local"
prompt_var WP_TITLE             "Site title"                       "My WordPress Site"
prompt_var WP_ADMIN_USER        "WP admin username"                "admin"
prompt_var WP_ADMIN_PASS        "WP admin password"                "Admin123$" 1
prompt_var WP_ADMIN_EMAIL       "WP admin email"                   "admin@example.com"

# ---------- Paths ----------
prompt_var WP_PATH              "WordPress install path"           "/var/www/html/wordpress-cli"
# prompt_var STATIC_SITE_PATH     "Static site path (leave blank to skip)"   ""
prompt_var MENU_NAME            "Primary menu name"                "Main Menu"
prompt_var CREATE_VIRTUAL_HOST  "Configure /etc/hosts and Apache (1=yes, 0=no)" "0"
case "$CREATE_VIRTUAL_HOST" in
  0|1) ;;
  *) echo "❌ CREATE_VIRTUAL_HOST must be 0 or 1." >&2; exit 1 ;;
esac

# Derived (don’t prompt)
# STATIC_IMAGES_PATH="$STATIC_SITE_PATH/images"
# STATIC_CSS_PATH="$STATIC_SITE_PATH/css"

echo
echo "📋 Config summary:"
echo "  DB_NAME=$DB_NAME"
echo "  DB_USER=$DB_USER"
echo "  DB_HOST=$DB_HOST"
# echo "  MYSQL_ROOT_USER=$MYSQL_ROOT_USER"
echo "  WP_URL=$WP_URL"
echo "  WP_TITLE=$WP_TITLE"
echo "  WP_ADMIN_USER=$WP_ADMIN_USER"
echo "  WP_ADMIN_EMAIL=$WP_ADMIN_EMAIL"
echo "  WP_PATH=$WP_PATH"
echo "  CREATE_VIRTUAL_HOST=$CREATE_VIRTUAL_HOST"
# echo "  STATIC_SITE_PATH=${STATIC_SITE_PATH:-<empty>}"
# echo "  STATIC_IMAGES_PATH=$STATIC_IMAGES_PATH"
# echo "  STATIC_CSS_PATH=$STATIC_CSS_PATH"
echo "  MENU_NAME=$MENU_NAME"
echo

# ========== INSTALL SCRIPT ==========

echo "🚀 Starting WordPress Installation..."

# ---- Ensure WP-CLI is available -------------------------------------------
# SUDO helper
if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

# Minimal pkg installer (Debian/Ubuntu preferred; falls back to yum/dnf/apk)
install_pkgs() {
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -y && $SUDO apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    $SUDO yum install -y "$@"
  elif command -v apk >/dev/null 2>&1; then
    $SUDO apk add --no-cache "$@"
  else
    echo "⚠️ Could not detect package manager to install: $*"
    return 1
  fi
}

ensure_wp_cli() {
  if command -v wp >/dev/null 2>&1; then
    echo "✅ WP-CLI found: $(command -v wp) ($(wp --version 2>/dev/null))"
  else
    echo "⬇️ Installing WP-CLI ..."
    # Ensure deps
    command -v php >/dev/null 2>&1 || install_pkgs php-cli || install_pkgs php
    command -v curl >/dev/null 2>&1 || install_pkgs curl

    tmp="/tmp/wp-cli.phar"
    curl -sSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o "$tmp" || {
      echo "❌ Failed to download WP-CLI phar"; exit 1;
    }
    chmod +x "$tmp"

    # Prefer system-wide location; fall back to ~/.local/bin
    if $SUDO mv "$tmp" /usr/local/bin/wp 2>/dev/null; then
      echo "✅ Installed WP-CLI to /usr/local/bin/wp"
    else
      mkdir -p "$HOME/.local/bin"
      mv "$tmp" "$HOME/.local/bin/wp"
      export PATH="$HOME/.local/bin:$PATH"
      echo "✅ Installed WP-CLI to $HOME/.local/bin/wp (PATH updated for this run)"
    fi
  fi

  # Allow running as root (common in provisioning)
  if [ "$(id -u)" -eq 0 ]; then export WP_CLI_ALLOW_ROOT=1; fi
}

ensure_wp_cli

# Create installation directory
mkdir -p "$WP_PATH"
cd "$WP_PATH" || exit 1

# ---------- Host & Apache VirtualHost ----------
configure_local_site() (
  WP_HOST="$(printf '%s\n' "$WP_URL" | sed -E 's~^[a-zA-Z]+://~~; s~[/?#].*$~~; s~:.*$~~')"
  if ! [[ "$WP_HOST" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$ ]]; then
    echo "❌ Use a hostname in WP_URL to configure the local site." >&2
    exit 1
  fi

  HOSTS_FILE="/etc/hosts"
  VHOST_FILE="/etc/apache2/sites-available/000-default.conf"
  ENABLED_VHOST_FILE="/etc/apache2/sites-enabled/000-default.conf"
  if ! command -v apache2ctl >/dev/null || [ ! -f "$VHOST_FILE" ]; then
    echo "❌ Local site setup requires Apache and $VHOST_FILE." >&2
    exit 1
  fi
  if ! [ "$VHOST_FILE" -ef "$ENABLED_VHOST_FILE" ]; then
    echo "❌ Apache's 000-default.conf is disabled. Enable it with sudo a2ensite 000-default.conf and try again." >&2
    exit 1
  fi

  WORK_DIR="$(mktemp -d)" || exit 1
  trap 'rm -rf -- "$WORK_DIR"' EXIT

  # Match hostname fields exactly and preserve aliases and comments.
  if ! awk -v host="$WP_HOST" '
    {
      original = $0
      comment_at = index($0, "#")
      sub(/#.*/, "")
      entry = $1
      removed = 0
      for (i = 2; i <= NF; i++) {
        if (tolower($i) != tolower(host) || $1 == "127.0.0.1") {
          entry = entry " " $i
          if (tolower($i) == tolower(host)) mapped = 1
        } else {
          removed = 1
        }
      }
      if (!removed) print original
      else if (entry != $1) print entry (comment_at ? " " substr(original, comment_at) : "")
      else if (comment_at) print substr(original, comment_at)
    }
    END { if (!mapped) print "127.0.0.1\t" host }
  ' "$HOSTS_FILE" > "$WORK_DIR/hosts"; then
    echo "❌ Could not prepare $HOSTS_FILE." >&2
    exit 1
  fi

  LOG_STEM="$(basename "$WP_PATH" | tr -cd '[:alnum:]_-')"
  LOG_STEM="${LOG_STEM:-wordpress}"
  APACHE_PATH="${WP_PATH//\\/\\\\}"
  APACHE_PATH="${APACHE_PATH//\"/\\\"}"
  BLOCK_BEGIN="# BEGIN wp-cli ${WP_HOST}"
  BLOCK_END="# END wp-cli ${WP_HOST}"

  cat > "$WORK_DIR/vhost" <<EOF || exit 1
${BLOCK_BEGIN}
<VirtualHost *:80>
    ServerName ${WP_HOST}
    ServerAlias ${WP_HOST}
    DocumentRoot "${APACHE_PATH}"

    ErrorLog \${APACHE_LOG_DIR}/${LOG_STEM}.error.log
    CustomLog \${APACHE_LOG_DIR}/${LOG_STEM}.access.log combined

    <Directory "${APACHE_PATH}">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
${BLOCK_END}
EOF

  # Replace the managed block in place. Reject an unterminated block before writing.
  if ! awk -v start="$BLOCK_BEGIN" -v end="$BLOCK_END" -v block="$WORK_DIR/vhost" '
    function print_block(   line, status) {
      while ((status = (getline line < block)) > 0) print line
      if (status < 0) exit 1
      close(block)
    }
    $0 == start {
      if (!found) print_block()
      found = in_block = 1
      next
    }
    $0 == end && in_block { in_block = 0; next }
    !in_block { print }
    END {
      if (in_block) exit 1
      if (!found) {
        if (NR) print ""
        print_block()
      }
    }
  ' "$VHOST_FILE" > "$WORK_DIR/000-default.conf"; then
    echo "❌ Could not prepare $VHOST_FILE. Check that its managed block has an end marker." >&2
    exit 1
  fi

  if ! $SUDO a2enmod rewrite >/dev/null; then
    echo "❌ Could not enable Apache's rewrite module." >&2
    exit 1
  fi
  BACKUP_FILE="$($SUDO mktemp "${VHOST_FILE}.bak.XXXXXXXX")" || exit 1
  if ! $SUDO cp -- "$VHOST_FILE" "$BACKUP_FILE"; then
    echo "❌ Could not back up $VHOST_FILE." >&2
    exit 1
  fi

  if ! $SUDO cp -- "$WORK_DIR/000-default.conf" "$VHOST_FILE" ||
     ! $SUDO apache2ctl configtest ||
     ! { $SUDO systemctl reload apache2 || $SUDO service apache2 reload; }; then
    echo "❌ Apache configuration or reload failed for $WP_HOST." >&2
    if $SUDO cp -- "$BACKUP_FILE" "$VHOST_FILE"; then
      echo "Restored $VHOST_FILE from $BACKUP_FILE." >&2
    else
      echo "❌ Could not restore $VHOST_FILE. Backup is at $BACKUP_FILE." >&2
    fi
    exit 1
  fi

  if ! cmp -s -- "$WORK_DIR/hosts" "$HOSTS_FILE" &&
     ! $SUDO cp -- "$WORK_DIR/hosts" "$HOSTS_FILE"; then
    echo "❌ Apache was configured, but writing $HOSTS_FILE failed for $WP_HOST." >&2
    exit 1
  fi

  echo "✅ /etc/hosts and Apache configured for $WP_HOST → $WP_PATH"
)

if [ "$CREATE_VIRTUAL_HOST" = "1" ]; then
  echo "🌐 Preparing local host + Apache vhost..."
  configure_local_site || exit 1
else
  echo "⏭️ Skipping /etc/hosts and Apache setup. Set CREATE_VIRTUAL_HOST=1 to enable it."
fi

# ---------- Database Setup ----------
echo "🛢️ Creating database (if not exists)..."
mysql -u"$DB_USER" -p"$DB_PASS" -e \
  "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# ---------- Download WordPress ----------
echo "⬇️ Downloading WordPress..."
wp core download --path="$WP_PATH" --allow-root

# ---------- Config ----------
echo "⚙️ Creating wp-config.php..."
wp config create \
  --dbname="$DB_NAME" \
  --dbuser="$DB_USER" \
  --dbpass="$DB_PASS" \
  --dbhost="$DB_HOST" \
  --path="$WP_PATH" \
  --skip-check --allow-root

# ---- Raise PHP execution time in wp-config.php (idempotent) ----
WPCFG="$WP_PATH/wp-config.php"

if [ -f "$WPCFG" ]; then
  # Skip if we already added it
  if ! grep -q "max_execution_time.*3600" "$WPCFG"; then
    echo "⏱️ Adding max_execution_time=3600 to wp-config.php …"
    SNIPPET="$(mktemp)"
    cat > "$SNIPPET" <<'PHP'
/* Bump PHP execution time for heavy tasks */
@ini_set('max_execution_time', '3600');  // 3600 seconds = 1 hour
@set_time_limit(3600);
PHP

    TMP="$(mktemp)"
    awk -v f="$SNIPPET" '
      BEGIN{done=0}
      { print }
      !done && /That'"'"'s all, stop editing! Happy publishing\./ {
        system("cat " f); 
        done=1
      }
    ' "$WPCFG" > "$TMP" && mv "$TMP" "$WPCFG"
    rm -f "$SNIPPET"
    echo "✅ Inserted execution time snippet after the stop-editing marker."
  else
    echo "ℹ️ max_execution_time snippet already present; skipping."
  fi
else
  echo "❌ wp-config.php not found at $WPCFG." >&2
  exit 1
fi

# ---------- Install WP ----------
echo "📝 Installing WordPress..."
wp core install \
  --url="$WP_URL" \
  --title="$WP_TITLE" \
  --admin_user="$WP_ADMIN_USER" \
  --admin_password="$WP_ADMIN_PASS" \
  --admin_email="$WP_ADMIN_EMAIL" \
  --path="$WP_PATH" --allow-root || {
    echo "❌ WP-CLI could not install WordPress at $WP_URL." >&2
    exit 1
  }

# ---------- Install local plugins (folder or zip) ----------
echo "📦 Installing local plugins from script/launch directory (dir or zip)..."

# 1) List of local plugins. Put either a folder name or a zip filename.
LOCAL_PLUGINS=(
  # "/plugins/devteampro-dotnet-wp"
  # "/plugins/ninetyseven-scheduler"
  # "some-plugin.zip"      # zip
  # "/absolute/path/custom-plugin" or "/abs/path/custom-plugin.zip"
)

# If you leave the array empty, we can auto-discover; otherwise we use your list.
if [ "${#LOCAL_PLUGINS[@]}" -eq 0 ]; then
  echo "🔎 Auto-discovering local plugins (*.zip and directories) ..."
  mapfile -t LOCAL_PLUGINS < <(
    { [ -n "$ORIGINAL_SCRIPT_DIR" ] && find "$ORIGINAL_SCRIPT_DIR" -maxdepth 1 -mindepth 1 \( -type d -o -type f -name '*.zip' \) -printf "%p\n"; } 2>/dev/null
    { [ -n "$ORIGINAL_CWD" ]        && find "$ORIGINAL_CWD"        -maxdepth 1 -mindepth 1 \( -type d -o -type f -name '*.zip' \) -printf "%p\n"; } 2>/dev/null
  )
  # De-dupe
  if [ "${#LOCAL_PLUGINS[@]}" -gt 0 ]; then
    LOCAL_PLUGINS=($(printf "%s\n" "${LOCAL_PLUGINS[@]}" | awk '!seen[$0]++'))
  fi
fi

# Helper: resolve an item to a full path (dir or zip)
resolve_item_path() {
  local item="$1"
  # absolute or relative existing path?
  if [ -e "$item" ]; then echo "$item"; return 0; fi
  # try script dir / launch dir
  for base in "$ORIGINAL_SCRIPT_DIR" "$ORIGINAL_CWD"; do
    if [ -e "$base/$item" ]; then echo "$base/$item"; return 0; fi
  done
  return 1
}

PLUGINS_DIR="$WP_PATH/wp-content/plugins"
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"
$SUDO mkdir -p "$PLUGINS_DIR"

# multisite flag
IS_MS="$(wp eval 'echo is_multisite()?1:0;' --path="$WP_PATH" --allow-root 2>/dev/null || echo 0)"
ACTIVATE_FLAG=$([ "$IS_MS" = "1" ] && echo "--activate-network" || echo "--activate")

for item in "${LOCAL_PLUGINS[@]}"; do
  ITEM_PATH="$(resolve_item_path "$item")" || { echo "❌ Not found: $item"; continue; }

  if [ -d "$ITEM_PATH" ]; then
    # ===== Directory plugin install =====
    SLUG="$(basename "$ITEM_PATH")"
    DEST_DIR="$PLUGINS_DIR/$SLUG"
    echo "📁 Installing directory plugin: $SLUG"
    if command -v rsync >/dev/null 2>&1; then
      $SUDO rsync -a --delete "$ITEM_PATH"/ "$DEST_DIR"/
    else
      # Fallback without rsync (less ideal if removing files)
      $SUDO rm -rf "$DEST_DIR"
      $SUDO mkdir -p "$DEST_DIR"
      $SUDO cp -a "$ITEM_PATH"/. "$DEST_DIR"/
    fi
    # basic perms (you also run a full perms pass later)
    $SUDO find "$DEST_DIR" -type d -exec chmod 755 {} \;
    $SUDO find "$DEST_DIR" -type f -exec chmod 644 {} \;

    # Try to activate
    if wp plugin activate "$SLUG" --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
      echo "✅ Activated (dir): $SLUG"
    else
      # WP-CLI sometimes warns yet activates; double-check:
      if wp plugin is-active "$SLUG" --path="$WP_PATH" --allow-root; then
        echo "✅ Activated (dir, with warnings): $SLUG"
      else
        echo "⚠️ Could not activate (dir): $SLUG"
      fi
    fi

  elif [ -f "$ITEM_PATH" ] && [[ "$ITEM_PATH" == *.zip ]]; then
    # ===== ZIP plugin install =====
    ZIP_BASENAME="$(basename "$ITEM_PATH")"
    DEST_ZIP_PATH="$PLUGINS_DIR/$ZIP_BASENAME"
    echo "🧩 Installing zip plugin: $ZIP_BASENAME"
    $SUDO cp -f "$ITEM_PATH" "$DEST_ZIP_PATH"
    $SUDO chmod 644 "$DEST_ZIP_PATH"

    if wp plugin install "$DEST_ZIP_PATH" $ACTIVATE_FLAG --force --path="$WP_PATH" --allow-root; then
      echo "✅ Installed & activated (zip): $ZIP_BASENAME"
    else
      echo "⚠️ Install reported an issue for zip: $ZIP_BASENAME"
    fi
  else
    echo "⚠️ Unsupported item (not dir or .zip): $ITEM_PATH"
  fi
done

# ---------- Theme Setup ----------
echo "🎨 Installing Hello Elementor Theme..."
wp theme install hello-elementor --activate --allow-root

# Remove all inactive themes
echo "🧹 Removing inactive themes..."
wp theme delete $(wp theme list --status=inactive --field=name --allow-root) --allow-root || true

# ---------- Post-install Tweaks ----------
echo "🔧 Setting defaults..."
wp option update blogdescription "Just another WordPress site" --allow-root
wp plugin update --all --allow-root

# ---------- Install Essential Plugins ----------
ESSENTIAL_PLUGINS=(
  "advanced-custom-fields"
  # "elementor"
  # "elementor-pro"
)
echo "🔌 Installing essential plugins: ${ESSENTIAL_PLUGINS[*]} ..."
for plugin in "${ESSENTIAL_PLUGINS[@]}"; do
  if ! wp plugin is-installed "$plugin" --allow-root; then
    wp plugin install "$plugin" --activate --allow-root
  else
    wp plugin activate "$plugin" --allow-root
  fi
done

# ---------- Cleanup Plugins ----------
echo "🧹 Removing inactive plugins..."
INACTIVE_PLUGINS=$(wp plugin list --status=inactive --field=name --allow-root)
if [ -n "$INACTIVE_PLUGINS" ]; then
  wp plugin delete $INACTIVE_PLUGINS --allow-root
else
  echo "✅ No inactive plugins found."
fi

# ---------- Permalink Setup ----------
echo "🔗 Setting permalink structure..."
if command -v apache2 >/dev/null 2>&1 || ps -A | grep -q apache2; then
  echo "⚡ Apache detected → setting permalinks and regenerating .htaccess"
  wp rewrite structure '/%postname%/' --hard --allow-root

  if [ ! -f "$WP_PATH/.htaccess" ]; then
    cat > "$WP_PATH/.htaccess" <<'EOL'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOL
    echo "✅ Default .htaccess created"
  fi
elif command -v nginx >/dev/null 2>&1 || ps -A | grep -q nginx; then
  echo "🌐 Nginx detected → only setting permalink option in DB"
  wp rewrite structure '/%postname%/' --allow-root
  echo "⚠️ Remember to configure Nginx manually for pretty permalinks."
else
  echo "❓ Could not detect Apache or Nginx → skipping rewrite rules."
fi

# ---------- Create Primary Menu (optional but harmless) ----------
if ! wp menu list --allow-root | grep -q "$MENU_NAME"; then
  echo "🍽️ Creating menu: $MENU_NAME"
  wp menu create "$MENU_NAME" --allow-root
  # Best effort to assign first available location (jq recommended)
  if command -v jq >/dev/null 2>&1; then
    MENU_LOCATION=$(wp menu location list --allow-root --format=json | jq -r '.[0].location')
    if [ -n "$MENU_LOCATION" ] && [ "$MENU_LOCATION" != "null" ]; then
      wp menu location assign "$MENU_NAME" "$MENU_LOCATION" --allow-root
      echo "✅ Menu assigned to location: $MENU_LOCATION"
    else
      echo "⚠️ No menu location found. Menu created but not assigned."
    fi
  else
    echo "ℹ️ jq not found — skipping auto-assign of menu location."
  fi
fi

# ---------- Child Theme (always create/activate) ----------
echo "🎨 Ensuring Hello Elementor Child Theme exists..."
CHILD_THEME="hello-elementor-child"
CHILD_PATH="$WP_PATH/wp-content/themes/$CHILD_THEME"
STYLE_FILE="$CHILD_PATH/style.css"

if [ ! -d "$CHILD_PATH" ]; then
  wp scaffold child-theme "$CHILD_THEME" \
    --parent_theme=hello-elementor \
    --theme_name="Hello Elementor Child" \
    --author="WP CLI Script" \
    --activate --allow-root
else
  wp theme activate "$CHILD_THEME" --allow-root
fi

# Copy screenshot from parent (optional)
PARENT_THEME="hello-elementor"
PARENT_PATH="$WP_PATH/wp-content/themes/$PARENT_THEME"
SCREEN_FOUND=""
for ext in png jpg jpeg webp; do
  if [ -f "$PARENT_PATH/screenshot.$ext" ]; then
    cp "$PARENT_PATH/screenshot.$ext" "$CHILD_PATH/screenshot.$ext"
    SCREEN_FOUND="$CHILD_PATH/screenshot.$ext"
    for rmext in png jpg jpeg webp; do
      if [ "$rmext" != "$ext" ] && [ -f "$CHILD_PATH/screenshot.$rmext" ]; then
        rm -f "$CHILD_PATH/screenshot.$rmext"
      fi
    done
    echo "🖼️ Copied parent theme screenshot → $SCREEN_FOUND"
    break
  fi
done
[ -z "$SCREEN_FOUND" ] && echo "⚠️ No screenshot.(png|jpg|jpeg|webp) found in $PARENT_PATH (skipping)."

FUNCTIONS_FILE_UPDATE="$CHILD_PATH/functions.php"
# ---------- Custom Code Additions ----------
echo "🛠️ Adding custom code snippets to child theme..."
# Append custom query modification if not already present
if ! grep -q "pre_get_posts.*programs" "$FUNCTIONS_FILE_UPDATE"; then
  cat >> "$FUNCTIONS_FILE_UPDATE" <<'PHP'

/**
 * Limit and order "programs" archive query
 */
add_action('pre_get_posts', function($query) {
    if (!is_admin() && $query->is_main_query() && is_post_type_archive('programs')) {
        $query->set('posts_per_page', 6);
        $query->set('meta_key', 'rank');
        $query->set('orderby', 'meta_value_num');
        $query->set('order', 'ASC');
    }
});
/**
 * Limit and order "instructors" archive query
 */
add_action('pre_get_posts', function($query) {
    if (!is_admin() && $query->is_main_query() && is_post_type_archive('instructors')) {
	$query->set('posts_per_page', 6);
	$query->set('meta_key', 'rank');
	$query->set('orderby', 'meta_value_num');
	$query->set('order', 'ASC');
    }
});
PHP
  echo "✅ Added pre_get_posts hook for 'programs' archive in functions.php"
else
  echo "ℹ️ pre_get_posts hook for 'programs' already exists in functions.php"
fi


# --- Add initial custom CSS if not already present ---
if ! grep -q "/* === Custom Initial CSS === */" "$STYLE_FILE"; then
  cat >> "$STYLE_FILE" <<'CSSINIT'

/* === Custom Initial CSS === */
.text-center {
  text-align: center;
}

.custom-logo-link {
  .custom-logo {
    width: 130px;
  }
}

.archive-programs-container {
  .main-heading {
    min-height: 250px;
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    text-align: center;
    margin-bottom: 30px;
    background: linear-gradient(35deg, #000, #333);
    isolation: isolate;
    h1 {
      font-size: 3rem;
      font-weight: bold;
      background: linear-gradient(135deg, #f06, #4a90e2);
      background-size: cover;
      background-position: center;
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      position: relative;
      &::before {
        content: "";
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        width: 110%;
        height: 110%;
        background-color: #fff;
        border-radius: 10px;
        z-index: -1;
      }
    }
  }
}

@media (width > 1200px) {
  #content {
    &.archive-programs {
      max-width: 1440px;
    }
  }
}

.archive-programs {
  > h1 {
    margin-bottom: 40px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px 30px;
    background-color: var(--wp--preset--color--vivid-red);
    color: #fff;
    border-radius: 5px;
    @media (width < 600px) {
      font-size: 1.6rem;
    }
  }
  .programs-list {
    display: grid;
    /* grid-template-columns: repeat(auto-fit, minmax(370px, 1fr)); */
    grid-template-columns: 1fr;
    gap: 20px;
    .program-card {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      .content-wrapper {
        display: flex;
        align-items: flex-start;
        justify-content: center;
        flex-direction: column;
        height: 100%;
        padding: 40px;
      }
      &.even {
        direction: rtl;
        .content-wrapper {
          direction: ltr;
        }
      }

      .program-thumbnail {
        width: 100%;
        height: 550px;
        display: flex;
        align-items: center;
        justify-content: center;
        a {
          width: 100%;
          height: 100%;
          img {
            height: 100%;
            width: 100%;
            object-fit: cover;
            object-position: top;
            border-radius: 10px;
          }
        }
      }
      .program-excerpt {
        p {
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }
      }
    }
    .learn-more-button {
      display: inline-block;
      padding: 10px 20px;
      background-color: var(--wp--preset--color--vivid-red);
      color: #fff;
      border-radius: 5px;
      text-decoration: none;
      border: 2px solid var(--wp--preset--color--vivid-red);
      transition: all 0.3s ease;
      &:hover {
        background-color: transparent;
        color: var(--wp--preset--color--vivid-red);
        text-decoration: none;
      }
    }
  }
  .pagination {
    max-width: 650px;
    margin-top: 50px;
    justify-content: center;
    gap: 20px;
    a {
      padding: 10px 20px;
      background-color: var(--wp--preset--color--vivid-red);
      color: #fff;
      border-radius: 5px;
      &:hover {
        background-color: var(--wp--preset--color--vivid-red);
        color: #fff;
        text-decoration: none;
      }
    }
    span {
      padding: 10px 20px;
      background-color: var(--wp--preset--color--cyan-bluish-gray);
      color: #fff;
      font-weight: bold;
      border-radius: 5px;
    }
    @media (width< 600px) {
      flex-wrap: wrap;
      justify-content: center;
      gap: 10px;
    }
  }
}

/* Single Programs */

#content {
  &.single-programs {
    img {
      width: 100%;
    }
  }
}

/* Home Page ~ Programs */
.programs_sc_empty,
.reviews_sc_empty {
  text-align: center;
  font-size: 20px;
}
.programs_sc_heading,
.reviews_sc_heading { 
  text-align: center;
  margin-block: 20px 30px;
}
.programs_home_wrapper,
.reviews_home_wrapper {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
  gap: 15px;
  .program_box {
    .program_image {
      img {
        width: 100%;
        height: 300px;
        object-fit: cover;
        border-radius: 3px;
      }
    }
    .program_content {
      a {
        text-decoration: none;
      }
      p {
        display: -webkit-box;
        overflow: hidden;
        line-clamp: 2;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        min-height: 50px;
      }
      > a {
        display: inline-flex;
        width: 150px;
        height: 45px;
        border-radius: 5px;
        color: #fff;
        align-items: center;
        justify-content: center;
        background-color: var(--wp--preset--color--vivid-red);
        &:hover {
          background-color: #b32828ff;
        }
      }
    }
  }
}

.reviews_home_wrapper {
  .review_box {
    padding: 20px;
    border-bottom-width: 1px;
    border-bottom-color: rgb(238, 238, 238);
    background-color: #eaeaea29;
    border-bottom-width: 3px;
    border-bottom-color: var(--wp--preset--color--vivid-red);

    .img {
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .content {
      p {
        text-align: justify;
        text-align-last: center;
      }
    }
  }
}

/* === End Custom Initial CSS === */

CSSINIT
  echo "✅ Initial custom CSS added to style.css"
else
  echo "ℹ️ Initial custom CSS already present, skipping."
fi

# ---------- Custom Page Template ----------
echo "📄 Creating custom page template in child theme..."

CHILD_PATH="$WP_PATH/wp-content/themes/hello-elementor-child"

# Ensure the child theme folder exists
mkdir -p "$CHILD_PATH"

if [ "${INSECURE_PERMS:-0}" = "1" ]; then
  # ---------- Permissions (INSECURE: local dev only) ----------
  if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi
  echo "⚠️ Setting INSECURE permissions (777) on $WP_PATH — local dev only!"
  $SUDO chmod -R 777 "$WP_PATH"
  echo "✅ Done (but consider switching to safe perms before going live)."
else
  # ---------- Permissions (recommended) ----------
  # Detect a likely web user; override by exporting WEB_USER if needed
  WEB_USER="${WEB_USER:-$(ps -o user= -C apache2 2>/dev/null | head -n1)}"
  WEB_USER="${WEB_USER:-$(ps -o user= -C httpd   2>/dev/null | head -n1)}"
  WEB_USER="${WEB_USER:-$(ps -o user= -C nginx   2>/dev/null | head -n1)}"
  WEB_USER="${WEB_USER:-www-data}"   # fallback for Debian/Ubuntu

  if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

  echo "🔐 Setting recommended permissions for $WP_PATH (owner: $WEB_USER)"
  $SUDO chown -R "$WEB_USER:$WEB_USER" "$WP_PATH"

  # Directories 755, files 644
  find "$WP_PATH" -type d -exec $SUDO chmod 755 {} \;
  find "$WP_PATH" -type f -exec $SUDO chmod 644 {} \;

  # Allow uploads to be group-writable (helpful for CLI + web user collaboration)
  $SUDO chmod -R 775 "$WP_PATH/wp-content"
  $SUDO find "$WP_PATH/wp-content" -type f -exec chmod 664 {} \;

  # Tighten sensitive files
  $SUDO chmod 640 "$WP_PATH/wp-config.php" 2>/dev/null || true
  $SUDO chmod 640 "$WP_PATH/.htaccess"     2>/dev/null || true
  echo "✅ Permissions hardened."
fi

# 6) Flush caches
wp cache flush --allow-root || true

if [ "$CREATE_VIRTUAL_HOST" = "1" ]; then
  echo "✅ WordPress installed successfully at $WP_URL. Local hostname and Apache setup completed."
else
  echo "✅ WordPress installed with site URL $WP_URL. Local hostname and Apache setup were skipped."
fi
