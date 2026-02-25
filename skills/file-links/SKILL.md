---
name: file-links
description: 'When referencing files, format them as markdown links with line numbers using GitHub-style #L syntax.'
---

# Format file references as markdown links

When referencing files in your output, always format them as markdown links. Use the GitHub-style `#L` fragment for line numbers.

## Format

With a line number:

```
[filename.el:42](relative/path/to/filename.el#L42)
```

With a line range:

```
[filename.el:42-50](relative/path/to/filename.el#L42-L50)
```

Without a line number:

```
[filename.el](relative/path/to/filename.el)
```

## Rules

- Use paths relative to the project root.
- Include line numbers when they are relevant (e.g., error locations, function definitions, modified lines).
- Use line ranges when referring to a block of code.
- The link text should be the filename (or relative path if needed for clarity) followed by the line number.
