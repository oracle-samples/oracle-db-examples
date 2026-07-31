#!/usr/bin/env bash
#
# Verify Exadata System Software versions from a central database server.
#
# This script uses dcli to run:
#   - dbmcli on each database server
#   - cellcli on each storage server
#
# The labs require Exadata System Software 24.1 or later.

set -u

DCLI_BIN=${DCLI_BIN:-dcli}
MIN_EXADATA_VERSION=${MIN_EXADATA_VERSION:-24.1}
DBS_GROUP=${DBS_GROUP:-}
CELLS_GROUP=${CELLS_GROUP:-}
DBS_NODES=${DBS_NODES:-}
CELLS_NODES=${CELLS_NODES:-}
DBS_USER=${DBS_USER:-oracle}
CELLS_USER=${CELLS_USER:-celladmin}

CHECK_DBSERVERS=1
CHECK_CELLS=1

usage() {
    cat <<USAGE
Usage: $0 [options]

Verify Exadata System Software versions using dcli from a central location.

Options:
  --min-version VERSION     Minimum required Exadata version. Default: ${MIN_EXADATA_VERSION}
  --dcli PATH               dcli executable. Default: ${DCLI_BIN}
  --dbs-group FILE          dcli group file for database servers.
  --cells-group FILE        dcli group file for storage servers.
  --dbs-nodes LIST          Comma-separated database server host names.
  --cells-nodes LIST        Comma-separated storage server host names.
  --dbs-user USER           SSH user for database servers; must have passwordless sudo access to dbmcli. Default: ${DBS_USER}
  --cells-user USER         SSH user for storage servers. Default: ${CELLS_USER}
  --skip-dbservers          Skip dbmcli checks on database servers.
  --skip-cells              Skip cellcli checks on storage servers.
  -h, --help                Show this help.

The same values can be supplied with environment variables:
  DCLI_BIN, MIN_EXADATA_VERSION, DBS_GROUP, CELLS_GROUP, DBS_NODES,
  CELLS_NODES, DBS_USER, CELLS_USER

Database-server checks run 'sudo -n dbmcli'. Configure passwordless sudo for
the selected database-server user. The -n option reports missing sudo access
without prompting for a password.
USAGE
}

require_option_value() {
    local option=$1

    if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
        echo "ERROR: ${option} requires a value." >&2
        usage >&2
        exit 2
    fi
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --min-version)
            require_option_value "$1" "${2:-}"
            MIN_EXADATA_VERSION=$2
            shift 2
            ;;
        --dcli)
            require_option_value "$1" "${2:-}"
            DCLI_BIN=$2
            shift 2
            ;;
        --dbs-group)
            require_option_value "$1" "${2:-}"
            DBS_GROUP=$2
            shift 2
            ;;
        --cells-group)
            require_option_value "$1" "${2:-}"
            CELLS_GROUP=$2
            shift 2
            ;;
        --dbs-nodes)
            require_option_value "$1" "${2:-}"
            DBS_NODES=$2
            shift 2
            ;;
        --cells-nodes)
            require_option_value "$1" "${2:-}"
            CELLS_NODES=$2
            shift 2
            ;;
        --dbs-user)
            require_option_value "$1" "${2:-}"
            DBS_USER=$2
            shift 2
            ;;
        --cells-user)
            require_option_value "$1" "${2:-}"
            CELLS_USER=$2
            shift 2
            ;;
        --skip-dbservers)
            CHECK_DBSERVERS=0
            shift
            ;;
        --skip-cells)
            CHECK_CELLS=0
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ "$CHECK_DBSERVERS" -eq 0 ] && [ "$CHECK_CELLS" -eq 0 ]; then
    echo "ERROR: Both database server and storage server checks are disabled." >&2
    exit 2
fi

version_ge() {
    local candidate=$1
    local required=$2
    local IFS=.
    local -a candidate_parts required_parts
    local max_parts i left right

    read -r -a candidate_parts <<< "$candidate"
    read -r -a required_parts <<< "$required"

    max_parts=${#candidate_parts[@]}
    if [ "${#required_parts[@]}" -gt "$max_parts" ]; then
        max_parts=${#required_parts[@]}
    fi

    for ((i = 0; i < max_parts; i++)); do
        left=${candidate_parts[$i]:-0}
        right=${required_parts[$i]:-0}

        if ((10#$left > 10#$right)); then
            return 0
        fi
        if ((10#$left < 10#$right)); then
            return 1
        fi
    done

    return 0
}

extract_version() {
    grep -Eo '[0-9]+([.][0-9]+)+' | tail -n 1
}

require_file() {
    local path=$1
    local description=$2

    if [ ! -r "$path" ]; then
        echo "ERROR: Cannot read ${description}: ${path}" >&2
        exit 1
    fi
}

temporary_group_files=

cleanup() {
    local file

    for file in $temporary_group_files; do
        [ -n "$file" ] && [ -f "$file" ] && rm -f "$file"
    done
}

trap cleanup EXIT

create_group_file_from_nodes() {
    local nodes=$1
    local label=$2
    local group_file node
    local -a node_list

    group_file=$(mktemp "${TMPDIR:-/tmp}/exadata-${label}-group.XXXXXX")
    temporary_group_files="${temporary_group_files} ${group_file}"

    IFS=, read -r -a node_list <<< "$nodes"
    for node in "${node_list[@]}"; do
        node=${node#"${node%%[![:space:]]*}"}
        node=${node%"${node##*[![:space:]]}"}
        if [ -n "$node" ]; then
            printf '%s\n' "$node" >> "$group_file"
        fi
    done

    if [ ! -s "$group_file" ]; then
        echo "ERROR: ${label} node list did not contain any host names." >&2
        exit 1
    fi

    printf '%s\n' "$group_file"
}

resolve_group_file() {
    local group_file=$1
    local nodes=$2
    local label=$3

    if [ -n "$group_file" ] && [ -n "$nodes" ]; then
        echo "ERROR: Specify either ${label} group file or ${label} node list, not both." >&2
        exit 2
    fi

    if [ -n "$group_file" ]; then
        require_file "$group_file" "${label} group file"
        printf '%s\n' "$group_file"
        return 0
    fi

    if [ -n "$nodes" ]; then
        create_group_file_from_nodes "$nodes" "$label"
        return 0
    fi

    echo "ERROR: Specify --${label}-group or --${label}-nodes." >&2
    exit 2
}

run_dcli_check() {
    local label=$1
    local group_file=$2
    local ssh_user=$3
    local remote_command=$4
    local output line version failures

    echo
    echo "Checking ${label}"
    echo "Group file: ${group_file}"
    echo "Remote user: ${ssh_user}"

    if ! output=$("$DCLI_BIN" -g "$group_file" -l "$ssh_user" "$remote_command" 2>&1); then
        echo "$output"
        echo "FAIL: dcli could not complete ${label} check." >&2
        return 1
    fi

    echo "$output"

    failures=0
    while IFS= read -r line; do
        version=$(printf '%s\n' "$line" | extract_version)

        if [ -z "$version" ]; then
            echo "WARN: Could not identify a version in output line: $line" >&2
            failures=$((failures + 1))
            continue
        fi

        if version_ge "$version" "$MIN_EXADATA_VERSION"; then
            echo "PASS: ${label} reports ${version}, which meets ${MIN_EXADATA_VERSION} or later."
        else
            echo "FAIL: ${label} reports ${version}, which is below ${MIN_EXADATA_VERSION}." >&2
            failures=$((failures + 1))
        fi
    done <<< "$output"

    if [ "$failures" -gt 0 ]; then
        return 1
    fi

    return 0
}

echo "Exadata System Software pre-flight check"
echo "Minimum required version: ${MIN_EXADATA_VERSION}"

overall_status=0

if [ "$CHECK_DBSERVERS" -eq 1 ]; then
    if DBS_GROUP=$(resolve_group_file "$DBS_GROUP" "$DBS_NODES" "dbs"); then
        :
    else
        exit $?
    fi
fi

if [ "$CHECK_CELLS" -eq 1 ]; then
    if CELLS_GROUP=$(resolve_group_file "$CELLS_GROUP" "$CELLS_NODES" "cells"); then
        :
    else
        exit $?
    fi
fi

if ! command -v "$DCLI_BIN" >/dev/null 2>&1; then
    echo "ERROR: dcli was not found. Set DCLI_BIN or run this script from an Exadata node with dcli available." >&2
    exit 1
fi

if [ "$CHECK_DBSERVERS" -eq 1 ]; then
    if ! run_dcli_check \
        "database server software" \
        "$DBS_GROUP" \
        "$DBS_USER" \
        "sudo -n dbmcli -e 'list dbserver attributes name,releaseVersion'"; then
        overall_status=1
    fi
fi

if [ "$CHECK_CELLS" -eq 1 ]; then
    if ! run_dcli_check \
        "storage server software" \
        "$CELLS_GROUP" \
        "$CELLS_USER" \
        "cellcli -e 'list cell attributes name,releaseVersion'"; then
        overall_status=1
    fi
fi

echo
if [ "$overall_status" -eq 0 ]; then
    echo "READY: Exadata System Software version checks passed."
else
    echo "NOT READY: One or more Exadata System Software version checks failed." >&2
fi

exit "$overall_status"
