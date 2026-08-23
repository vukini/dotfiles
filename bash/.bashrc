# ~/.bashrc  -- real file lives at ~/.dotfiles/bash/.bashrc
#
# Load order matters in two places:
#   * ble.sh is sourced early with --attach=none and attached LAST, after
#     everything else has finished touching PROMPT_COMMAND and keybindings.
#   * custom_prompt.sh assigns PROMPT_COMMAND=command_prompt (an assignment,
#     not an append), so it must run BEFORE mise/zoxide/atuin add their hooks.

# --------------------------------------------------------------- interactive
# Nothing below here should run for non-interactive shells (scp, rsync, ...).
[[ $- != *i* ]] && return

# True for a real terminal; false inside Emacs' shell or a dumb TERM.
_is_rich_term() { [[ -z "$EMACS" && -z "$INSIDE_EMACS" && "$TERM" != "dumb" ]]; }

# ble.sh: source early, attach at the very end of this file.
if _is_rich_term && [[ -r "$HOME/.local/share/blesh/ble.sh" ]]; then
    source -- "$HOME/.local/share/blesh/ble.sh" --attach=none
fi

# ------------------------------------------------------------------- secrets
# API keys live outside this file so it can be committed safely.
# ~/.config/shell/secrets.env is mode 600 and gitignored.
[ -r "$HOME/.config/shell/secrets.env" ] && . "$HOME/.config/shell/secrets.env"

# ---------------------------------------------------------------------- PATH
# Idempotent, so re-sourcing this file (alias `r`) no longer grows PATH.
# Missing directories are skipped rather than added blindly.
add_path() {
    # add_path DIR [after]   -- prepends by default
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) return 0 ;;
    esac
    if [ "$2" = after ]; then
        PATH="$PATH:$1"
    else
        PATH="$1:$PATH"
    fi
}

add_path "$HOME/bin"                             after
add_path "$HOME/bin/doublecmd"                   after
add_path "$HOME/.local/share/gem/ruby/3.4.0/bin"
add_path "$HOME/bin/odin-bin"    # was "~/bin/odin-bin/": tilde never expands in quotes
add_path /usr/local/lib64/LispWorksPersonal
add_path "$HOME/.pixi/bin"
add_path "$HOME/.rbenv/bin"
export PATH

# ------------------------------------------------------------------- history
HISTSIZE=10000
HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# No history juggling in PROMPT_COMMAND: atuin already provides cross-shell
# history, and `history -c; history -r` re-read the whole file every prompt.

# ------------------------------------------------------------- shell options
shopt -s checkwinsize
export TERMINAL='kitty'

# Caps -> Ctrl. Only meaningful under X; guarded so TTY and ssh sessions
# do not spawn a doomed setxkbmap on every shell.
if [ -n "$DISPLAY" ] && command -v setxkbmap >/dev/null 2>&1; then
    setxkbmap -option ctrl:swapcaps
fi

# -------------------------------------------------------------------- prompt
# Sets PROMPT_COMMAND=command_prompt, which rebuilds PS1 each prompt.
# Must precede the tool hooks below.
[ -r "$HOME/bin/custom_prompt.sh" ] && . "$HOME/bin/custom_prompt.sh"

# ------------------------------------------------------------------- aliases

# navigation and listing
alias ..='z ..'
alias mkd='mkdir -p'
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
if command -v exa >/dev/null 2>&1; then
    alias ls='exa --group-directories-first --icons'
    alias ll='exa -lha --group-directories-first --icons'
    alias e='exa'
    alias et='exa'
    alias el='exa -l'
    alias lst='exa -l --tree --level=2'
    alias lstf='exa -l --tree'
fi

# editors and this file
alias n='nvim'
alias nf='n $(fzf)'
alias ec='emacsclient -nw'
alias b='nvim ~/.bashrc'
alias eb='emacsclient -nw ~/.bashrc'
alias r='source ~/.bashrc'

# config files
alias lh='nvim ~/.config/herbstluftwm/autostart'
alias lnv='nvim ~/.config/nvim'
alias lq='nvim ~/.config/qtile/config.py'
alias lresolv='sudo nvim /etc/resolv.conf'

# files
alias chx='chmod +x'
alias cpr='cp -r'
alias xo='xdg-open'
alias pdf='evince'

# processes and system
alias psg='ps aux | grep'
alias fq='ps aux | grep qtile'
alias kk='sudo kill -9'
alias hg='history | grep'
alias nmtui='sudo nmtui'
alias swapcaps='setxkbmap -option ctrl:swapcaps'
alias rq='qtile cmd-obj -o cmd -f restart'

# packages (xbps)
alias pi='sudo xbps-install -S'
alias pis='sudo xbps-query -Rs'
alias piu='sudo xbps-install -Syu'

# network
alias pv='ping voidlinux.org'   # was defined twice; the `-c 5` variant was shadowed
alias didi='ssh REDACTED-HOST'

# languages and tools
alias activate='. .venv/bin/activate'
alias sb='sbcl'
alias lisp='/usr/local/lib64/LispWorksPersonal/lispworks-personal-8-0-1-amd64-linux'
alias cuis='/home/vukini/apps/Cuis7/Cuis7-2-main/RunCuisOnLinux.sh &'
alias gc='git clone'

# flask app (gunicorn under runit)
alias start-app='sudo sv restart gunicorn.service'
alias status-app='sudo sv status gunicorn'
alias check-app='sudo journalctl -u gunicorn -n 50 --no-pager'
alias db-edit='sudo -u postgres psql'

# ------------------------------------------------------------------ functions

nn() {
    cd "$HOME/.config/nvim" || return
    nvim "$HOME/.config/nvim/init.lua"
}

hc() {
    herbstclient "$@"
}

# Restart the Emacs daemon cleanly, refusing to discard unsaved work.
emacs-restart() {
    local bin=/usr/local/bin/emacs   # 31.0.50; /usr/bin/emacs is 30.2

    local unsaved
    unsaved=$(emacsclient -e '(delq nil (mapcar (lambda (b)
                                (and (buffer-file-name b)
                                     (buffer-modified-p b)
                                     (buffer-file-name b)))
                              (buffer-list)))' 2>/dev/null)
    if [ -n "$unsaved" ] && [ "$unsaved" != "nil" ]; then
        echo "Unsaved buffers, aborting:" >&2
        echo "  $unsaved" >&2
        return 1
    fi

    echo "Stopping daemon(s)..."
    emacsclient -e '(kill-emacs)' >/dev/null 2>&1
    sv down emacs-daemon 2>/dev/null

    # Wait for them to actually exit. The previous pattern
    # 'emacs (--fg-)?-?-daemon' did not match "--fg-daemon", so this loop
    # used to fall through immediately.
    local i=0
    while pgrep -f 'emacs.*--(fg-)?daemon' >/dev/null 2>&1; do
        i=$((i + 1))
        [ "$i" -gt 20 ] && { echo "Daemon did not exit" >&2; return 1; }
        sleep 0.25
    done

    # Clear a stale desktop lock (a live daemon removes its own on exit).
    [ -f "$HOME/.emacs.desktop.lock" ] && rm -f "$HOME/.emacs.desktop.lock"

    echo "Starting $("$bin" --version | head -1)..."
    "$bin" --daemon || return 1
    emacsclient -e '(list emacs-version (emacs-init-time))'
}

# ------------------------------------------------------------------ tool init
# These append to PROMPT_COMMAND, so they must come after custom_prompt.sh.

# zoxide costs ~3 ms and its PROMPT_COMMAND hook must run from the first
# prompt to record directory visits, so it stays eager.
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"

# rbenv -- lazy.
# `eval "$(rbenv init - bash)"` costs ~50 ms, and ~28 ms of that is a startup
# `rbenv rehash`. Only two things are needed for `ruby`, `gem` and `bundle` to
# resolve: the shims directory on PATH, and RBENV_SHELL. Both are free, so set
# them directly and defer the rest until the first actual `rbenv` command.
#
# Trade-off: a gem binary installed in this shell has no shim until something
# rehashes. Running any `rbenv` command triggers full init (including rehash),
# so `rbenv rehash` after `gem install` behaves exactly as before.
if [ -d "$HOME/.rbenv/shims" ]; then
    add_path "$HOME/.rbenv/shims"
    export RBENV_SHELL=bash
    rbenv() {
        unset -f rbenv
        eval "$(command rbenv init - bash)"
        rbenv "$@"
    }
fi

# mise -- lazy.
# Activation costs ~25 ms to install a per-prompt hook. `mise ls` and
# `mise config ls` are both empty, so it currently manages no tools and that
# cost buys nothing. The stub loads it on first use instead.
#
# NOTE: while lazy, mise's per-directory auto-activation does NOT run. If you
# start using mise to manage tool versions, delete this stub and restore:
#     eval "$("$HOME/.local/bin/mise" activate bash)"
if [ -x "$HOME/.local/bin/mise" ]; then
    mise() {
        unset -f mise
        eval "$("$HOME/.local/bin/mise" activate bash)"
        mise "$@"
    }
fi

[ -r "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env"
[ -r "$HOME/.opam/opam-init/init.sh" ] && \
    . "$HOME/.opam/opam-init/init.sh" >/dev/null 2>&1

[ -r "$HOME/.dircolors" ] && eval "$(dircolors -b "$HOME/.dircolors")"
[ -r "$HOME/apps/herbstluftwm/share/herbstclient-completion.bash" ] && \
    . "$HOME/apps/herbstluftwm/share/herbstclient-completion.bash"

# Collapse duplicate PATH entries, keeping the first occurrence of each.
# add_path above is already idempotent, but `rbenv init` and opam's init.sh
# re-prepend their directories unconditionally every time they run, so
# re-sourcing this file would otherwise keep growing PATH.
_dedupe_path() {
    local out='' dir
    local IFS=':'
    for dir in $PATH; do
        [ -n "$dir" ] || continue
        case ":$out:" in
            *":$dir:"*) ;;
            *) out="${out:+$out:}$dir" ;;
        esac
    done
    PATH="$out"
    export PATH
}
_dedupe_path

# --------------------------------------------------------- interactive extras
# Widgets and keybindings that only make sense in a real terminal.
if _is_rich_term; then
    [ -r /usr/share/wikiman/widgets/widget.bash ] && \
        . /usr/share/wikiman/widgets/widget.bash

    command -v fzf >/dev/null 2>&1 && eval "$(fzf --bash)"
    [ -r "$HOME/.fzf.bash" ] && . "$HOME/.fzf.bash"

    [ -r "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
    command -v atuin >/dev/null 2>&1 && eval "$(atuin init bash)"

    # Must be last: ble.sh takes over the line editor.
    [[ ${BLE_VERSION-} ]] && ble-attach
fi

echo "Successfully sourced .bashrc"
