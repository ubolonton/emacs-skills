---
name: compile
description: 'This skill should be used when the user invokes "/compile" to run a command in an Emacs compilation buffer via emacsclient instead of in the terminal.'
tools: Bash
disable-model-invocation: true
---

# Run command in Emacs compilation buffer

Instead of running a command in the terminal, run it in an Emacs `*compilation*` buffer using `emacsclient --eval`. The compilation buffer makes errors and warnings clickable, allowing easy navigation to source locations.

Use whatever command is relevant from the current context. If the user provides a specific command (e.g., `/compile npm test`), use that command.

## How to run

Set `default-directory` to the project root so relative paths in error output resolve correctly.

```sh
emacsclient --eval '
(let ((default-directory "/path/to/project/"))
  (compile "the-command"))'
```

## Rules

- Set `default-directory` to the project root.
- If no command is apparent from context and the user didn't specify one, ask the user what to run.
- Run the `emacsclient --eval` command via the Bash tool.
