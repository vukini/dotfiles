# Environment notes

Reference for this machine's shell and Emacs configuration, and a record of
what changed on 2026-08-23.

- **Shell config** — `~/.dotfiles/bash/.bashrc` (this repo). `~/.bashrc` is a
  symlink to it.
- **Line editor config** — `~/.dotfiles/bash/.blerc` (this repo). `~/.blerc` is a
  symlink to it, same scheme as `.bashrc`. Read by ble.sh when `.bashrc` sources
  it; owns the fzf and zoxide integrations, so the two files must stay in step.
- **Secrets** — `~/.config/shell/secrets.env`, mode `600`, **outside this repo**
  and gitignored. Sourced by `.bashrc`.
- **Emacs config** — `~/.emacs.d/config.org` (separate repo). `config.el` is
  generated from it by `org-babel-load-file`; never edit `config.el` by hand.

---

## Part 1 — Shell quick reference

Reload after editing: `r`

### Git

`gs`, `gp` and `ya` are **not** used as aliases — they are real binaries on this
system (ghostscript, PARI/GP, and yazi's own package manager). Hence `gst`,
`gps`, and `y`.

> This rule has been broken once already: the 2026-08-23 alias recovery added
> `gs` and `gp` from an old fragment, shadowing both binaries until it was
> caught. Check `command -v` before adding any two-letter alias.

| Alias | Runs | Notes |
|---|---|---|
| `g` | `git` | bare prefix, e.g. `g bisect` |
| `gst` | `git status -sb` | short + branch line |
| `ga` | `git add` | |
| `gaa` | `git add -A` | everything, including deletions |
| `gcm` | `git commit -m` | |
| `gca` | `git commit -a -m` | skips staging |
| `gamend` | `git commit --amend --no-edit` | keeps the message |
| `gco` | `git checkout` | |
| `gsw` | `git switch` | preferred over `gco` for branches |
| `gb` | `git branch -vv` | shows upstream tracking |
| `gd` | `git diff` | unstaged |
| `gds` | `git diff --staged` | what a commit would contain |
| `gl` | `git log --oneline --graph --decorate -20` | current branch |
| `gla` | `… --all -30` | all branches |
| `gps` | `git push` | |
| `gpl` | `git pull --ff-only` | refuses to create a merge commit |
| `gf` | `git fetch --all --prune` | drops deleted remote branches |
| `gr` | `git remote -v` | |
| `gsh` / `gshp` | `git stash` / `git stash pop` | |
| `gundo` | `git reset --soft HEAD~1` | undo last commit, **keep changes staged** |
| `gwip` | `git add -A && git commit -m wip` | scratch checkpoint |
| `gc` | `git clone` | pre-existing |
| `lg` | `lazygit` | full TUI |
| `gfo` | `git fetch origin` | narrower than `gf` |
| `gcheck` | `git checkout` | same as `gco` |
| `gsp` | `git stash; git pull` | |
| `gcredential` | `git config credential.helper store` | ⚠ plaintext `~/.git-credentials` |

### Directory navigation

| Alias | Runs |
|---|---|
| `..` | `z ..` (zoxide) |
| `...` / `....` / `.....` | up 2 / 3 / 4 levels |
| `cd-` | `cd -`, previous directory |
| `d` | `dirs -v`, numbered directory stack |
| `mkd` | `mkdir -p` |

`z <partial-name>` jumps to a frecent directory; `zi` picks interactively.

### Yazi

`y` is a **function, not an alias** — a child process cannot change its parent's
working directory, so it writes its exit directory to a temp file via
`--cwd-file` and the function `cd`s there.

| | |
|---|---|
| `y` | open yazi; quit with **`q`** to land in the directory you browsed to |
| | quit with **`Q`** to leave the shell where it was |

### Emacs

| Alias | Runs | Notes |
|---|---|---|
| `ec` | `emacsclient -nw` | terminal frame |
| `eg` | `emacsclient -c -n -a ""` | new GUI frame, returns immediately |
| `eb` | `emacsclient -nw ~/.bashrc` | |
| `eq` | `emacs -Q -nw` | vanilla, no config — for bisecting config bugs |
| `ekill` | `emacsclient -e '(kill-emacs)'` | |
| `emacs-restart` | *function* | see below |

`emacs-restart` refuses to run if any buffer has unsaved changes, stops both the
manual and the runit-supervised daemon, waits for them to actually exit, clears a
stale desktop lock, then starts `/usr/local/bin/emacs --daemon` (31.0.50) and
reports the version and init time.

### Neovim

| Alias | Runs |
|---|---|
| `n` / `nv` | `nvim` |
| `nf` | `nvim $(fzf)` |
| `nvd` | `nvim -d`, diff two files |
| `nvc` | edit `~/.config/nvim/init.lua` |
| `nn` | *function* — cd to nvim config, then open `init.lua` |
| `lnv` | `nvim ~/.config/nvim` |

### Other pre-existing aliases

| Group | Aliases |
|---|---|
| listing | `ls` `ll` `e` `et` `el` `lst` `lstf` (eza when installed) |
| config | `b` `lsw` (`~/.stumpwmrc`) `lnv` `lresolv` |
| files | `chx` `cpr` `xo` `pdf` |
| system | `psg` `kk` `hg` `nmtui` `swapcaps` |
| xbps | `pi` `pis` `piu` |
| network | `pv` `didi` |
| languages | `activate` `sb` `lisp` `cuis` |
| flask app | `start-app` `status-app` `check-app` `db-edit` |

### Line editor (ble.sh) and its keybindings

ble.sh replaces bash's readline entirely: syntax highlighting, an inline
autosuggestion, and a completion menu. It is installed at
`~/.local/share/blesh` (**not** in this repo — update it with `ble-update`) and
configured by `~/.blerc`, which **is** in this repo.

fzf and zoxide are driven *through* ble.sh rather than by their own shell init.
The stock inits bind keys with readline's `bind -x`, which ble.sh does not
honour; ble.sh's own `integration/` modules bind via `ble-bind`, which it does.

| Key | Does |
|---|---|
| `M-t` | fzf file picker — inserts the path at the cursor |
| `M-c` | fzf directory picker — `cd`s into the choice |
| `C-r` | atuin history search (full-screen) |
| `M-r` | fzf history search — the same widget `C-r` would otherwise give |
| `**`+`TAB` | fzf completion trigger, e.g. `vim **<TAB>` |
| `TAB` | ble.sh's own completion menu |

**`M-t`, not `C-t`.** StumpWM holds `C-t` as its prefix key (it is on the
default; there is no `set-prefix-key` in `~/.stumpwmrc`), so `C-t` is grabbed by
the WM and never reaches the terminal. `.blerc` rebinds the file picker to `M-t`
via `ble/util/import/eval-after-load`, which is required because the module
import is deferred to `ble-attach` and would otherwise overwrite a plain
`ble-bind`. The module's original `C-t` bindings are left in place — harmless
while the WM holds the key, and live again if the prefix ever moves.

**`C-r` was contested.** Both atuin and fzf bind it in the emacs keymap, and fzf
was winning: atuin binds during `atuin init bash` in `.bashrc`, but fzf's module
is deferred to `ble-attach`, which runs later and overwrote it. `.blerc` now
re-asserts atuin's binding in the same after-load hook, and parks fzf's history
widget on `M-r` so both remain reachable.

The re-assert calls `atuin-bind`, not a hand-written `ble-bind`.
`atuin-search-emacs` is not a real widget — it is a token `atuin-bind` rewrites
to `__atuin_history --keymap-mode=emacs` before dispatching to whichever
`__atuin_bind_impl` suits the bash/ble.sh combination in play. Going through
atuin's own binder keeps that translation and impl choice in atuin's hands.

Troubleshooting dials live in `~/.blerc`, ordered by likelihood: auto-complete
delay first, then syntax highlighting (`highlight_filename` is the one that
stalls on Dropbox/Tresorit trees), then terminal redraw.

---

## Part 2 — What changed

### Shell (`~/.dotfiles`)

The repo itself is new — `~/.dotfiles` was previously untracked.

**`036a3b8` — initial commit / refactor.** Reorganised `.bashrc` into sections
(guard → secrets → PATH → history → options → prompt → aliases → functions →
tool init → interactive extras) and fixed five bugs:

| Bug | Fix |
|---|---|
| API keys stored in plaintext in `.bashrc` | moved to `~/.config/shell/secrets.env`, mode `600`, gitignored |
| `PATH="~/bin/odin-bin/"` — tilde never expands inside quotes | use `$HOME` |
| `emacs-restart`'s `pgrep` pattern never matched `--fg-daemon` | `emacs.*--(fg-)?daemon` |
| `PS1='$(py:)…'` was dead code (`py:` undefined; `command_prompt` rebuilds `PS1` each prompt) | removed |
| PATH grew on every re-source — 31 → 39 entries after two | idempotent `add_path` + a final `_dedupe_path` |
| duplicate `alias pv` | kept the surviving definition |

Also: all `source` lines are existence-guarded, and the
`history -a; history -c; history -r` in `PROMPT_COMMAND` was dropped — atuin
already provides cross-shell history, and that reloaded a 20 000-line file at
every prompt.

`setxkbmap` was removed from `.bashrc` entirely (first guarded by `$DISPLAY`,
then dropped): `~/.xinitrc` already applies `ctrl:swapcaps` once per X session,
so running it again in every interactive shell was redundant. The `swapcaps`
alias remains for re-applying it by hand after a keyboard hotplug, which resets
xkb options.

**`11aedc0` — lazy-load rbenv and mise.** Startup **~165 ms → ~88 ms**.

Measured cost of each init (best of 3; empty bash = 3 ms baseline):

```
rbenv      52 ms   <- 26 ms generate + 28 ms startup `rbenv rehash`
mise       28 ms
atuin      11 ms
fzf         7 ms
zoxide      6 ms
dircolors   5 ms
opam/ghcup  3 ms
```

Only the top two were deferred. The rest are ≤8 ms and their hooks or
keybindings must exist from the first prompt, so lazy-loading them would break
Ctrl-R, fzf bindings, or zoxide's directory tracking to save a few milliseconds.

> Superseded in part by `a9193fd`: the fzf and zoxide rows no longer describe
> `.bashrc` at all. Both now load as ble.sh modules from `~/.blerc`, and fzf's
> is deferred to `ble-attach` by `ble-import -d`. The timings above were
> measured before that move and have not been re-taken.

- **rbenv** — the shims directory and `RBENV_SHELL` are all `ruby`/`gem`/`bundle`
  need, and both are free to set, so they are set directly and `rbenv init` is
  deferred behind a stub function.
  *Caveat:* a gem binary installed in the current shell has no shim until
  something rehashes. Any `rbenv` command triggers full init including rehash,
  so `rbenv rehash` after `gem install` behaves as before.
- **mise** — `mise ls` and `mise config ls` are both empty, so activation was
  installing a per-prompt hook for tools it does not manage.
  *Caveat:* while lazy, mise's per-directory auto-activation does **not** run. If
  mise ever manages tool versions, replace the stub with
  `eval "$("$HOME/.local/bin/mise" activate bash)"` — the line is in a comment
  at the stub.

> Superseded 2026-08-25: **mise was removed entirely**, stub and all. It never
> managed a single tool. The one attempt, `mise use -g ruby@3` on 2025-12-02,
> exited 1 because mise's Ruby backend compiles via `ruby-build`, which was not
> installed on this box until 2026-03-04 — three months later. rbenv was
> installed on 2025-12-28 as the fallback and has handled Ruby ever since
> (3.4.6, Rails 8.1.1). Running two Ruby version managers with both shim sets on
> PATH was the actual problem, so only one is kept. `~/.local/bin/mise`,
> `~/.local/share/mise`, `~/.cache/mise` and the `.bashrc` stub are gone.

Caching the generated scripts was measured too and does **not** help rbenv: the
expensive `rbenv rehash` runs on every eval regardless of where the script came
from.

**`47dbeea` — aliases.** The 34 above, plus `y()`. 45 → 79 aliases.

**`1e7064f` — drop `setxkbmap` from `.bashrc`.** See the note above. Startup
**~92 ms → ~68 ms**: it was forking a process in every interactive shell.

**window-manager cleanup.** The WM is **StumpWM** (`~/.xinitrc`); qtile and
herbstluftwm are commented out there. Removed the aliases that only made sense
under those: `rq` (qtile restart), `fq` (`ps aux | grep qtile`, superseded by
`psg qtile`), `lq`, `lh`, the `hc()` herbstclient wrapper, and the herbstclient
completion source line. Added `lsw` for `~/.stumpwmrc`. 79 → 76 aliases.

Both WMs and their config files are still installed and untouched — only the
shell aliases went. Re-add them if you switch back.

**`a9193fd` — hand fzf and zoxide to ble.sh; eza aliases.** Three things:

- The listing aliases called `exa`, which on this system is only a compat
  symlink to `eza`, and passed a bare `--icons`. Modern eza takes an *optional*
  `WHEN` value there, so `ls Documents/` was parsed as `--icons=Documents/` and
  errored out. Now `eza … --icons=auto` (auto so icons drop when piped).
- fzf and zoxide integration moved to `~/.blerc`. fzf was also being initialised
  **twice** — `~/.fzf.bash` ends in the same `eval "$(fzf --bash)"` that the
  line above it had just run, double-registering its readline bindings.
  `~/.fzf/bin` is still put on PATH for `fzf-tmux` and `fzf-preview.sh`.
- Four git aliases recovered from the old ml4w `~/dotfiles/10-aliases` fragment
  before deleting it: `gfo`, `gcheck`, `gsp`, `gcredential`.

**`8c68f01` — npm-global PATH entry into `add_path`.** It had been appended raw
at the end of the file as `export PATH=~/.npm-global/bin:$PATH` — unquoted tilde
(the same trap already flagged against `odin-bin`), and no dedupe, so
re-sourcing stacked another copy on each time. `add_path` handles both. Kept
last among the prepends so npm globals still win.

**`ba22619` — track `.blerc`.** `.bashrc` now depends on it, so versioning only
one would let them drift. Symlinked from `$HOME` like `.bashrc`.

**alias regression fix.** `a9193fd` also added `gs` and `gp` from that same
fragment, shadowing `/usr/bin/gs` (ghostscript) and `/usr/bin/gp` (PARI/GP) —
exactly what the note at the top of the Git section exists to prevent. Both
removed; `gst` and `gps` remain the intended spellings.

**ble.sh updated** from `0.4.0-devel4+2f564e6` (2025-11-26) to `+63c23e9`, nine
months of fixes on a bash 5.3 system. Not in this repo — `~/.local/share/blesh`,
updated with `ble-update`.

### Emacs (`~/.emacs.d`, 5 commits)

**`f7649c5` — defect fixes.** `config.el` turned out to be *generated* from
`config.org` and gitignored, so all edits went to the `.org`. Ten confirmed
defects fixed, including `hl-line-mode` never applying globally, `require
'package` sitting after `package-initialize`, a hook on a nonexistent
`M-mode-hook`, a keybinding to an undefined `paredit-dwim`, a `:custom (setq
completion--styles …)` that was a silent no-op, and a leftover
`(setq debug-on-error t)`. Also `ring-bell-function 'ingore` → `'ignore` in
`init.el`.

**`b456cc0` — untracked runtime state.** `history`, `places` and `tramp` were
tracked *and* gitignored; `.gitignore` has no effect on tracked files, so they
needed `git rm --cached`. Only `history` was genuinely missing a rule.

**`1ad82ca` — restructure.** Grouped into Bootstrap / Core / Completion /
Navigation / Editing / Languages / Tools / Attic. 126 lines of commented-out
elisp moved to an Attic section marked `:tangle no`; `rc.el` retired in favour of
`use-package` throughout; `:load no` dropped from all 40 blocks (it is not an
org-babel header argument and tangles identically without it); 28 progress
messages reduced to 6 phase markers. Two more bugs surfaced: Magit's `C-x g` was
inside `:config` while `:commands` deferred the package, so the key was unbound
until magit had loaded some other way; and the speedbar settings were written as
prose outside any source block and had never executed.

**`0aaba92` — startup warnings.** Added `lexical-binding` cookies to `init.el`
and to the first tangled block of `config.org`. The repeating face warnings came
from `gruber-darker-theme` setting nine face attributes to `nil`, which Emacs now
rejects in favour of `unspecified` — a `:filter-args` advice on
`custom-theme-set-faces` rewrites the specs as the theme registers them, rather
than patching the installed package where an update would revert it.

**`ca2fa0f` — TypeScript support.** `eglot-ensure` hooks for `c-mode`,
`c++-mode`, `js-mode`, `typescript-ts-mode` and `tsx-ts-mode`.

---

## Language tooling status

| Language | Mode | LSP server | Auto-starts |
|---|---|---|---|
| Python | `python-mode` | `pylsp` | yes |
| C / C++ | `c-mode` / `c++-mode` | `ccls` | yes |
| JavaScript | `js-mode` | `typescript-language-server` | yes |
| TypeScript | `typescript-ts-mode` | `typescript-language-server` | yes |
| Odin | `odin-ts-mode` | `ols` | yes |
| Zig | `zig-mode` | `zls` | yes |

TypeScript previously opened in `fundamental-mode` — since Emacs 29 it is
tree-sitter only, with no legacy fallback mode, and the grammar was missing.
Fixed by `xbps-install tree-sitter-typescript`, which ships both the
`typescript` and `tsx` grammars.

Not installed: a JSON language server (`js-json-mode` works, but with no LSP) —
`npm i -g vscode-langservers-extracted` would add JSON, HTML, CSS and ESLint.
`clangd` is also absent; on Void it lives in `clang-tools-extra`, but that package
creates **no `/usr/bin` symlinks**, so it would need a symlink or an explicit
path in `eglot-server-programs` to be found. `ccls` works and is already wired up.

---

## Outstanding

- **Rotate the OpenAI and Perplexity API keys.** They were in plaintext in
  `.bashrc` and appeared in a chat transcript. Moving them to `secrets.env` fixes
  storage, not prior exposure.
- `~/bin/doublecmd` and `~/.rbenv/bin` do not exist. The old `.bashrc` added them
  to PATH blindly; `add_path` now skips missing directories.
- `~/.emacs.d/config.el` is tracked *and* gitignored, so it keeps reappearing as
  modified and needs `git add -f`. `git rm --cached config.el` would end this —
  `init.el` regenerates it at startup.
- ~~The `emacs-daemon` runit service is `sv down` and points at
  `/usr/bin/emacs` (30.2).~~ **Resolved 2026-08-23 — this was a misreading.**
  Two service directories existed: a stale `~/emacs-daemon` (last touched
  2025-11-19, recorded pid dead, `run` calling `/usr/bin/emacs`) and the live
  `~/service/emacs-daemon`. Only the latter is what
  `/run/runit/runsvdir/current/emacs-daemon` symlinks to, and it already calls
  `/usr/local/bin/emacs` and is up. The stale copy was moved to
  `~/archive/emacs-daemon-old/`.
  **Moved again 2026-08-25** — the service directory now lives at
  `/etc/sv/emacs-daemon`, where every other runit service is, with
  `/var/service/emacs-daemon` symlinked to it. Nothing under `$HOME` is
  involved any more, so the two-directories confusion above cannot recur.
  Only `run` was carried over — `supervise/` is recreated by runsv, and the two
  `run.bak-*` copies were dropped with the old directory (the live script is the
  one in `/etc/sv`, and `~/archive/emacs-daemon-old/` still holds the 2025 stale
  service dir). The move itself needed no edit to the script
  (it never derived paths from its own location), but it is now root-owned, so
  editing it needs `sudo`. `sv down emacs-daemon` in `.bashrc` addresses the service by
  name through `/var/service`, so it was unaffected.
  The move also exposed a latent bug: `runsv` execs `run` with cwd set to the
  service directory, so the daemon inherited it as its working directory and
  every new frame, `*scratch*` and `find-file` started there. This was always
  true — it just went unnoticed while the path was `~/service/emacs-daemon`
  rather than a root-owned `/etc/sv` one. Fixed 2026-08-25 by a
  `cd /home/vukini || exit 1` before the `exec`; `command-line-default-directory`
  now reports `~/`. Same class of fix as the `cd "$HOME"` in `.xinitrc`.
- **`~/bin/cuis` is not tracked anywhere.** The `cuis` alias and
  `~/.local/share/applications/cuis.desktop` both point at that wrapper rather
  than calling `RunCuisOnLinux.sh` directly, so the alias in this repo depends on
  a script that is not in it (same situation as ble.sh below).
  The wrapper exists because Cuis resolves `DirectoryEntry userBaseDirectory` to
  `#currentDirectory`, not to the documented `<cuisBase>-UserFiles` sibling — so
  launching from `$HOME` (which both entry points did) scattered `UserChanges/`
  and `UserPrefs.txt` into the home directory. It passes `-ud <abs path>` to pin
  them, and must also pass the image path explicitly, because
  `RunCuisOnLinux.sh` only forwards arguments to the image after it has seen an
  `.image` argument. The image is globbed from `CuisImage/`, so a version bump
  needs no edit to the wrapper.
  Points at **Cuis 7.8** (`~/apps/Cuis7-8`, a git clone) as of 2026-08-25; 7.8
  has the same `userBaseDirectory` behaviour as 7.2, re-tested. The 7.2 tree at
  `~/apps/Cuis7/` was deleted the same day — its user `.changes` files held only
  startup and `CoreUpdates` fileIn records, no method or class definitions, so
  there was no image work to lose.
  Verified: launched from an unrelated directory, both that directory and `$HOME`
  stay clean, and files land in `~/apps/Cuis7-8-UserFiles/`.
- `~/.xinitrc` is not tracked in this repo; it now contains the `cd "$HOME"` that
  stops terminals inheriting whatever directory `startx` was run from.
- ~~`~/.dotfiles` has no remote.~~ Resolved — `origin` is
  `git@github.com:vukini/dotfiles.git`.
- **ble.sh is not tracked anywhere.** `~/.blerc` is in this repo but the editor
  itself lives in `~/.local/share/blesh` and is updated out-of-band with
  `ble-update`. A version bump can change binding behaviour under `.blerc`
  without any commit here; the version in use is recorded in Part 2.
- ~~**`C-r` is claimed by both atuin and fzf.**~~ Resolved — `.blerc` re-asserts
  atuin's binding after the fzf module loads, and fzf's history widget moved to
  `M-r`. Worth re-checking after any ble.sh or atuin update, since the fix
  depends on hook ordering at `ble-attach`.
