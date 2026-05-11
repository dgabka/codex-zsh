# Repository Guidelines

## Project Structure & Module Organization

This repository is a zsh integration for the Codex CLI. `codex-zsh.zsh` is the entrypoint users source from `.zshrc`. Runtime internals live in `lib/agent/`: core helpers, session state, Codex execution, and preexec hook installation. Public colon commands live in `lib/commands/`, including `:commit` and `:help`. The optional commit skill lives at `skills/commit/SKILL.md`. There is no `test/` directory or asset pipeline.

## Build, Test, and Development Commands

No build step is required.

- `zsh -n codex-zsh.zsh lib/**/*.zsh`: syntax-check the entrypoint and library files.
- `source ./codex-zsh.zsh`: load the integration in interactive zsh.
- `:agent-debug`: inspect hook registration, session state, and model/effort.
- `: explain this repo`: manually verify the preexec agent prompt path.
- `:commit optional context`: verify commit-message generation.
- `:help`: verify the command list without requiring Codex or fzf.

Use a disposable shell so existing shell state does not hide bugs.

## Coding Style & Naming Conventions

Write zsh, not bash. Prefer `emulate -L zsh` inside functions and use zsh arrays intentionally. Keep agent helpers private with the `_codex_agent_` prefix. Public commands use colon-prefixed names such as `:new`, `:plan`, `:commit`, `:help`, and `:agent-debug`. Use two-space indentation and concise stderr messages with `print -u2 --`.

Avoid redefining bare `:` or intercepting ZLE Enter widgets. The integration relies on a preexec hook for compatibility with autosuggestions, vi-mode, and normal shell redraw behavior.

## Testing Guidelines

There is no formal test framework yet. At minimum, run `zsh -n codex-zsh.zsh lib/**/*.zsh` before committing. For behavior changes, test in clean interactive zsh by sourcing `./codex-zsh.zsh` and exercising the relevant command. Verify that bare `:` remains the builtin no-op and that `: <prompt>` invokes Codex through preexec. When touching session logic, check same-directory resume and changed-directory fresh-session behavior.

## Commit & Pull Request Guidelines

The bundled workflow expects conventional commits in the form `type(scope): description`, for example `fix(agent): preserve builtin colon command`. Keep descriptions imperative, lowercase, concise, and without a trailing period. Use `:commit` when available to generate a candidate message.

Pull requests should describe the user-facing shell behavior changed, include manual test commands and results, and call out compatibility risks with zsh plugins such as autosuggestions or vi-mode. Link related issues when applicable.

## Agent-Specific Instructions

Keep the dependency surface small: Codex CLI is required, and `fzf` should remain optional for `:model` and `:effort`. Preserve Starship integration as environment-variable output only; do not add prompt rendering here.
