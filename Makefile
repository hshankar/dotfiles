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

all: $(OS)

macos: sudo core-macos packages link duti

linux: core-linux link

core-macos: oh-my-zsh brew

core-linux: oh-my-zsh 
	apt-get update
	apt-get upgrade -y
	apt-get dist-upgrade -f
	apt-get -y install stow

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

unlink:
	stow --delete -t $(HOME) runcom
	stow --delete -t $(XDG_CONFIG_HOME) config
	stow --delete -t $(HOME)/.oh-my-zsh/custom oh-my-zsh
	stow --delete -t $(HOME)/.vim vim
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE.bak ]; then \
		mv -v $(HOME)/$$FILE.bak $(HOME)/$${FILE%%.bak}; fi; done

brew:
	is-executable brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | zsh

oh-my-zsh:
	test -d $(HOME)/.oh-my-zsh || curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | zsh

brew-packages: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Brewfile || true

cask-apps: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Caskfile || true

duti:
	duti -v $(DOTFILES_DIR)/install/duti