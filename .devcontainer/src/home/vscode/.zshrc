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

# AWS
complete -C '/usr/local/bin/aws_completer' aws

# Helm
source <(helm completion zsh)

# Flux
source <(flux completion zsh)

# Kubernetes
source <(kubectl completion zsh)

# Terraform
complete -o nospace -C /usr/local/bin/terraform terraform

####################
# AWS Vault
####################
export AWS_VAULT_BACKEND="file"
export AWS_VAULT_FILE_PASSPHRASE=""
