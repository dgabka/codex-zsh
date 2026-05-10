---
name: commit
description: Write a short conventional commit message from a supplied diff and repository context.
---

Create one commit subject for the provided change set.

Output only the final subject line. Do not add markdown, quotes, code fences,
JSON, explanations, alternatives, or trailing commentary.

Use this shape:

type(optional-scope): imperative summary

Valid types are:

feat, fix, refactor, perf, docs, style, test, chore, ci, build, revert

Guidelines:

- Prefer the smallest accurate type for the user-visible effect of the diff.
- Add a scope when it makes the subject clearer; keep it lowercase and compact.
- Use imperative mood: "add", "remove", "handle", "split", "rename".
- Keep the summary lowercase, without a final period.
- Aim for a compact subject; do not exceed 72 characters unless unavoidable.
- Describe the result of the change, not the mechanical edits.
- Do not include issue numbers, PR numbers, ticket IDs, or parenthetical refs.
- If the diff clearly changes a public contract in a breaking way, mark it with
  `!`, for example `feat(api)!: require auth token`.

Use the inputs in this order:

1. `git_diff` tells you what actually changed.
2. `additional_context` can clarify intent or preferred wording.
3. `recent_commit_messages` shows the repository's style; ignore references
   such as `(#123)` when learning from it.
4. `branch_name` is only a weak hint.

Examples:

- feat(auth): add oauth login
- fix(api): handle empty user response
- refactor(parser): simplify token dispatch
- docs(readme): describe local setup
- chore(deps): update lockfile

Return exactly one line.
# Git Commit Skill

Create one commit subject for the provided change set.

Output only the final subject line. Do not add markdown, quotes, code fences,
JSON, explanations, alternatives, or trailing commentary.

Use this shape:

type(optional-scope): imperative summary

Valid types are:

feat, fix, refactor, perf, docs, style, test, chore, ci, build, revert

## Guidelines:

- Prefer the smallest accurate type for the user-visible effect of the diff.
- Add a scope when it makes the subject clearer; keep it lowercase and compact.
- Use imperative mood: "add", "remove", "handle", "split", "rename".
- Keep the summary lowercase, without a final period.
- Aim for a compact subject; do not exceed 72 characters unless unavoidable.
- Describe the result of the change, not the mechanical edits.
- Do not include issue numbers, PR numbers, ticket IDs, or parenthetical refs.
- If the diff clearly changes a public contract in a breaking way, mark it with
  `!`, for example `feat(api)!: require auth token`.

## Use the inputs in this order:

1. `git_diff` tells you what actually changed.
2. `additional_context` can clarify intent or preferred wording.
3. `recent_commit_messages` shows the repository's style; ignore references
   such as `(#123)` when learning from it.
4. `branch_name` is only a weak hint.

## Examples:

- feat(auth): add oauth login
- fix(api): handle empty user response
- refactor(parser): simplify token dispatch
- docs(readme): describe local setup
- chore(deps): update lockfile

Return exactly one line.


