# If not running interactively, don't do anything

[ -z "$PS1" ] && return

# Resolve DOTFILES_DIR (assuming ~/.dotfiles on distros without readlink and/or $BASH_SOURCE/$0)
CURRENT_SCRIPT=$BASH_SOURCE

if [[ -n $CURRENT_SCRIPT && -x readlink ]]; then
  SCRIPT_PATH=$(readlink -n "$CURRENT_SCRIPT")
  if [[ -n "$SCRIPT_PATH" ]]; then
    DOTFILES_DIR="${PWD}/$(dirname "$(dirname "$SCRIPT_PATH")")"
  else
    echo "Warning: readlink failed, falling back to ~/.dotfiles"
    DOTFILES_DIR="$HOME/.dotfiles"
  fi
elif [ -d "$HOME/.dotfiles" ]; then
  DOTFILES_DIR="$HOME/.dotfiles"
else
  echo "Unable to find dotfiles, exiting."
  return
fi

# Make utilities available

PATH="$DOTFILES_DIR/bin:$PATH"

# Source the dotfiles (order matters)

for DOTFILE in "$DOTFILES_DIR"/system/.{function,function_*,n,path,env,exports,alias,grep,prompt,completion,fix,zoxide}; do
  . "$DOTFILE"
done

if is-macos; then
  for DOTFILE in "$DOTFILES_DIR"/system/.{env,alias,function}.macos; do
    . "$DOTFILE"
  done
fi

# Set LSCOLORS

eval "$(dircolors -b "$DOTFILES_DIR"/system/.dir_colors)"

# Wrap up

unset CURRENT_SCRIPT SCRIPT_PATH DOTFILE
export DOTFILES_DIR
export PATH="$PATH:$HOME/.maestro/bin"

# Contextual History
[[ -f "$HOME/.local/share/contextual-history/contextual-history.bash" ]] && source "$HOME/.local/share/contextual-history/contextual-history.bash"
