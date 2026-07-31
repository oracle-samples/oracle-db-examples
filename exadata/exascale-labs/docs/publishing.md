# Publishing a Public Snapshot

The internal repository is the source of truth. The public repository receives
reviewed snapshots under `exadata/exascale-labs/`.

## Release Process

1. Merge the internal release changes to `main` and create an annotated tag.
2. Start from a clean local clone of `alex-blyth-pm/oracle-db-examples`.
3. Run the publication script from the internal repository:

   ```bash
   tools/publish-public-snapshot.sh \
     --tag v0.2.2 \
     --public-repo /path/to/oracle-db-examples
   ```

4. Review the prepared public branch, commit it, push it, and open a pull request to public `main`.
5. After the public pull request merges, create an annotated tag named
   `exadata-exascale-labs-v0.2.2` on the public merge commit.

## Safeguards

The script requires an annotated source tag and a clean public clone. It exports
the tagged source with `docs/blogs/` excluded, replaces only the public labs
directory, records the internal tag and commit in `PUBLICATION.md`, and runs
Git whitespace validation. It does not commit, push, or open pull requests.

Use `--dry-run` to validate the export without changing the public clone.
