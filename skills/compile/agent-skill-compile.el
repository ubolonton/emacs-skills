(require 'cl-lib)

(cl-defun agent-skill-compile (&key dir command output)
  "Populate an Emacs compilation buffer with OUTPUT.

DIR is the project root (used for resolving relative paths in errors).
COMMAND is the command that was run (displayed in the buffer header).
OUTPUT is the command's output as a string."
  (let ((default-directory (file-name-as-directory dir)))
    (with-current-buffer (get-buffer-create "*compilation*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "-*- mode: compilation; default-directory: %S -*-\n"
                        default-directory))
        (insert (format "Command: %s\n\n" command))
        (insert output)
        (insert (format "\n\nCompilation finished.\n")))
      (compilation-mode)
      (goto-char (point-min))
      (display-buffer (current-buffer)))))

(provide 'agent-skill-compile)
