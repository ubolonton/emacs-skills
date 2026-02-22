---
name: select
description: 'This skill should be used when the user invokes "/select" to open a file in Emacs and select a region relevant to the current discussion via emacsclient.'
tools: Bash
disable-model-invocation: true
---

# Select region in Emacs

Open a file in Emacs and select (activate the region around) the code or text most relevant to the current discussion using `emacsclient --eval`. This allows the user to immediately act on the selection: narrow, copy, refactor, comment, etc.

Determine the relevant file and line range from the most recent interaction context.

## How to select

```sh
emacsclient --eval '
(progn
  (find-file "/path/to/file")
  (goto-char (point-min))
  (forward-line (1- START_LINE))
  (set-mark (point))
  (forward-line (- END_LINE START_LINE))
  (end-of-line)
  (activate-mark))'
```

Replace `START_LINE` and `END_LINE` with the appropriate line numbers.

## Rules

- Use absolute paths for files.
- Choose the region that is most relevant to the current discussion (e.g., a function just modified, a block with an error, code just generated).
- If no specific region is apparent, select the entire relevant function or block.
- If no relevant file or region exists in the recent interaction, inform the user.
- Run the `emacsclient --eval` command via the Bash tool.
