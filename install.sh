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
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
    elif [[ "$os" == "linux" ]]; then
        # Update package manager
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y git curl build-essential
        elif command_exists yum; then
            sudo yum update -y
            sudo yum install -y git curl gcc gcc-c++ make
        else
            log_error "Unsupported Linux distribution"
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
        cd "$DOTFILES_DIR"
        git pull origin main
    else
        log_info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        cd "$DOTFILES_DIR"
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
        echo -n "Enter your full name: "
        read -r git_name
        echo -n "Enter your email: "
        read -r git_email
        echo -n "Enter your GitHub username: "
        read -r github_user
    fi
    
    # Update git config with user details
    sed -i.bak "s/PLACEHOLDER_NAME/$git_name/" config/git/config
    sed -i.bak "s/PLACEHOLDER_EMAIL/$git_email/" config/git/config
    sed -i.bak "s/PLACEHOLDER_GITHUB_USER/$github_user/" config/git/config
    
    rm config/git/config.bak
    
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
            make linux-no-sudo
        else
            log_info "Running full Linux installation..."
            make linux
        fi
    else
        log_info "Running dotfiles installation..."
        make all
    fi
    
    log_success "Dotfiles installation completed!"
    log_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
}

# Run main function
main "$@"