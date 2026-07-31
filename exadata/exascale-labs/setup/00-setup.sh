#!/usr/bin/env bash
#
# Create SALES_MAIN and register its PDB resource and service with Clusterware.
#
# The SQL driver preserves the secure PDB administrator password prompt, then
# this wrapper starts and verifies the resulting Clusterware-managed PDB.

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

sql_connect=${LAB_DB_CONNECT:-"/ as sysdba"}
sql_client=${LAB_SQL_CLIENT:-auto}

find_sql_client() {
    is_sqlcl() {
        "${1}" -version 2>&1 | grep -qi 'SQLcl'
    }

    case "$sql_client" in
        auto)
            if command -v sql >/dev/null 2>&1 && is_sqlcl "$(command -v sql)"; then
                command -v sql
            elif command -v sqlplus >/dev/null 2>&1; then
                command -v sqlplus
            else
                echo "ERROR: Oracle SQLcl or SQL*Plus was not found in PATH." >&2
                return 1
            fi
            ;;
        sqlcl|sql)
            if ! command -v sql >/dev/null 2>&1 || ! is_sqlcl "$(command -v sql)"; then
                echo "ERROR: LAB_SQL_CLIENT=sql requires Oracle SQLcl; 'sql' is missing or is a different client." >&2
                return 1
            fi
            command -v sql
            ;;
        sqlplus)
            command -v sqlplus
            ;;
        *)
            echo "ERROR: LAB_SQL_CLIENT must be auto, sqlcl, sql, or sqlplus." >&2
            return 1
            ;;
    esac
}

sql_bin=$(find_sql_client)
read -r -a connect_args <<< "$sql_connect"

echo "Creating SALES_MAIN and configuring Clusterware availability"
echo "SQL client: ${sql_bin}"

# Validate CDB and RAC placement configuration before creating the PDB. The
# verification command is read-only and exits successfully when SALES_MAIN is
# not yet registered as a Clusterware resource.
"$repo_root/common/manage-pdb-clusterware.sh" verify SALES_MAIN >/dev/null

(
    cd "$script_dir"
    "$sql_bin" -s "${connect_args[@]}" @00-setup-driver.sql
)

"$repo_root/common/manage-pdb-clusterware.sh" ensure-and-start SALES_MAIN
"$repo_root/common/manage-pdb-clusterware.sh" verify SALES_MAIN

echo "SALES_MAIN setup complete."
