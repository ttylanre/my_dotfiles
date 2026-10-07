# ============================================================
#  .zshrc — Organized Configuration
# ============================================================


# ------------------------------------------------------------
# POWERLEVEL10K INSTANT PROMPT (must stay near top)
# ------------------------------------------------------------
#if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
 # source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
#fi


# ------------------------------------------------------------
# OH MY ZSH SETUP
# ------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

ZSH_THEME=""

# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )
# CASE_SENSITIVE="true"
# HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode disabled
# zstyle ':omz:update' mode auto
# zstyle ':omz:update' mode reminder
# zstyle ':omz:update' frequency 13
# DISABLE_MAGIC_FUNCTIONS="true"
# DISABLE_LS_COLORS="true"
# DISABLE_AUTO_TITLE="true"
# ENABLE_CORRECTION="true"
# COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# COMPLETION_WAITING_DOTS="true"
# DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="mm/dd/yyyy"
# ZSH_CUSTOM=/path/to/new-custom-folder
# Enable cursor shape switching
VI_MODE_SET_CURSOR=true
# Set desired cursor shapes (Beam/Pipe for Insert, Solid Block for Normal)
VI_MODE_CURSOR_INSERT=6
VI_MODE_CURSOR_NORMAL=2
# Customize mode indicator text (optional)
MODE_INDICATOR="%F{yellow}[NORMAL]%f"
INSERT_MODE_INDICATOR="%F{green}[INSERT]%f"
# Force prompt redraw when changing modes
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true

plugins=(git vi-mode sudo copypath copyfile)
for plugin in fancy-ctrl-z zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
    if [[ -d "$ZSH_CUSTOM/plugins/$plugin" || -d "$ZSH/plugins/$plugin" ]]; then
        plugins+=("$plugin")
    fi
done

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
fi


# ------------------------------------------------------------
# ENVIRONMENT & PATH
# ------------------------------------------------------------
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export MANPATH="/usr/local/man:${MANPATH:-}"
export LANG="${LANG:-en_US.UTF-8}"
export TERMINAL="kitty"
export BROWSER="firefox"
export FILEMANAGER="thunar"
# export TERM="xterm-256color"

# fnm (Fast Node Manager)
FNM_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/fnm"
if [[ -d "$FNM_PATH" ]] && command -v fnm >/dev/null 2>&1; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi


# ------------------------------------------------------------
# EDITOR
# ------------------------------------------------------------
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#  export EDITOR='nvim'
# fi

#------------------------------------------------------
# Environment Variables
#-------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export SUDO_EDITOR="nvim"
export FCEDIT="nvim"

# ------------------------------------------------------------
# TOOL INITIALISATION
# ------------------------------------------------------------
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)
# eval "$(ssh-agent -s)"
# ssh-add ~/.ssh/id_ed25519


# ------------------------------------------------------------
# CORE ALIASES — Navigation & Utilities
# ------------------------------------------------------------
alias c='clear'
alias q='exit'
alias v='nvim'
alias vi='nvim'
alias nvim2="NVIM_APPNAME=nvim2 nvim"
if command -v termux-open >/dev/null 2>&1; then
    alias open='termux-open'
elif command -v xdg-open >/dev/null 2>&1; then
    alias open='xdg-open'
fi
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons -F -H --group-directories-first --git -1'
fi
# alias ls='eza --all --long --group --group-directories-first --icons --header --time-style long-iso'

alias ..='cd ..'
alias ...='cd ../..'
alias mkd='mkdir -p'
alias path='echo $PATH | tr ":" "\n"'


# Copy and go to the directory
function cpg() {
	if [[ -d "$2" ]];then
		cp "$1" "$2" && cd "$2"
	else
		cp "$1" "$2"
	fi
}

# Move and go to the directory
function mvg() {
	if [[ -d "$2" ]];then
		mv "$1" "$2" && cd "$2"
	else
		mv "$1" "$2"
	fi
}

# Create and go to the directory
function mkdirg() {
	mkdir -p "$@" && cd "$@"
}

# ------------------------------------------------------------
# CORE ALIASES — System & Maintenance
# ------------------------------------------------------------
alias mst='echo "--- Home Directory Usage ---" && du -h -d 1 "$HOME" | sort -hr | head -n 5 && echo "--- Total Termux App Usage ---" && du -sh "$PREFIX/.."'
alias ops='bash ~/scripts/dashboard.sh'

if [[ -x "$(command -v lazygit)" ]]; then
    alias lg='lazygit'
fi

alias ports='ss -tulnp'
alias psg='ps aux | grep'

# Host-aware sweep
function sweep() {
    if [[ "$(uname -o)" == "Android" ]]; then
        # Termux
        rm -rf ~/.cache/*
        rm -rf $PREFIX/tmp/*
        npm cache clean --force
        go clean -cache
        apt autoremove -y && apt clean
    else
        # EndeavourOS / Arch
        rm -rf ~/.cache/*
        npm cache clean --force
        go clean -cache
        sudo pacman -Sc --noconfirm
        yay -Sc --noconfirm
    fi
    echo "✅ Sweep done."
}

# Host-aware update
function update() {
    if [[ "$(uname -o)" == "Android" ]]; then
        apt update && apt upgrade -y
    else
        sudo pacman -Syu && yay -Syu
    fi
}


# ------------------------------------------------------------
# CORE ALIASES — DWM & Dotfiles
# ------------------------------------------------------------
alias recomp='cd ~/suckless-meta/dwm && rm -rf config.h && sudo make clean install'
alias dwmconf='nvim ~/suckless-meta/dwm/config.def.h'
alias niriconf='nvim ~/.config/niri/config.kdl'
alias xconf='nvim ~/dotfiles/scripts/start_dwm.sh'
alias nvimconf= 'z nvim && nvim .'

# ------------------------------------------------------------
# CORE ALIASES — Neovim
# ------------------------------------------------------------
alias vi='nvim .'
alias vrc='nvim ~/.zshrc'
alias vdots='cd ~/dotfiles && nvim .'

# ------------------------------------------------------------
# CORE ALIASES — Git
# ------------------------------------------------------------
alias check-secrets="grep -rE 'API_KEY|SECRET|PASSWORD' ."

function gpush() {
    git add .
    git diff --cached --stat
    echo -n "Commit message (leave blank to auto): "
    read msg
    if [[ -z "$msg" ]]; then
        local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        local changed=$(git diff --cached --name-only | wc -l | tr -d ' ')
        msg="[$branch] Update $changed file(s) — $(date +'%b %d, %Y')"
    fi
    git commit -m "$msg" && git push origin main
}


# ------------------------------------------------------------
# CORE ALIASES — Media & Downloads
# ------------------------------------------------------------
alias ytdlmp4='yt-dlp -f "bv[ext!=webm][height<=720]+ba/b[ext!=webm][height<=720]" --merge-output-format mp4 -o "%(title)s.%(ext)s"'
alias getmp3='yt-dlp -x --audio-format mp3 --audio-quality 0 --add-metadata --embed-thumbnail -o "~/Downloads/%(title)s.%(ext)s"'
alias getvid='yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --add-metadata -o "~/Downloads/%(title)s.%(ext)s"'
alias play="ffplay -nodisp -autoexit"

# ------------------------------------------------------------
# CORE ALIASES — Audio & Brightness
# ------------------------------------------------------------
alias vup='amixer set Master 5%+'
alias vdown='amixer set Master 5%-'
alias bup='brightnessctl set +10%'
alias bdown='brightnessctl set 10%-'


# ------------------------------------------------------------
# CORE ALIASES — Timers
# ------------------------------------------------------------
alias r60='termdown 60 -f slant && termux-vibrate && termux-tts-speak "Time up"'
alias r90='termdown 90 -f slant && termux-vibrate && termux-tts-speak "Time up"'


# ------------------------------------------------------------
# CORE ALIASES — Terminal Browsers & Web
# ------------------------------------------------------------
alias wiki='w3m en.wikipedia.org'
alias reddit='w3m old.reddit.com'
alias news='w3m news.ycombinator.com'
alias hn='w3m news.ycombinator.com'
alias w3m-tor='pxc w3m'

function s() {
    local query=$(echo "$*" | sed 's/ /+/g')
    w3m "https://duckduckgo.com/html/?q=$query"
}

# ------------------------------------------------------------
# CORE ALIASES — Terminal Browsers & Web
# ------------------------------------------------------------
# Basic quick sync with progress and archive mode
alias rsync-copy='rsync -avP'
# Exact mirror sync (deletes extra files at destination)
alias rsync-mirror='rsync -avP --delete'
# Compressed sync over network
alias rsync-net='rsync -avzP'
# Safe dry run check (shows what would happen without transferring)
alias rsync-check='rsync -avP --dry-run'

# ------------------------------------------------------------
# CORE ALIASES — Session Management
# ------------------------------------------------------------
# The Nuke Alias
alias nuke="rm -f ~/.zsh_history && history -c && pkill -u $(whoami) && exit"
# The "Quiet Nuke" (Wipes logs but keeps the session open)
alias wipe="rm -f ~/.zsh_history && truncate -s 0 ~/.zsh_history && history -p && clear"

sleeppc() {
    killall -q picom
    sleep 20
    systemctl suspend
}


# ------------------------------------------------------------
# CORE ALIASES — Shortcuts & Misc
# ------------------------------------------------------------
alias grab="~/.shortcuts/grab.sh"
alias kali="nh"
alias ksh='rish -c "nh"'

if [[ -x "$(command -v bat)" ]]; then
    alias cat='bat'
fi

if [[ -x "$(command -v fzf)" ]]; then
    alias fzf='fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'
    # Alias to fuzzy find files in the current folder(s), preview them, and launch in an editor
	if [[ -x "$(command -v xdg-open)" ]]; then
		alias preview='open $(fzf --info=inline --query="${@}")'
	else
		alias preview='edit $(fzf --info=inline --query="${@}")'
	fi
fi




# ------------------------------------------------------------
# NETWORK & SECURITY
# ------------------------------------------------------------

# User-Agent Strings
UA_IPHONE="Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
UA_WINDOWS="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
UA_LINUX="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

# Identity Aliases
alias curl-iphone="curl -A '$UA_IPHONE'"
alias curl-win="curl -A '$UA_WINDOWS'"
alias curl-linux="curl -A '$UA_LINUX'"

# Proxychains shorthand
alias pxc="proxychains4 -q"

# Tor Control
alias tor-on="pgrep -x tor > /dev/null && echo '✅ Tor already running' || (tor && echo '🚀 Starting Tor...' && sleep 5)"
alias tor-off="pkill -9 tor && echo '🛑 Tor stopped.'"
alias tor-check="pxc curl -s https://check.torproject.org/api/ip"

# IP Checking
alias myip="curl -s https://ifconfig.me"
alias torip="pxc curl -s https://ifconfig.me"


# Get local IP addresses
if [[ -x "$(command -v ip)" ]]; then
    alias iplocal="ip -br -c a"
else
    alias iplocal="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"
fi

# Get public IP addresses
if [[ -x "$(command -v curl)" ]]; then
    alias ipexternal="curl -s ifconfig.me && echo"
elif [[ -x "$(command -v wget)" ]]; then
    alias ipexternal="wget -qO- ifconfig.me && echo"
fi

# Stealth Function
# Usage: pxc-stealth-win <command>
pxc-stealth-win() {
    proxychains4 -q curl -A "$UA_WINDOWS" "$@"
}

alias nmtui="NEWT_COLORS=\$(tr '\n' ' ' < ~/.config/nmtui/theme) nmtui"

# ------------------------------------------------------------
# BANNER & TODO SYSTEM
# ------------------------------------------------------------

# source ~/scripts/rbanner.sh

function todo() {
    if [[ -z "$1" ]]; then
        cat -n ~/.todo 2>/dev/null || echo "No tasks."
    elif [[ "$1" == "clear" ]]; then
        > ~/.todo && echo "Cleared." && source ~/scripts/rbanner.sh
    else
        echo "$*" >> ~/.todo && source ~/scripts/rbanner.sh
    fi
}

# --- Auto-bell for long-running terminal tasks ---
typeset -g MY_CMD_START_TIME=0

function preexec() {
    MY_CMD_START_TIME=$SECONDS
}

function precmd() {
    local exit_code=$?
    if (( MY_CMD_START_TIME > 0 )); then
        local duration=$(( SECONDS - MY_CMD_START_TIME ))
        # If the command took 10+ seconds, ring the bell on completion
        if (( duration > 10 )); then
            echo -e "\a"
        fi
        MY_CMD_START_TIME=0
    fi
}

# Automatically sync Wayland/niri variables inside tmux panes
if [ -n "$TMUX" ]; then
    eval $(tmux show-environment -s WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE 2>/dev/null)
fi

# ------------------------------------------------------------
# STARTUP
# ------------------------------------------------------------
fastfetch

#Import colorscheme from 'wal' asynchronously
# (cat ~/.cache/wal/sequences &)
# pulseaudio --kill >/dev/null 2>&1
# pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

# Powerlevel10k config
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
set -o vi

# 1. Force zsh-autosuggestions to accept with Ctrl+Space instead of just Right Arrow
bindkey '^ ' forward-word

# 2. Make History Substring Search work with Up/Down Arrows
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Flutter
export PATH="$HOME/.local/share/flutter/bin:$PATH"

# Android SDK (Local user directory)
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/build-tools/latest"
export PATH="$PATH:$ANDROID_HOME/build-tools/28.0.3"

# Browser
export CHROME_EXECUTABLE=/usr/bin/chromium
