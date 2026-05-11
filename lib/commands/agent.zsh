function :new {
  emulate -L zsh

  _codex_agent_clear_session

  if (( $# == 0 )); then
    print -u2 -- ":new: cleared codex agent session"
    return
  fi

  _codex_agent_run ":new" "$@"
}

function :plan {
  emulate -L zsh

  local prompt="$*"
  if [[ -z "$prompt" ]]; then
    prompt="Create a decision-complete implementation plan for the current task. Do not edit files."
  else
    prompt="Create a decision-complete implementation plan for the following task. Do not edit files. Task: $prompt"
  fi

  _codex_agent_run ":plan" "$prompt"
}

function :model {
  emulate -L zsh

  local choice
  choice=$(_codex_agent_pick model \
    gpt-5.5 \
    gpt-5.4 \
    gpt-5.4-mini \
    gpt-5.3-codex \
    gpt-5.2) || return $?

  export CODEX_AGENT_SELECTED_MODEL="$choice"
  if [[ -n "${CODEX_AGENT_SESSION_ID:-}" ]]; then
    export CODEX_AGENT_MODEL="$choice"
  fi
  print -u2 -- ":model: selected $CODEX_AGENT_SELECTED_MODEL"
}

function :effort {
  emulate -L zsh

  local choice
  choice=$(_codex_agent_pick effort \
    low \
    medium \
    high \
    xhigh) || return $?

  export CODEX_AGENT_SELECTED_REASONING_EFFORT="$choice"
  if [[ -n "${CODEX_AGENT_SESSION_ID:-}" ]]; then
    export CODEX_AGENT_REASONING_EFFORT="$choice"
  fi
  print -u2 -- ":effort: selected $CODEX_AGENT_SELECTED_REASONING_EFFORT"
}

function :agent-debug {
  emulate -L zsh

  print -r -- "agent source: ${(%):-%x}"
  print -r -- "main enter:  $(bindkey '^M' 2>/dev/null)"
  print -r -- "emacs enter: $(bindkey -M emacs '^M' 2>/dev/null)"
  print -r -- "viins enter: $(bindkey -M viins '^M' 2>/dev/null)"
  print -r -- "vicmd enter: $(bindkey -M vicmd '^M' 2>/dev/null)"
  print -r -- "accept-line: ${widgets[accept-line]-missing}"
  print -r -- "preexec hook:${preexec_functions[(r)_codex_agent_preexec]-missing}"
  print -r -- "session:     ${CODEX_AGENT_SESSION_ID:-inactive}"
  print -r -- "model:       ${CODEX_AGENT_MODEL:-inactive} selected=${CODEX_AGENT_SELECTED_MODEL:-default}"
  print -r -- "effort:      ${CODEX_AGENT_REASONING_EFFORT:-inactive} selected=${CODEX_AGENT_SELECTED_REASONING_EFFORT:-default}"
  whence -w :
}
