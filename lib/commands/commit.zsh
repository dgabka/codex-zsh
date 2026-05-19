function _codex_commit_trim {
  emulate -L zsh

  local value="$1"
  if [[ "$value" != *[![:space:]]* ]]; then
    return
  fi

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  print -rn -- "$value"
}

function _codex_commit_message_from_file {
  emulate -L zsh

  local message first_line last_line
  message=$(<"$1")
  message="$(_codex_commit_trim "$message")"

  local fence='```'
  first_line="${message%%$'\n'*}"
  last_line="${message##*$'\n'}"
  if [[ "$first_line" == ${fence}* && "$last_line" == "$fence" ]]; then
    local -a lines
    lines=("${(@f)message}")
    lines=("${(@)lines[2,-2]}")
    message="${(F)lines}"
    message="$(_codex_commit_trim "$message")"
  fi

  first_line="${message%%$'\n'*}"
  if [[ "$message" == *$'\n'* && ("$first_line" == "text" || "$first_line" == "commit") ]]; then
    message="${message#*$'\n'}"
    message="$(_codex_commit_trim "$message")"
  fi

  print -rn -- "$message"
}

function _codex_commit_prefill_command {
  emulate -L zsh

  local commit_prefix="$1"
  local message="$2"
  local subject body command

  subject="${message%%$'\n'*}"
  subject="$(_codex_commit_trim "$subject")"
  [[ -n "$subject" ]] || return 1

  command="$commit_prefix ${(qq)subject}"

  if [[ "$message" == *$'\n'* ]]; then
    body="${message#*$'\n'}"
    body="$(_codex_commit_trim "$body")"
    if [[ -n "$body" ]]; then
      local -a lines paragraphs
      local line trimmed paragraph
      lines=("${(@f)body}")
      paragraphs=()
      paragraph=""

      for line in "${lines[@]}"; do
        trimmed="$(_codex_commit_trim "$line")"
        if [[ -z "$trimmed" ]]; then
          paragraph="$(_codex_commit_trim "$paragraph")"
          [[ -n "$paragraph" ]] && paragraphs+=("$paragraph")
          paragraph=""
        else
          [[ -n "$paragraph" ]] && paragraph+=$'\n'
          paragraph+="$line"
        fi
      done

      paragraph="$(_codex_commit_trim "$paragraph")"
      [[ -n "$paragraph" ]] && paragraphs+=("$paragraph")

      for paragraph in "${paragraphs[@]}"; do
        command+=" -m ${(qq)paragraph}"
      done
    fi
  fi

  print -rn -- "$command"
}

function :commit {
  emulate -L zsh
  setopt pipefail

  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    print -u2 -- ":commit: not inside a git repository"
    return 1
  }

  if ! command -v codex >/dev/null 2>&1; then
    print -u2 -- ":commit: codex is not available on PATH"
    return 1
  fi

  local commit_prefix diff_label git_diff
  if ! git diff --cached --quiet --exit-code; then
    diff_label="git diff --staged"
    commit_prefix="git commit -m"
    git_diff=$(git diff --cached) || return 1
  elif ! git diff --quiet --exit-code; then
    diff_label="git diff"
    commit_prefix="git commit -am"
    git_diff=$(git diff) || return 1
  else
    print -u2 -- ":commit: no staged or tracked unstaged changes"
    return 1
  fi

  local recent_commit_messages branch_name additional_context
  recent_commit_messages=$(git log -12 --pretty=format:%s 2>/dev/null || true)
  branch_name=$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || true)
  additional_context="$*"

  local tmp_dir prompt_file output_file log_file message codex_status
  tmp_dir=$(mktemp -d -t codex-commit.XXXXXX) || return 1
  prompt_file="$tmp_dir/prompt.md"
  output_file="$tmp_dir/message.txt"
  log_file="$tmp_dir/codex.log"

  {
    print -r -- "If the commit skill is available, use it to generate exactly one conventional commit message and ignore the fallback rules below."
    print -r -- ""
    print -r -- "If the commit skill is not available, use this fallback prompt:"
    print -r -- "You are a commit message generator that creates concise, conventional commit messages from git diffs."
    print -r -- 'Return ONLY raw text. No markdown. No code blocks. No ``` markers.'
    print -r -- "The first line must use this format: type(scope): description"
    print -r -- "Allowed types: feat, fix, refactor, perf, docs, style, test, chore, ci, build, revert"
    print -r -- "Scope is optional, lowercase, and has no spaces."
    print -r -- "Description must be imperative, lowercase, no period, and 10-72 characters."
    print -r -- "Prefer a single-line message. Add body paragraphs only when the diff is complex, the user asks for detail, or the reasoning would be lost from the subject alone."
    print -r -- "When adding a body, separate it from the subject with one blank line. Keep body lines wrapped naturally and explain why the change was made."
    print -r -- "For breaking changes, add ! after type or scope, for example refactor!: or feat(api)!:."
    print -r -- "Rules: focus on the primary change; be specific; exclude issue/PR references; match recent commit style; use imperative mood; keep it concise."
    print -r -- "Input priority: git_diff, additional_context, recent_commit_messages, branch_name."
    print -r -- ""
    print -r -- "git_diff_source: $diff_label"
    print -r -- ""
    print -r -- "git_diff:"
    print -r -- '```diff'
    print -r -- "$git_diff"
    print -r -- '```'
    print -r -- ""
    print -r -- "additional_context:"
    print -r -- "$additional_context"
    print -r -- ""
    print -r -- "recent_commit_messages:"
    print -r -- '```text'
    print -r -- "$recent_commit_messages"
    print -r -- '```'
    print -r -- ""
    print -r -- "branch_name:"
    print -r -- "$branch_name"
    print -r -- ""
    print -r -- "Return only the commit message."
  } >|"$prompt_file"

  print -u2 -- ":commit: generating commit message"
  codex exec \
    -m gpt-5.4-mini \
    -c 'model_reasoning_effort="low"' \
    --sandbox read-only \
    --ephemeral \
    --color never \
    -C "$repo_root" \
    -o "$output_file" \
    - <"$prompt_file" >|"$log_file" 2>&1
  codex_status=$?

  if ((codex_status != 0)); then
    if [[ -s "$log_file" ]]; then
      tail -40 "$log_file" >&2
    fi
    rm -rf -- "$tmp_dir"
    print -u2 -- ":commit: codex failed"
    return $codex_status
  fi

  message="$(_codex_commit_message_from_file "$output_file")"

  rm -rf -- "$tmp_dir"

  if [[ -z "$message" ]]; then
    print -u2 -- ":commit: codex returned an empty message"
    return 1
  fi

  local commit_command
  commit_command="$(_codex_commit_prefill_command "$commit_prefix" "$message")" || {
    print -u2 -- ":commit: codex returned an empty subject"
    return 1
  }

  print -z -- "$commit_command"
  print -u2 -- ":commit: prefilled $commit_prefix"
}
