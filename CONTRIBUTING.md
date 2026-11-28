# Contributing to DropTerm

Thanks for taking an interest. Issues and pull requests are both welcome; this file covers the bar they are held to.

## Reporting a bug

- Search [the issue tracker](https://github.com/l1br3-io/dropterm/issues) and [known issues](docs/known-issues.md) first - what you found may already be documented with a workaround.
- Include the DropTerm version, the desktop environment and compositor, and how to reproduce. Terminal-content cases (escape sequences, shell integration) ideally name the sequence emitted.
- Anything you believe is exploitable goes through [SECURITY.md](SECURITY.md), not the public tracker.

## Development setup

The [Development](docs/development.md) page is the full guide; the short version:

- Rust stable via [rustup](https://rustup.rs/) and `just` itself; `just deps` checks and installs the build prerequisites through the system package manager.
- `just dev-install` plus the `dropterm-dev` launcher gives you the dev loop with a fully isolated dev identity - config, state, and D-Bus name never touch an installed release (see [Development](docs/development.md)).
- `just check` is the bar: fmt-check, clippy, tests, and the docs link checker. It is silent on green; a failed gate prints what failed.
- Runtime behavior is only testable on real Wayland desktops; the manual checklist in [Testing](docs/testing.md) is walked by the maintainers on release trees. Unit tests cover what runs headless - write them for your change, inline in `#[cfg(test)] mod tests`.

## Pull requests

- Small and atomic: one logical change per PR, with conventional commit subjects (`feat:`, `fix:`, `docs:`, `chore:`) - the release tooling reads them to derive versions.
- Every shipped feature carries its docs: a `docs/` page or section linked from README's Documentation index, and any new config key documented in `docs/configuration.md` (a test enforces the latter; `just check` catches it).
- The `SPEC.md`/`tasks/` planning set referenced in some history is local working state and gitignored; PR descriptions carry their own context, and reviewers should not ask for the set.
- Contributions are licensed under the project's license, GPL-3.0-only. Opening a PR is agreement to that, under GitHub's standard terms - there is no CLA or DCO beyond it.

## AI policy

AI-assisted contributions are welcome, with the same bar as any change: a human in the loop who genuinely understands the work. Adapted from [Zed's AI policy](https://github.com/zed-industries/zed/blob/main/CONTRIBUTING.md#ai-policy), which adapts ripgrep's:

- LLMs may help write code, but you submitted the PR, so you own it - every line, why it is there, and what the tests cover. "The model wrote it" is not an answer to a review question.
- No fully autonomous agents. PRs that look like unattended agent output - nobody able to explain the change, bulk-generated commit trails, multi-feature dumps - may be closed without notice.
- Write your own communications. PR descriptions, issue comments, and review replies are the conversation with the maintainer; keep them your words.
- Machine translation is fine for non-native English speakers: put the translation in a quote block and keep your original-language text after it.
- Sharing LLM chat context as evidence in an issue: quote only the relevant part, say it is AI-generated, and add your own note on why it matters.
