#!/usr/bin/env bash

# Prepare a reviewable public-repository snapshot from an annotated release tag.
# The script intentionally does not commit, push, or create a pull request.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/publish-public-snapshot.sh --tag <release-tag> --public-repo <path> [options]

Required arguments:
  --tag <release-tag>       Annotated tag in this repository, for example v0.2.2.
  --public-repo <path>      Clean local clone of alex-blyth-pm/oracle-db-examples.

Options:
  --branch <branch>         Public release branch. Defaults to
                            exadata-exascale-labs-<release-tag>.
  --destination <path>      Destination within the public repository. Defaults to
                            exadata/exascale-labs.
  --dry-run                 Validate the source export without changing the public clone.
  --help                    Show this help text.

The script exports the tagged source with docs/blogs excluded, replaces only the
destination directory, updates publication metadata, and adds the landing-page
link when it is missing. Review, commit, push, and open the public pull request
after the script completes.
EOF
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

release_tag=''
public_repo=''
public_branch=''
destination='exadata/exascale-labs'
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      release_tag=${2:-}
      shift 2
      ;;
    --public-repo)
      public_repo=${2:-}
      shift 2
      ;;
    --branch)
      public_branch=${2:-}
      shift 2
      ;;
    --destination)
      destination=${2:-}
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      fail "Unknown argument: $1"
      ;;
  esac
done

[[ -n "$release_tag" ]] || fail '--tag is required.'
[[ -n "$public_repo" ]] || fail '--public-repo is required.'
[[ "$destination" == exadata/* && "$destination" != */../* && "$destination" != *'/..' ]] \
  || fail '--destination must be a relative path below exadata/.'

source_repo=$(git rev-parse --show-toplevel 2>/dev/null) \
  || fail 'Run this script from within the internal labs repository.'

[[ $(git -C "$source_repo" cat-file -t "$release_tag" 2>/dev/null || true) == tag ]] \
  || fail "${release_tag} must be an annotated tag."

source_commit=$(git -C "$source_repo" rev-parse "${release_tag}^{commit}")
release_version=$(git -C "$source_repo" show "${release_tag}:VERSION" 2>/dev/null | tr -d '[:space:]') \
  || fail "${release_tag} does not contain VERSION."

[[ -n "$release_version" ]] || fail "${release_tag} contains an empty VERSION."
[[ -d "$public_repo/.git" ]] || fail '--public-repo must be a local Git clone.'

public_repo=$(cd "$public_repo" && pwd)
[[ -n "$public_branch" ]] || public_branch="exadata-exascale-labs-${release_tag}"

if [[ "$dry_run" == false ]]; then
  if [[ -n $(git -C "$public_repo" status --porcelain) ]]; then
    fail 'The public repository has uncommitted or untracked files.'
  fi

  if [[ -n $(git -C "$public_repo" status --porcelain --ignored -- "$destination" | grep '^!!' || true) ]]; then
    fail "The public destination contains ignored files: ${destination}. Remove or relocate them first."
  fi
fi

staging_dir=$(mktemp -d "${TMPDIR:-/tmp}/exadata-exascale-export.XXXXXX")
cleanup() {
  rm -rf "$staging_dir"
}
trap cleanup EXIT

git -C "$source_repo" archive --format=tar "$release_tag" -- . ':(exclude)docs/blogs' \
  | tar -xf - -C "$staging_dir"

[[ ! -e "$staging_dir/docs/blogs" ]] \
  || fail 'The public export unexpectedly contains docs/blogs.'
[[ -f "$staging_dir/README.md" ]] || fail 'The source export does not contain README.md.'

if [[ "$dry_run" == true ]]; then
  printf 'Validated public export for %s (%s).\n' "$release_tag" "$source_commit"
  printf 'No changes were made to %s.\n' "$public_repo"
  exit 0
fi

git -C "$public_repo" fetch origin main

if git -C "$public_repo" show-ref --verify --quiet "refs/heads/${public_branch}"; then
  fail "Public branch already exists locally: ${public_branch}"
fi

git -C "$public_repo" switch -c "$public_branch" origin/main
git -C "$public_repo" rm -r --ignore-unmatch -- "$destination"
mkdir -p "$public_repo/$destination"

tar -C "$staging_dir" -cf - . | tar -C "$public_repo/$destination" -xf -
diff -qr "$staging_dir" "$public_repo/$destination"

publication_file="$public_repo/$destination/PUBLICATION.md"
printf '%s\n' \
  '# Publication Metadata' \
  '' \
  'This directory is a generated public snapshot of the Exadata Exascale Labs repository.' \
  '' \
  "- Internal release tag: \`${release_tag}\`" \
  "- Internal source commit: \`${source_commit}\`" \
  "- Release version: \`${release_version}\`" \
  "- Public destination: \`${destination}\`" \
  > "$publication_file"

landing_readme="$public_repo/exadata/README.md"
landing_link='- [Exadata Exascale Labs](./exascale-labs/) - Hands-on Oracle AI Database 26ai labs for Exadata Exascale snapshot and cloning workflows.'

[[ -f "$landing_readme" ]] || fail 'The public repository does not contain exadata/README.md.'

if ! grep -Fqx -- "$landing_link" "$landing_readme"; then
  landing_tmp=$(mktemp "${TMPDIR:-/tmp}/exadata-landing-readme.XXXXXX")
  awk -v link="$landing_link" '
    { print }
    !inserted && $0 == "## Examples" {
      getline
      print
      print link
      inserted = 1
    }
    END {
      if (!inserted) {
        exit 1
      }
    }
  ' "$landing_readme" > "$landing_tmp" \
    || fail 'Could not locate the Examples section in exadata/README.md.'
  mv "$landing_tmp" "$landing_readme"
fi

git -C "$public_repo" diff --check
[[ ! -e "$public_repo/$destination/docs/blogs" ]] \
  || fail 'The public destination contains docs/blogs after staging.'

printf 'Public release branch prepared: %s\n' "$public_branch"
printf 'Review changes with: git -C %s status --short\n' "$public_repo"
printf 'Then commit, push, and open a pull request to main.\n'
