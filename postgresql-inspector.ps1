Write-Host "PostgreSQL Inspector" -ForegroundColor Green
Write-Host "--------------------" -ForegroundColor Green
Write-Host "This script connects to a PostgreSQL database and provides live diagnostic information." -ForegroundColor Yellow
Write-Host "It checks server info, active queries, index usage, database size, and configuration settings." -ForegroundColor Yellow

# Prompt user for the database URL
$dbUrl = Read-Host "Enter PostgreSQL External Database URL (postgresql://user:password@host:port/dbname)"

# Validate the URL format
if (-not $dbUrl.StartsWith("postgresql://")) {
    Write-Host "Invalid URL format. Make sure it starts with postgresql://" -ForegroundColor Red
    exit 1
}

Write-Host "Setting up connection to the database..." -ForegroundColor Yellow
$env:DATABASE_URL = $dbUrl

# Function to run a query and display results with a descriptive title
function RunQuery($title, $query, $description) {
    Write-Host ""
    Write-Host "=== $title ===" -ForegroundColor Cyan
    Write-Host $description -ForegroundColor Yellow
    psql $env:DATABASE_URL -X -q -c $query 2>$null
}

# Test the connection
Write-Host "Testing database connection..." -ForegroundColor Yellow
psql $env:DATABASE_URL -c "SELECT 1;" >$null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Connection failed. Please check the URL, credentials, and network." -ForegroundColor Red
    exit 1
}
Write-Host "Connected successfully!" -ForegroundColor Green

while ($true) {
    Write-Host "`nStarting database inspection loop..." -ForegroundColor Yellow

    RunQuery "Server Version" "SELECT version();" "Shows PostgreSQL server version and build info."
    RunQuery "Uptime" "SELECT now() - pg_postmaster_start_time() AS uptime;" "Displays how long the database server has been running."
    RunQuery "Current Database / User" "SELECT current_database(), current_user;" "Shows which database and user we are connected as."
    RunQuery "Connection Info" "
    SELECT inet_client_addr() AS client_ip,
           inet_client_port() AS client_port,
           ssl,
           version AS ssl_version,
           cipher
    FROM pg_stat_ssl
    JOIN pg_stat_activity USING (pid)
    WHERE pid = pg_backend_pid();
    " "Displays client IP, port, and SSL/TLS info."
    RunQuery "Active Queries" "
    SELECT pid,
           state,
           now() - query_start AS duration,
           query
    FROM pg_stat_activity
    WHERE state <> 'idle'
    ORDER BY query_start;
    " "Lists currently running queries, how long they've been running, and their states."
    RunQuery "Index Usage" "
    SELECT relname AS table,
           seq_scan,
           idx_scan,
           idx_scan - seq_scan AS index_advantage
    FROM pg_stat_user_tables
    ORDER BY idx_scan DESC;
    " "Shows index usage vs sequential scans per table to identify optimization opportunities."
    RunQuery "Vacuum / Dead Tuples" "
    SELECT relname AS table,
           n_dead_tup,
           last_vacuum,
           last_autovacuum
    FROM pg_stat_user_tables
    ORDER BY n_dead_tup DESC;
    " "Displays table bloat and last vacuum/autovacuum times."
    RunQuery "Database Size" "
    SELECT pg_size_pretty(pg_database_size(current_database()));
    " "Shows total size of the current database."
    RunQuery "WAL Statistics (if permitted)" "
    SELECT * FROM pg_stat_wal;
    " "Displays write-ahead log stats if permissions allow."
    RunQuery "Autovacuum Settings" "
    SHOW autovacuum;
    SHOW autovacuum_naptime;
    " "Shows autovacuum status and frequency."
    RunQuery "Memory Settings" "
    SHOW shared_buffers;
    SHOW work_mem;
    SHOW maintenance_work_mem;
    " "Displays key memory configuration affecting performance."

    Write-Host ""
    Write-Host "Inspection complete. Review the colored output above." -ForegroundColor Green

    Read-Host "Press Enter to run the inspection again, or Ctrl+C to exit"
}
