# emacs-skills

Claude Code skills for Emacs integration.

## Skills

### /dired

Open files from the latest agent interaction in an Emacs dired buffer via `emacsclient`.

- **Same directory**: Opens dired at the parent directory with the relevant files marked, showing them in context alongside sibling files.
- **Multiple directories**: Creates a curated `*agent-files*` dired buffer containing only the relevant files, using relative paths from a common ancestor.

### /open

Open files from the latest agent interaction in Emacs buffers via `emacsclient`. Jumps to a specific line when relevant.

### /select

Open a file in Emacs and select the region most relevant to the current discussion. Ready to act on immediately — narrow, copy, refactor, etc.

### /compile

Run a command in an Emacs `*compilation*` buffer via `emacsclient` instead of in the terminal. Errors and warnings become clickable for easy navigation.

## Requirements

- Emacs running a server (`M-x server-start` or `(server-start)` in your init file)
- `emacsclient` available on `$PATH`

## Install

```sh
claude plugin marketplace add xenodium/emacs-skills
claude plugin install emacs-skills@xenodium-emacs-skills
```

## Update

```sh
claude plugin marketplace update xenodium-emacs-skills
```

## Uninstall

```sh
claude plugin uninstall emacs-skills
```
