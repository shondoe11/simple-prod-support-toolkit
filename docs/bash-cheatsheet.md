# Bash Cheatsheet


## ShellCheck (Phase 10)

- **Run it**: `shellcheck scripts/*.sh` — install via `brew install shellcheck` (mac) or `apt-get install shellcheck` (Linux/CI).
- **Severity filter**: `shellcheck --severity=warning scripts/*.sh` only reports `warning`/`error`, hiding `info`/`style` noise. Severity order (low to high): `style` < `info` < `warning` < `error`.
- **`SC1091`** (`Not following sourced file`): happens when sourcing a file via a dynamically built path (e.g. `source "$SCRIPT_DIR/utils.sh"`), since ShellCheck can't statically resolve variables. The `-x` flag tells it to actually follow sourced files, but it still can't resolve dynamic paths reliably — `--severity=warning` is a simpler fix since `SC1091` is only `info` level.
- **`# shellcheck source=./path`** directive: documents the real path for tooling/IDE support, even if `-x` can't always resolve it. Place directly above the `source` line.
- **`# shellcheck disable=CODE`** directive: must be placed immediately before a *complete compound command* (e.g. before `if`, not before an `elif` branch mid-block) — otherwise raises `SC1123`.
- **`SC2126`** (`grep|wc -l` vs `grep -c`): `grep -c` only counts matches *per file*; when counting across multiple files with `-h` (no filename prefix), `grep pattern files... | wc -l` is actually correct for a combined total, so disabling this rule is justified when you intentionally need a summed count.
- **`SC2009`** (`ps | grep` vs `pgrep`): prefer `pgrep`, but `ps aux | grep` is a reasonable fallback for partial/fuzzy process name matches that `pgrep -x` (exact match) would miss.
- **`SC2034`** (unused variable from `read`): when destructuring a line with `read -r a b c d`, use `_` for any fields you don't need instead of unused named variables, e.g. `read -r filesystem _ _ _ pcent mount`.
