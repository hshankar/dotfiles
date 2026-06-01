HOST_PROMPT=''
[[ -n "$SSH_CONNECTION" ]] && HOST_PROMPT="%{$fg[magenta]%}%m%{$reset_color%} "

PROMPT="%(?:%{$fg_bold[green]%}%1{➜%} :%{$fg_bold[red]%}%1{➜%} ) %{$fg_bold[yellow]%}[%*]%{$reset_color%} ${HOST_PROMPT}%{$fg[cyan]%}%~%{$reset_color%}"
PROMPT+=' $(git_prompt_info) %{$fg_bold[green]%}» %{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[yellow]%}%1{✗%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" "

# Leave one empty line after each command
precmd() {
  echo
}
