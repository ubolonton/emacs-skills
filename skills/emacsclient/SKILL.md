---
name: emacsclient
description: 'When the user asks to do something in Emacs, use emacsclient to communicate with the running Emacs server rather than launching a new Emacs instance.'
tools: Bash
---

# Prefer emacsclient

The user has an Emacs server running. When asked to do something in Emacs (open a file, evaluate elisp, run a command, etc.), always use `emacsclient` rather than launching `emacs`.

## Examples

- Open a file: `emacsclient --no-wait "/path/to/file"`
- Evaluate elisp: `emacsclient --eval '(some-function)'`
- Open at a line: `emacsclient --no-wait +42 "/path/to/file"`

## Rules

- Always use `emacsclient`, never `emacs`.
- Use `--no-wait` when opening files so the command returns immediately.
- Use `--eval` when evaluating elisp.
- Run `emacsclient` commands via the Bash tool.
