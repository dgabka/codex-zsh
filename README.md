# codex-zsh

Codex CLI integration with zsh.

## Usage

Source the entrypoint from your `.zshrc`:

```zsh
source /path/to/codex-zsh/codex-zsh.zsh
```

Optional: install the bundled commit skill so `:commit` can use the richer
skill prompt:

```zsh
mkdir -p ~/.codex/skills
ln -s /path/to/codex-zsh/skills/commit ~/.codex/skills/commit
```

Then use agent prompts directly from your shell:

```zsh
: explain this codebase
:new start a fresh session
:plan design the implementation first
:model
:effort
:commit
```

## Commands

- `: <prompt>` sends a prompt to `codex exec`
- `:new [prompt]` clears the active session, optionally starting a new one
- `:plan [prompt]` asks Codex for an implementation plan without editing files
- `:model` opens an `fzf` picker for the Codex model
- `:effort` opens an `fzf` picker for reasoning effort
- `:commit [context]` generates a conventional commit message and pre-fills `git commit`

`:commit` asks Codex to use the bundled commit skill when available, and falls
back to embedded commit-message rules when the skill is not installed.

The shell prompt can read these env vars to show active agent status:

- `CODEX_AGENT_MODEL`
- `CODEX_AGENT_REASONING_EFFORT`

## Extras

### Starship prompt

`CODEX_AGENT_MODEL` and `CODEX_AGENT_REASONING_EFFORT` are exported only after
an agent session is active. To show the active Codex model and reasoning effort
in Starship, add a custom module to your `starship.toml`:

```toml
[custom]
[custom.codex_agent]
command = "if [ -n \"$CODEX_AGENT_MODEL\" ] && [ -n \"$CODEX_AGENT_REASONING_EFFORT\" ]; then\n  printf \"%s:%s\" \"$CODEX_AGENT_MODEL\" \"$CODEX_AGENT_REASONING_EFFORT\"\nelif [ -n \"$CODEX_AGENT_MODEL\" ]; then\n  printf \"%s\" \"$CODEX_AGENT_MODEL\"\nelse\n  printf \"%s\" \"$CODEX_AGENT_REASONING_EFFORT\"\nfi\n"
format = 'via [$symbol$output]($style) '
style = 'bold cyan'
symbol = '󱚟 '
when = 'test -n "$CODEX_AGENT_MODEL" || test -n "$CODEX_AGENT_REASONING_EFFORT"'
```
