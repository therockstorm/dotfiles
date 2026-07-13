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
`brew bundle --file ~/dev/dotfiles/Brewfile`. `mise bootstrap status` shows
mise-managed drift. If a real file already exists at a symlink target, add
`--force-dotfiles`.

## How it's layered

- `Brewfile`: system formulae, casks, and third-party taps.
- `.config/mise/config.toml`: Node, dotfiles, macOS defaults, repositories,
  and bootstrap orchestration.
- Native installers: Claude Code and Codex, so their updates land promptly.

Manual steps not yet automated:

- Install sbx, Little Snitch, and the App Store apps Amphetamine and NextDNS.
  Little Snitch remains manual because its system extension needs approval.
- Optionally run `bin/remove-preinstalled-apps` once to delete the iLife/iWork
  suite (prompts before deleting; SIP-protected apps can only be hidden).
- System Settings > Displays > Night Shift > Schedule.

## Agent notes

For an AI agent: run the Installation one-liner. A human must accept the
Command Line Tools dialog, enter an administrator password for Homebrew, and
complete any vendor installer or permission prompts (notably Backblaze and AWS
VPN Client). Add `--force-dotfiles` when targets exist as real files. Verify
with `mise bootstrap status` (no missing entries),
`brew bundle check --file ~/dev/dotfiles/Brewfile` and
`zsh -ic 'starship --version'`.

## Work machines

Employer setup layers its own Brewfile and mise config into the same run.
Homebrew deduplicates packages shared by both Brewfiles; the mise layers remain
disjoint. `.zshrc` supports the layering with two optional sources: the
employer shell config (only its path is hardcoded; inert on personal machines)
and `~/.zshrc.local` for untracked machine-specific config (work
exports/aliases, machine paths).

## Migrating from an old machine

These files are deliberately untracked — work-internal references and
1Password pointer files don't belong in a public repo. Copy them across
once; everything else converges from this repo:

- `~/.zshrc.local` — work exports and aliases (update any repo paths if the
  new machine's layout differs)
- `~/.config/op/*.env` — work 1Password scopes (skip `npm.env`; the employer
  bootstrap writes it)
- `~/.config/groundcrew/`
- `~/.config/clearance/personal-allow-hosts`
- Codex: re-set `model`, `model_reasoning_effort`, and `personality` in
  `~/.codex/config.toml`; the rest of that file is machine-appended state
