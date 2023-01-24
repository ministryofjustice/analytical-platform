# Oh My Zsh! theme - partly inspired by https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/robbyrussell.zsh-theme
# Source: https://github.com/devcontainers/features/blob/main/src/common-utils/scripts/devcontainers.zsh-theme

__zsh_prompt() {
    local prompt_username
    if [ ! -z "${GITHUB_USER}" ]; then 
        prompt_username="@${GITHUB_USER}"
    else
        prompt_username="%n"
    fi
    PROMPT="%{$fg[green]%}${prompt_username} %(?:%{$reset_color%}➜ :%{$fg_bold[red]%}➜ )" # User/exit code arrow
    PROMPT+='%{$fg_bold[blue]%}%(5~|%-1~/…/%3~|%4~)%{$reset_color%} ' # cwd
    PROMPT+='`\
        if [ "$(git config --get devcontainers-theme.hide-status 2>/dev/null)" != 1 ] && [ "$(git config --get codespaces-theme.hide-status 2>/dev/null)" != 1 ]; then \
            export BRANCH=$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git --no-optional-locks rev-parse --short HEAD 2>/dev/null); \
            if [ "${BRANCH}" != "" ]; then \
                echo -n "%{$fg_bold[cyan]%}(%{$fg_bold[red]%}${BRANCH}" \
                && if [ "$(git config --get devcontainers-theme.show-dirty 2>/dev/null)" = 1 ] && \
                    git --no-optional-locks ls-files --error-unmatch -m --directory --no-empty-directory -o --exclude-standard ":/*" > /dev/null 2>&1; then \
                        echo -n " %{$fg_bold[yellow]%}✗"; \
                fi \
                && echo -n "%{$fg_bold[cyan]%})%{$reset_color%} "; \
            fi; \
        fi`'

    # AWS Vault Profile
    if command -v aws-vault &> /dev/null; then
      PROMPT+='`\
          if [[ ${AWS_VAULT} == *"dev"* ]]; then \
            echo -n "[ aws: %{$fg[green]%}${AWS_VAULT}%{$reset_color%} ] "; \
          elif [[ ${AWS_VAULT} == *"management"* ]]; then \
            echo -n "[ aws: %{$fg[blue]%}${AWS_VAULT}%{$reset_color%} ] "; \
          elif [[ ${AWS_VAULT} == *"prod"* ]]; then \
            echo -n "[ aws: %{$fg[red]%}${AWS_VAULT}%{$reset_color%} ] "; \
          elif [[ ! -z ${AWS_VAULT} ]]; then \
            echo -n "[ aws: %{$fg[yellow]%}${AWS_VAULT}%{$reset_color%} ] "; \
          fi`'
    fi

    # Kubernetes Context
    if command -v kubectl &> /dev/null; then
      PROMPT+='`\
          if [[ "$( kubectl config get-contexts | grep "*" | awk "{ print $2 }" | cut -d"/" -f2 )" == *"development"* ]]; then \
            echo -n "[ k8s: %{$fg[green]%}development%{$reset_color%} ] "; \
          elif [[ "$( kubectl config get-contexts | grep "*" | awk "{ print $2 }" | cut -d"/" -f2 )" == *"github-actions-moj"* ]]; then \
            echo -n "[ k8s: %{$fg[blue]%}github-actions-moj%{$reset_color%} ] "; \
          elif [[ "$( kubectl config get-contexts | grep "*" | awk "{ print $2 }" | cut -d"/" -f2 )" == *"production"* ]]; then \
            echo -n "[ k8s: %{$fg[red]%}production%{$reset_color%} ] "; \
          fi`'
    fi

    PROMPT+='%{$fg[white]%}$ %{$reset_color%}'
    unset -f __zsh_prompt
}

__zsh_prompt
