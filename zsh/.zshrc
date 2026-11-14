# ============================================================
#  ~/.zshrc  —  Arch / EndeavourOS (niri, dwm) + Termux
# ============================================================
#  Sections
#    1.  Helpers & host detection
#    2.  Environment & PATH
#    3.  Oh My Zsh (plugins, vi-mode)
#    4.  Shell options & history
#    5.  Completion
#    6.  Tool initialisation (starship, zoxide, fzf, bat)
#    7.  Keybindings
#    8.  Aliases
#    9.  Functions
#    10. Hooks (long-running command bell, tmux env sync)
#    11. Local overrides & startup banner
# ============================================================


# ------------------------------------------------------------
# 1. HELPERS & HOST DETECTION
# ------------------------------------------------------------

# has <cmd> — true if <cmd> is on PATH (uses zsh's command hash: no fork, fast)
has() { (( $+commands[$1] )) }

# _confirm "question" — y/N prompt, returns 0 only on "y"
_confirm() {
    local reply
    read -q "reply?$1 [y/N] "
    local rc=$?
    print
    return $rc
}

# IS_TERMUX=1 when running inside Termux on Android (no subprocess needed)
typeset -gi IS_TERMUX=0
[[ $OSTYPE == *android* || ${PREFIX:-} == *com.termux* ]] && IS_TERMUX=1


# ------------------------------------------------------------
# 2. ENVIRONMENT & PATH
# ------------------------------------------------------------
export LANG="${LANG:-en_US.UTF-8}"
export MANPATH="/usr/local/man:${MANPATH:-}"
export TERMINAL="kitty"
export BROWSER="qutebrowser"
export FILEMANAGER="thunar"
# export TERM="xterm-256color"

# --- PATH ---------------------------------------------------
typeset -U path PATH            # keep PATH entries unique
path=(
    $HOME/bin
    $HOME/.local/bin
    /usr/local/bin
    $path
)

# Flutter
[[ -d $HOME/.local/share/flutter/bin ]] && path=($HOME/.local/share/flutter/bin $path)

# Android SDK (local user directory)
export ANDROID_HOME="$HOME/Android/Sdk"
if [[ -d $ANDROID_HOME ]]; then
    path+=(
        $ANDROID_HOME/cmdline-tools/latest/bin
        $ANDROID_HOME/platform-tools
        $ANDROID_HOME/build-tools/latest
        $ANDROID_HOME/build-tools/28.0.3
    )
fi

# Drop PATH entries that don't exist on this machine
path=( ${^path}(N-/) )

# --- Node (fnm) ---------------------------------------------
# --use-on-cd switches Node versions automatically from .nvmrc / .node-version
FNM_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/fnm"
[[ -d $FNM_PATH ]] && path=($FNM_PATH $path)
has fnm && eval "$(fnm env --use-on-cd --shell zsh)"

# --- Editor -------------------------------------------------
if   has nvim; then _editor=nvim
elif has vim;  then _editor=vim
else                _editor=vi
fi
export EDITOR=$_editor VISUAL=$_editor SUDO_EDITOR=$_editor FCEDIT=$_editor
unset _editor

# --- Dev tools ----------------------------------------------
export CHROME_EXECUTABLE=/usr/bin/chromium    # Flutter web


# ------------------------------------------------------------
# 3. OH MY ZSH
# ------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

ZSH_THEME=""                          # prompt is handled by Starship
zstyle ':omz:update' mode disabled    # disabled | auto | reminder
HIST_STAMPS="mm/dd/yyyy"              # timestamp format for `history`

# --- vi-mode plugin -----------------------------------------
# Cursor codes: 2 = steady block, 6 = steady beam
VI_MODE_SET_CURSOR=true
VI_MODE_CURSOR_INSERT=6
VI_MODE_CURSOR_NORMAL=2
# Redraw the prompt on mode change so Starship's vi indicator updates
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
# --- web-search plugin --------------------------------------
ZSH_WEB_SEARCH_ENGINES=(
    arch "https://wiki.archlinux.org/index.php?search="
)
# --- Plugins ------------------------------------------------
plugins=(git vi-mode sudo fancy-ctrl-z command-not-found colored-man-pages copypath copyfile extract web-search)

# Third-party plugins are added only if installed (git clone into $ZSH_CUSTOM/plugins).
# Order matters:
#   fzf-tab                  → before autosuggestions / syntax-highlighting
#   zsh-syntax-highlighting  → before history-substring-search
for plugin in you-should-use fzf-tab zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
    if [[ -d "$ZSH_CUSTOM/plugins/$plugin" || -d "$ZSH/plugins/$plugin" ]]; then
        plugins+=("$plugin")
    fi
done
unset plugin

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    # Fallback so completion still works without Oh My Zsh
    autoload -Uz compinit && compinit
fi


# ------------------------------------------------------------
# 4. SHELL OPTIONS & HISTORY
# ------------------------------------------------------------
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY          # save timestamps
setopt HIST_IGNORE_ALL_DUPS      # no duplicate entries
setopt HIST_IGNORE_SPACE         # commands starting with a space are not saved (handy for secrets)
setopt HIST_REDUCE_BLANKS        # trim superfluous whitespace
setopt HIST_VERIFY               # show !! expansions before running them
setopt SHARE_HISTORY             # share history between terminals

setopt AUTO_CD                   # typing a directory name cd's into it
setopt AUTO_PUSHD                # cd pushes onto the directory stack (use `dirs -v`, `cd -N`)
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt INTERACTIVE_COMMENTS      # allow # comments on the command line

KEYTIMEOUT=1                     # near-instant ESC in vi-mode (default is 0.4s)


# ------------------------------------------------------------
# 5. COMPLETION
# ------------------------------------------------------------
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'      # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no                                  # let fzf-tab handle the menu
zstyle ':completion:*:descriptions' format '[%d]'               # group headers in fzf-tab

# fzf-tab previews / behaviour
zstyle ':fzf-tab:*' switch-group ',' '.'                        # , and . cycle completion groups
has eza && zstyle ':fzf-tab:complete:(cd|z|zi|ls|eza):*' fzf-preview 'eza -1 --color=always --icons $realpath'


# ------------------------------------------------------------
# 6. TOOL INITIALISATION
# ------------------------------------------------------------
has starship && eval "$(starship init zsh)"
has zoxide   && eval "$(zoxide init zsh)"      # provides `z` and `zi`

# bat is called `batcat` on Debian/Ubuntu
if   has bat;    then _bat=bat
elif has batcat; then _bat=batcat
fi
# Coloured man pages via bat
[[ -n $_bat ]] && export MANPAGER="sh -c 'col -bx | $_bat -l man -p'"

# --- fzf (needs fzf ≥ 0.48 for `fzf --zsh`) ------------------
if has fzf; then
    source <(fzf --zsh)       # Ctrl-R history, Ctrl-T files, Alt-C directories

    # Catppuccin Mocha colours + sane layout
    export FZF_DEFAULT_OPTS=" \
    --height=40% --layout=reverse --border --info=inline \
    --color=bg:#1e1e2e,bg+:#313244,fg:#cdd6f4,fg+:#cdd6f4 \
    --color=hl:#b4befe,hl+:#b4befe,info:#cba6f7,prompt:#94e2d5 \
    --color=pointer:#b4befe,marker:#a6e3a1,spinner:#cba6f7 \
    --color=header:#89b4fa,border:#585b70,gutter:#1e1e2e"

    # Use fd (fast, respects .gitignore) when available
    if has fd; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi

    # Previews — applied only to Ctrl-T / Alt-C, so `cmd | fzf` isn't affected
    # (the old `alias fzf='fzf --preview ...'` broke non-file input)
    if [[ -n $_bat ]]; then
        FZF_FILE_PREVIEW="$_bat --style=numbers --color=always --line-range :500 {}"
    else
        FZF_FILE_PREVIEW="head -n 200 {}"
    fi
    export FZF_CTRL_T_OPTS="--preview '$FZF_FILE_PREVIEW'"
    has eza && export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons {}'"
fi


# ------------------------------------------------------------
# 7. KEYBINDINGS
# ------------------------------------------------------------
# Ctrl+Space → accept the next word of the autosuggestion
bindkey -M viins '^ ' forward-word

# History substring search: ↑/↓ in insert mode, k/j in normal mode
if (( $+widgets[history-substring-search-up] )); then
    for key in '^[[A' '^[OA' "${terminfo[kcuu1]:-}"; do
        [[ -n $key ]] && bindkey -M viins "$key" history-substring-search-up
    done
    for key in '^[[B' '^[OB' "${terminfo[kcud1]:-}"; do
        [[ -n $key ]] && bindkey -M viins "$key" history-substring-search-down
    done
    bindkey -M vicmd 'k' history-substring-search-up
    bindkey -M vicmd 'j' history-substring-search-down
    unset key
fi


# ------------------------------------------------------------
# 8. ALIASES
# ------------------------------------------------------------

# --- Core & navigation --------------------------------------
alias c='clear'
alias q='exit'
alias reload='exec zsh'                     # restart the shell and re-read .zshrc
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkd='mkdir -p'
alias path='print -l $path'                 # one PATH entry per line
alias grep='grep --color=auto'
alias df='df -h'
alias free='free -h'

# --- Editors ------------------------------------------------
if has nvim; then
    alias v='nvim'
    alias vi='nvim'
    alias vim='nvim'
    alias v.='nvim .'                       # open current directory
    alias nvim2='NVIM_APPNAME=nvim2 nvim'   # alternate config in ~/.config/nvim2
fi
alias y='yazi'

# --- Open files with the desktop default --------------------
if has termux-open; then
    alias open='termux-open'
elif has xdg-open; then
    alias open='xdg-open'
fi

# --- Listing (eza) ------------------------------------------
if has eza; then
    alias ls='eza --icons -F --group-directories-first -1'
    alias ll='eza -lah --icons --git --group-directories-first --time-style=long-iso'
    alias lt='eza --tree --level=2 --icons'      # quick tree view
else
    alias ls='ls --color=auto -F --group-directories-first'
    alias ll='ls -lah'
fi

# --- cat → bat ----------------------------------------------
# --paging=never keeps it cat-like (no auto-pager); use `bat` directly for paging
[[ -n $_bat ]] && alias cat="$_bat --paging=never"

# --- Config shortcuts ---------------------------------------
# Defined from two tables so adding a new one is a single line.
#   files → open the file in $EDITOR
#   dirs  → cd into the directory and open it in $EDITOR
() {
    local name target
    local -A files=(
        vrc           $HOME/.zshrc
        tmuxconf      $HOME/.tmux.conf
        picomconf     $HOME/.config/picom/picom.conf
        xconf         $HOME/.local/bin/start_dwm.sh
        niriconf      $HOME/.config/niri/config.kdl
        starshipconf  $HOME/.config/starship.toml
        kittyconf     $HOME/.config/kitty/kitty.conf
        dwmconf       $HOME/suckless-meta/dwm/config.def.h
    )
    local -A dirs=(
        vdots         $HOME/dotfiles
        nvimconf      $HOME/.config/nvim
        waybarconf    $HOME/.config/waybar
    )
    for name target in ${(kv)files}; do alias "$name=\$EDITOR ${(q)target}"; done
    for name target in ${(kv)dirs};  do alias "$name=cd ${(q)target} && \$EDITOR ."; done
}
alias waybartheme="$HOME/.config/waybar/scripts/theme.sh"

# --- System -------------------------------------------------
alias ops='bash ~/scripts/dashboard.sh'
alias ports='ss -tulnp'                     # add sudo to see process names for all users
has lazygit && alias lg='lazygit'

# --- Packages (Arch only) -----------------------------------
if (( ! IS_TERMUX )) && has pacman; then
    alias pacs='pacman -Ss'
    alias pacq='pacman -Qs'
    alias pacown='pacman -Qo'
    alias orphans='pacman -Qdtq'
    alias pacsize='expac -H M "%m\t%n" | sort -h | tail -20'
    alias failed='systemctl --failed; journalctl -p 3 -xb --no-pager | tail -20'
fi

# --- Media & downloads (yt-dlp) -----------------------------
alias ytdlmp4='yt-dlp -f "bv[ext!=webm][height<=720]+ba/b[ext!=webm][height<=720]" --merge-output-format mp4 -o "%(title)s.%(ext)s"'
alias getmp3='yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-metadata --embed-thumbnail -o "$HOME/Downloads/%(title)s.%(ext)s"'
alias getvid='yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --embed-metadata -o "$HOME/Downloads/%(title)s.%(ext)s"'
alias play='ffplay -nodisp -autoexit'

# --- Audio & brightness -------------------------------------
# PipeWire/WirePlumber if present, otherwise ALSA
if has wpctl; then
    alias vup='wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+'
    alias vdown='wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-'
    alias vmute='wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle'
else
    alias vup='amixer set Master 5%+'
    alias vdown='amixer set Master 5%-'
    alias vmute='amixer set Master toggle'
fi
alias bup='brightnessctl set +10%'
alias bdown='brightnessctl set 10%-'

# --- Timers (see timer() below) -----------------------------
alias r60='timer 60'
alias r90='timer 90'

# --- Terminal browsers & web --------------------------------
alias wiki='w3m en.wikipedia.org'
alias reddit='w3m old.reddit.com'
alias hn='w3m news.ycombinator.com'
alias news='w3m news.ycombinator.com'
alias w3m-tor='pxc w3m'                     # w3m through Tor

# --- rsync --------------------------------------------------
alias rsync-copy='rsync -avP'               # archive mode + progress
alias rsync-mirror='rsync -avP --delete'    # exact mirror (deletes extras at destination!)
alias rsync-net='rsync -avzP'               # compressed, for network transfers
alias rsync-check='rsync -avP --dry-run'    # preview only, transfers nothing

# --- Network & privacy --------------------------------------
UA_IPHONE="Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
UA_WINDOWS="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
UA_LINUX="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

alias curl-iphone="curl -A '$UA_IPHONE'"
alias curl-win="curl -A '$UA_WINDOWS'"
alias curl-linux="curl -A '$UA_LINUX'"

alias pxc='proxychains4 -q'                 # run any command through proxychains
alias tor-off='pkill -x tor && echo "🛑 Tor stopped."'
alias tor-check='pxc curl -s https://check.torproject.org/api/ip'
alias myip='curl -s https://ifconfig.me && echo'
alias torip='pxc curl -s https://ifconfig.me && echo'

if has ip; then
    alias iplocal='ip -br -c a'
else
    alias iplocal="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"
fi

# --- Misc shortcuts -----------------------------------------
alias grab="$HOME/.shortcuts/grab.sh"

# --- Termux only --------------------------------------------
if (( IS_TERMUX )); then
    alias mst='echo "--- Home Directory Usage ---" && du -h -d 1 "$HOME" | sort -hr | head -n 5 && echo "--- Total Termux App Usage ---" && du -sh "$PREFIX/.."'
    alias kali='nh'                         # NetHunter
    alias ksh='rish -c "nh"'                # via Shizuku
fi


# ------------------------------------------------------------
# 9. FUNCTIONS
# ------------------------------------------------------------

# --- Files & directories ------------------------------------

# cpg SRC DEST — copy, then cd into DEST if it's a directory
cpg() {
    if [[ -d $2 ]]; then cp -- "$1" "$2" && cd -- "$2"
    else cp -- "$1" "$2"; fi
}

# mvg SRC DEST — move, then cd into DEST if it's a directory
mvg() {
    if [[ -d $2 ]]; then mv -- "$1" "$2" && cd -- "$2"
    else mv -- "$1" "$2"; fi
}

# mkdirg DIR — create DIR (with parents) and cd into it
mkdirg() { mkdir -p -- "$1" && cd -- "$1"; }

# extract ARCHIVE — unpack almost any archive format
extract() {
    [[ -f $1 ]] || { print -u2 "Usage: extract <archive>"; return 1; }
    case $1 in
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.xz|*.txz)   tar xJf "$1" ;;
        *.tar.zst)        tar --zstd -xf "$1" ;;
        *.tar)            tar xf "$1" ;;
        *.zip)            unzip "$1" ;;
        *.7z)             7z x "$1" ;;
        *.rar)            unrar x "$1" ;;
        *.gz)             gunzip "$1" ;;
        *.bz2)            bunzip2 "$1" ;;
        *.xz)             unxz "$1" ;;
        *) print -u2 "extract: unknown archive format: $1"; return 1 ;;
    esac
}

# pkgi / pkgr — fuzzy install and remove (Arch only)
if (( ! IS_TERMUX )) && has pacman; then
		# pkgi — fuzzy install from repos + AUR
		pkgi() {
				local pkgs=$( (pacman -Slq; has yay && yay -Slqa 2>/dev/null) | sort -u \
						| fzf -m --preview 'yay -Si {1}' --prompt='install > ')
				[[ -n $pkgs ]] && yay -S ${=pkgs}
		}
# pkgr — fuzzy remove installed packages
pkgr() {
		local pkgs=$(pacman -Qq | fzf -m --preview 'pacman -Qi {1}' --prompt='remove > ')
		[[ -n $pkgs ]] && sudo pacman -Rns ${=pkgs}
}
fi

# serve [PORT] — serve the current directory over HTTP (default 8000)
serve() { python3 -m http.server "${1:-8000}"; }

# --- Fuzzy helpers (fzf) ------------------------------------

# preview — fuzzy-find a file, then open it (desktop default app, else $EDITOR)
preview() {
    local f
    f=$(fzf --query="$*" --preview "${FZF_FILE_PREVIEW:-head -n 200 {}}") || return
    [[ -n $f ]] || return
    if (( $+aliases[open] )); then open "$f"; else $EDITOR "$f"; fi
}

# fe — fuzzy-find a file and edit it
fe() {
    local f
    f=$(fzf --query="$*" --preview "${FZF_FILE_PREVIEW:-head -n 200 {}}") && $EDITOR "$f"
}

# fkill [SIGNAL] — pick processes with fzf and kill them (default SIGTERM)
fkill() {
    local pids
    pids=$(ps -u "$USER" -o pid,comm,%cpu,%mem --sort=-%cpu | sed 1d \
           | fzf -m --header='Select process(es) to kill (Tab = multi-select)' | awk '{print $1}')
    [[ -n $pids ]] && print -- "$pids" | xargs kill -"${1:-15}"
}

# backup FILE — timestamped copy next to the original
backup() { cp -a -- "$1" "$1.bak.$(date +%Y%m%d-%H%M%S)"; }

# up N — go up N directories
up() { local d=""; for ((i=0; i<${1:-1}; i++)); do d+="../"; done; cd "$d"; }

# take FILE — mkdir + touch + edit helper for new scripts
newscript() { print -r -- "#!/usr/bin/env bash\nset -euo pipefail\n" > "$1" && chmod +x "$1" && $EDITOR "$1"; }

# cheat QUERY — fetch cheat sheets from cheat.sh
cheat() { curl -s "cheat.sh/${(j:+:)@}" | ${PAGER:-less}; }

# weather — quick terminal forecast
weather() { curl -s "wttr.in/${1:-Lagos}?0"; }

# bigfiles — largest files under the current directory
bigfiles() { du -ah . 2>/dev/null | sort -hr | head -n ${1:-20}; }

# --- System maintenance -------------------------------------

# sweep — clear caches (asks for confirmation; host-aware)
sweep() {
    print -P "%F{yellow}This wipes ~/.cache and package-manager caches.%f"
    _confirm "Continue?" || { print "Aborted."; return 1; }

    rm -rf ~/.cache/*(N)
    has npm && npm cache clean --force
    has go  && go clean -cache

    if (( IS_TERMUX )); then
        rm -rf $PREFIX/tmp/*(N)
        apt autoremove -y && apt clean
    else
        sudo pacman -Sc --noconfirm
        has yay && yay -Sc --noconfirm
    fi
    print "✅ Sweep done."
}

# update — full system update (host-aware). `yay` already covers the official repos.
update() {
    if (( IS_TERMUX )); then
        apt update && apt upgrade -y
    elif has yay; then
        yay -Syu
    else
        sudo pacman -Syu
    fi
}

# recomp — rebuild and install dwm from a fresh config.h (runs in a subshell: your cwd is untouched)
recomp() {
    ( cd ~/suckless-meta/dwm && rm -f config.h && sudo make clean install )
}

# sleeppc — stop picom, wait 20s, then suspend
sleeppc() {
    has picom && pkill -x picom
    sleep 20
    systemctl suspend
}

# timer [SECONDS] — countdown, then vibrate/speak (Termux) or notify (desktop)
timer() {
    local secs=${1:-60}
    termdown "$secs" -f slant || return
    if (( IS_TERMUX )); then
        termux-vibrate && termux-tts-speak "Time up"
    else
        print -n '\a'
        has notify-send && notify-send "⏰ Timer" "${secs}s is up"
    fi
}

# psg PATTERN — grep running processes (the [x]yz trick hides the grep itself)
psg() {
    (( $# )) || { print -u2 "Usage: psg <pattern>"; return 1; }
    ps aux | grep -i "[${1[1]}]${1[2,-1]}"
}

# --- Default applications (xdg-mime) -------------------------

# mimeof FILE — show a file's MIME type and its current default app
mimeof() {
    [[ -e $1 ]] || { print -u2 "Usage: mimeof <file>"; return 1; }
    local mime=$(xdg-mime query filetype "$1")
    print -P "%F{blue}type:%f    $mime"
    print -P "%F{blue}default:%f $(xdg-mime query default $mime)"
}

# defapp MIME — current default handler for a MIME type
defapp() { xdg-mime query default "$1"; }

# canopen MIME — list installed apps that declare support for a MIME type
canopen() {
    grep -l "^MimeType=.*$1" /usr/share/applications/*.desktop(N) ~/.local/share/applications/*.desktop(N) \
        | xargs -n1 basename
}

# setdefault MIME [APP.desktop] — set the default; pick the app with fzf if omitted
setdefault() {
    (( $# )) || { print -u2 "Usage: setdefault <mime> [app.desktop]"; return 1; }
    local mime=$1 app=$2
    if [[ -z $app ]]; then
        app=$( { canopen "$mime"; } | sort -u | fzf --prompt="default for $mime > ") || return
    fi
    xdg-mime default "$app" "$mime" && print "$mime → $(xdg-mime query default $mime)"
}

# setfor FILE [APP.desktop] — same as setdefault, but takes the MIME type from a file
setfor() {
    [[ -e $1 ]] || { print -u2 "Usage: setfor <file> [app.desktop]"; return 1; }
    setdefault "$(xdg-mime query filetype "$1")" "${@:2}"
}

# --- Default apps by category --------------------------------

# Category → MIME types it covers (edit freely)
typeset -gA DEFAULT_CATEGORIES=(
    browser  "x-scheme-handler/http x-scheme-handler/https text/html"
    pdf      "application/pdf"
    ebook    "application/epub+zip image/vnd.djvu"
    image    "image/png image/jpeg image/gif image/webp image/svg+xml"
    video    "video/mp4 video/x-matroska video/webm video/quicktime"
    audio    "audio/mpeg audio/flac audio/ogg audio/x-wav"
    text     "text/plain text/markdown text/x-shellscript"
    archive  "application/zip application/x-tar application/x-7z-compressed application/x-compressed-tar"
    files    "inode/directory"
    mail     "x-scheme-handler/mailto"
)

# setapp [CATEGORY] [APP.desktop] — set the default app for a whole category
# Omit either argument and fzf will ask.
setapp() {
    local cat=$1 app=$2 m
    if [[ -z $cat ]]; then
        cat=$(print -l ${(ko)DEFAULT_CATEGORIES} | fzf --prompt="category > ") || return
    fi
    local -a mimes=( ${=DEFAULT_CATEGORIES[$cat]} )
    (( $#mimes )) || { print -u2 "Unknown category: $cat (see: defapps)"; return 1; }

    if [[ -z $app ]]; then
        app=$(canopen $mimes[1] | sort -u | fzf --prompt="$cat > ") || return
    fi

    for m in $mimes; do xdg-mime default "$app" "$m"; done
    [[ $cat == browser ]] && xdg-settings set default-web-browser "$app" 2>/dev/null
    print "$cat → $app"
}

# defapps — show the current default for every category
defapps() {
    local c
    for c in ${(ko)DEFAULT_CATEGORIES}; do
        printf '%-10s %s\n' $c "$(xdg-mime query default ${${=DEFAULT_CATEGORIES[$c]}[1]})"
    done
}

# --- Git ----------------------------------------------------

# check-secrets — look for likely credentials (git-aware, skips .git/node_modules)
check-secrets() {
    local pattern='API_KEY|SECRET|PASSWORD|TOKEN|PRIVATE KEY'
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        git grep -nIiE --untracked "$pattern" || print "No matches."
    else
        grep -rnIiE --exclude-dir={.git,node_modules,.venv} "$pattern" . || print "No matches."
    fi
}

# gpush — stage everything, review, commit (auto-message if blank), push current branch
gpush() {
    git rev-parse --is-inside-work-tree &>/dev/null \
        || { print -u2 "❌ Not inside a git repository."; return 1; }

    git add .
    if git diff --cached --quiet; then
        print "Nothing to commit."
        return 0
    fi
    git diff --cached --stat

    # Heads-up if the staged diff looks like it contains credentials
    if git diff --cached -U0 | grep -qiE '^\+.*(api_key|secret|password|token)'; then
        print -P "%F{yellow}⚠️  Staged changes mention API_KEY / SECRET / PASSWORD / TOKEN.%f"
        _confirm "Commit anyway?" || { print "Aborted (changes remain staged)."; return 1; }
    fi

    local branch=$(git rev-parse --abbrev-ref HEAD) msg
    read "msg?Commit message (leave blank to auto): "
    if [[ -z $msg ]]; then
        local changed=$(git diff --cached --name-only | wc -l | tr -d ' ')
        msg="[$branch] Update $changed file(s) — $(date +'%b %d, %Y')"
    fi

    git commit -m "$msg" && git push origin "$branch"
}

# --- Web ----------------------------------------------------

# s QUERY — DuckDuckGo search in w3m
s() { w3m "https://duckduckgo.com/html/?q=${(j:+:)@}"; }

# --- Network & privacy --------------------------------------

# tor-on — start Tor in the background if it isn't already running
tor-on() {
    if pgrep -x tor >/dev/null; then
        echo "✅ Tor already running"
    else
        echo "🚀 Starting Tor..."
        tor >"$HOME/.cache/tor.log" 2>&1 &!
        sleep 5
    fi
}

# pxc-stealth-win URL... — curl through proxychains with a Windows/Chrome user-agent
pxc-stealth-win() { proxychains4 -q curl -A "$UA_WINDOWS" "$@"; }

# nmtui — apply a custom colour theme when ~/.config/nmtui/theme exists
nmtui() {
    local theme=$HOME/.config/nmtui/theme
    if [[ -r $theme ]]; then
        NEWT_COLORS="$(tr '\n' ' ' < "$theme")" command nmtui "$@"
    else
        command nmtui "$@"
    fi
}

# niri-remote ARGS — point at the running niri session's socket (e.g. when SSH'd in) and run `niri msg`
niri-remote() {
    local -a socks=( /run/user/$UID/niri.*.sock(N) )
    (( $#socks )) || { print -u2 "niri-remote: no niri socket found"; return 1; }
    export NIRI_SOCKET=${socks[1]}
    niri msg "$@"
}

# --- Session privacy ----------------------------------------

# _wipe_history — delete the history file AND stop this session from saving a new one
_wipe_history() {
    rm -f "${HISTFILE:-$HOME/.zsh_history}"
    fc -p /dev/null        # swap in an empty in-memory history that saves nowhere
}

# wipe — erase shell history, keep the session open
wipe() {
    _wipe_history && clear && print "🧹 History wiped."
}

# nuke — erase history, then kill ALL your processes (logs you out!)
nuke() {
    _confirm "💣 Wipe history and kill ALL processes for $USER?" || { print "Aborted."; return 1; }
    _wipe_history
    pkill -u "$USER"
}

# --- Todo list ----------------------------------------------
# todo              list tasks
# todo <text>       add a task
# todo rm <number>  remove a task
# todo clear        remove everything
todo() {
    local file=$HOME/.todo
    case "$1" in
        "")    [[ -s $file ]] && command cat -n "$file" || echo "No tasks."; return ;;
        clear) : > "$file" && echo "Cleared." ;;
        rm)    if [[ $2 == <-> ]]; then sed -i "${2}d" "$file" && echo "Removed #$2."
               else echo "Usage: todo rm <number>"; return 1; fi ;;
        *)     echo "$*" >> "$file" ;;
    esac
    # Refresh the login banner if you have one
    [[ -r ~/scripts/rbanner.sh ]] && source ~/scripts/rbanner.sh
}


# ------------------------------------------------------------
# 10. HOOKS
# ------------------------------------------------------------
zmodload zsh/datetime            # provides $EPOCHSECONDS
autoload -Uz add-zsh-hook        # add hooks without clobbering other tools' precmd/preexec

# --- Terminal bell after long-running commands --------------
typeset -gi LONG_CMD_THRESHOLD=10                                   # seconds
typeset -ga LONG_CMD_IGNORE=(nvim vim vi v yazi y lazygit lg htop btop tmux ssh less man bat fzf fastfetch)
typeset -gi _cmd_start=0
typeset -g  _cmd_name=""

_cmd_timer_preexec() {
    _cmd_start=$EPOCHSECONDS
    _cmd_name=${${(z)1}[1]}      # first word of the command line
}

_cmd_timer_precmd() {
    (( _cmd_start )) || return
    local elapsed=$(( EPOCHSECONDS - _cmd_start ))
    _cmd_start=0
    (( elapsed > LONG_CMD_THRESHOLD )) || return
    (( ${LONG_CMD_IGNORE[(Ie)$_cmd_name]} )) && return              # skip interactive programs
    print -n '\a'
}

add-zsh-hook preexec _cmd_timer_preexec
add-zsh-hook precmd  _cmd_timer_precmd

# --- Sync Wayland/niri variables into tmux panes ------------
# (tmux show-environment accepts ONE variable per call, so loop)
if [[ -n $TMUX ]]; then
    for _var in WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE NIRI_SOCKET; do
        eval "$(tmux show-environment -s "$_var" 2>/dev/null)"
    done
    unset _var
fi


# ------------------------------------------------------------
# 11. LOCAL OVERRIDES & STARTUP BANNER
# ------------------------------------------------------------

# Machine-specific settings / secrets live in ~/.zshrc.local (keep it out of your dotfiles repo)
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local

# Startup banner — skip with:  NO_BANNER=1 zsh
if [[ -o interactive && -z ${NO_BANNER:-} ]]; then
    if (( IS_TERMUX )) && has ff; then
        ff                       # custom Termux fetch script
    elif has fastfetch; then
        fastfetch
    fi
fi

# Old Powerlevel10k / pywal / pulseaudio snippets were removed (unused).
# Re-add pywal with:  (cat ~/.cache/wal/sequences &)
