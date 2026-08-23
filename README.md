# Environment notes

Reference for this machine's shell and Emacs configuration, and a record of
what changed on 2026-08-23.

- **Shell config** — `~/.dotfiles/bash/.bashrc` (this repo). `~/.bashrc` is a
  symlink to it.
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
| listing | `ls` `ll` `e` `et` `el` `lst` `lstf` (exa when installed) |
| config | `b` `lh` `lq` `lresolv` |
| files | `chx` `cpr` `xo` `pdf` |
| system | `psg` `fq` `kk` `hg` `nmtui` `swapcaps` `rq` |
| xbps | `pi` `pis` `piu` |
| network | `pv` `didi` |
| languages | `activate` `sb` `lisp` `cuis` |
| flask app | `start-app` `status-app` `check-app` `db-edit` |

---

## Part 2 — What changed

### Shell (`~/.dotfiles`, 3 commits)

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

Also: `setxkbmap` is now guarded by `$DISPLAY` (it used to run in every TTY and
ssh session), all `source` lines are existence-guarded, and the
`history -a; history -c; history -r` in `PROMPT_COMMAND` was dropped — atuin
already provides cross-shell history, and that reloaded a 20 000-line file at
every prompt.

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

Caching the generated scripts was measured too and does **not** help rbenv: the
expensive `rbenv rehash` runs on every eval regardless of where the script came
from.

**`47dbeea` — aliases.** The 34 above, plus `y()`. 45 → 79 aliases.

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
- The `emacs-daemon` runit service is `sv down` and points at `/usr/bin/emacs`
  (30.2) while the daemon in use is 31.0.50. Editing the one line in
  `/run/runit/runsvdir/current/emacs-daemon/run` would make that permanent.
- `~/.dotfiles` has no remote.
