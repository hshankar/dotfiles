# Quick Setup

## One-line installation (recommended for new hosts):

```bash
curl -fsSL https://raw.githubusercontent.com/hshankar/dotfiles/main/install.sh -o /tmp/df-install.sh && bash /tmp/df-install.sh
```

> Note: download-then-run (rather than `curl … | bash`) so the installer's
> interactive prompts (git name/email, sudo, default shell) can read from
> your terminal. If you prefer a fully non-interactive run, set the
> environment variables documented under [Automated/Non-Interactive
> Installation](#automatednon-interactive-installation) instead.

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
- **Linux**: supported on **Debian/Ubuntu** (apt). Other distributions (Fedora/RHEL yum/dnf, Arch, Alpine, etc.) are not currently supported by the Makefile's `linux` target, which calls `apt-get` directly. The `linux-no-sudo` target (manual symlinks, no package installs) works on any Linux distro with zsh installed.

## Automated/Non-Interactive Installation

For CI/CD, Docker, or other automated environments:

```bash
# Set environment variables for Git config
export GIT_NAME="Your Name"
export GIT_EMAIL="your@email.com"
export GITHUB_USER="your-github-username"

# For Linux: specify sudo availability
export SUDO="true"   # or "false" for no sudo

# Enable non-interactive mode
export NON_INTERACTIVE="true"

# Run installation
curl -fsSL https://raw.githubusercontent.com/hshankar/dotfiles/main/install.sh | bash
```

### Environment Variables:

- `GIT_NAME` - Your full name for Git config
- `GIT_EMAIL` - Your email for Git config  
- `GITHUB_USER` - Your GitHub username
- `SUDO` - "true" or "false" for Linux sudo availability
- `NON_INTERACTIVE` - "true" to skip all prompts

### Multi-user hosts (non-root user after a root install)

The install is per-user: it clones to `~/.dotfiles` and links into `~/`.
If an administrator ran the install as root, the prerequisites (zsh, stow,
git, curl) are installed system-wide, but each non-root user still needs to
run the installer as themselves to get their own shell config. Because the
prerequisites are already present, a non-root user can run with `SUDO=false`
(no sudo needed):

```bash
export NON_INTERACTIVE=true SUDO=false \
       GIT_NAME="Your Name" GIT_EMAIL="your@email.com" GITHUB_USER="your-github"
curl -fsSL https://raw.githubusercontent.com/hshankar/dotfiles/main/install.sh | bash
```

> The variables must be `export`ed (or placed before `bash`, not `curl`) so the
> `bash` running the script inherits them — `VAR=val curl ... | bash` sets them
> only for `curl`, which ignores them.

The installer detects the already-present tools and skips the package-manager
step entirely. To set that user's default login shell (which requires sudo or
root), an administrator runs:

```bash
sudo chsh -s "$(command -v zsh)" <username>
```

## Credits

Credits to webpro at https://github.com/webpro/dotfiles/tree/main for the initial template
webpro's guide: [be the king of your castle!](https://www.webpro.nl/articles/getting-started-with-dotfiles)