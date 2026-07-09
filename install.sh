#!/bin/bash

set -e

DOTFILES_REPO="https://github.com/hshankar/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect non-interactive stdin (e.g. `curl ... | bash`). When bash reads the
# script from a pipe, stdin is not a terminal and the interactive prompts
# (git name/email, sudo, chsh) would all hit EOF. Rather than failing
# partway through after cloning, bail out early with actionable guidance
# unless the caller has explicitly opted into non-interactive mode.
require_interactive_stdin() {
    [[ "$NON_INTERACTIVE" == "true" ]] && return 0
    if [[ ! -t 0 ]]; then
        log_error "This installer is interactive but stdin is not a terminal"
        log_error "(this happens with 'curl ... | bash')."
        log_error ""
        log_error "Either:"
        log_error "  1. Download then run so prompts can read your terminal:"
        log_error "     curl -fsSL https://raw.githubusercontent.com/hshankar/dotfiles/main/install.sh -o /tmp/df-install.sh && bash /tmp/df-install.sh"
        log_error ""
        log_error "  2. Or run non-interactively (identity is optional):"
        log_error "     export NON_INTERACTIVE=true"
        log_error "     curl -fsSL https://raw.githubusercontent.com/hshankar/dotfiles/main/install.sh | bash"
        log_error ""
        log_error "     (Vars must be exported, or placed before 'bash' not 'curl',"
        log_error "      because 'VAR=val curl | bash' sets them only for curl.)"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" =~ ^darwin ]]; then
        echo "macos"
    elif [[ "$OSTYPE" =~ ^linux ]]; then
        echo "linux"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

# Install prerequisites
install_prerequisites() {
    local os=$(detect_os)
    
    log_info "Installing prerequisites for $os..."
    
    if [[ "$os" == "macos" ]]; then
        # Install Xcode Command Line Tools if not present
        if ! command_exists xcode-select; then
            log_info "Installing Xcode Command Line Tools..."
            xcode-select --install
            log_warn "Please complete Xcode Command Line Tools installation and re-run this script"
            exit 1
        fi
        
        # Install Homebrew if not present
        if ! command_exists brew; then
            log_info "Installing Homebrew..."
            local homebrew_script="/tmp/homebrew-install.sh"
            log_info "Downloading Homebrew installer..."
            curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$homebrew_script"
            if [[ ! -f "$homebrew_script" ]]; then
                log_error "Failed to download Homebrew installer"
                exit 1
            fi
            log_info "Executing Homebrew installer..."
            /bin/bash "$homebrew_script"
            rm -f "$homebrew_script"
        fi
        
    elif [[ "$os" == "linux" ]]; then
        install_linux_prerequisites
    fi
    
    # Ensure git is installed
    if ! command_exists git; then
        log_error "Git is required but not installed"
        exit 1
    fi
}

# Install Linux prerequisites (zsh, stow, build tooling) via the available
# package manager. stow is in EPEL on RHEL/CentOS, so epel-release is enabled
# best-effort there. No system-wide upgrade is performed.
#
# If all required tools are already present (e.g. root installed them
# system-wide on a shared host), skip the package-manager step entirely so a
# non-root user can run the installer without sudo. If tools are missing and
# SUDO=false, fail clearly with the list of missing packages rather than
# attempting a sudo prompt the user can't satisfy.
install_linux_prerequisites() {
    local required=(git curl zsh stow)
    local missing=()
    for pkg in "${required[@]}"; do
        command_exists "$pkg" || missing+=("$pkg")
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_info "All required tools (git, curl, zsh, stow) already present; skipping package installation"
        return 0
    fi

    if [[ "$SUDO" == "false" ]]; then
        log_error "Missing required tools: ${missing[*]}"
        log_error "SUDO=false so packages cannot be installed. Ask an administrator to install them system-wide:"
        log_error "  apt:     sudo apt-get install -y ${missing[*]}"
        log_error "  dnf/yum: sudo dnf install -y ${missing[*]} (enable epel-release first for stow on RHEL/CentOS)"
        exit 1
    fi

    local base_pkgs="git curl zsh stow"
    if command_exists apt-get; then
        log_info "Installing dependencies via apt..."
        sudo apt-get update || { log_error "Failed to update apt package list"; exit 1; }
        sudo apt-get install -y $base_pkgs build-essential || { log_error "Failed to install required packages"; exit 1; }
    elif command_exists dnf; then
        log_info "Installing dependencies via dnf..."
        sudo dnf install -y epel-release 2>/dev/null || true
        sudo dnf install -y $base_pkgs gcc gcc-c++ make || { log_error "Failed to install required packages (stow is in EPEL on RHEL/CentOS)"; exit 1; }
    elif command_exists yum; then
        log_info "Installing dependencies via yum..."
        sudo yum install -y epel-release 2>/dev/null || true
        sudo yum install -y $base_pkgs gcc gcc-c++ make || { log_error "Failed to install required packages (stow is in EPEL on RHEL/CentOS)"; exit 1; }
    else
        log_error "Unsupported Linux distribution - no apt-get/dnf/yum found"
        exit 1
    fi
}

# Clone or update dotfiles
setup_dotfiles() {
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_info "Dotfiles directory exists, updating..."
        cd "$DOTFILES_DIR" || { log_error "Failed to change to dotfiles directory"; exit 1; }
        if ! git status --porcelain 2>/dev/null | grep -q .; then
            git pull origin main || { log_error "Failed to update dotfiles repository"; exit 1; }
        else
            log_warn "Local changes detected in dotfiles directory, skipping git pull"
        fi
    else
        log_info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || { log_error "Failed to clone dotfiles repository"; exit 1; }
        cd "$DOTFILES_DIR" || { log_error "Failed to change to dotfiles directory"; exit 1; }
    fi
}

# Git identity is optional: if GIT_NAME/GIT_EMAIL env vars are provided they
# are used (and validated); otherwise an interactive prompt is offered when
# stdin is a terminal. If no identity is available, the shared git config is
# still installed and a reminder is printed. GITHUB_USER is no longer used
# (the [github] section was vestigial).
readonly EMAIL_REGEX='^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

validate_git_name() {
    local name="$1"
    # Allow letters, numbers, spaces, hyphens, apostrophes, periods
    [[ "$name" =~ ^[A-Za-z0-9[:space:]\.\'-]+$ ]]
}

# Prompt for an optional value via a global; inlined at call sites because
# bash 3.2 (macOS /bin/bash) has no namerefs.

setup_git_config() {
    log_info "Setting up Git configuration..."

    # Resolve identity from env vars (optional, validated).
    git_name="${GIT_NAME:-}"
    git_email="${GIT_EMAIL:-}"
    if [[ -n "$git_name" ]] && ! validate_git_name "$git_name"; then
        log_error "Invalid GIT_NAME environment variable: contains invalid characters"
        exit 1
    fi
    if [[ -n "$git_email" ]] && [[ ! "$git_email" =~ $EMAIL_REGEX ]]; then
        log_error "Invalid GIT_EMAIL environment variable: invalid email format"
        exit 1
    fi

    # If no identity from env and we have a terminal, prompt (skip allowed).
    # NON_INTERACTIVE still gates this here; the flag is removed in a follow-up.
    if [[ -z "$git_name" && -z "$git_email" && "$NON_INTERACTIVE" != "true" && -t 0 ]]; then
        echo -n "Enter your full name (enter to skip): "
        if ! read -r git_name; then
            log_error "No input received (EOF). Set GIT_NAME/GIT_EMAIL env vars or run in an interactive terminal."
            exit 1
        fi
        if [[ -n "$git_name" ]] && ! validate_git_name "$git_name"; then
            log_warn "Name contains invalid characters; skipping."
            git_name=""
        fi
        echo -n "Enter your email (enter to skip): "
        if ! read -r git_email; then
            log_error "No input received (EOF). Set GIT_NAME/GIT_EMAIL env vars or run in an interactive terminal."
            exit 1
        fi
        if [[ -n "$git_email" ]] && [[ ! "$git_email" =~ $EMAIL_REGEX ]]; then
            log_warn "Invalid email format; skipping."
            git_email=""
        fi
    fi

    # Locate the git config template (kept out of the stowed config/ tree so
    # the placeholder version is never symlinked into ~/.config).
    local template="$DOTFILES_DIR/install/gitconfig.template"
    if [[ ! -f "$template" ]]; then
        log_error "Git config template not found at $template"
        exit 1
    fi

    # Generate the user-specific git config in ~/.config/git/config (a real
    # file, not the tracked template) so the repo stays clean.
    local target_dir="$HOME/.config/git"
    local target="$target_dir/config"
    mkdir -p "$target_dir" || { log_error "Failed to create $target_dir"; exit 1; }

    # Preserve any existing identity so re-runs without GIT_* don't wipe it.
    local prev_name prev_email
    prev_name=$(git config --file "$target" user.name 2>/dev/null || true)
    prev_email=$(git config --file "$target" user.email 2>/dev/null || true)

    # Back up an existing real (non-symlink) config before overwriting.
    if [[ -f "$target" && ! -h "$target" ]]; then
        local backup="$target.bak.$(date +%s)"
        log_info "Backing up existing git config to $backup"
        mv "$target" "$backup" || { log_error "Failed to back up git config"; exit 1; }
    elif [[ -h "$target" ]]; then
        # A symlink left over from a previous stow-based install pointing at
        # config/git/config, which has since moved. Remove it before writing.
        log_info "Removing existing git config symlink at $target"
        rm -f "$target" || { log_error "Failed to remove existing git config symlink"; exit 1; }
    fi

    cp "$template" "$target" || { log_error "Failed to copy git config template"; exit 1; }

    # Set OS-appropriate credential helper
    local os=$(detect_os)
    if [[ "$os" == "linux" ]]; then
        sed -i.bak "s|helper = osxkeychain|helper = store|" "$target"
        rm -f "$target.bak"
    fi

    # Layer identity on top: provided > preserved. Written via git config so
    # the [user] section is created only when there's something to set.
    local final_name="${git_name:-$prev_name}"
    local final_email="${git_email:-$prev_email}"
    if [[ -n "$final_name" ]]; then
        git config --file "$target" user.name "$final_name" || { log_warn "Failed to set user.name"; }
    fi
    if [[ -n "$final_email" ]]; then
        git config --file "$target" user.email "$final_email" || { log_warn "Failed to set user.email"; }
    fi
    if [[ -z "$final_name" || -z "$final_email" ]]; then
        log_warn "Git identity not set. To set it later, run:"
        log_warn "  git config --global user.name 'Your Name'"
        log_warn "  git config --global user.email 'you@example.com'"
    fi

    log_success "Git configuration written to $target"
}

# Offer to set zsh as the login shell (skipped in non-interactive mode, or if
# zsh is missing or already the login shell).
maybe_change_shell() {
    local zsh_path
    zsh_path=$(command -v zsh 2>/dev/null) || { log_warn "zsh not found on PATH; skipping default-shell change"; return 0; }

    local current_shell="${SHELL:-}"
    if [[ "$current_shell" == "$zsh_path" ]]; then
        log_info "Login shell is already zsh ($zsh_path)"
        return 0
    fi

    # Non-interactive runs can't prompt; print the exact command to run.
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        log_warn "Non-interactive mode: skipping default-shell change."
        log_warn "To make zsh your default login shell, run:"
        log_warn "  sudo chsh -s $zsh_path $USER"
        log_warn "Then log out and back in."
        return 0
    fi

    echo -n "Set zsh as your default login shell? (y/n): "
    local answer
    if ! read -r answer; then
        log_warn "No input received (EOF); skipping default-shell change"
        return 0
    fi

    if [[ "$answer" =~ ^[Yy] ]]; then
        if ! command -v chsh >/dev/null 2>&1; then
            log_warn "chsh not found; run 'chsh -s $zsh_path' manually to set zsh as your default shell."
            return 0
        fi
        local os; os=$(detect_os)
        if [[ "$os" == "linux" ]] && sudo -n true 2>/dev/null; then
            # sudo credentials are cached from the install (make linux ran
            # sudo apt-get moments ago). Running chsh as root sets the shell
            # without PAM password auth, which otherwise fails on hosts where
            # the user authenticates by SSH key only (no usable password) —
            # e.g. default Azure/cloud VM users.
            # On RHEL/CentOS, chsh refuses shells not listed in /etc/shells.
            # The zsh package usually adds it, but ensure it defensively.
            if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
                echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null 2>/dev/null || true
            fi
            if sudo chsh -s "$zsh_path" "$USER"; then
                log_success "Login shell set to $zsh_path"
            else
                log_warn "Failed to set login shell. Run 'sudo chsh -s $zsh_path $USER' manually."
            fi
        elif chsh -s "$zsh_path"; then
            # macOS, or Linux without cached sudo creds: chsh prompts for the
            # user's login password (normal flow).
            log_success "Login shell set to $zsh_path"
        else
            log_warn "Failed to set login shell. On Linux run 'sudo chsh -s $zsh_path $USER'; on macOS run 'chsh -s $zsh_path'."
        fi
    else
        log_info "Skipping default-shell change (keeping $current_shell)"
    fi
}

# Main installation
main() {
    log_info "Starting dotfiles installation..."

    # Refuse to run interactively when stdin isn't a terminal (curl|bash).
    require_interactive_stdin

    # Install prerequisites
    install_prerequisites
    
    # Setup dotfiles
    setup_dotfiles
    
    # Setup git config
    setup_git_config
    
    # Run the main installation
    local os=$(detect_os)
    if [[ "$os" == "linux" ]]; then
        # Check for SUDO environment variable or prompt
        if [[ -n "$SUDO" ]]; then
            has_sudo="$SUDO"
            log_info "Using SUDO environment variable: $SUDO"
        elif [[ "$NON_INTERACTIVE" == "true" ]]; then
            # Default to no sudo in non-interactive mode for safety
            has_sudo="false"
            log_info "Non-interactive mode: defaulting to no-sudo installation"
        else
            echo -n "Do you have sudo privileges? (y/n): "
            if ! read -r has_sudo; then
                log_error "No input received (EOF). Set SUDO=true|false or run in an interactive terminal."
                exit 1
            fi
        fi
        
        if [[ "$has_sudo" =~ ^[FfNn]|false$ ]]; then
            log_info "Running Linux installation without sudo..."
            make linux-no-sudo || { log_error "Linux installation (no-sudo) failed"; exit 1; }
        else
            log_info "Running full Linux installation..."
            make linux || { log_error "Linux installation failed"; exit 1; }
        fi
    else
        log_info "Running dotfiles installation..."
        make all || { log_error "Dotfiles installation failed"; exit 1; }
    fi
    
    log_success "Dotfiles installation completed!"
    log_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"

    # Offer to switch the default login shell to zsh
    maybe_change_shell
}

# Run main function
main "$@"