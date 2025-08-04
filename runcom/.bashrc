.bash_profile

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path bash)"

# Contextual History
[[ -f "$HOME/.local/share/contextual-history/contextual-history.bash" ]] && source "$HOME/.local/share/contextual-history/contextual-history.bash"
