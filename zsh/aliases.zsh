if [ -x "$(command -v nvim)" ]; then
    alias vim=nvim
fi

if ! command -v exa &> /dev/null
then
    alias ls='ls --color=auto'
    alias ll='ls -alF'
else
    alias ls='exa -s type'
    alias ll='exa -alGF -s type'
fi

alias grep='rg --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
