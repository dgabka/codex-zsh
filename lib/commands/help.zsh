function :help {
  emulate -L zsh

  print -r -- "codex-zsh commands:"
  print -r -- "  : <prompt>          send a prompt to codex exec"
  print -r -- "  :new [prompt]       clear the active session, optionally starting a new one"
  print -r -- "  :plan [prompt]      ask Codex for an implementation plan without editing files"
  print -r -- "  :model              pick the Codex model with fzf"
  print -r -- "  :effort             pick reasoning effort with fzf"
  print -r -- "  :commit [context]   generate and prefill a conventional git commit message"
  print -r -- "  :agent-debug        print hook, session, model, and effort state"
  print -r -- "  :help               show this help"
}
