👉 [Support my work via GitHub Sponsors](https://github.com/sponsors/xenodium)

# emacs-skills

Claude Code skills for Emacs integration.

These skills enable tighter integration with agents running inside Emacs, for example [agent-shell](https://github.com/xenodium/agent-shell).

## Skills

### /dired

Open files from the latest agent interaction in an Emacs dired buffer via `emacsclient`.

- **Same directory**: Opens dired at the parent directory with the relevant files marked, showing them in context alongside sibling files.
- **Multiple directories**: Creates a curated `*agent-files*` dired buffer containing only the relevant files, using relative paths from a common ancestor.

### /open

Open files from the latest agent interaction in Emacs buffers via `emacsclient`. Jumps to a specific line when relevant.

### /select

Open a file in Emacs and select the region most relevant to the current discussion. Ready to act on immediately: narrow, copy, refactor, etc.

### /highlight

Highlight relevant regions in a file in Emacs with a temporary read-only minor mode. Press `q` to exit and remove highlights.

### /describe

Look up Emacs documentation using the appropriate mechanism: `describe-function`, `describe-variable`, `describe-key`, `describe-symbol`, `apropos`, `apropos-documentation`, `info`, or `shortdoc`.

### emacsclient (auto)

Always prefer `emacsclient` over `emacs` when the agent needs to interact with Emacs. This skill is not a slash command; it activates automatically.

### file-links (auto)

Format file references as markdown links with GitHub-style `#L` line numbers (e.g., `[file.el:42](path/to/file.el#L42)`). Activates automatically.

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
