function _codex_agent_preexec {
  emulate -L zsh

  local command="$1"
  if [[ "$command" == ': '* ]]; then
    local prompt="${command#': '}"
    [[ -n "$prompt" ]] || return
    _codex_agent_run ":" "$prompt"
  fi
}

_codex_agent_clear_session

if [[ -o interactive && -z "${CODEX_AGENT_PREEXEC_INSTALLED:-}" ]]; then
  typeset -g CODEX_AGENT_PREEXEC_INSTALLED=1
  typeset -ga preexec_functions
  preexec_functions+=(_codex_agent_preexec)
fi
