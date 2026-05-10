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

function _codex_agent_effective_model {
  print -r -- "${CODEX_AGENT_SELECTED_MODEL:-${CODEX_AGENT_MODEL:-${CODEX_AGENT_DEFAULT_MODEL:-gpt-5.5}}}"
}

function _codex_agent_effective_reasoning_effort {
  print -r -- "${CODEX_AGENT_SELECTED_REASONING_EFFORT:-${CODEX_AGENT_REASONING_EFFORT:-${CODEX_AGENT_DEFAULT_REASONING_EFFORT:-medium}}}"
}

function _codex_agent_exec_args {
  local -a args
  args=()

  local model reasoning_effort
  model="$(_codex_agent_effective_model)"
  reasoning_effort="$(_codex_agent_effective_reasoning_effort)"

  args+=(-m "$model")
  args+=(-c "model_reasoning_effort=\"${reasoning_effort}\"")

  print -rl -- "${args[@]}"
}

function _codex_agent_activate_session {
  export CODEX_AGENT_MODEL="$(_codex_agent_effective_model)"
  export CODEX_AGENT_REASONING_EFFORT="$(_codex_agent_effective_reasoning_effort)"
}

function _codex_agent_run {
  emulate -L zsh
  setopt pipefail

  local mode="$1"
  shift
  local display_mode="$mode"
  [[ "$display_mode" == ":" ]] && display_mode="agent"

  local prompt="$*"
  if [[ -z "$prompt" ]]; then
    print -u2 -- "$display_mode: missing prompt"
    return 1
  fi

  _codex_agent_require "$display_mode" || return 1

  local cwd="$PWD"
  local resume_session=0
  if [[ -n "${CODEX_AGENT_SESSION_ID:-}" && "${CODEX_AGENT_SESSION_CWD:-}" == "$cwd" ]]; then
    resume_session=1
  fi

  local tmp_dir output_file log_file code thread_id last_byte
  tmp_dir=$(mktemp -d -t codex-agent.XXXXXX) || return 1
  output_file="$tmp_dir/output.txt"
  log_file="$tmp_dir/codex.jsonl"

  print -u2 -- "$display_mode: running codex"

  local -a codex_args
  codex_args=(${(f)"$(_codex_agent_exec_args)"})

  if ((resume_session)); then
    codex exec resume \
      "${codex_args[@]}" \
      --json \
      -o "$output_file" \
      "$CODEX_AGENT_SESSION_ID" \
      "$prompt" >| "$log_file" 2>&1
  else
    codex exec \
      "${codex_args[@]}" \
      --json \
      --sandbox workspace-write \
      --color never \
      -C "$cwd" \
      -o "$output_file" \
      "$prompt" >| "$log_file" 2>&1
  fi
  code=$?

  if ((code != 0)); then
    if [[ -s "$log_file" ]]; then
      tail -40 "$log_file" >&2
    fi
    rm -rf -- "$tmp_dir"
    print -u2 -- "$display_mode: codex failed"
    return $code
  fi

  thread_id=$(sed -n 's/.*"thread_id":"\([^"]*\)".*/\1/p' "$log_file" | tail -1)
  if [[ -n "$thread_id" ]]; then
    export CODEX_AGENT_SESSION_ID="$thread_id"
    export CODEX_AGENT_SESSION_CWD="$cwd"
    _codex_agent_activate_session
  fi

  if [[ -s "$output_file" ]]; then
    cat "$output_file"
    last_byte=$(tail -c 1 "$output_file" 2>/dev/null | od -An -tx1 | tr -d '[:space:]')
    [[ "$last_byte" == "0a" ]] || print
  fi

  rm -rf -- "$tmp_dir"
}

function :new {
  emulate -L zsh

  unset CODEX_AGENT_SESSION_ID
  unset CODEX_AGENT_SESSION_CWD
  unset CODEX_AGENT_MODEL
  unset CODEX_AGENT_REASONING_EFFORT

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

function _codex_agent_preexec {
  emulate -L zsh

  local command="$1"
  if [[ "$command" == ': '* ]]; then
    local prompt="${command#': '}"
    [[ -n "$prompt" ]] || return
    _codex_agent_run ":" "$prompt"
  fi
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

unset CODEX_AGENT_SESSION_ID
unset CODEX_AGENT_SESSION_CWD
unset CODEX_AGENT_MODEL
unset CODEX_AGENT_REASONING_EFFORT

if [[ -o interactive && -z "${CODEX_AGENT_PREEXEC_INSTALLED:-}" ]]; then
  typeset -g CODEX_AGENT_PREEXEC_INSTALLED=1
  typeset -ga preexec_functions
  preexec_functions+=(_codex_agent_preexec)
fi
