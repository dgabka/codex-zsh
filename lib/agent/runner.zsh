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
