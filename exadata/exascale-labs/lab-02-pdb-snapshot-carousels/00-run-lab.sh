#!/usr/bin/env bash
#
# Run Lab 02 end-to-end without interactive pauses.
#
# The runner first cleans up any existing Lab 02 objects, then enables and
# verifies the database-managed PDB snapshot carousel. It intentionally leaves
# the carousel enabled for inspection.

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
workdir=$(mktemp -d "${TMPDIR:-/tmp}/exadata-lab02.XXXXXX")

cleanup() {
    rm -rf "$workdir"
}
trap cleanup EXIT

mkdir -p "$workdir"
cp -R "$repo_root/common" "$workdir/common"
cp -R "$script_dir" "$workdir/lab-02-pdb-snapshot-carousels"

sed -i \
    's/DEFINE LAB_PAUSE_SCRIPT      = pause.sql/DEFINE LAB_PAUSE_SCRIPT      = pause-off.sql/' \
    "$workdir/common/config.sql"

preflight_sql="$workdir/lab-02-pdb-snapshot-carousels/.preflight.sql"
cat > "$preflight_sql" <<'SQL'
@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Checking Lab 02 prerequisites

DECLARE
    l_container_name VARCHAR2(128);
    l_main_pdbs      NUMBER;
BEGIN
    SELECT sys_context('USERENV', 'CON_NAME')
    INTO   l_container_name
    FROM   dual;

    IF l_container_name <> '&&ROOT_CONTAINER' THEN
        raise_application_error(
            -20000,
            'Run this script from &&ROOT_CONTAINER. Current container is ' ||
            l_container_name
        );
    END IF;

    SELECT COUNT(*)
    INTO   l_main_pdbs
    FROM   dba_pdbs
    WHERE  pdb_name = UPPER('&&MAIN_PDB');

    IF l_main_pdbs = 0 THEN
        raise_application_error(
            -20010,
            '&&MAIN_PDB does not exist. Run setup before Lab 02.'
        );
    END IF;

    dbms_output.put_line('PASS: &&MAIN_PDB exists.');
END;
/
SQL

run_sql() {
    local script_name=$1

    echo
    echo "==> ${script_name}"
    (
        cd "$workdir/lab-02-pdb-snapshot-carousels"
        printf '@%s\nEXIT SQL.SQLCODE\n' "$script_name" |
            "$sql_bin" -s "$sql_connect"
    )
}

echo "Running Lab 02 without interactive pauses"
echo "SQL client: $sql_bin"
if [ -n "${LAB_DB_CONNECT:-}" ]; then
    echo "Connect: LAB_DB_CONNECT override configured"
else
    echo "Connect: local SYSDBA default"
fi

run_sql .connectivity.sql
run_sql .preflight.sql
run_sql 04-cleanup.sql
run_sql 01-enable-snapshot-carousel.sql
run_sql 02-verify-snapshot-carousel.sql

echo
echo "Lab 02 complete. Automated snapshot carousel is enabled for inspection."
