# >>> vikix aliases >>>
[ -f "$HOME/.config/vikix/vikix.bash" ] && . "$HOME/.config/vikix/vikix.bash"
# <<< vikix aliases <<<
# ~/.bashrc  -- real file lives at ~/.dotfiles/bash/.bashrc
#
# Only what is particular to this machine and to me. Everything general --
# history, listing, moving around, git, editors, xbps, fzf, atuin, zoxide,
# yazi, ssh-agent -- comes from Vikix, read by the block above
# (~/.config/vikix/vikix.bash; `alias` lists it all). Anything below runs
# later, so it wins.
#
# Load order matters in two places:
#   * ble.sh is sourced early with --attach=none and attached LAST, after
#     everything else has finished touching PROMPT_COMMAND and keybindings.
#   * custom_prompt.sh assigns PROMPT_COMMAND=command_prompt (an assignment,
#     not an append), wiping the hooks Vikix installed, so zoxide and atuin
#     are initialised again after it.

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
# API keys and host-specific aliases (ssh targets) live outside this file so
# it can be committed safely. ~/.config/shell/secrets.env is mode 600 and
# gitignored.
[ -r "$HOME/.config/shell/secrets.env" ] && . "$HOME/.config/shell/secrets.env"

# ---------------------------------------------------------------------- PATH
# Idempotent, so re-sourcing this file (alias `r`) doesn't grow PATH.
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

export TERMINAL='alacritty'

# -------------------------------------------------------------------- prompt
# Sets PROMPT_COMMAND=command_prompt, which rebuilds PS1 each prompt, and
# replaces Vikix's prompt. Must precede the tool hooks below.
[ -r "$HOME/bin/custom_prompt.sh" ] && . "$HOME/bin/custom_prompt.sh"

# ------------------------------------------------------------ my own names
# Habits from before Vikix. Vikix's name for the same thing, if any, is in
# brackets.
alias n='nvim'                          # (v)
alias nv='nvim'                         # (v)
alias nf='n $(fzf)'
alias eb='emacsclient -nw ~/.bashrc'    # (bb: in $EDITOR)
alias nvc='nvim ~/.config/nvim/init.lua'
alias lnv='nvim ~/.config/nvim'
alias lsw='nvim ~/.stumpwm.d/user.lisp' # was ~/.stumpwmrc, which Vikix turned into user.lisp
alias lresolv='sudo nvim /etc/resolv.conf'
nn() {
    cd "$HOME/.config/nvim" || return
    nvim "$HOME/.config/nvim/init.lua"
}

alias et='eza'
alias el='eza -l'
alias lst='eza -l --tree --level=2'     # (lt, without the long listing)
alias lstf='eza -l --tree'
alias pdf='evince'                      # xdg-open uses zathura

alias kk='sudo kill -9'
alias off='sudo shutdown -h now'   # not `sh`: that is the Bourne shell
alias nmtui='sudo nmtui'
alias swapcaps='vikix-keyboard'    # re-apply ~/.config/vikix/keyboard after a keyboard hotplug

alias pi='sudo xbps-install -S'         # (xi)
alias pis='sudo xbps-query -Rs'         # (xs)
alias piu='sudo xbps-install -Syu'      # (xu)

alias sb='sbcl'

# recovered from the old ml4w ~/dotfiles/10-aliases fragment (deleted 2026-08-23)
alias gfo='git fetch origin'           # narrower than gf
alias gcheck='git checkout'            # (gco)
alias gsp='git stash; git pull'
# _gcatchup DIR: when GitHub has commits this repo doesn't (another
# machine or session pushed), put ours on top of them with a rebase.
# Refuses, changing nothing, when there are uncommitted changes, or when
# a commit not yet pushed carries a tag: a rebase gives it a new id and
# the tag would stay on the old one (a session re-tags those). A conflict
# is undone, so the repo is left as it was.
_gcatchup() {
  local r=$1 tagged new
  git -C "$r" fetch -q origin || { echo "   couldn't fetch from GitHub"; return 1; }
  new=$(git -C "$r" rev-list --count '..@{u}' 2>/dev/null || echo 0)
  [ "$new" -gt 0 ] || return 0   # nothing new there
  if [ -z "$(git -C "$r" log --oneline '@{u}..')" ]; then   # none of ours: a fast-forward, as a plain pull
    git -C "$r" merge -q --ff-only '@{u}' && echo "   caught up: $new new from GitHub"
    return
  fi
  if ! git -C "$r" diff --quiet || ! git -C "$r" diff --cached --quiet; then
    echo "   GitHub has new commits, and there are uncommitted changes: commit them, then try again"
    return 1
  fi
  tagged=$(git -C "$r" log --format=%H '@{u}..' | while read -r c; do git -C "$r" tag --points-at "$c"; done)
  if [ -n "$tagged" ]; then
    echo "   GitHub has new commits, and this release isn't pushed yet: $(echo $tagged)"
    echo "   ask a session to rebase it onto origin/main and move the tag"
    return 1
  fi
  if git -C "$r" rebase -q '@{u}' >/dev/null 2>&1; then
    echo "   caught up: $new new from GitHub, ours on top"
  else
    git -C "$r" rebase --abort 2>/dev/null
    echo "   GitHub's new commits clash with ours; left as it was. Ask a session to rebase and resolve it"
    return 1
  fi
}

# gpush [DIR...]: make sure these repos are on GitHub, commits and tags
# (the plain `git push` gup used to do left tags behind). Without DIRs,
# the Vikix project: the dev repo and the Emacs config (emacs-void).
# Uncommitted changes are only listed. When GitHub has moved on, it
# catches up first (_gcatchup) and pushes again.
gpush() {
  local r ok=0 missing
  [ $# -gt 0 ] || set -- ~/src/vikix ~/.emacs.d
  for r in "$@"; do
    echo "== ${r/#$HOME/\~}"
    git -C "$r" status --short | grep -v '^??' | sed 's/^/   not committed: /'
    # A new repo's first push: give the branch its upstream.
    git -C "$r" rev-parse -q --verify '@{u}' >/dev/null 2>&1 ||
      git -C "$r" push -q -u origin HEAD || { ok=1; continue; }
    git -C "$r" push --follow-tags -q 2>/dev/null ||
      { _gcatchup "$r" && git -C "$r" push --follow-tags -q; } || { ok=1; continue; }
    missing=$(comm -23 <(git -C "$r" tag | sort) \
      <(git -C "$r" ls-remote --tags origin | sed -n 's|.*refs/tags/\([^^]*\)$|\1|p' | sort))
    # shellcheck disable=SC2086  # one tag a word
    [ -z "$missing" ] || git -C "$r" push -q origin $missing || ok=1
    git -C "$r" fetch -q origin
    if [ -n "$(git -C "$r" log --oneline '@{u}..' 2>/dev/null)" ]; then
      echo "   still ahead of origin"; ok=1
    else
      echo "   pushed: $(git -C "$r" log -1 --format='%h %s' | cut -c1-60)"
    fi
  done
  return $ok
}
# gpl: pull, and when both sides have new commits, put ours on top
# (_gcatchup) instead of refusing. Replaces Vikix's `git pull --ff-only`.
unalias gpl 2>/dev/null
gpl() { echo "== ${PWD/#$HOME/\~}"; _gcatchup . && echo "   up to date: $(git log -1 --format='%h %s' | cut -c1-60)"; }
# The repos plugin (vikix plugin add repos) does these for every project at
# once: repos push | pull | ship | update, pinned projects (Esploro, the
# plugins) pushed before Vikix. Without it, the gpush above.
_repos() { command -v repos >/dev/null 2>&1; }
# gup: push everything that needs it, then only Vikix's part of an update
# (core: seconds). Void's packages and your tools (cargo rebuilds from
# source: minutes) come with gsys, run now and then.
unalias gup gall gdots gliv gesp 2>/dev/null
gup() { if _repos; then repos ship; else gpush && vikix update core; fi; }
gpullall() { repos pull "$@"; }   # every project: GitHub's new commits, yours on top
alias gsys='vikix update'          # the whole system: Void, Vikix, your tools
# gtry: the desktop takes ~/src/vikix's main straight from there, without
# GitHub or the key's passphrase: seconds, for trying a small change
# (a lesson, a key) before pushing. gup pushes the same commits later.
alias gtry='vikix update core --from ~/src/vikix'
gdots() { if _repos; then repos push .dotfiles; else gpush ~/.dotfiles; fi; }              # these dotfiles
gliv()  { if _repos; then repos push living-series; else gpush ~/src/living-series; fi; }  # the Living Series
gesp()  { if _repos; then repos push esploro; else gpush ~/src/esploro; fi; }              # Esploro
gall()  { if _repos; then repos push; else gpush ~/src/vikix ~/.emacs.d ~/.dotfiles ~/src/living-series ~/src/project-logs ~/src/esploro; fi; }   # everything
alias gcredential='git config credential.helper store'   # WARNING: plaintext ~/.git-credentials

alias pv='ping voidlinux.org'

# ------------------------------------------------------- this machine's tools
alias pydoc-html='xdg-open ~/pydocs/python-3.14-docs-html/index.html'
alias lisp='/usr/local/lib64/LispWorksPersonal/lispworks-personal-8-0-1-amd64-linux'
alias cuis='$HOME/bin/cuis &'   # wrapper pins -ud so user files stay out of $PWD

# flask app (gunicorn under runit)
alias start-app='sudo sv restart gunicorn.service'
alias status-app='sudo sv status gunicorn'
alias check-app='sudo journalctl -u gunicorn -n 50 --no-pager'
alias db-edit='sudo -u postgres psql'

# Replaces Vikix's emacs-restart: here Emacs 31 is built into /usr/local,
# and a runit service (emacs-daemon) runs a daemon too.
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

# zoxide, again: custom_prompt.sh above wiped the hook Vikix installed, and
# the hook must run from the first prompt to record directory visits.
#
# It MUST be initialised here, not from ~/.blerc: .blerc is read at ble.sh
# source time (above), and integration/zoxide self-initialises when it finds
# zoxide uninitialised; that put __zoxide_hook in PROMPT_COMMAND too early,
# custom_prompt.sh dropped it, and zoxide stopped recording visits entirely
# (symptom: `zoxide: detected a possible configuration issue`).
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
    # wikiman (installed by hand, not from xbps): Ctrl+F searches the docs.
    [ -r /usr/share/wikiman/widgets/widget.bash ] && \
        . /usr/share/wikiman/widgets/widget.bash

    # fzf's key bindings come from ble.sh (~/.blerc imports
    # integration/fzf-completion and fzf-key-bindings), which binds them via
    # `ble-bind`; the stock `fzf --bash` uses readline `bind -x`, which
    # would double-bind the keys. Only ~/.fzf/bin is needed from ~/.fzf.bash:
    # fzf-tmux and fzf-preview.sh. (The fzf binary itself comes from
    # /usr/bin/fzf -- this appends, so the system one still wins.)
    [[ ":$PATH:" == *":$HOME/.fzf/bin:"* ]] || PATH="${PATH:+$PATH:}$HOME/.fzf/bin"

    # atuin, again (custom_prompt.sh wiped its hook too). As in Vikix: Ctrl+R
    # searches; the Up arrow stays plain history.
    [ -r "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
    command -v atuin >/dev/null 2>&1 && eval "$(atuin init bash --disable-up-arrow)"

    # Must be last: ble.sh takes over the line editor.
    [[ ${BLE_VERSION-} ]] && ble-attach
fi

echo "Successfully sourced .bashrc"

. "$HOME/.local/bin/env"

# Free Pascal 3.2.2 + Lazarus 4.8, built by fpcupdeluxe in ~/fpcupdeluxe.
# fpc finds its config through ~/fpcupdeluxe/fpc/bin/etc/fpc.cfg (a link).
# Lazarus keeps its settings in config_lazarus, so lazbuild needs --pcp.
[[ ":$PATH:" == *":$HOME/fpcupdeluxe/fpc/bin/x86_64-linux:"* ]] || PATH="$HOME/fpcupdeluxe/fpc/bin/x86_64-linux:$PATH"
alias lazbuild='$HOME/fpcupdeluxe/lazarus/lazbuild --pcp=$HOME/fpcupdeluxe/config_lazarus'
alias lazarus='$HOME/Lazarus_fpcupdeluxe.sh'

# iPhone over the cable (~/.local/bin/iphone; Super+Shift+i is the menu).
alias ips='iphone status'     # name, iOS, battery, paired, mounted
alias ipm='iphone mount'      # mount at ~/iphone
alias ipu='iphone unmount'    # unmount before unplugging
alias ipo='iphone open'       # mount and open alacritty in DCIM
alias ipp='iphone photos'     # copy camera roll to ~/Pictures/iphone
alias ipb='iphone backup'     # full device backup to ~/backups/iphone

# --- Fuzzy finding (fzf, with fd, bat and rg) ---------------------------------
# Type a few letters to narrow, Enter picks, Esc leaves. Hidden files are in,
# .git isn't. Each takes an optional folder or starting query.
#   ff  [dir]    find a file, preview it; prints the path (cp "$(ff)" ...)
#   fo  [dir]    find a file and open it in its usual program (xdg-open)
#   fe  [dir]    find a file and edit it in $EDITOR
#   fcd [dir]    find a folder and cd into it
#   fh           find a command in your history; Up then brings it back
#   frg PATTERN  find text in files (ripgrep); edit at that line
_fz_files() { fd --type f --hidden --exclude .git . "${1:-.}" 2>/dev/null; }
_fz_preview='bat --style=numbers --color=always --line-range :300 {} 2>/dev/null || file {}'

ff() {
  _fz_files "$1" | fzf --height 80% --reverse --prompt 'file> ' --preview "$_fz_preview"
}

fo() {
  local f; f=$(ff "$1") || return
  setsid -f xdg-open "$f" >/dev/null 2>&1
}

fe() {
  local f; f=$(ff "$1") || return
  "${EDITOR:-nvim}" "$f"
}

fcd() {
  local d
  d=$(fd --type d --hidden --exclude .git . "${1:-.}" 2>/dev/null |
      fzf --height 80% --reverse --prompt 'cd> ' --preview 'eza -1 --color=always --group-directories-first {}') || return
  cd "$d" || return
}

fh() {
  local c
  c=$(HISTTIMEFORMAT='' history | sed 's/^ *[0-9]* *//' | tac | awk '!seen[$0]++' |
      fzf --height 60% --reverse --prompt 'history> ' --no-sort) || return
  # Not run: it goes into your history, so Up brings it to the prompt
  # to check or change first.
  history -s "$c"
  printf '%s   (Up to use it)\n' "$c"
}

frg() {
  [ -n "$1" ] || { echo "frg PATTERN [dir]"; return 1; }
  local hit
  hit=$(rg --line-number --no-heading --color=always --hidden --glob '!.git' "$1" "${2:-.}" |
        fzf --ansi --height 80% --reverse --prompt 'text> ' --delimiter : \
            --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
            --preview-window '+{2}-/2') || return
  "${EDITOR:-nvim}" "+$(cut -d: -f2 <<<"$hit")" "$(cut -d: -f1 <<<"$hit")"
}
