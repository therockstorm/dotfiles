# dotfiles

Machine configuration, converged by [mise](https://mise.jdx.dev/): packages
(Homebrew formulae/casks and App Store apps), dotfile symlinks, macOS
defaults, and login agents are all declared in `.config/mise/config.toml`.

## Installation

```sh
curl -fsSL https://mise.run | sh && export PATH="$HOME/.local/bin:$PATH"
git clone https://github.com/therockstorm/dotfiles.git ~/dev/dotfiles
mkdir -p ~/.config/mise
ln -s ~/dev/dotfiles/.config/mise/config.toml ~/.config/mise/config.toml
mise bootstrap --yes
```

The seed `ln -s` exists because mise can't symlink its own config before
reading it; every other symlink is declared in `[dotfiles]`. Re-run
`mise bootstrap` any time to converge; `mise bootstrap status` shows drift.
If a real file already exists at a symlink target, add `--force-dotfiles`.

Manual steps not yet automated:

- Sign into the App Store before the first run so `mas:` apps install.
- Install Backblaze, sbx, Cotypist, AWS VPN Client, and Little Snitch (see
  notes in `.config/mise/config.toml`).
- Optionally run `bin/remove-preinstalled-apps` once to delete the iLife/iWork
  suite (prompts before deleting; SIP-protected apps can only be hidden).
- System Settings > Displays > Night Shift > Schedule.

## Agent notes

For an AI agent: the Installation block above is fully scriptable except
signing into the App Store (required before `mas:` packages install — skipped
entries converge on re-run). Add `--force-dotfiles` when targets exist as
real files. Verify with `mise bootstrap status` (no missing entries) and
`zsh -ic 'starship --version'`.

## Work machines

Employer setup layers its own mise config into the same run. Ownership stays
disjoint — work-standard packages live in the work config, everything
personal lives here — so the layers never conflict and this repo works the
same with or without it. `.zshrc` supports the layering with two optional
sources: the employer shell config (only its path is hardcoded; inert on
personal machines) and `~/.zshrc.local` for untracked machine-specific
config (work exports/aliases, machine paths).

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
