# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=
PS1='C:${PWD//\//\\\\}> '

echo -e "Microsoft Windows [Version 6.1.7600]\nCopyright (c) 2009 Microsoft Corporation.  All rights reserved.\n"

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
eval $(thefuck --alias nya)
export THEFUCK_ALTER_HISTORY=true
alias update='sudo dnf upgrade'
alias clean='sudo dnf autoremove'
alias install='sudo dnf install'
alias remove='sudo dnf remove'
alias search='dnf search'
alias ..='cd ..'
alias ll='ls -lah'
alias ports='ss -tulpn'
alias c='clear'
alias ff='fastfetch'
alias scs='sudo systemctl status'
alias scr='sudo systemctl restart'
alias jlu='journalctl -u'
alias dfh='df -h'
alias free='free -h'
