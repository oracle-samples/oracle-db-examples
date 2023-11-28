#!/bin/bash

# set token
IDENTIFICATION=$(python get.py "$BRANCH_REF")
DBNAME=$(python clean_dbname.py "$IDENTIFICATION")

# kustomize remove if exists
if test -f "kustomization.yaml"; then
  rm kustomization.yaml
fi

# create patch
cat <<EOF > patch.yaml
- op: add # action
  path: "/spec/details/compartmentOCID"
  value: ${COMPARTMENT_OCID}
- op: add # action
  path: "/spec/details/dbName"
  value: db${DBNAME}
- op: add # action
  path: "/spec/details/displayName"
  value: dbtest-${IDENTIFICATION}
EOF