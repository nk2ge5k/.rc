source "$HOME/.cargo/env"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# default editor is nvim
export EDITOR='nvim'
# change man pager to nvim
# export MANPAGER="nvim -c 'set ft=man' -"

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

export GOPATH=$HOME

# Add libraries path to linker
export LD_LIBRARY_PATH="/usr/local/lib"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/bin/go/bin:$PATH"
export PATH="$HOME/scripts/enabled/:$PATH"

export XDG_CONFIG_HOME=$HOME/.config

if [ -x "$(command -v gpgconf)" ]; then
  export GPG_TTY=$(tty)
  gpgconf --launch gpg-agent
fi

export FZF_DEFAULT_COMMAND='rg --files'

if [ -x "$(command -v ssh-agent)" ]; then
  eval `ssh-agent` > /dev/null
  if [[ "$(uname)" == "Darwin" ]]; then
    ssh-add --apple-use-keychain 2> /dev/null
  fi
fi
