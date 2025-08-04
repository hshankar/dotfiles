SHELL = /bin/zsh
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/if-else bin/is-macos macos linux)
HOMEBREW_PREFIX := $(shell bin/if-else bin/is-macos $(shell bin/if-else bin/is-arm64 /opt/homebrew /usr/local) /home/linuxbrew/.linuxbrew)
# export N_PREFIX = $(HOME)/.n
PATH := $(HOMEBREW_PREFIX)/bin:$(DOTFILES_DIR)/bin:$(PATH)
# SHELLS := /private/etc/shells
BIN := $(HOMEBREW_PREFIX)/bin
export XDG_CONFIG_HOME = $(HOME)/.config
export STOW_DIR = $(DOTFILES_DIR)
export ACCEPT_EULA=Y

# Check if required commands exist
check-deps:
	@echo "Checking dependencies..."
	@if [ "$(OS)" = "macos" ]; then \
		command -v brew >/dev/null 2>&1 || { echo "Error: Homebrew is required but not installed"; exit 1; }; \
	fi
	@echo "Basic dependencies satisfied"

# Check if stow is installed (separate from basic deps)
check-stow:
	@echo "Checking for stow..."
	@command -v stow >/dev/null 2>&1 || { echo "Error: stow is required but not installed"; exit 1; }
	@echo "stow is available"

all: $(OS)

# Selective installation targets
minimal: check-deps oh-my-zsh check-stow link
packages-only: check-deps brew-packages cask-apps
config-only: check-deps check-stow link
linux-no-sudo: oh-my-zsh link-no-stow

macos: check-deps sudo core-macos packages check-stow link duti

linux: check-deps core-linux check-stow link

core-macos: oh-my-zsh brew

core-linux: oh-my-zsh 
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo apt-get dist-upgrade -f
	sudo apt-get -y install stow

sudo:
	sudo -v
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

packages: brew-packages cask-apps

link:
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
		mv -v $(HOME)/$$FILE{,.bak}; fi; done
	mkdir -p $(XDG_CONFIG_HOME)
	stow -t $(HOME) runcom
	stow -t $(XDG_CONFIG_HOME) config
	stow -t $(HOME)/.oh-my-zsh/custom oh-my-zsh
	stow -t $(HOME)/.vim vim
	mkdir -p $(HOME)/.local/runtime
	chmod 700 $(HOME)/.local/runtime

link-no-stow:
	@echo "Creating symlinks manually (no stow required)..."
	@for FILE in $$(ls -A runcom); do \
		if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
			echo "Backing up existing $$FILE"; \
			mv $(HOME)/$$FILE $(HOME)/$$FILE.bak; \
		fi; \
		echo "Linking $$FILE"; \
		ln -sf $(DOTFILES_DIR)/runcom/$$FILE $(HOME)/$$FILE; \
	done
	@mkdir -p $(XDG_CONFIG_HOME)
	@for FILE in $$(find config -type f); do \
		TARGET_DIR=$(XDG_CONFIG_HOME)/$$(dirname $$FILE | sed 's/^config\///'); \
		mkdir -p $$TARGET_DIR; \
		ln -sf $(DOTFILES_DIR)/$$FILE $$TARGET_DIR/$$(basename $$FILE); \
	done
	@mkdir -p $(HOME)/.oh-my-zsh/custom/themes
	@ln -sf $(DOTFILES_DIR)/oh-my-zsh/themes/hshankar.zsh-theme $(HOME)/.oh-my-zsh/custom/themes/
	@mkdir -p $(HOME)/.vim/colors
	@ln -sf $(DOTFILES_DIR)/vim/colors/solarized.vim $(HOME)/.vim/colors/
	@mkdir -p $(HOME)/.local/runtime
	@chmod 700 $(HOME)/.local/runtime
	@echo "Manual symlinks created successfully"

unlink:
	stow --delete -t $(HOME) runcom
	stow --delete -t $(XDG_CONFIG_HOME) config
	stow --delete -t $(HOME)/.oh-my-zsh/custom oh-my-zsh
	stow --delete -t $(HOME)/.vim vim
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE.bak ]; then \
		mv -v $(HOME)/$$FILE.bak $(HOME)/$${FILE%%.bak}; fi; done

brew:
	@if ! is-executable brew; then \
		echo "Installing Homebrew..."; \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash || { echo "Homebrew installation failed"; exit 1; }; \
	else \
		echo "Homebrew already installed"; \
	fi

oh-my-zsh:
	@if [ ! -d $(HOME)/.oh-my-zsh ]; then \
		echo "Installing Oh My Zsh..."; \
		curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | RUNZSH=no bash || { echo "Oh My Zsh installation failed"; exit 1; }; \
	else \
		echo "Oh My Zsh already installed"; \
	fi

brew-packages: brew
	@echo "Installing Homebrew packages..."
	@brew bundle --file=$(DOTFILES_DIR)/install/Brewfile || { echo "Some brew packages failed to install, continuing..."; }

cask-apps: brew
	@echo "Installing Homebrew cask applications..."
	@brew bundle --file=$(DOTFILES_DIR)/install/Caskfile || { echo "Some cask apps failed to install, continuing..."; }

duti:
	duti -v $(DOTFILES_DIR)/install/duti