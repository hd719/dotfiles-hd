#!/bin/bash
set -e

BACKUP_DIR="$HOME/Developer/Blaze/blaze-backups"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Flags to track which backups succeeded
PG_DEV_BACKUP_SUCCESS=false
PG_TEST_BACKUP_SUCCESS=false
REDIS_BACKUP_SUCCESS=false

# ===============================================================================
# STEP 1: PREPARE BACKUP DIRECTORY AND HANDLE EXISTING BACKUPS
# ===============================================================================
echo "🔄 STEP 1: PREPARING BACKUP DIRECTORY"
echo "======================================"

echo "🔍 Checking for existing backups..."

# Create backup directory if it doesn't exist
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "📁 Creating backup directory: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  echo "✅ Backup directory created: $BACKUP_DIR"
else
  echo "📁 Using existing backup directory: $BACKUP_DIR and renaming existing backups"
  # Check and rename existing PostgreSQL backup files
  if [[ -f "$BACKUP_DIR/pg_almanac_development.sql" ]]; then
    echo "🔄 Renaming existing PostgreSQL development backup to pg_almanac_development.sql.bk-$TIMESTAMP"
    mv "$BACKUP_DIR/pg_almanac_development.sql" "$BACKUP_DIR/pg_almanac_development.sql.bk-$TIMESTAMP"
  fi

  if [[ -f "$BACKUP_DIR/pg_almanac_test.sql" ]]; then
    echo "🔄 Renaming existing PostgreSQL test backup to pg_almanac_test.sql.bk-$TIMESTAMP"
    mv "$BACKUP_DIR/pg_almanac_test.sql" "$BACKUP_DIR/pg_almanac_test.sql.bk-$TIMESTAMP"
  fi

  # Check and rename existing Redis backup
  if [[ -f "$BACKUP_DIR/dump.rdb" ]]; then
    echo "🔄 Renaming existing Redis backup to dump.rdb.bk-$TIMESTAMP"
    mv "$BACKUP_DIR/dump.rdb" "$BACKUP_DIR/dump.rdb.bk-$TIMESTAMP"
  fi
fi
echo "✅ Existing backups renamed with .bk-$TIMESTAMP extension (if they existed)"
echo ""

# ===============================================================================
# STEP 2: DETECT RUNNING SERVICES (HOMEBREW VS DOCKER)
# ===============================================================================
echo "🔄 STEP 2: DETECTING RUNNING SERVICES"
echo "====================================="

# Detect if PostgreSQL is running locally or in Docker
echo "🔍 Checking if PostgreSQL is running locally..."
PG_RUNNING_LOCALLY=false
if brew services list | grep -q "postgresql@15.*started"; then
  echo "🔍 PostgreSQL is running locally via Homebrew"
  PG_RUNNING_LOCALLY=true
else
  echo "🔍 PostgreSQL is not running locally"
fi

# Detect if Redis is running locally or in Docker
echo "🔍 Checking if Redis is running locally..."
REDIS_RUNNING_LOCALLY=false
if brew services list | grep -q "redis.*started"; then
  echo "🔍 Redis is running locally via Homebrew"
  REDIS_RUNNING_LOCALLY=true
else
  echo "🔍 Redis is not running locally"
fi

# Detect if Docker is running
echo "🔍 Checking if Docker is running..."
DOCKER_RUNNING=false
if docker info >/dev/null 2>&1; then
  echo "🔍 Docker is running"
  DOCKER_RUNNING=true
else
  echo "🔍 Docker is not running"
fi
echo "🔍 Docker status: $DOCKER_RUNNING"
echo "🔍 PostgreSQL status: $PG_RUNNING_LOCALLY"
echo "🔍 Redis status: $REDIS_RUNNING_LOCALLY"
echo ""

# ===============================================================================
# STEP 3: BACK UP POSTGRESQL DATABASES
# ===============================================================================
echo "🔄 STEP 3: BACKING UP POSTGRESQL DATABASES"
echo "=========================================="

# Back up the PostgreSQL development database
echo "📦 Dumping PostgreSQL (almanac_development)"
if [ "$PG_RUNNING_LOCALLY" = true ]; then
  # If PostgreSQL is running locally via Homebrew, back up from there
  echo "🔍 Backing up local PostgreSQL (almanac_development)"
  if pg_dump almanac_development > "$BACKUP_DIR/pg_almanac_development.sql"; then
    echo "✅ Backed up local PostgreSQL (almanac_development)"
    PG_DEV_BACKUP_SUCCESS=true
  else
    echo "❌ Failed to backup local PostgreSQL (almanac_development)"
  fi
elif [ "$DOCKER_RUNNING" = true ] && docker ps | grep -q almanac_db; then
  # If PostgreSQL is running in Docker, back up from the container
  echo "🔍 Backing up Docker PostgreSQL (almanac_development)"
  if docker exec almanac_db pg_dump -U postgres almanac_development > "$BACKUP_DIR/pg_almanac_development.sql"; then
    echo "✅ Backed up Docker PostgreSQL (almanac_development)"
    PG_DEV_BACKUP_SUCCESS=true
  else
    echo "❌ Failed to backup Docker PostgreSQL (almanac_development)"
  fi
else
  # If neither local nor Docker PostgreSQL is available, show warning and continue
  echo "⚠️ Cannot backup PostgreSQL (almanac_development): neither local nor Docker instance available"
fi

# Back up the PostgreSQL test database
echo "📦 Dumping PostgreSQL (almanac_test)"
if [ "$PG_RUNNING_LOCALLY" = true ]; then
  # If PostgreSQL is running locally via Homebrew, back up from there
  echo "🔍 Backing up local PostgreSQL (almanac_test)"
  if pg_dump almanac_test > "$BACKUP_DIR/pg_almanac_test.sql"; then
    echo "✅ Backed up local PostgreSQL (almanac_test)"
    PG_TEST_BACKUP_SUCCESS=true
  else
    echo "❌ Failed to backup local PostgreSQL (almanac_test)"
  fi
elif [ "$DOCKER_RUNNING" = true ] && docker ps | grep -q almanac_db_test; then
  # If PostgreSQL is running in Docker, back up from the container
  echo "🔍 Backing up Docker PostgreSQL (almanac_test)"
  if docker exec almanac_db_test pg_dump -U postgres almanac_test > "$BACKUP_DIR/pg_almanac_test.sql"; then
    echo "✅ Backed up Docker PostgreSQL (almanac_test)"
    PG_TEST_BACKUP_SUCCESS=true
  else
    echo "❌ Failed to backup Docker PostgreSQL (almanac_test)"
  fi
else
  # If neither local nor Docker PostgreSQL is available, show warning and continue
  echo "⚠️ Cannot backup PostgreSQL (almanac_test): neither local nor Docker instance available"
fi
echo ""

# ===============================================================================
# STEP 4: BACK UP REDIS DATA
# ===============================================================================
echo "🔄 STEP 4: BACKING UP REDIS DATA"
echo "================================"

# Back up Redis data
echo "📦 Saving Redis snapshot"
if [ "$REDIS_RUNNING_LOCALLY" = true ]; then
  # If Redis is running locally via Homebrew, back up from there
  echo "🔍 Backing up local Redis"
  echo "📦 Using BGSAVE on local Redis"
  if redis-cli BGSAVE; then
    # BGSAVE is asynchronous, so wait for 5 seconds
    sleep 5
    REDIS_DUMP_PATH="/opt/homebrew/var/db/redis/dump.rdb"
    echo "📦 Copying Redis dump.rdb from Homebrew path to backup directory"
    if cp "$REDIS_DUMP_PATH" "$BACKUP_DIR/"; then
      REDIS_BACKUP_SUCCESS=true
    else
      echo "❌ Failed to copy Redis dump file from $REDIS_DUMP_PATH"
    fi
  else
    echo "❌ Failed to execute BGSAVE on local Redis"
  fi
elif [ "$DOCKER_RUNNING" = true ] && docker ps | grep -q almanac_redis; then
  # If Redis is running in Docker, back up from the container
  echo "🔍 Backing up Docker Redis"
  echo "📦 Saving snapshot from Docker Redis"
  # We use SAVE instead of BGSAVE in Docker to ensure it's completed before we copy
  if docker exec almanac_redis redis-cli SAVE; then
    # Copy the dump file from the container to local backup directory
    echo "📦 Copying Redis dump.rdb from Docker container to backup directory"
    if docker cp almanac_redis:/data/dump.rdb "$BACKUP_DIR/"; then
      REDIS_BACKUP_SUCCESS=true
    else
      echo "❌ Failed to copy Redis dump file from Docker container"
    fi
  else
    echo "❌ Failed to execute SAVE on Docker Redis"
  fi
else
  # If neither local nor Docker Redis is available, show warning and continue
  echo "⚠️ Cannot backup Redis: neither local nor Docker instance available"
fi

# Verify the Redis backup was successful by checking file size
if [ "$REDIS_BACKUP_SUCCESS" = true ]; then
  echo "🔍 Verifying Redis backup..."
  BACKUP_SIZE=$(du -h "$BACKUP_DIR/dump.rdb" | cut -f1)
  echo "📊 Redis backup size: $BACKUP_SIZE"
  if [[ -s "$BACKUP_DIR/dump.rdb" ]]; then
    echo "✅ Redis backup successful"
  else
    echo "❌ Redis backup failed - file is empty"
    REDIS_BACKUP_SUCCESS=false
  fi
fi
echo ""

# ===============================================================================
# BACKUP COMPLETE
# ===============================================================================
echo "🎉 BACKUP SUMMARY"
echo "================"

# Report on what was successfully backed up
BACKUP_COUNT=0
[ "$PG_DEV_BACKUP_SUCCESS" = true ] && ((BACKUP_COUNT++))
[ "$PG_TEST_BACKUP_SUCCESS" = true ] && ((BACKUP_COUNT++))
[ "$REDIS_BACKUP_SUCCESS" = true ] && ((BACKUP_COUNT++))

if [ "$BACKUP_COUNT" -eq 0 ]; then
  echo "❌ No backups were successful"
  echo "📋 Possible issues:"
  echo "   - Neither local nor Docker services are running"
  echo "   - Docker containers are not running (try 'docker-compose up -d')"
  echo "   - Local services are not running (try 'brew services start postgresql@15 redis')"
  exit 1
elif [ "$BACKUP_COUNT" -eq 3 ]; then
  echo "✅ All backups completed successfully!"
else
  echo "⚠️ Partial backup completed ($BACKUP_COUNT of 3 services)"
fi

echo "📂 Backup location: $BACKUP_DIR"
echo "🗓️ Previous backups renamed with .bk-$TIMESTAMP extension (if they existed)"
echo ""
echo "📋 Backup status:"
if [ "$PG_DEV_BACKUP_SUCCESS" = true ]; then
  echo "✅ PostgreSQL development: $BACKUP_DIR/pg_almanac_development.sql"
else
  echo "❌ PostgreSQL development: Not backed up"
fi

if [ "$PG_TEST_BACKUP_SUCCESS" = true ]; then
  echo "✅ PostgreSQL test: $BACKUP_DIR/pg_almanac_test.sql"
else
  echo "❌ PostgreSQL test: Not backed up"
fi

if [ "$REDIS_BACKUP_SUCCESS" = true ]; then
  echo "✅ Redis: $BACKUP_DIR/dump.rdb (Size: $BACKUP_SIZE)"
else
  echo "❌ Redis: Not backed up"
fi
