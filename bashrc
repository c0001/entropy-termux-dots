alias ll='ls -al'
alias proxy-test="curl -I 'https://www.google.com'"

declare ehvar_proxyp=''
function ehpset () {
    export https_proxy=http://192.168.3.161:7890
    export RSYNC_PROXY=192.168.3.161:7890
    export HTTPS_PROXY=http://192.168.3.161:7890
    export HTTP_PROXY=http://192.168.3.161:7890
    export http_proxy=http://192.168.3.161:7890
    ehvar_proxyp=1
}

function ehpunset () {
    unset https_proxy
    unset RSYNC_PROXY
    unset HTTPS_PROXY
    unset HTTP_PROXY
    unset http_proxy
    ehvar_proxyp=''
}

function ehwebdav_share () {
    rclone serve webdav --addr '192.168.3.191:8090' \
           --user test --pass "${1:-XKxuiuGaVAGuBAOn}" \
           '/storage/7DAC-E74A/'
}

function __ehbash_promptcommand () {
    local _last_exit="$?"
    local pb='\[\e[0;32m\]\w\[\e[0m\] \[\e[0;97m\]\[\e[0m\]'
    local px="$ehvar_proxyp"
    if [[ -n $px ]] ; then
        pb="🌎 ${pb}"
    fi
    local RCol='\[\033[00m\]'
    local Red='\[\033[01;31m\]'
    local Gre='\[\033[01;32m\]'
    local Yel='\[\033[01;33m\]'
    local Blu='\[\033[01;34m\]'
    local Pur='\[\033[01;35m\]'

    if [ $_last_exit != 0 ]; then
        pb+=" -${Red}${_last_exit}${RCol}-"
    else
        pb+=" -${Gre}${_last_exit}${RCol}-"
    fi
    PS1="${pb} \$ "
}

PROMPT_COMMAND='__ehbash_promptcommand'

function ehbash_reload_bashrc () {
    { source ~/.bashrc && echo ok; } || \
        echo err
}

export PATH="${HOME}/.local/bin:${PATH}"

# ========== dev ==========
# pyenv
export PATH="${HOME}/projects/pyenv/bin:${PATH}"
export PYENV_ROOT="${HOME}/projects/pyenv"
if command -v pyenv &>/dev/null ; then
    eval "$(pyenv init -)"
fi
