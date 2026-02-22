---
name: open
description: 'This skill should be used when the user invokes "/open" to open files from the latest interaction in Emacs buffers via emacsclient.'
tools: Bash
disable-model-invocation: true
---

# Open files in Emacs

Open files from the most recent interaction in Emacs buffers using `emacsclient`. Only include files relevant to the latest interaction (files just generated, edited, listed, or produced by the most recent tool output), not all files mentioned throughout the conversation.

## How to open files

Use `emacsclient` to visit each file. Use `--no-wait` so the command returns immediately.

### Single file

```sh
emacsclient --no-wait "/path/to/file.txt"
```

### Multiple files

```sh
emacsclient --no-wait "/path/to/file1.txt" "/path/to/file2.txt" "/path/to/file3.txt"
```

### Opening at a specific line

If a specific line number is relevant (e.g., an error location or a newly added function), use the `+LINE` syntax:

```sh
emacsclient --no-wait +42 "/path/to/file.txt"
```

## Rules

- Use absolute paths for all files.
- Use `--no-wait` so the command returns immediately.
- If a specific line is relevant, use the `+LINE` syntax to jump to it.
- If no relevant files exist in the recent interaction, inform the user that there are no files to open.
- Run the `emacsclient` command via the Bash tool.
