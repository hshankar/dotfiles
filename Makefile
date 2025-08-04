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
	@command -v stow >/dev/null 2>&1 || { echo "Error: stow is required but not installed"; exit 1; }
	@if [ "$(OS)" = "macos" ]; then \
		command -v brew >/dev/null 2>&1 || { echo "Error: Homebrew is required but not installed"; exit 1; }; \
	fi
	@echo "All dependencies satisfied"

all: $(OS)

# Selective installation targets
minimal: check-deps oh-my-zsh link
packages-only: brew-packages cask-apps check-deps
config-only: check-deps link
linux-no-sudo: oh-my-zsh link-no-stow

macos: sudo core-macos packages check-deps link duti

linux: check-deps core-linux link

core-macos: oh-my-zsh brew

core-linux: oh-my-zsh 
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo apt-get dist-upgrade -f
	sudo apt-get -y install stow

sudo:
	@echo "Requesting sudo access (required for some operations)..."
	sudo -v
	@echo "Sudo access granted"

packages: brew-packages cask-apps

link:
	@echo "Creating backup of existing files and setting up symlinks..."
	@for FILE in $$(ls -A runcom 2>/dev/null || true); do \
		if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
			backup_file="$(HOME)/$$FILE.bak.$$(date +%s)"; \
			echo "Backing up $$FILE to $$backup_file"; \
			mv $(HOME)/$$FILE "$$backup_file" || { echo "Failed to backup $$FILE"; exit 1; }; \
		fi; \
	done
	@mkdir -p $(XDG_CONFIG_HOME)
	stow -t $(HOME) runcom || { echo "Failed to stow runcom"; exit 1; }
	stow -t $(XDG_CONFIG_HOME) config || { echo "Failed to stow config"; exit 1; }
	@mkdir -p $(HOME)/.oh-my-zsh/custom || { echo "Failed to create oh-my-zsh custom directory"; exit 1; }
	stow -t $(HOME)/.oh-my-zsh/custom oh-my-zsh || { echo "Failed to stow oh-my-zsh"; exit 1; }
	stow -t $(HOME)/.vim vim || { echo "Failed to stow vim"; exit 1; }
	@mkdir -p $(HOME)/.local/runtime
	@chmod 700 $(HOME)/.local/runtime

link-no-stow:
	@echo "Creating symlinks manually (no stow required)..."
	@for FILE in $$(ls -A runcom 2>/dev/null || true); do \
		if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
			backup_file="$(HOME)/$$FILE.bak.$$(date +%s)"; \
			echo "Backing up existing $$FILE to $$backup_file"; \
			mv $(HOME)/$$FILE "$$backup_file" || { echo "Failed to backup $$FILE"; exit 1; }; \
		fi; \
		echo "Linking $$FILE"; \
		ln -sf $(DOTFILES_DIR)/runcom/$$FILE $(HOME)/$$FILE || { echo "Failed to link $$FILE"; exit 1; }; \
	done
	@mkdir -p $(XDG_CONFIG_HOME) || { echo "Failed to create XDG_CONFIG_HOME"; exit 1; }
	@for FILE in $$(find config -type f 2>/dev/null || true); do \
		TARGET_DIR=$(XDG_CONFIG_HOME)/$$(dirname $$FILE | sed 's/^config\///'); \
		mkdir -p $$TARGET_DIR || { echo "Failed to create directory $$TARGET_DIR"; exit 1; }; \
		ln -sf $(DOTFILES_DIR)/$$FILE $$TARGET_DIR/$$(basename $$FILE) || { echo "Failed to link config file $$FILE"; exit 1; }; \
	done
	@mkdir -p $(HOME)/.oh-my-zsh/custom/themes || { echo "Failed to create oh-my-zsh themes directory"; exit 1; }
	@if [ -f $(DOTFILES_DIR)/oh-my-zsh/themes/hshankar.zsh-theme ]; then \
		ln -sf $(DOTFILES_DIR)/oh-my-zsh/themes/hshankar.zsh-theme $(HOME)/.oh-my-zsh/custom/themes/ || { echo "Failed to link zsh theme"; exit 1; }; \
	fi
	@mkdir -p $(HOME)/.vim/colors || { echo "Failed to create vim colors directory"; exit 1; }
	@if [ -f $(DOTFILES_DIR)/vim/colors/solarized.vim ]; then \
		ln -sf $(DOTFILES_DIR)/vim/colors/solarized.vim $(HOME)/.vim/colors/ || { echo "Failed to link vim colorscheme"; exit 1; }; \
	fi
	@mkdir -p $(HOME)/.local/runtime || { echo "Failed to create local runtime directory"; exit 1; }
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
		temp_script=$$(mktemp) || { echo "Failed to create temporary file"; exit 1; }; \
		test -n "$$temp_script" || { echo "Empty temporary file path"; exit 1; }; \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$$temp_script" || { echo "Failed to download Homebrew installer"; exit 1; }; \
		/bin/bash "$$temp_script" || { echo "Homebrew installation failed"; rm -f "$$temp_script"; exit 1; }; \
		rm -f "$$temp_script"; \
	else \
		echo "Homebrew already installed"; \
	fi

oh-my-zsh:
	@if [ ! -d $(HOME)/.oh-my-zsh ]; then \
		echo "Installing Oh My Zsh..."; \
		temp_script=$$(mktemp) || { echo "Failed to create temporary file"; exit 1; }; \
		test -n "$$temp_script" || { echo "Empty temporary file path"; exit 1; }; \
		curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$$temp_script" || { echo "Failed to download Oh My Zsh installer"; exit 1; }; \
		RUNZSH=no /bin/bash "$$temp_script" || { echo "Oh My Zsh installation failed"; rm -f "$$temp_script"; exit 1; }; \
		rm -f "$$temp_script"; \
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