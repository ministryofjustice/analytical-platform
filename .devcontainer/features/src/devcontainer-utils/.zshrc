####################
# Oh My ZSH Internals
####################
export ZSH="${HOME}/.oh-my-zsh"
export ZSH_THEME="moj-codespaces"
export plugins=(git)

source "${ZSH}/oh-my-zsh.sh"

####################
# Oh My ZSH Options
####################
export DISABLE_AUTO_UPDATE="true"
export DISABLE_UPDATE_PROMPT="true"

####################
# Shell Options
####################
export HISTFILE="${HOME}/.commandhistory/.zsh_history"

####################
# Shell Completion
####################
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit

####################
# Dotfiles
####################
for file in ${HOME}/.dotfiles/*.sh; do
  source ${file}
done

####################
# First Notice
####################
if [ -t 1 ] && [[ "${TERM_PROGRAM}" = "vscode" || "${TERM_PROGRAM}" = "codespaces" ]] && [ ! -f "/opt/vscode-dev-containers/first-run-notice-already-displayed" ]; then
  cat "/usr/local/etc/vscode-dev-containers/first-run-notice.txt"
  ((sleep 10s; touch "/opt/vscode-dev-containers/first-run-notice-already-displayed") &)
fi
