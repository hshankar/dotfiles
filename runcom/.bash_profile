# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Locate the dotfiles directory.
# Default to the standard install location (~/​.dotfiles); allow an explicit
# override via the environment, and fall back to resolving this file's symlink
# target (this file is stowed as ~/.bash_profile → repo/runcom/.bash_profile).
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
if [[ ! -d "$DOTFILES_DIR" ]] && command -v realpath >/dev/null 2>&1; then
    _src=$(realpath "$BASH_SOURCE" 2>/dev/null)
    [[ -n "$_src" ]] && DOTFILES_DIR="$(dirname "$(dirname "$_src")")"
    unset _src
fi
export DOTFILES_DIR

# Make dotfiles bin/ available
[[ -d "$DOTFILES_DIR/bin" ]] && PATH="$DOTFILES_DIR/bin:$PATH"

# Personal tool paths (guarded so missing dirs don't error)
[[ -d "$HOME/.maestro/bin" ]] && export PATH="$PATH:$HOME/.maestro/bin"

# Contextual History
[[ -f "$HOME/.local/share/contextual-history/contextual-history.bash" ]] && source "$HOME/.local/share/contextual-history/contextual-history.bash"
