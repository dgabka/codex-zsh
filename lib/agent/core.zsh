function _codex_agent_require {
  if ! command -v codex >/dev/null 2>&1; then
    print -u2 -- "$1: codex is not available on PATH"
    return 1
  fi
}

function _codex_agent_require_fzf {
  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 -- "$1: fzf is not available on PATH"
    return 1
  fi
}

function _codex_agent_pick {
  emulate -L zsh

  local label="$1"
  shift

  _codex_agent_require_fzf ":$label" || return 1

  local choice
  choice=$(printf '%s\n' "$@" | fzf --height=40% --reverse --prompt="codex $label> ") || return 130
  [[ -n "$choice" ]] || return 1

  print -r -- "$choice"
}
