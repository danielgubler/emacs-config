;;; mermaid-mode.el --- major mode for working with mermaid graphs -*- lexical-binding: t; -*-
;; This file is NOT part of Emacs.

;;; Code:

;; (defgroup mermaid-mode nil
;;   "Major mode for working with mermaid graphs."
;;   :group 'extensions
;;   :link '(url-link :tag "Repository" "https://github.com/abrochard/mermaid-mode"))

(setq mmd-opening-paragraph "^ *subgraph")
(setq mmd-closing-paragraph "^ *end *$")
(setq mmd-paragraph-tag-rx (concat "\\(" mmd-opening-paragraph "\\)\\|\\(" mmd-closing-paragraph "\\)"))

(defcustom mermaid-flags ""
  "Additional flags to pass to the mermaid-cli."
  :group 'mermaid-mode
  :type 'string)

(defconst mermaid-font-lock-keywords
  `((,(regexp-opt '("graph" "subgraph" "end" "flowchart" "sequenceDiagram" "classDiagram" "stateDiagram" "erDiagram" "gantt" "pie" "loop" "alt" "else" "opt") 'words) . font-lock-keyword-face)
    ("---\\|-?->*\\+?\\|==>\\|===" . font-lock-function-name-face)
    (,(regexp-opt '("TB" "TD" "BT" "LR" "RL" "DT" "BT" "class" "title" "section" "participant" "dataFormat" "Note") 'words) . font-lock-constant-face)))

(defvar mermaid-syntax-table
  (let ((syntax-table (make-syntax-table)))
    ;; Comment style "%% ..."
    (modify-syntax-entry ?% ". 124" syntax-table)
    (modify-syntax-entry ?\n ">" syntax-table)
    syntax-table)
  "Syntax table for `mermaid-mode'.")

(defun mmd-is-line-closing-paragraph ()
  "Returns t if the current line is a closing paragraph line, otherwise returns nil"
  (let ((l (line-number-at-pos)))
    (save-excursion
      (beginning-of-line)
      (and (re-search-forward mmd-closing-paragraph nil t)
           (eq l (line-number-at-pos))))))

(defun mmd-find-opening-paragraph-line-indentation (nested)
  "Returns the indentation of the matching opening paragraph line, or nil if there isn't one"
  (save-excursion
    (beginning-of-line)
    (if (re-search-backward mmd-paragraph-tag-rx nil t)
        (progn
          (if (mmd-is-line-closing-paragraph)
              (setq nested (+ nested 1))
            (setq nested (- nested 1)))
          (if (< nested 0) (current-indentation) (mmd-find-opening-paragraph-line-indentation nested))))))

(defun mmd-calculate-indentation ()
  "Get the indentation of the opening paragraph for the current line or nil if there is no opening line"
  (let ((openingIndentation (mmd-find-opening-paragraph-line-indentation 0)))
    (cond
     (openingIndentation
      (if (mmd-is-line-closing-paragraph)
          openingIndentation
        (+ 2 openingIndentation)))
     (t 0))))

(defun mermaid-indent-line ()
  "Indent the current line to based on its nesting"
  (indent-line-to (mmd-calculate-indentation)))

;;;###autoload
(define-derived-mode mermaid-mode prog-mode "mermaid"
  :syntax-table mermaid-syntax-table
  (setq-local font-lock-defaults '(mermaid-font-lock-keywords))
  (setq-local indent-line-function 'mermaid-indent-line)
  (setq-local comment-start "%%")
  (setq-local comment-end "")
  (setq-local comment-start-skip "%%+ *"))

(provide 'mermaid-mode)
;;; mermaid-mode.el ends here
