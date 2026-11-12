# dotfiles

Machine configuration converged by Homebrew and
[mise](https://mise.jdx.dev/): Homebrew owns system packages and applications;
mise owns runtimes, dotfile symlinks, macOS defaults, repositories, and tasks.

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/therockstorm/dotfiles/main/install.sh | bash
```

Idempotent — rerun at any point. On a brand-new Mac it triggers Apple's
Command Line Tools dialog (accept it) and waits for that install to finish
before continuing. The script installs Homebrew and mise, clones this repo to
`~/dev/dotfiles`, seeds the one symlink mise can't create for itself
(`~/.config/mise/config.toml`), and hands off to `mise bootstrap --yes`.

Re-run `mise bootstrap` any time to converge; its final task runs
`brew bundle --no-upgrade --file ~/dev/dotfiles/Brewfile`. `mise bootstrap status` shows
mise-managed drift. If a real file already exists at a symlink target, add
`--force-dotfiles`.

## How it's layered

- `Brewfile`: system formulae, casks, and third-party taps.
- `.config/mise/config.toml`: Node, dotfiles, macOS defaults, repositories,
  and bootstrap orchestration.
- Native installers: Claude Code and Codex, so their updates land promptly.

Manual steps not yet automated:

- Install the App Store app Amphetamine.
- Optionally run `bin/remove-preinstalled-apps` once to delete the iLife/iWork
  suite (prompts before deleting; SIP-protected apps can only be hidden).
- System Settings > Displays > select More Space.
- System Settings > Displays > Night Shift > Schedule.
- System Settings > Keyboard > Keyboard Shortcuts > Spotlight > off.
- System Settings > Keyboard > Keyboard Shortcuts > Screenshots > off.
- Slack > Settings > Notifications > Sound & appearance > Show a badge on
  Slack's icon to indicate new activity: off.

## Git cleanup

`tidy-safe --recursive ~/dev` audits repositories without deleting anything.
Add `--apply --yes` to remove worktrees and branches with merge proof.

To also remove inactive worktrees while retaining their unmerged branches:

```sh
tidy-safe --recursive ~/dev --inactive-worktrees --apply --yes
```

This opt-in mode requires no Git activity in the preceding 24 hours and no
process with a working directory inside the worktree. It checks Git metadata
timestamps and uses `lsof`; if either check is unavailable, it keeps the worktree.
The activity checks apply to existing worktrees, including merged worktrees.
Missing directories retain the normal stale-registration cleanup policy.

Clean worktrees and partial removals with no unique surviving contents can be
removed when their exact commit remains on a local branch. Partial removals
with missing `.git` markers are repaired and rechecked before removal. Modified,
staged-only, or untracked data, locked worktrees, and Git operations remain
protected. Detached unmerged worktrees still require merge proof.

A rebase, bisect, or cherry-pick protects its affected branch. Unrelated merged
branches can still be cleaned up; if the operation's branch cannot be identified,
branch cleanup stays blocked. Cleanup revalidates candidates before deletion.

Run the cleanup regression tests with:

```sh
(for test in tests/tidy-safe*.test.zsh; do zsh "$test" || exit; done)
```

## Agent notes

For an AI agent: run the Installation one-liner. A human must accept the
Command Line Tools dialog, enter an administrator password for Homebrew, and
complete any vendor installer or permission prompts (notably Backblaze and AWS
VPN Client). Add `--force-dotfiles` when targets exist as real files. Verify
with `mise bootstrap status` (no missing entries),
`brew bundle check --no-upgrade --file ~/dev/dotfiles/Brewfile` and
`zsh -ic 'starship --version'`.

## Migrating from an old machine

These files are deliberately untracked. Copy them once:

- `~/.zshrc.local`: work exports and aliases (update repo path)
- `~/.config/op/*.env`: work 1Password scopes
- `~/.config/clipboard/`: work shell config sourced by `.zshrc`
- `~/.agents/AGENTS.local.md`: private agent instructions; shared instructions
  are symlinked from `.agents/AGENTS.md` in this repo
