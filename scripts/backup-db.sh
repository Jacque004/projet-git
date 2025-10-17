#!/usr/bin/env bash
set -euo pipefail

# Universal database backup script
# Supports: PostgreSQL, MySQL/MariaDB, MongoDB, SQLite, Cloudflare D1 (optional)
# Output: compressed .tar.gz containing dump files per database
# Detection: based on env vars and available CLIs

# --------------
# Helpers
# --------------
log() { echo "[backup-db] $*" >&2; }
fail() { echo "[backup-db][ERROR] $*" >&2; exit 1; }

require_bin() {
  local bin="$1"; shift || true
  if ! command -v "$bin" >/dev/null 2>&1; then
    fail "Binaire requis non trouvé: $bin"
  fi
}

timestamp() { date +"%Y%m%d-%H%M%S"; }

mkworkdir() {
  local dir
  dir=$(mktemp -d -t backup-db-XXXXXXXX)
  echo "$dir"
}

print_help() {
  cat <<'EOF'
Usage: scripts/backup-db.sh [options]

Options:
  --type <postgres|mysql|mariadb|mongo|sqlite|d1|auto>   Type de base (par défaut: auto)
  --out <dir>                                            Dossier de sortie (par défaut: ./backups)
  --db <name>                                            Nom de la base (Postgres/MySQL/Mongo)
  --host <host> --port <port>                            Hôte et port (si applicable)
  --user <user> --password <password>                    Identifiants (si applicable)
  --url <connection-url>                                 URL de connexion (prioritaire si fournie)
  --sqlite-file <path>                                   Fichier SQLite à sauvegarder
  --d1-db <name>                                         Nom DB Cloudflare D1 (wrangler requis)
  --no-tar                                               Ne pas regrouper en tar.gz (laisse fichiers bruts)
  -h, --help                                             Afficher l'aide

Variables d'env reconnues:
  DATABASE_URL, DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD,
  PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD,
  MYSQL_HOST, MYSQL_PORT, MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD,
  MONGO_URL, MONGODB_URI,
  SQLITE_FILE,
  D1_DATABASE

Exemples:
  scripts/backup-db.sh --type auto
  scripts/backup-db.sh --type postgres --url "$DATABASE_URL"
  scripts/backup-db.sh --type mysql --host 127.0.0.1 --user root --password secret --db app
  scripts/backup-db.sh --type mongo --url "$MONGODB_URI"
  scripts/backup-db.sh --type sqlite --sqlite-file data.sqlite
  scripts/backup-db.sh --type d1 --d1-db mydb
EOF
}

# --------------
# Parse args
# --------------
TYPE="auto"
OUT_DIR="./backups"
DB_NAME=""
HOST=""
PORT=""
USER=""
PASSWORD=""
URL=""
SQLITE_FILE="${SQLITE_FILE:-}"
D1_DB="${D1_DATABASE:-}"
MAKE_TAR=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) TYPE="$2"; shift 2;;
    --out) OUT_DIR="$2"; shift 2;;
    --db) DB_NAME="$2"; shift 2;;
    --host) HOST="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --user) USER="$2"; shift 2;;
    --password) PASSWORD="$2"; shift 2;;
    --url) URL="$2"; shift 2;;
    --sqlite-file) SQLITE_FILE="$2"; shift 2;;
    --d1-db) D1_DB="$2"; shift 2;;
    --no-tar) MAKE_TAR=0; shift;;
    -h|--help) print_help; exit 0;;
    *) echo "Argument inconnu: $1"; print_help; exit 1;;
  esac
done

mkdir -p "$OUT_DIR"
TS=$(timestamp)
WORKDIR=$(mkworkdir)
trap 'rm -rf "$WORKDIR"' EXIT

# --------------
# Detection
# --------------
if [[ "$TYPE" == "auto" ]]; then
  if [[ -n "${DATABASE_URL:-}" ]]; then
    URL="$DATABASE_URL"
  fi
  if [[ -n "$URL" ]]; then
    if [[ "$URL" =~ ^postgres://|^postgresql:// ]]; then TYPE=postgres; fi
    if [[ "$URL" =~ ^mysql://|^mariadb:// ]]; then TYPE=mysql; fi
    if [[ "$URL" =~ ^mongodb://|^mongodb\+srv:// ]]; then TYPE=mongo; fi
  fi
  if [[ "$TYPE" == "auto" && -n "${PGHOST:-}${PGDATABASE:-}${PGUSER:-}" ]]; then TYPE=postgres; fi
  if [[ "$TYPE" == "auto" && -n "${MYSQL_HOST:-}${MYSQL_DATABASE:-}${MYSQL_USER:-}" ]]; then TYPE=mysql; fi
  if [[ "$TYPE" == "auto" && -n "${MONGO_URL:-}${MONGODB_URI:-}" ]]; then TYPE=mongo; fi
  if [[ "$TYPE" == "auto" && -n "$SQLITE_FILE" ]]; then TYPE=sqlite; fi
  if [[ "$TYPE" == "auto" && -n "$D1_DB" ]]; then TYPE=d1; fi
fi

log "Type détecté: $TYPE"

# --------------
# Dump implementations
# --------------
backup_postgres() {
  local target_dir="$WORKDIR/postgres"
  mkdir -p "$target_dir"
  require_bin pg_dump

  local url="${URL:-}"
  if [[ -z "$url" ]]; then
    local h="${HOST:-${PGHOST:-localhost}}"
    local p="${PORT:-${PGPORT:-5432}}"
    local u="${USER:-${PGUSER:-postgres}}"
    local d="${DB_NAME:-${PGDATABASE:-postgres}}"
    local pw="${PASSWORD:-${PGPASSWORD:-}}"
    if [[ -n "$pw" ]]; then export PGPASSWORD="$pw"; fi
    url="postgresql://$u@$h:$p/$d"
  fi

  log "Dump PostgreSQL vers $target_dir"
  pg_dump "$url" --no-owner --format=custom --file "$target_dir/$DB_NAME-${TS}.dump" || fail "pg_dump a échoué"
}

backup_mysql() {
  local target_dir="$WORKDIR/mysql"
  mkdir -p "$target_dir"
  require_bin mysqldump

  local h="${HOST:-${MYSQL_HOST:-localhost}}"
  local p="${PORT:-${MYSQL_PORT:-3306}}"
  local u="${USER:-${MYSQL_USER:-root}}"
  local d="${DB_NAME:-${MYSQL_DATABASE:-}}"
  local pw="${PASSWORD:-${MYSQL_PASSWORD:-}}"
  if [[ -z "$d" && -n "$URL" ]]; then
    # try to parse db name from mysql url
    d=$(echo "$URL" | sed -E 's#.*/([^/?]+).*#\1#')
  fi
  if [[ -z "$d" ]]; then fail "Nom de base MySQL requis (via --db ou MYSQL_DATABASE)"; fi

  local pass_arg=()
  if [[ -n "$pw" ]]; then pass_arg=("-p$pw"); fi

  log "Dump MySQL/MariaDB vers $target_dir"
  mysqldump -h "$h" -P "$p" -u "$u" ${pass_arg[@]:-} "$d" > "$target_dir/$d-${TS}.sql" || fail "mysqldump a échoué"
}

backup_mongo() {
  local target_dir="$WORKDIR/mongo"
  mkdir -p "$target_dir"
  if command -v mongodump >/dev/null 2>&1; then
    require_bin mongodump
    local conn="${URL:-${MONGODB_URI:-${MONGO_URL:-}}}"
    if [[ -z "$conn" ]]; then fail "URL MongoDB requise (via --url ou MONGODB_URI)"; fi
    log "Dump MongoDB via mongodump"
    mongodump --uri="$conn" --out "$target_dir" || fail "mongodump a échoué"
  elif command -v atlas >/dev/null 2>&1; then
    # Optional: MongoDB Atlas CLI could be used, but typically mongodump is standard
    fail "mongodump non trouvé. Installez mongodb-database-tools."
  else
    fail "mongodump non trouvé. Installez mongodb-database-tools."
  fi
}

backup_sqlite() {
  local target_dir="$WORKDIR/sqlite"
  mkdir -p "$target_dir"
  require_bin sqlite3

  local file="${SQLITE_FILE:-}"
  if [[ -z "$file" ]]; then fail "--sqlite-file requis pour SQLite ou variable SQLITE_FILE"; fi
  if [[ ! -f "$file" ]]; then fail "Fichier SQLite introuvable: $file"; fi

  log "Dump SQLite vers $target_dir"
  sqlite3 "$file" ".backup '$target_dir/$(basename "$file").$TS.sqlite'" || fail "sqlite backup a échoué"
}

backup_d1() {
  local target_dir="$WORKDIR/d1"
  mkdir -p "$target_dir"
  require_bin wrangler

  local db="${D1_DB:-}"
  if [[ -z "$db" ]]; then fail "--d1-db requis ou D1_DATABASE"; fi

  log "Export Cloudflare D1 vers $target_dir"
  wrangler d1 export "$db" --output "$target_dir/$db-${TS}.sql" || fail "wrangler d1 export a échoué"
}

# --------------
# Run
# --------------
case "$TYPE" in
  postgres) backup_postgres;;
  mysql|mariadb) backup_mysql;;
  mongo) backup_mongo;;
  sqlite) backup_sqlite;;
  d1) backup_d1;;
  *) fail "Type inconnu ou non détecté: $TYPE";;
esac

# --------------
# Packaging
# --------------
if [[ "$MAKE_TAR" -eq 1 ]]; then
  TAR_FILE="$OUT_DIR/db-backup-$TYPE-$TS.tar.gz"
  log "Compression vers $TAR_FILE"
  tar -C "$WORKDIR" -czf "$TAR_FILE" .
  log "Fini: $TAR_FILE"
else
  log "Fichiers bruts conservés dans $WORKDIR"
  # Déplacer le dossier vers OUT_DIR
  mv "$WORKDIR" "$OUT_DIR/backup-$TYPE-$TS"
  log "Fini: $OUT_DIR/backup-$TYPE-$TS"
fi
