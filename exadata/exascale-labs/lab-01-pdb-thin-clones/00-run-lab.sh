#!/usr/bin/env bash
#
# Run Lab 01 end-to-end without interactive pauses.
#
# The runner first cleans up any existing Lab 01 objects, then runs the lab
# through the refresh step. It intentionally does not run final cleanup so the
# resulting snapshot and clone state can be used by a later lab.

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

sql_connect=${LAB_DB_CONNECT:-"/ as sysdba"}
sql_client=${LAB_SQL_CLIENT:-auto}

find_sql_client() {
    case "$sql_client" in
        auto)
            if command -v sql >/dev/null 2>&1; then
                command -v sql
            elif command -v sqlplus >/dev/null 2>&1; then
                command -v sqlplus
            else
                echo "ERROR: sqlcl 'sql' or sqlplus was not found in PATH." >&2
                return 1
            fi
            ;;
        sqlcl|sql)
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
workdir=$(mktemp -d "${TMPDIR:-/tmp}/exadata-lab01.XXXXXX")

cleanup() {
    rm -rf "$workdir"
}
trap cleanup EXIT

mkdir -p "$workdir"
cp -R "$repo_root/common" "$workdir/common"
cp -R "$script_dir" "$workdir/lab-01-pdb-thin-clones"

sed -i \
    's/DEFINE LAB_PAUSE_SCRIPT      = pause.sql/DEFINE LAB_PAUSE_SCRIPT      = pause-off.sql/' \
    "$workdir/common/config.sql"

preflight_sql="$workdir/lab-01-pdb-thin-clones/.preflight.sql"
cat > "$preflight_sql" <<'SQL'
@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Checking Lab 01 prerequisites

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
            '&&MAIN_PDB does not exist. Run setup/00-create-sales-main.sql, ' ||
            'setup/01-mask-data.sql, and setup/02-verify-environment.sql before Lab 01.'
        );
    END IF;

    dbms_output.put_line('PASS: &&MAIN_PDB exists.');
END;
/
SQL

read -r -a connect_args <<< "$sql_connect"

run_sql() {
    local script_name=$1

    echo
    echo "==> ${script_name}"
    (
        cd "$workdir/lab-01-pdb-thin-clones"
        printf '@%s\nEXIT SQL.SQLCODE\n' "$script_name" |
            "$sql_bin" -s "${connect_args[@]}"
    )
}

echo "Running Lab 01 without interactive pauses"
echo "SQL client: $sql_bin"
echo "Connect: $sql_connect"

run_sql .preflight.sql
run_sql 07-cleanup.sql
run_sql 01-create-snapshot.sql
run_sql 02-create-consistent-snapshot.sql
run_sql 03-create-clones.sql
run_sql 04-verify-independence.sql
run_sql 05-create-clone-of-clone.sql
run_sql 06-refresh-clone.sql

echo
echo "Lab 01 complete. Snapshot and clone state is ready for the next lab."
