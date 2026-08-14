#!/usr/bin/env bash
# ==============================================================================
# Automated Test Runner for Azure SQL Database CI/CD
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_SQL_FILE="$SCRIPT_DIR/run_all_tests.sql"

echo "=============================================================================="
echo "🧪 Running Azure SQL Automated Test Suite"
echo "=============================================================================="

# 1. Check if SQL_CONNECTION_STRING is provided
if [ -z "$SQL_CONNECTION_STRING" ]; then
    echo ""
    echo "⚠️  SQL_CONNECTION_STRING environment variable is not set."
    echo "Please set it before running tests:"
    echo 'export SQL_CONNECTION_STRING="Server=tcp:freetier-sqlserver-central.database.windows.net,1433;Initial Catalog=appdb;Persist Security Info=False;User ID=<USER>;Password=<PASS>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"'
    echo ""
    echo "Or run the tests directly in Azure Portal Query Editor with: tests/run_all_tests.sql"
    exit 0
fi

# 2. Extract connection components from SQL_CONNECTION_STRING
SERVER=$(echo "$SQL_CONNECTION_STRING" | grep -o 'Server=tcp:[^;,]*' | sed 's/Server=tcp://' | sed 's/,1433//')
DATABASE=$(echo "$SQL_CONNECTION_STRING" | grep -o 'Initial Catalog=[^;]*' | sed 's/Initial Catalog=//')
USER_ID=$(echo "$SQL_CONNECTION_STRING" | grep -o 'User ID=[^;]*' | sed 's/User ID=//')
PASSWORD=$(echo "$SQL_CONNECTION_STRING" | grep -o 'Password=[^;]*' | sed 's/Password=//')

echo "Server:   $SERVER"
echo "Database: $DATABASE"
echo "User:     $USER_ID"
echo "Test File: $TEST_SQL_FILE"
echo ""

# 3. Check for sqlcmd availability
if command -v sqlcmd &> /dev/null; then
    echo "Executing tests via sqlcmd..."
    sqlcmd -S "$SERVER" -d "$DATABASE" -U "$USER_ID" -P "$PASSWORD" -i "$TEST_SQL_FILE" -b
    echo ""
    echo "✅ Test execution complete!"
else
    echo "⚠️  sqlcmd CLI is not installed locally."
    echo "You can copy and run 'tests/run_all_tests.sql' directly in Azure Portal Query Editor."
fi
