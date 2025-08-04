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
        # Update package manager
        if command_exists apt-get; then
            log_info "Updating package manager and installing dependencies..."
            sudo apt-get update || { log_error "Failed to update apt package list"; exit 1; }
            sudo apt-get install -y git curl build-essential || { log_error "Failed to install required packages"; exit 1; }
        elif command_exists yum; then
            log_info "Updating package manager and installing dependencies..."
            sudo yum update -y || { log_error "Failed to update yum packages"; exit 1; }
            sudo yum install -y git curl gcc gcc-c++ make || { log_error "Failed to install required packages"; exit 1; }
        else
            log_error "Unsupported Linux distribution - neither apt-get nor yum found"
            exit 1
        fi
    fi
    
    # Ensure git is installed
    if ! command_exists git; then
        log_error "Git is required but not installed"
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

# Setup git configuration (supports env vars for automation)
setup_git_config() {
    log_info "Setting up Git configuration..."
    
    # Use environment variables if available, otherwise prompt
    if [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" && -n "$GITHUB_USER" ]]; then
        git_name="$GIT_NAME"
        git_email="$GIT_EMAIL"
        github_user="$GITHUB_USER"
        log_info "Using environment variables for Git config"
    elif [[ "$NON_INTERACTIVE" == "true" ]]; then
        log_warn "Non-interactive mode but no Git environment variables set"
        log_warn "Skipping Git configuration - you'll need to set it manually later"
        return 0
    else
        while [[ -z "$git_name" ]]; do
            echo -n "Enter your full name: "
            read -r git_name
            [[ -z "$git_name" ]] && log_warn "Name cannot be empty. Please try again."
        done
        
        while [[ -z "$git_email" || ! "$git_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; do
            echo -n "Enter your email: "
            read -r git_email
            if [[ -z "$git_email" ]]; then
                log_warn "Email cannot be empty. Please try again."
            elif [[ ! "$git_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                log_warn "Invalid email format. Please enter a valid email address."
            fi
        done
        
        while [[ -z "$github_user" ]]; do
            echo -n "Enter your GitHub username: "
            read -r github_user
            [[ -z "$github_user" ]] && log_warn "GitHub username cannot be empty. Please try again."
        done
    fi
    
    # Validate inputs
    if [[ -z "$git_name" || -z "$git_email" || -z "$github_user" ]]; then
        log_error "Git configuration values cannot be empty"
        exit 1
    fi
    
    # Validate email format
    if [[ ! "$git_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        log_error "Invalid email format: $git_email"
        exit 1
    fi
    
    # Check if git config file exists
    if [[ ! -f "config/git/config" ]]; then
        log_error "Git config template not found at config/git/config"
        exit 1
    fi
    
    # Update git config with user details
    sed -i.bak "s/PLACEHOLDER_NAME/$git_name/" config/git/config || { log_error "Failed to update git name"; exit 1; }
    sed -i.bak "s/PLACEHOLDER_EMAIL/$git_email/" config/git/config || { log_error "Failed to update git email"; exit 1; }
    sed -i.bak "s/PLACEHOLDER_GITHUB_USER/$github_user/" config/git/config || { log_error "Failed to update GitHub user"; exit 1; }
    
    rm -f config/git/config.bak
    
    log_success "Git configuration updated"
}

# Main installation
main() {
    log_info "Starting dotfiles installation..."
    
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
            read -r has_sudo
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
}

# Run main function
main "$@"