# Release signing keys

The release workflow signs `sha256sums` with an SSH key held in the
repository's `RELEASE_SIGN_KEY` secret, and publishes the signature as
`sha256sums.sig` next to the checksums. Users verify the checksums file
against this directory's `allowed_signers` before trusting the tarballs.
The signing step itself lives in
[release.yml](../.github/workflows/release.yml) (`Sign sha256sums`); the
release reference is [Releasing](../docs/development.md) in
`docs/development.md`.

## One-time setup (maintainer)

1. Generate a dedicated ed25519 key, using `dropterm-release` as the
   comment - the comment becomes the signature's principal, and the
   verify command below matches on it:

       ssh-keygen -t ed25519 -C dropterm-release -f dropterm-release-key

2. Commit the public half here as `release.pub`, and the
   allowed-signers file users verify against as `allowed_signers` - one
   line, the principal, then the public key's type and body copied from
   `dropterm-release-key.pub` (the comment is not part of the key):

       dropterm-release ssh-ed25519 AAAA...

3. Store the *private* key file's contents as the repository secret
   `RELEASE_SIGN_KEY` (Settings → Secrets and variables → Actions). The
   private key never touches git: nothing in the workflow echoes it, and
   the signing step keeps it in a `mktemp -d` directory that is deleted
   on exit.

A tag push without the secret fails the signing step rather than
publishing an unsigned release; a dry-run (`workflow_dispatch`) without
it assembles the set unsigned, with a notice.

## Verify a release (users)

From a release page, after downloading `sha256sums` and `sha256sums.sig`:

    curl -LO https://raw.githubusercontent.com/l1br3-io/dropterm/main/keys/allowed_signers
    ssh-keygen -Y verify -f allowed_signers -I dropterm-release \
      -s sha256sums.sig -n file < sha256sums

`Good "sha256sums" signature with ...` means the checksums are the ones
the signing key produced. Then verify the tarballs against those
checksums with `sha256sum -c --ignore-missing sha256sums`.
