# -*- mode: sh; -*-
_ehbash_func_prev_errp () {
    [[ $? -ne 0 ]]
}

_ehbash_func_err ()
{
    echo "\e[031m$*\e[0m"
}

_ehbash_func_nerr ()
{
    if _ehbash_func_prev_errp ; then
        echo "\e[031m$*\e[0m"
    fi
}

alias ll='ls -al'
alias proxy-test="curl -I 'https://www.google.com'"
alias gst='git status'
alias glog='git log'
alias eemacs='emacsclient -t'

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
           --user test --pass "${2:-XKxuiuGaVAGuBAOn}" \
           "${1:?err: No share path given for '\$1'!}"
}

function __ehbash_promptcommand () {
    local _last_exit="$?"
    local pb='\[\e[0;32m\]\w\[\e[0m\] \[\e[0;97m\]\[\e[0m\]'
    local px="$ehvar_proxyp"
    if [[ -n $px ]] \
           || [[ -n $http_proxy  ]] \
           || [[ -n $HTTP_PROXY  ]] \
           || [[ -n $https_proxy ]] \
           || [[ -n $HTTPS_PROXY ]] \
           || [[ -n $RSYNC_PROXY ]]
    then
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

function ehbash_vlock ()
{
    (
        set +e
        function __vlock__ ()
        {
            local pass='passwd1234' i j=0
            echo "\
========== current tty is locked, please input password to unlock it =========="
            # FIXME: use 'sleep' and Nchar reading return to reject
            # tty's infinitely stdin streaming while termux sleep or
            # turned into background which made high cpu while this
            # vlock.
            while [[ $i != "$pass" ]]; do
                echo "verifying ..." ; sleep 4
                if (( j == 0 )) ; then
                    read -N 10 -sp "Input passwd: " i ;
                else
                    read -N 10 -sp "\
[wrong passwd detected] reintput passwd: " i ;
                fi
                echo
                j=1
            done
            echo "Bingo!"
        }
        trap '' SIGQUIT SIGTERM SIGKILL SIGINT SIGTSTP
        __vlock__
    )
}

function ehbash_sshd_init () {
    echo "Enable SSH daemon mode ..."
    if pgrep -x sshd &>/dev/null; then
        echo "A exist SSHD daemon is running, trying keep aliving ..."
        local cmd="\
echo '--> ehbash_alive_sshd ...' && \
while sleep 30 ; do ! pgrep -x sshd && sshd ; done"
        # keep sshd alive
        if pgrep -af "bash -c ${cmd}" ; then
            if ! pkill -f "bash -c ${cmd}" ; then
                _ehbash_func_err "can not kill existed guard, abort!"
                return 1
            fi
        fi
        if nohup bash -c "$cmd" &>/dev/null & then
            return 0
        else
            return 1
        fi
    fi
    sshd && \
        {
            echo "-- locking interaction ..." ;
            ehbash_vlock ;
        }
}

if [[ ! $PATH =~ "${HOME}/.local/bin" ]] ; then
    export PATH="${HOME}/.local/bin:${PATH}"
fi
if [[ ! $PATH =~ "${HOME}/.cargo/bin" ]] ; then
    export PATH="${HOME}/.cargo/bin:${PATH}"
fi
if [[ ! $PATH =~ "${HOME}/go/bin" ]] ; then
    export PATH="${HOME}/go/bin:${PATH}"
fi

# ========== completion ==========

# yt-dlp
declare ehvar_ytdlp_bashcmp_f="\
/data/data/com.termux/files/home/.local/others/\
yt-dlp/.venv/share/bash-completion/completions/yt-dlp"

if [[ -f $ehvar_ytdlp_bashcmp_f ]] ; then
    . "$ehvar_ytdlp_bashcmp_f" && complete -F yt-dlp '__yt_dlp'
fi

# ========== dev ==========
# pyenv
export PATH="${HOME}/projects/pyenv/bin:${PATH}"
export PYENV_ROOT="${HOME}/projects/pyenv"
if command -v pyenv &>/dev/null ; then
    eval "$(pyenv init -)"
fi

if command -v zoxide &>/dev/null ; then
    eval "$(zoxide init bash)"
fi

if command -v fzf &>/dev/null ; then
    . /data/data/com.termux/files/usr/share/fzf/key-bindings.bash || \
        _ehbash_func_err "init fzf bash integration fatal"
fi

if command -v navi &>/dev/null ; then
    eval "$(navi widget bash)"
    _ehbash_func_nerr \
        "navi env initial with fatal"
fi

# ========== startup ==========

export MPD_HOST=localhost
export MPD_PORT=9688

# we always lock the termux native tty if we are not a ssh connection.
if [[ -z $SSH_CLIENT ]] && \
       [[ -z $SSH_CONNECTION ]] && \
       [[ -z $SSH_TTY ]]
then
    ehbash_vlock
fi

function __ehbash_prevrtn_okp ()
{
    local prev="$?"
    if type -tP ee >/dev/null ; then
        echo -e "\e[31mCommand 'ee' is found, but it's aliased.\e[0m"
        return 1
    fi
    if [[ $prev -eq 0 ]] ; then
        echo -e "\e[32mOk prev checked as success: ${prev}\e[0m"
    else
        echo -e "\e[31mErr prev checked as fatal: ${prev}\e[0m"
    fi
}
alias ee='__ehbash_prevrtn_okp'
