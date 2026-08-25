# ~/.bashrc  -- real file lives at ~/.dotfiles/bash/.bashrc
#
# Load order matters in two places:
#   * ble.sh is sourced early with --attach=none and attached LAST, after
#     everything else has finished touching PROMPT_COMMAND and keybindings.
#   * custom_prompt.sh assigns PROMPT_COMMAND=command_prompt (an assignment,
#     not an append), so it must run BEFORE zoxide/atuin add their hooks.

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
add_path "$HOME/.npm-global/bin"   # npm global prefix; provides `claude`
add_path "$HOME/.cargo/bin"                      after   # append: /usr/bin/exa is eza 0.23, the cargo one is dead exa 0.10
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

# Caps -> Ctrl is applied once per X session by ~/.xinitrc, so it is
# deliberately NOT run here. Use the `swapcaps` alias to re-apply it by hand
# (e.g. after hotplugging a keyboard, which resets xkb options).

# -------------------------------------------------------------------- prompt
# Sets PROMPT_COMMAND=command_prompt, which rebuilds PS1 each prompt.
# Must precede the tool hooks below.
[ -r "$HOME/bin/custom_prompt.sh" ] && . "$HOME/bin/custom_prompt.sh"

# ------------------------------------------------------------------- aliases

# navigation and listing
alias ..='z ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias d='dirs -v'          # numbered directory stack; use with pushd/popd
alias cd-='cd -'           # previous directory
alias mkd='mkdir -p'
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -lha --group-directories-first --icons=auto'
    alias e='eza'
    alias et='eza'
    alias el='eza -l'
    alias lst='eza -l --tree --level=2'
    alias lstf='eza -l --tree'
fi

# editors and this file
alias n='nvim'
alias nf='n $(fzf)'
alias ec='emacsclient -nw'
alias b='nvim ~/.bashrc'
alias eb='emacsclient -nw ~/.bashrc'
alias r='source ~/.bashrc'

# nvim
alias nv='nvim'
alias nvd='nvim -d'                     # diff two files
alias nvc='nvim ~/.config/nvim/init.lua'

# emacs  (ec = emacsclient -nw, eb = edit this file, both above)
alias eg='emacsclient -c -n -a ""'      # new GUI frame, returns immediately
alias eq='emacs -Q -nw'                 # vanilla emacs, no config -- for debugging
alias ekill="emacsclient -e '(kill-emacs)'"
# see also the emacs-restart function below

# git
# `gs`, `gp` and `ya` are deliberately NOT used: they are taken by
# ghostscript, PARI/GP, and yazi's own package manager respectively.
alias g='git'
alias gst='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gcm='git commit -m'
alias gca='git commit -a -m'
alias gamend='git commit --amend --no-edit'
alias gco='git checkout'
alias gsw='git switch'
alias gb='git branch -vv'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --oneline --graph --decorate --all -30'
alias gps='git push'
alias gpl='git pull --ff-only'
alias gf='git fetch --all --prune'
alias gr='git remote -v'
alias gsh='git stash'
alias gshp='git stash pop'
alias gundo='git reset --soft HEAD~1'   # undo last commit, keep changes staged
alias gwip='git add -A && git commit -m wip'
alias lg='lazygit'

# recovered from the old ml4w ~/dotfiles/10-aliases fragment (deleted 2026-08-23)
#
# NOT recovered: `gs` and `gp`. The fragment defined both, but they are real
# binaries here -- gs is ghostscript, gp is PARI/GP -- and aliasing them would
# shadow the commands. `gst` and `gps` exist precisely to avoid that; see the
# note at the top of the Git section in README.md.
alias gfo='git fetch origin'           # narrower than gf
alias gcheck='git checkout'            # duplicate of gco
alias gsp='git stash; git pull'
alias gcredential='git config credential.helper store'   # WARNING: plaintext ~/.git-credentials

# config files
# The WM is StumpWM (see ~/.xinitrc). qtile and herbstluftwm are still
# installed and their configs still exist, but nothing here drives them --
# re-add aliases if you switch back.
alias lsw='nvim ~/.stumpwmrc'
alias lnv='nvim ~/.config/nvim'
alias lresolv='sudo nvim /etc/resolv.conf'

# files
alias chx='chmod +x'
alias cpr='cp -r'
alias xo='xdg-open'
alias pdf='evince'

# processes and system
alias psg='ps aux | grep'      # e.g. `psg stumpwm`
alias kk='sudo kill -9'
alias hg='history | grep'
alias nmtui='sudo nmtui'
alias swapcaps='setxkbmap -option ctrl:swapcaps'   # re-apply after keyboard hotplug
alias off='sudo shutdown -h now'   # not `sh`: that is the Bourne shell

# packages (xbps)
alias pi='sudo xbps-install -S'
alias pis='sudo xbps-query -Rs'
alias piu='sudo xbps-install -Syu'

# network
alias pv='ping voidlinux.org'   # was defined twice; the `-c 5` variant was shadowed
# Host-specific aliases (ssh targets etc.) live in ~/.config/shell/secrets.env,
# which is mode 600 and gitignored, so no hostnames land in this repo.

# languages and tools
alias activate='. .venv/bin/activate'
alias jlab='source ~/venvs/jupyter-base/bin/activate && jupyter lab &'
alias pydoc-html='xdg-open ~/pydocs/python-3.14-docs-html/index.html'
alias sb='sbcl'
alias lisp='/usr/local/lib64/LispWorksPersonal/lispworks-personal-8-0-1-amd64-linux'
alias cuis='$HOME/bin/cuis &'   # wrapper pins -ud so user files stay out of $PWD
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

# yazi, leaving the shell in whatever directory you quit from.
# Must be a function, not an alias: a child process cannot change our cwd.
# Quit with `q` to cd there; `Q` quits without changing directory.
y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
    yazi "$@" --cwd-file="$tmp"
    cwd="$(command cat -- "$tmp" 2>/dev/null)"
    rm -f -- "$tmp"          # removed before any early exit, so it never leaks
    if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
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
#
# It MUST be initialised here, after custom_prompt.sh, not from ~/.blerc.
# custom_prompt.sh:105 does `PROMPT_COMMAND=command_prompt` -- an assignment,
# not an append -- so any hook installed before it is silently wiped. .blerc is
# read at ble.sh source time (line 18), and integration/zoxide self-initialises
# when it finds zoxide uninitialised; that put __zoxide_hook in PROMPT_COMMAND
# too early, custom_prompt.sh dropped it, and zoxide stopped recording visits
# entirely (symptom: `zoxide: detected a possible configuration issue`).
#
# This does not fight the .blerc import. integration/zoxide only runs
# `zoxide init bash` when it finds no __zoxide_* functions to wrap; with them
# already defined it takes the other branch and just advises them, so the
# ble.sh-aware `zi` picker wrappers survive. Init is idempotent regardless --
# the hook install is guarded by a `!= *__zoxide_hook*` test.
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

[ -r "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env"
[ -r "$HOME/.opam/opam-init/init.sh" ] && \
    . "$HOME/.opam/opam-init/init.sh" >/dev/null 2>&1

[ -r "$HOME/.dircolors" ] && eval "$(dircolors -b "$HOME/.dircolors")"

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

    # 2026-08-23: fzf shell integration moved into ble.sh (~/.blerc imports
    # integration/fzf-completion and fzf-key-bindings). Those bind C-t/C-r via
    # `ble-bind`, which ble.sh honours; the stock `fzf --bash` uses readline
    # `bind -x`, which ble.sh does not -- running both double-binds the keys.
    #
    # These two lines were ALSO initialising fzf twice: ~/.fzf.bash itself ends
    # in `eval "$(fzf --bash)"`, so the eval below ran, then ran again on the
    # next line. Both are now off; .blerc owns fzf.
    #command -v fzf >/dev/null 2>&1 && eval "$(fzf --bash)"
    #[ -r "$HOME/.fzf.bash" ] && . "$HOME/.fzf.bash"

    # ...but keep what .fzf.bash did besides the eval: put ~/.fzf/bin on PATH
    # for fzf-tmux and fzf-preview.sh. (The fzf binary itself comes from
    # /usr/bin/fzf 0.74.3 -- this appends, so the system one still wins.)
    [[ ":$PATH:" == *":$HOME/.fzf/bin:"* ]] || PATH="${PATH:+$PATH:}$HOME/.fzf/bin"

    [ -r "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
    command -v atuin >/dev/null 2>&1 && eval "$(atuin init bash)"

    # Must be last: ble.sh takes over the line editor.
    [[ ${BLE_VERSION-} ]] && ble-attach
fi

echo "Successfully sourced .bashrc"

. "$HOME/.local/bin/env"
