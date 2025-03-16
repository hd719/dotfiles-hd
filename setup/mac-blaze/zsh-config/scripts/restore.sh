#!/bin/bash
set -e

# Paths to the backup files
BACKUP_DIR="$HOME/Developer/Blaze/blaze-backups"
PG_BACKUP="$BACKUP_DIR/pg_almanac_development.sql"
REDIS_BACKUP="$BACKUP_DIR/dump.rdb"

# ===============================================================================
# STEP 1: VERIFY BACKUP FILES AND PREREQUISITES
# ===============================================================================
echo "🔄 STEP 1: VERIFYING BACKUP FILES AND PREREQUISITES"
echo "=================================================="

# Check if backup files exist
echo "🔍 Checking if backup files exist..."
if [[ ! -f "$PG_BACKUP" ]]; then
  echo "❌ PostgreSQL backup file not found: $PG_BACKUP"
  exit 1
fi

if [[ ! -f "$REDIS_BACKUP" ]]; then
  echo "❌ Redis backup file not found: $REDIS_BACKUP"
  exit 1
fi

# Check if Docker is running
echo "🔍 Checking if Docker is running..."
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker is not running. Please start Docker first."
  exit 1
fi

# Check if required containers exist and are running
echo "🔍 Checking if required Docker containers exist and are running..."

# Check PostgreSQL container
if ! docker ps -a | grep -q almanac_db; then
  echo "❌ PostgreSQL container 'almanac_db' not found."
  echo "⚠️ Please start your containers with: cd path/to/project && docker-compose up -d"
  exit 1
elif ! docker ps | grep -q almanac_db; then
  echo "❌ PostgreSQL container 'almanac_db' exists but is not running."
  echo "⚠️ Please start your containers with: cd path/to/project && docker-compose up -d"
  exit 1
fi

# Check Redis container
if ! docker ps -a | grep -q almanac_redis; then
  echo "❌ Redis container 'almanac_redis' not found."
  echo "⚠️ Please start your containers with: cd path/to/project && docker-compose up -d"
  exit 1
elif ! docker ps | grep -q almanac_redis; then
  echo "❌ Redis container 'almanac_redis' exists but is not running."
  echo "⚠️ Please start your containers with: cd path/to/project && docker-compose up -d"
  exit 1
fi

echo "✅ All backup files and prerequisites verified"
echo ""

# ===============================================================================
# STEP 2: STOP LOCAL SERVICES (IF RUNNING)
# ===============================================================================
echo "🔄 STEP 2: STOPPING LOCAL SERVICES"
echo "=================================="

echo "🔍 Checking local services status..."

# Stop PostgreSQL service
if brew services list | grep -q "postgresql@15.*started"; then
  echo "🛑 Stopping local PostgreSQL service..."
  brew services stop postgresql@15
  echo "✅ PostgreSQL stopped."
else
  echo "⚠️ PostgreSQL is already stopped."
fi

# Also try stopping regular postgresql service if it exists
if brew services list | grep -q "postgresql.*started"; then
  echo "🛑 Stopping local PostgreSQL service..."
  brew services stop postgresql
  echo "✅ PostgreSQL stopped."
fi

# Stop Redis service
if brew services list | grep -q "redis.*started"; then
  echo "🛑 Stopping local Redis service..."
  brew services stop redis
  echo "✅ Redis stopped."
else
  echo "⚠️ Redis is already stopped."
fi

echo "✅ Local services stopped (or were already stopped)"
echo ""

# ===============================================================================
# STEP 3: RESTORE POSTGRESQL DATABASE
# ===============================================================================
echo "🔄 STEP 3: RESTORING POSTGRESQL DATABASE"
echo "======================================="

echo "🔄 Restoring PostgreSQL (almanac_development) to Docker..."

# First, ensure the user exists with proper permissions
echo "🔧 Step 3.1: Creating PostgreSQL user 'hameldesai' if not exists..."
docker exec almanac_db psql -U postgres -c "DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'hameldesai') THEN
    CREATE USER hameldesai WITH SUPERUSER LOGIN;
  END IF;
END
\$\$;" || {
    echo "❌ Failed to create user 'hameldesai'"
    exit 1
}
echo "✅ User check/creation complete"

# Now attempt the restore
echo "🔄 Step 3.2: Restoring database..."
if ! docker exec -i almanac_db psql -U postgres -d almanac_development < "$PG_BACKUP" 2>&1 | tee /tmp/pg_restore.log; then
    if grep -q "role \"hameldesai\" does not exist" /tmp/pg_restore.log; then
        echo "❌ User creation didn't work as expected. This is unexpected - please check PostgreSQL logs"
        docker exec almanac_db psql -U postgres -c '\du'
        exit 1
    else
        echo "❌ PostgreSQL restore failed with unknown error"
        exit 1
    fi
else
    echo "✅ PostgreSQL restore complete"
fi
echo ""

# ===============================================================================
# STEP 4: RESTORE REDIS DATA
# ===============================================================================
echo "🔄 STEP 4: RESTORING REDIS DATA"
echo "=============================="
echo "⚠️ Redis restore requires special handling - see comments in script for details"

# -----------------------------------------------------------------------------
# IMPORTANT: Redis Restore Process Details
#
# The Redis restore process requires careful handling to avoid data loss.
# Here's why the following steps are critical:
#
# 1. Redis normally saves its current state to disk during shutdown.
#    If we use a simple restart after copying our backup, Redis would
#    overwrite our backup file with its current empty state before restarting.
#
# 2. The initial attempts with `docker restart` failed because:
#    a) We copied the backup dump.rdb to /data/
#    b) We issued docker restart, causing Redis to shut down gracefully
#    c) During shutdown, Redis saved its current empty state to /data/dump.rdb
#    d) This overwrote our backup file
#    e) When Redis restarted, it loaded the empty dump.rdb
#    f) Result: 0 keys were loaded
#
# 3. The solution is to:
#    a) Start the container (if needed)
#    b) Copy our backup file
#    c) Use redis-cli SHUTDOWN NOSAVE to shut down without saving state
#    d) Start the container, which will now properly load our backup
# -----------------------------------------------------------------------------

echo "🔄 Restoring Redis dump to Docker"

# Step 4.1: Ensure Redis container is running for file copy
echo "🔍 Step 4.1: Preparing Redis container..."
# Make sure the Redis container is running so we can copy to it
docker start almanac_redis >/dev/null 2>&1 || true

# Step 4.2: Copy the backup file to the container
echo "📦 Step 4.2: Copying Redis dump file..."
if ! docker cp "$REDIS_BACKUP" almanac_redis:/data/dump.rdb; then
  echo "❌ Failed to copy Redis backup file to container"
  exit 1
fi
echo "✅ Successfully copied Redis backup to container"

# Step 4.3: Set proper permissions on the file
echo "🔒 Step 4.3: Setting permissions on dump.rdb..."
docker exec almanac_redis chmod 644 /data/dump.rdb

# Step 4.4: Remove existing AOF files (if any)
echo "🧹 Step 4.4: Removing existing AOF files (if any)..."
docker exec almanac_redis sh -c 'rm -f /data/appendonly.aof*' || true # Allow failure if AOF disabled/not present

# Step 4.5: Shutdown Redis WITHOUT saving its current (empty) state
# This is critical - using SHUTDOWN NOSAVE prevents Redis from overwriting
# our backup file during the shutdown process
echo "🛑 Step 4.5: Shutting down Redis container without saving..."
docker exec almanac_redis redis-cli SHUTDOWN NOSAVE || true # Allow failure if already stopped
sleep 2 # Give it a moment to shut down

# Step 4.6: Start Redis container - it should now load the copied RDB
echo "🚀 Step 4.6: Starting Redis container..."
docker start almanac_redis

# Step 4.7: Wait for Redis to start and load the RDB
echo "⏳ Step 4.7: Waiting for Redis to load data..."
sleep 5

echo "✅ Redis restore process completed"

# Step 4.8: Verify Redis restore
echo "🔍 Step 4.8: Verifying Redis restore..."
REDIS_KEYS=$(docker exec almanac_redis redis-cli DBSIZE)
echo "📊 Redis now has $REDIS_KEYS keys"

if [[ "$REDIS_KEYS" -gt 0 ]]; then
  echo "✅ Redis restore confirmed!"
else
  echo "❌ Redis restore failed: 0 keys found after loading."
  echo "   Check Redis logs: docker logs almanac_redis --tail 50"
  exit 1
fi
echo ""

# ===============================================================================
# RESTORE COMPLETE
# ===============================================================================
echo "🎉 RESTORE COMPLETE"
echo "=================="
echo "✅ All services have been successfully restored"
echo "📊 Redis keys restored: $REDIS_KEYS"
echo ""
echo "Your Docker containers are now running with the restored data"
echo "You can use the following commands to verify:"
echo "  - PostgreSQL: docker exec -it almanac_db psql -U postgres -d almanac_development -c 'SELECT count(*) FROM pg_tables;'"
echo "  - Redis: docker exec -it almanac_redis redis-cli DBSIZE"

# ==============================================================================
# REDIS RESTORE TROUBLESHOOTING NOTES
# ==============================================================================
#
# When restoring Redis data from an RDB file to a Docker container, we encountered
# several challenges that required a specific approach. Here's what we learned:
#
# Problem:
# 1. When using `docker restart almanac_redis`, Redis would save its current
#    (empty) state during shutdown, overwriting our backup file we had just copied.
#
# 2. Redis in docker-compose was initially configured with --appendonly yes, which
#    meant it prioritized AOF files over RDB files during startup, even when we
#    removed AOF files before restart.
#
# Solution:
# 1. Modified docker-compose.yml to remove --appendonly yes to make Redis
#    use RDB as its primary persistence mechanism.
#
# 2. Used SHUTDOWN NOSAVE to stop Redis without letting it save its state,
#    preventing it from overwriting our backup file.
#
# 3. Sequence that works:
#    a) Copy backup dump.rdb to /data/ directory in container
#    b) Remove any AOF files (good practice even with appendonly disabled)
#    c) SHUTDOWN NOSAVE - stop Redis without saving current state
#    d) Start Redis - now it loads our backup file correctly
#
# If your Redis backup still isn't loading:
# 1. Check if your docker-compose still has --appendonly yes
# 2. Verify the backup file exists and has a non-zero size
# 3. Check permissions on the dump.rdb file in the container
# 4. Inspect Redis logs: docker logs almanac_redis
# ==============================================================================
