# Quick Setup

## One-line installation (recommended for new hosts):

```bash
curl -fsSL https://raw.githubusercontent.com/hshankar/dotfiles/main/install.sh | bash
```

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
- **Applications**: VS Code, VLC, Obsidian, TextMate
- **Configuration**: Git, Vim, Zsh, Tmux configs

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

## Credits

Credits to webpro at https://github.com/webpro/dotfiles/tree/main for the initial template
webpro's guide: [be the king of your castle!](https://www.webpro.nl/articles/getting-started-with-dotfiles)