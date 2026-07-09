# Quick Setup

## One-line installation (recommended for new hosts):

```bash
curl -fsSL https://raw.githubusercontent.com/hshankar/dotfiles/main/install.sh -o /tmp/df-install.sh && bash /tmp/df-install.sh
```

> Note: download-then-run gives you the interactive prompts (git identity,
> sudo password, default shell). `curl … | bash` also works — it runs
> non-interactively with sensible defaults (identity left unset, sudo
> auto-detected, default shell unchanged with a hint printed). See
> [Automated/Non-Interactive Installation](#automatednon-interactive-installation).

## Manual installation:

1. Clone the repository:
```bash
git clone https://github.com/hshankar/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2. Run the installation:
```bash
make all
```

## Installation Options

- `make all` - Full installation (default)
- `make minimal` - Only Oh My Zsh and config files
- `make packages-only` - Only Homebrew packages and apps
- `make config-only` - Only configuration files
- `make linux-no-sudo` - Linux installation without sudo (no package installs)

## What gets installed:

- **Shell**: Oh My Zsh with custom theme
- **Package Manager**: Homebrew (macOS) or apt packages (Linux)
- **CLI Tools**: git, tmux, ripgrep, fzf, etc.
- **Applications**: VS Code, VLC, Obsidian (cross-platform); TextMate (macOS only)
- **Configuration**: Git, Vim, Zsh, Tmux configs

## Platform support

- **macOS**: fully supported (Homebrew + casks, duti defaults, osxkeychain credential helper).
- **Linux**: supported on **Debian/Ubuntu** (apt), **Fedora/RHEL/CentOS** (dnf/yum). stow is in EPEL on RHEL/CentOS and is enabled automatically. The `linux-no-sudo` target (manual symlinks, no package installs) is used automatically when sudo is unavailable, and works on any Linux distro with zsh installed.

## Automated/Non-Interactive Installation

For CI/CD, Docker, or other automated environments, pipe straight into bash —
it runs non-interactively with sensible defaults (no flags required):

```bash
curl -fsSL https://raw.githubusercontent.com/hshankar/dotfiles/main/install.sh | bash
```

Git identity is optional. Set it only if you want it configured during install;
otherwise the shared git config is still installed and a reminder is printed
(set it later with `git config --global user.name` / `user.email`).

```bash
export GIT_NAME="Your Name" GIT_EMAIL="your@email.com"
curl -fsSL https://raw.githubusercontent.com/hshankar/dotfiles/main/install.sh | bash
```

> The variables must be `export`ed (or placed before `bash`, not `curl`) so the
> `bash` running the script inherits them — `VAR=val curl ... | bash` sets them
> only for `curl`, which ignores them.

### Environment Variables:

- `GIT_NAME` - (optional) Your full name for Git config
- `GIT_EMAIL` - (optional) Your email for Git config

There are no `NON_INTERACTIVE` or `SUDO` flags: interactivity is detected from
whether stdin is a terminal, and sudo is auto-detected via `sudo -n true`
(full install with package installs if usable or if a terminal is available
for a sudo password prompt; otherwise a no-sudo manual-symlink path).

### Multi-user hosts (non-root user after a root install)

The install is per-user: it clones to `~/.dotfiles` and links into `~/`.
If an administrator ran the install as root, the prerequisites (zsh, stow,
git, curl) are installed system-wide, but each non-root user still needs to
run the installer as themselves to get their own shell config. Because the
prerequisites are already present, a non-root user can run without any sudo
(sudo is auto-detected; without it, the no-sudo install path is used):

```bash
export GIT_NAME="Your Name" GIT_EMAIL="your@email.com"
curl -fsSL https://raw.githubusercontent.com/hshankar/dotfiles/main/install.sh | bash
```

> On Linux, sudo is auto-detected; a non-root user without sudo automatically
> gets the no-sudo install path (manual symlinks). The variables must be
> `export`ed (or placed before `bash`, not `curl`) so the `bash` running the
> script inherits them.

The installer detects the already-present tools and skips the package-manager
step entirely. To set that user's default login shell (which requires sudo or
root), an administrator runs:

```bash
sudo chsh -s "$(command -v zsh)" <username>
```

## Credits

Credits to webpro at https://github.com/webpro/dotfiles/tree/main for the initial template
webpro's guide: [be the king of your castle!](https://www.webpro.nl/articles/getting-started-with-dotfiles)