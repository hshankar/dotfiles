#!/bin/bash

# Example: Installing dotfiles in a Docker container or CI environment

# Set your Git configuration
export GIT_NAME="Your Name"
export GIT_EMAIL="your@email.com"
export GITHUB_USER="your-github-username"

# Configure for non-interactive mode
export NON_INTERACTIVE="true"

# For Linux containers without sudo
export SUDO="false"

# Install dotfiles
curl -fsSL https://raw.githubusercontent.com/hshankar/dotfiles/main/install.sh | bash

# Start a zsh login shell to pick up the new configuration
exec zsh -l