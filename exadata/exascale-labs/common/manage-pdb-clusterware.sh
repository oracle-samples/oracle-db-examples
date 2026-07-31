#!/usr/bin/env bash
#
# Manage workshop PDB resources and services with Oracle Clusterware.
#
# SQL scripts retain PDB creation, snapshot, clone, refresh, and drop DDL.
# Use this helper for routine PDB availability and service placement.

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
config_file=${PDB_CLUSTERWARE_CONFIG:-"$script_dir/config.sql"}
srvctl_bin=${SRVCTL_BIN:-srvctl}

usage() {
    cat <<USAGE
Usage: $0 <command> <pdb>[,<pdb>...]

Commands:
  ensure-and-start  Create missing PDB resources and services, then start both.
  stop-and-remove   Stop and remove services and PDB resources when present.
  verify            Report PDB resource, service, and RAC placement status.

Configuration comes from common/config.sql. Set CDB_UNIQUE_NAME to the target
CDB DB_UNIQUE_NAME before running this utility. With the default AUTO placement,
also set RAC_SERVICE_PREFERRED to the comma-separated RAC instance list. Override
the srvctl executable with SRVCTL_BIN when it is not on PATH.
USAGE
}

config_value() {
    local name=$1

    awk -v name="$name" '
        $1 == "DEFINE" && $2 == name {
            value = $0
            sub(/^[^=]*=[[:space:]]*/, "", value)
            sub(/[[:space:]]*--.*/, "", value)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            print value
            exit
        }
    ' "$config_file"
}

require_config() {
    local name=$1
    local value

    value=$(config_value "$name")
    if [ -z "$value" ] || [[ "$value" == TODO_* ]]; then
        echo "ERROR: Set ${name} in ${config_file} before running this command." >&2
        exit 2
    fi
    printf '%s\n' "$value"
}

require_binary() {
    if ! command -v "$srvctl_bin" >/dev/null 2>&1; then
        echo "ERROR: srvctl was not found. Set SRVCTL_BIN or run from the Oracle Grid or database environment." >&2
        exit 1
    fi
}

pdb_service_name() {
    local pdb_name=$1
    local configured_pdb configured_service
    local -a prefixes=(MAIN_PDB DEV_CLONE_1 DEV_CLONE_2 DEV_CLONE_CHILD QA_PDB CI_PDB)
    local prefix

    for prefix in "${prefixes[@]}"; do
        configured_pdb=$(require_config "$prefix")
        if [ "$pdb_name" = "$configured_pdb" ]; then
            configured_service=$(require_config "${prefix}_SERVICE")
            printf '%s\n' "$configured_service"
            return 0
        fi
    done

    echo "ERROR: ${pdb_name} is not a configured workshop PDB in ${config_file}." >&2
    return 1
}

pdb_resource_exists() {
    "$srvctl_bin" config pdb -db "$cdb_unique_name" -pdb "$1" >/dev/null 2>&1
}

service_exists() {
    "$srvctl_bin" config service -db "$cdb_unique_name" -service "$1" >/dev/null 2>&1
}

pdb_is_running() {
    local output

    output=$("$srvctl_bin" status pdb -db "$cdb_unique_name" -pdb "$1" -detail 2>&1) || true
    printf '%s\n' "$output" | grep -Eqi 'is running|running on'
}

service_is_running() {
    local output

    output=$("$srvctl_bin" status service -db "$cdb_unique_name" -service "$1" -verbose 2>&1) || true
    printf '%s\n' "$output" | grep -Eqi 'is running|running on'
}

start_pdb_if_needed() {
    local pdb_name=$1

    if pdb_is_running "$pdb_name"; then
        echo "PDB resource already running: ${pdb_name}"
    else
        "$srvctl_bin" start pdb -db "$cdb_unique_name" -pdb "$pdb_name"
    fi
}

start_service_if_needed() {
    local service_name=$1

    if service_is_running "$service_name"; then
        echo "PDB service already running: ${service_name}"
    else
        "$srvctl_bin" start service -db "$cdb_unique_name" -service "$service_name"
    fi
}

ensure_and_start() {
    local pdb_name=$1
    local service_name

    service_name=$(pdb_service_name "$pdb_name")

    if ! pdb_resource_exists "$pdb_name"; then
        echo "Adding Clusterware PDB resource: ${pdb_name}"
        if [ "$pdb_placement" = ALL ]; then
            "$srvctl_bin" add pdb -db "$cdb_unique_name" -pdb "$pdb_name" \
                -cardinality ALL -policy AUTOMATIC
        else
            "$srvctl_bin" add pdb -db "$cdb_unique_name" -pdb "$pdb_name" \
                -policy AUTOMATIC
        fi
    else
        echo "PDB resource already exists: ${pdb_name}"
    fi

    if ! service_exists "$service_name"; then
        echo "Adding PDB service: ${service_name}"
        if [ "$pdb_placement" = ALL ]; then
            "$srvctl_bin" add service -db "$cdb_unique_name" -service "$service_name" \
                -pdb "$pdb_name" -cardinality "$service_cardinality" -policy AUTOMATIC
        else
            "$srvctl_bin" add service -db "$cdb_unique_name" -service "$service_name" \
                -pdb "$pdb_name" -preferred "$service_preferred" -policy AUTOMATIC
        fi
    else
        echo "PDB service already exists: ${service_name}"
    fi

    start_pdb_if_needed "$pdb_name"
    start_service_if_needed "$service_name"
}

stop_and_remove() {
    local pdb_name=$1
    local service_name

    service_name=$(pdb_service_name "$pdb_name")

    if service_exists "$service_name"; then
        echo "Stopping and removing PDB service: ${service_name}"
        "$srvctl_bin" stop service -db "$cdb_unique_name" -service "$service_name" \
            -stopoption IMMEDIATE -drain_timeout 0 || true
        "$srvctl_bin" remove service -db "$cdb_unique_name" -service "$service_name" -force
    else
        echo "PDB service not configured: ${service_name}"
    fi

    if pdb_resource_exists "$pdb_name"; then
        echo "Stopping and removing Clusterware PDB resource: ${pdb_name}"
        "$srvctl_bin" stop pdb -db "$cdb_unique_name" -pdb "$pdb_name" \
            -stopoption IMMEDIATE -drain_timeout 0 -stopsvcoption IMMEDIATE || true
        "$srvctl_bin" remove pdb -db "$cdb_unique_name" -pdb "$pdb_name" -force
    else
        echo "PDB resource not configured: ${pdb_name}"
    fi
}

verify() {
    local pdb_name=$1
    local service_name

    service_name=$(pdb_service_name "$pdb_name")
    echo
    echo "PDB resource: ${pdb_name}"
    if pdb_resource_exists "$pdb_name"; then
        echo "Expected placement: ${pdb_placement}"
        "$srvctl_bin" config pdb -db "$cdb_unique_name" -pdb "$pdb_name"
        "$srvctl_bin" status pdb -db "$cdb_unique_name" -pdb "$pdb_name" -detail
    else
        echo "NOT CONFIGURED"
    fi

    echo "PDB service: ${service_name}"
    if service_exists "$service_name"; then
        if [ "$pdb_placement" = ALL ]; then
            echo "Expected service cardinality: ${service_cardinality}"
        else
            echo "Expected preferred instances: ${service_preferred}"
        fi
        "$srvctl_bin" config service -db "$cdb_unique_name" -service "$service_name"
        "$srvctl_bin" status service -db "$cdb_unique_name" -service "$service_name" -verbose
    else
        echo "NOT CONFIGURED"
    fi
}

if [ "$#" -eq 1 ] && { [ "$1" = -h ] || [ "$1" = --help ]; }; then
    usage
    exit 0
fi

if [ "$#" -ne 2 ]; then
    usage >&2
    exit 2
fi

command_name=$1
IFS=, read -r -a pdb_names <<< "$2"
if [ "${#pdb_names[@]}" -eq 0 ]; then
    echo "ERROR: Specify at least one PDB." >&2
    exit 2
fi

require_binary
cdb_unique_name=${CDB_UNIQUE_NAME:-$(require_config CDB_UNIQUE_NAME)}
pdb_placement=${RAC_PDB_PLACEMENT:-$(require_config RAC_PDB_PLACEMENT)}
service_cardinality=$(require_config RAC_SERVICE_CARDINALITY)

case "$pdb_placement" in
    AUTO)
        service_preferred=${RAC_SERVICE_PREFERRED:-$(require_config RAC_SERVICE_PREFERRED)}
        ;;
    ALL)
        service_preferred=
        ;;
    *)
        echo "ERROR: RAC_PDB_PLACEMENT in ${config_file} must be AUTO or ALL." >&2
        exit 2
        ;;
esac

for pdb_name in "${pdb_names[@]}"; do
    pdb_name=${pdb_name//[[:space:]]/}
    if [ -z "$pdb_name" ]; then
        echo "ERROR: PDB list contains an empty name." >&2
        exit 2
    fi

    case "$command_name" in
        ensure-and-start) ensure_and_start "$pdb_name" ;;
        stop-and-remove) stop_and_remove "$pdb_name" ;;
        verify) verify "$pdb_name" ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
done
