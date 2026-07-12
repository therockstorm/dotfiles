# dotfiles

Machine configuration, converged by [mise](https://mise.jdx.dev/): packages
(Homebrew formulae/casks and App Store apps), dotfile symlinks, macOS
defaults, and login agents are all declared in `.config/mise/config.toml`.

## Installation

```sh
curl -fsSL https://mise.run | sh && export PATH="$HOME/.local/bin:$PATH"
git clone https://github.com/therockstorm/dotfiles.git ~/dev/trs/dotfiles
mkdir -p ~/.config/mise
ln -s ~/dev/trs/dotfiles/.config/mise/config.toml ~/.config/mise/config.toml
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
- System Settings > Displays > Night Shift > Schedule.

## Agent notes

For an AI agent: the Installation block above is fully scriptable except
signing into the App Store (required before `mas:` packages install — skipped
entries converge on re-run). Add `--force-dotfiles` when targets exist as
real files. Verify with `mise bootstrap status` (no missing entries) and
`zsh -ic 'starship --version'`.

## Work machines

Employer setup (e.g. Clipboard's `clipboard-bootstrap`) layers its own mise
config into the same run. Ownership stays disjoint — work-standard packages
live in the work config, everything personal lives here — so the layers
never conflict and this repo works the same with or without it.
