---
name: compile
description: 'This skill should be used when the user invokes "/compile" to run a command and display its output in an Emacs compilation buffer via emacsclient.'
tools: Bash
disable-model-invocation: true
---

# Run command and show output in Emacs compilation buffer

When the user invokes `/compile`, run the command in the terminal first (so you can see the output directly and offer to fix issues), then send the output to an Emacs `*compilation*` buffer for clickable error navigation.

Use whatever command is relevant from the current context. If the user provides a specific command (e.g., `/compile npm test`), use that command.

## Steps

1. Run the command via Bash and capture its output.
2. Call `agent-skill-compile` to populate the compilation buffer with the output.

First, locate `agent-skill-compile.el` which lives alongside this skill file at `skills/compile/agent-skill-compile.el` in the emacs-skills plugin directory.

```sh
emacsclient --eval '
(progn
  (load "/path/to/skills/compile/agent-skill-compile.el" nil t)
  (agent-skill-compile
    :dir "/path/to/project"
    :command "the-command"
    :output "the captured output from step 1"))'
```

## Rules

- Set `:dir` to the project root so relative paths in errors resolve correctly.
- Set `:command` to the command that was run.
- Set `:output` to the full output captured from running the command.
- If no command is apparent from context and the user didn't specify one, ask the user what to run.
- If the output contains errors, offer to fix them.
- Locate `agent-skill-compile.el` relative to this skill file's directory.
- Run the `emacsclient --eval` command via the Bash tool.
