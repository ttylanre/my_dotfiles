# EndeavourOS / Arch Linux Niri Wayland Dotfiles

[![CI](https://img.shields.io/github/actions/workflow/status/tty-lanre/my_dotfiles/dotfiles.yml?label=CI&logo=github)](https://github.com/lanre647/my_dotfiles/actions)
[![License](https://img.shields.io/github/license/tty-lanre/my_dotfiles?label=license)](LICENSE)
[![GNU Stow](https://img.shields.io/badge/managed%20with-GNU%20Stow-green)](https://www.gnu.org/software/stow/)
[![Wayland](https://img.shields.io/badge/session-Wayland-4c7899)](#desktop-stack)

A reproducible **EndeavourOS and Arch Linux Niri Wayland rice** with
developer-focused dotfiles, managed through GNU Stow.

It includes a Catppuccin Mocha desktop built around **Niri**, **Waybar**,
**Fuzzel**, **Kitty**, **Mako**, and **swaylock**, plus a terminal workflow
with **Neovim**, **Tmux**, **Zsh**, Git, Starship, and CLI utilities.

> [!WARNING]
> This repository is personal but designed to be reusable. Review the scripts
> and use `--dry-run` before applying it to a system with existing dotfiles.
> The installer creates links and intentionally does not overwrite conflicts.

## Screenshots

### Niri Wayland workspace

![Niri Wayland desktop on EndeavourOS using Waybar and the Catppuccin Mocha theme](./screenshots/hero.webp)

### Neovim development workflow

![Neovim configuration with Kitty terminal and Tmux on EndeavourOS](./screenshots/editor.webp)

### Linux terminal utilities

![Fuzzel, Fastfetch, htop, cava, nmtui, and CLI tools in the dotfiles setup](./screenshots/utilities.webp)

## Quick start

Requirements for the remote bootstrap: Bash, Git, and an internet connection. It clones into `~/.dotfiles`, initializes the bundled submodules, installs missing base tools, and links all packages.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tty-lanre/my_dotfiles/main/bootstrap.sh)
```

Review the installer actions first with a local checkout:

```bash
git clone --recurse-submodules https://github.com/tty-lanre/my_dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --dry-run
./install.sh
```

The interactive installer asks before installing missing base tools. `--yes` enables package installation without prompting; `--no-packages` skips it. Supported package managers are apt, pacman, dnf, Homebrew, and Termux `pkg`. On a machine without one of these, install GNU Stow, Git, tmux, zsh, and Vim yourself.

## Selecting packages

By default, every available Stow package is linked, including the desktop-specific Niri, Waybar, X11, and swaylock configs. Limit the change to one or more packages if appropriate:

```bash
./install.sh --package nvim --package git --no-packages
./install.sh --list
./install.sh --target "$HOME/test-dotfiles" --dry-run
```

Packages are `bin`, `clipmenu`, `dunst`, `fastfetch`, `fuzzel`, `git`, `kitty`, `lazygit`, `mako`, `niri`, `nvim`, `picom`, `scripts`, `starship`, `swaylock`, `tmux`, `vim`, `waybar`, `x11`, and `zsh`.

GNU Stow's conflict checks are intentional: if a target file already exists and is not one of these dotfiles' links, Stow reports the conflict and leaves it in place. Back up or move the conflicting file yourself, then rerun the installer. Re-running the installer updates existing links.

## What gets linked

- Most packages map their directory contents into `$HOME` (for example, `nvim/.config/nvim` maps to `~/.config/nvim`).
- `scripts` is linked into `~/bin`; `bin` is linked into `~/.local/bin`.
- `.config` is kept as a normal directory. Stow uses `--no-folding` so unrelated files under it are not hidden by a directory symlink.
- Tmux Plugin Manager is included as a Git submodule. The tmux config can install TPM/plugins on first launch; plugin downloads require network access.

## Requirements and optional applications

The installer only installs the base tools needed for Stow and the main terminal configs: GNU Stow, Git, tmux, zsh, and Vim. Desktop environments and their programs have additional dependencies that vary by package (for example Niri, Kitty, fuzzel, Waybar, and wallpaper utilities); install those with your system's package manager as needed.

Zsh starts without Oh My Zsh if it is not installed. Starship, zoxide, fzf, fnm, eza, and custom Oh My Zsh plugins are optional and initialized only when available. Some aliases and desktop keybindings still require their corresponding applications.

## Uninstalling links

From the repository root, remove links for selected packages with Stow:

```bash
stow --dir="$PWD" --target="$HOME" --delete nvim git
stow --dir="$PWD" --target="$HOME/bin" --delete scripts
```

This removes links only; it does not uninstall applications or delete user data.

## Repository layout

Each top-level config directory is a Stow package. The `scripts/` package has a separate target (`~/bin`); `pkgs/` contains package lists and is not linked.

## License

MIT — use it, fork it, improve it.
