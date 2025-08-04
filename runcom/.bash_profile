# If not running interactively, don't do anything

[ -z "$PS1" ] && return

# Resolve DOTFILES_DIR safely - prevent symlink attacks
CURRENT_SCRIPT=$BASH_SOURCE

# Use a safer approach that resolves to canonical paths
if [[ -n $CURRENT_SCRIPT ]]; then
  # Get the real path to prevent symlink attacks
  if command -v realpath > /dev/null 2>&1; then
    REAL_SCRIPT=$(realpath "$CURRENT_SCRIPT" 2>/dev/null)
    if [[ -n "$REAL_SCRIPT" ]]; then
      DOTFILES_DIR="$(dirname "$(dirname "$REAL_SCRIPT")")"
    fi
  elif [[ -x readlink ]]; then
    # Fallback to readlink but validate the result
    SCRIPT_PATH=$(readlink -f "$CURRENT_SCRIPT" 2>/dev/null)
    if [[ -n "$SCRIPT_PATH" && "$SCRIPT_PATH" == /* ]]; then
      # Ensure we got an absolute path and it's reasonable
      DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_PATH")")"
    fi
  fi
fi

# Validate and set fallback
if [[ -z "$DOTFILES_DIR" || "$DOTFILES_DIR" != /* ]]; then
  # Fallback to known safe location
  DOTFILES_DIR="$HOME/.dotfiles"
fi

# Final validation that DOTFILES_DIR is safe and exists
if [[ ! -d "$DOTFILES_DIR" ]]; then
  echo "Unable to find dotfiles directory, exiting."
  return
fi

# Additional security check: ensure DOTFILES_DIR is within reasonable bounds
if [[ "$DOTFILES_DIR" != "$HOME"* && "$DOTFILES_DIR" != /opt/* && "$DOTFILES_DIR" != /usr/local/* ]]; then
  echo "Warning: DOTFILES_DIR appears to be in an unusual location: $DOTFILES_DIR" >&2
  echo "Falling back to ~/.dotfiles for security"
  DOTFILES_DIR="$HOME/.dotfiles"
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo "Unable to find safe dotfiles directory, exiting."
    return
  fi
fi

# Make utilities available

PATH="$DOTFILES_DIR/bin:$PATH"

# Source the dotfiles (order matters) - with validation for security

# Whitelist of allowed dotfile names for security
allowed_dotfiles=(
  ".function" ".function_*" ".n" ".path" ".env" ".exports" 
  ".alias" ".grep" ".prompt" ".completion" ".fix" ".zoxide"
)

for pattern in "${allowed_dotfiles[@]}"; do
  for DOTFILE in "$DOTFILES_DIR"/system/${pattern}; do
    # Validate file exists and is a regular file
    if [[ -f "$DOTFILE" && -r "$DOTFILE" ]]; then
      # Validate the file path is within expected directory structure
      if [[ "$DOTFILE" == "$DOTFILES_DIR"/system/.* ]]; then
        # Additional security: check file doesn't contain obvious malicious patterns
        if ! grep -q "rm -rf\|eval.*\$\|exec.*\$\|\`.*\`" "$DOTFILE" 2>/dev/null; then
          . "$DOTFILE"
        else
          echo "Warning: Skipping potentially unsafe dotfile: $DOTFILE" >&2
        fi
      else
        echo "Warning: Dotfile path validation failed: $DOTFILE" >&2
      fi
    fi
  done
done

if is-macos; then
  macos_dotfiles=(".env.macos" ".alias.macos" ".function.macos")
  for dotfile_name in "${macos_dotfiles[@]}"; do
    DOTFILE="$DOTFILES_DIR/system/${dotfile_name}"
    # Validate file exists and is a regular file
    if [[ -f "$DOTFILE" && -r "$DOTFILE" ]]; then
      # Validate the file path is within expected directory structure
      if [[ "$DOTFILE" == "$DOTFILES_DIR"/system/.* ]]; then
        # Additional security: check file doesn't contain obvious malicious patterns
        if ! grep -q "rm -rf\|eval.*\$\|exec.*\$\|\`.*\`" "$DOTFILE" 2>/dev/null; then
          . "$DOTFILE"
        else
          echo "Warning: Skipping potentially unsafe dotfile: $DOTFILE" >&2
        fi
      else
        echo "Warning: Dotfile path validation failed: $DOTFILE" >&2
      fi
    fi
  done
fi

# Set LSCOLORS - with validation

DIR_COLORS_FILE="$DOTFILES_DIR/system/.dir_colors"
if [[ -f "$DIR_COLORS_FILE" && -r "$DIR_COLORS_FILE" ]]; then
  # Validate that the file path is within our dotfiles directory
  if [[ "$DIR_COLORS_FILE" == "$DOTFILES_DIR"/system/.dir_colors ]]; then
    # Check that dircolors command exists
    if command -v dircolors > /dev/null 2>&1; then
      # Get dircolors output and validate it before eval
      DIRCOLORS_OUTPUT=$(dircolors -b "$DIR_COLORS_FILE" 2>/dev/null)
      if [[ -n "$DIRCOLORS_OUTPUT" && "$DIRCOLORS_OUTPUT" =~ ^LS_COLORS= ]]; then
        eval "$DIRCOLORS_OUTPUT"
      else
        echo "Warning: dircolors output validation failed" >&2
      fi
    fi
  else
    echo "Warning: dir_colors file path validation failed" >&2
  fi
fi

# Wrap up

unset CURRENT_SCRIPT SCRIPT_PATH DOTFILE
export DOTFILES_DIR
export PATH="$PATH:$HOME/.maestro/bin"

# Contextual History
[[ -f "$HOME/.local/share/contextual-history/contextual-history.bash" ]] && source "$HOME/.local/share/contextual-history/contextual-history.bash"
