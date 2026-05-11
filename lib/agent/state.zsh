function _codex_agent_effective_model {
  print -r -- "${CODEX_AGENT_SELECTED_MODEL:-${CODEX_AGENT_MODEL:-${CODEX_AGENT_DEFAULT_MODEL:-gpt-5.5}}}"
}

function _codex_agent_effective_reasoning_effort {
  print -r -- "${CODEX_AGENT_SELECTED_REASONING_EFFORT:-${CODEX_AGENT_REASONING_EFFORT:-${CODEX_AGENT_DEFAULT_REASONING_EFFORT:-medium}}}"
}

function _codex_agent_activate_session {
  export CODEX_AGENT_MODEL="$(_codex_agent_effective_model)"
  export CODEX_AGENT_REASONING_EFFORT="$(_codex_agent_effective_reasoning_effort)"
}

function _codex_agent_clear_session {
  unset CODEX_AGENT_SESSION_ID
  unset CODEX_AGENT_SESSION_CWD
  unset CODEX_AGENT_MODEL
  unset CODEX_AGENT_REASONING_EFFORT
}
