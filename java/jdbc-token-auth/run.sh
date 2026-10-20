#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -f target/oracle-jdbc-token-auth-demo-1.0.0.jar ]]; then
  echo 'Build first: mvn -B verify' >&2
  exit 1
fi
exec java -cp 'target/oracle-jdbc-token-auth-demo-1.0.0.jar:target/lib/*' demo.TokenAuthDemo "$@"
