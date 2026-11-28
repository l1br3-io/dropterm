# Security Policy

DropTerm is a terminal emulator with shell access: take reports about it seriously.

## Supported versions

Only the latest tagged release receives security fixes. Development builds (`main`, the `-dev` images) are unsupported; verify a bug reproduces on the current release before reporting.

## Reporting

Use GitHub's private vulnerability reporting for this repository - **Security → Report a vulnerability** on [the repo's Security tab](https://github.com/l1br3-io/dropterm/security). Do not open a public issue for anything you believe is exploitable.

Include the version, the desktop environment, and a reproduction: a command sequence, an escape-sequence payload, or a config file that triggers it.

## Scope

In scope: everything that runs with the user's privileges - the PTY handling and terminal engine, escape-sequence parsing, the layer-shell surface behavior, config parsing (`config.ron`, `profiles.ron`, `keybinds.ron`, `completions.toml`), the D-Bus single-instance and CLI seams, and the release pipeline's artifacts (tarballs, checksums, signatures).

Out of scope: crashes or misbehavior without a security dimension (report those on the tracker), and anything requiring physical access or a malicious compositor.

## What happens next

This is a solo-maintained project; expect a first response within about a week. Confirmed issues are fixed and released on the normal cadence, and the reporter is credited in the release notes unless they ask not to be. There is no bug bounty and no formal embargo beyond standard responsible disclosure: please give a fix a reasonable head start before publishing details.
