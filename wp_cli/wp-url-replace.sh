#!/usr/bin/env bash
set -euo pipefail

echo "=== WordPress URL Replace (WP-CLI preferred) ==="

read -r -p "Path to WordPress (default: current dir): " WP_PATH
WP_PATH="${WP_PATH:-$(pwd)}"

read -r -p "Old URL (e.g. https://old.com): " OLD_URL
read -r -p "New URL (e.g. https://new.com): " NEW_URL

read -r -p "Dry run? (y/N): " DRY
DRY="${DRY:-N}"

echo ""
echo "Checking WP-CLI..."
if command -v wp >/dev/null 2>&1 && [[ -f "$WP_PATH/wp-config.php" ]]; then
  echo "WP-CLI found and wp-config.php exists. Using WP-CLI (safe for serialized data)."

  CMD=(wp --path="$WP_PATH" search-replace "$OLD_URL" "$NEW_URL" --all-tables-with-prefix --precise --report-changed-only)
  if [[ "$DRY" =~ ^[Yy]$ ]]; then
    CMD+=(--dry-run)
  fi

  echo ""
  echo "Running:"
  printf ' %q' "${CMD[@]}"
  echo -e "\n"

  "${CMD[@]}"
  echo -e "\nDone (WP-CLI)."
  exit 0
fi

echo "WP-CLI not usable here (missing wp, or wp-config.php not found). Falling back to MySQL mode."
echo "NOTE: MySQL REPLACE() can break serialized values in wp_options/wp_postmeta."

# MySQL details
read -r -p "DB Host (default: localhost): " DB_HOST
DB_HOST="${DB_HOST:-localhost}"

read -r -p "DB Name: " DB_NAME
read -r -p "DB User: " DB_USER
read -r -s -p "DB Password: " DB_PASS
echo ""

read -r -p "WP Table Prefix (default: wp_): " WP_PREFIX
WP_PREFIX="${WP_PREFIX:-wp_}"

MYSQL_CMD=(mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" --batch --raw)

# Impact preview (counts)
SQL_DRY=$(cat <<SQL
SELECT 'options(home/siteurl)' AS area, COUNT(*) AS rows_to_change
FROM ${WP_PREFIX}options
WHERE option_name IN ('home','siteurl') AND option_value LIKE CONCAT('%','${OLD_URL}','%');
SELECT 'posts(guid)' AS area, COUNT(*) AS rows_to_change
FROM ${WP_PREFIX}posts
WHERE guid LIKE CONCAT('%','${OLD_URL}','%');
SELECT 'posts(post_content)' AS area, COUNT(*) AS rows_to_change
FROM ${WP_PREFIX}posts
WHERE post_content LIKE CONCAT('%','${OLD_URL}','%');
SELECT 'postmeta(meta_value)' AS area, COUNT(*) AS rows_to_change
FROM ${WP_PREFIX}postmeta
WHERE meta_value LIKE CONCAT('%','${OLD_URL}','%');
SQL
)

echo -e "\n== Impact preview =="
"${MYSQL_CMD[@]}" -e "$SQL_DRY"
echo ""

if [[ "$DRY" =~ ^[Yy]$ ]]; then
  echo "Dry run selected. No updates executed."
  exit 0
fi

read -r -p "Proceed with MySQL updates? (y/N): " OK
OK="${OK:-N}"
if [[ ! "$OK" =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

SQL_UPDATES=$(cat <<SQL
UPDATE ${WP_PREFIX}options
SET option_value = REPLACE(option_value, '${OLD_URL}', '${NEW_URL}')
WHERE option_name IN ('home','siteurl');

UPDATE ${WP_PREFIX}posts
SET guid = REPLACE(guid, '${OLD_URL}', '${NEW_URL}');

UPDATE ${WP_PREFIX}posts
SET post_content = REPLACE(post_content, '${OLD_URL}', '${NEW_URL}');

UPDATE ${WP_PREFIX}postmeta
SET meta_value = REPLACE(meta_value, '${OLD_URL}', '${NEW_URL}');
SQL
)

echo -e "\n== Running MySQL updates =="
"${MYSQL_CMD[@]}" -e "$SQL_UPDATES"
echo -e "\nDone (MySQL)."
