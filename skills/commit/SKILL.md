---
name: commit
description: Write a conventional commit message from a supplied diff and repository context. Supports multiline when justified.
---

# Git Commit Skill

Create a commit message for the provided change set.

Default to a single subject line. Add a body only when it meaningfully aids
understanding — not to restate what the diff shows.

Do not add markdown, quotes, code fences, JSON, explanations, alternatives,
or trailing commentary around the commit message itself.

Use this shape:

type(optional-scope): imperative summary

[optional blank line + body]

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

## When to add a body:

Add a body only when at least one of these is true:

- The **why** is non-obvious and would surprise a future reader of `git log`.
- Multiple unrelated concerns changed together and listing them aids navigation.
- A subtle constraint, workaround, or invariant must be preserved by future editors.

Do **not** add a body when:

- The subject already tells the full story.
- The body would just reword the subject or list files touched.
- The diff is small and self-explanatory.

Body lines should wrap at 72 characters. Use plain prose or a short bullet list
(`- point`). Keep it concise — two or three sentences is usually enough.

## Use the inputs in this order:

1. `git_diff` tells you what actually changed.
2. `additional_context` can clarify intent or preferred wording.
3. `recent_commit_messages` shows the repository's style; ignore references
   such as `(#123)` when learning from it.
4. `branch_name` is only a weak hint.

## Examples:

Subject-only (most common):

- feat(auth): add oauth login
- fix(api): handle empty user response
- refactor(parser): simplify token dispatch
- docs(readme): describe local setup
- chore(deps): update lockfile

With body (only when justified):

```
fix(scheduler): prevent double-firing on rapid re-renders

The effect cleanup was running after the new effect started, so the
cancel flag from the previous run was clearing the new timer. Moved
cleanup to fire synchronously before re-scheduling.
```

Return the subject line, and optionally a blank line followed by a body.

