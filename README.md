# dotfiles

Machine configuration converged by Homebrew and
[mise](https://mise.jdx.dev/): Homebrew owns system packages and applications;
mise owns runtimes, dotfile symlinks, macOS defaults, repositories, and tasks.

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/therockstorm/dotfiles/master/install.sh | bash
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
- System Settings > Keyboard > Keyboard Shortcuts > Spotlight > turn off
  Spotlight shortcuts.

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
- `~/.config/groundcrew/`: config and allow-hosts files
