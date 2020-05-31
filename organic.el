;; Organic.el — command line interface for Emacs Org-mode.
;; Copyright © 2020 Ivan Gankevich
;; 
;; This file is part of Organic.el.
;; 
;; Virtual Testbed is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; 
;; Virtual Testbed is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with Virtual Testbed.  If not, see <https://www.gnu.org/licenses/>.

(defun usage ()
  (message "usage: org action ...")
  (message "  init                      install/update emacs packages")
  (message "    -d directory            build directory (default: build)")
  (message "  export [options] files    export orgmode file")
  (message "    -o format               output format (latex, beamer, odt, ascii, html, md)")
  (message "    -O format               final format (pdf)")
  (message "    -d directory            build directory (default: build)")
  (message "  publish                   publish orgmode as web-site")
  (message "    -d directory            build directory (default: build)")
  (message "  execute file [line]       execute org-babel source code block")
  (message "    -d directory            build directory (default: build)")
  (message "Put package list in .org/packages.el in the current directory.")
  (message "Put custom Emacs configuration in .org/config.el in the current directory.")
  (kill-emacs 1))

(defconst %packages "./.org/packages.el")
(defconst %config "./.org/config.el")
(defconst %build-directory "./build")

(defun org-export/init (argv)
  (require 'package)
  (defvar build-directory %build-directory)
  (defvar prev-arg nil)
  (dolist (arg argv)
    (progn
      (cond
        ((not prev-arg) t)
        ((string-equal prev-arg "-d") (setq build-directory arg))
        (t t))
      (setq prev-arg arg)))
  (message (format "build-directory: %s" build-directory))
  (if (file-exists-p %packages)
    (load-file %packages)
    (progn
      ; list the packages you want
      (setq package-list '(org org-plus-contrib org-ref htmlize gnuplot))
      ; list the repositories containing them
      (setq package-archives '(("elpa" . "https://tromey.com/elpa/")
                               ("gnu" . "https://elpa.gnu.org/packages/")
                               ("melpa" . "https://melpa.org/packages/")
                               ("org" . "https://orgmode.org/elpa/")))))
  ; set installation prefix
  (setq package-user-dir (file-truename build-directory))
  (make-directory package-user-dir t)
  ; activate all the packages (in particular autoloads)
  (package-initialize)
  ; fetch the list of packages available 
  (unless package-archive-contents
    (package-refresh-contents))
  ; install the missing packages
  (dolist (package package-list)
    (unless (package-installed-p package)
      (package-install package))))

(defun org-export/format->extension (fmt)
  (cond
    ((string-equal fmt "latex") "tex")
    ((string-equal fmt "beamer") "tex")
    ((string-equal fmt "odt") "odt")
    ((string-equal fmt "ascii") "txt")
    ((string-equal fmt "html") "html")
    ((string-equal fmt "md") "md")
    (t fmt)))

(defun org-export/export-file (file fmt)
  (find-file file)
  (cond
    ((string-equal fmt "latex") (org-latex-export-to-latex))
    ((string-equal fmt "beamer") (org-beamer-export-to-latex))
    ((string-equal fmt "odt") (org-odt-export-to-odt))
    ((string-equal fmt "ascii") (org-ascii-export-to-ascii))
    ((string-equal fmt "html") (org-html-export-to-html))
    ((string-equal fmt "md") (org-md-export-to-markdown))
    (t (progn
         (message (format "Unknown export format: %s" format-1))
         (kill-emacs 1)))))

(defun org-export/default-latex->pdf (file build-directory)
  (message
    (shell-command-to-string
      (mapconcat
        'identity
        (list "env max_print_line=1000 texfot --no-stderr --quiet"
              "latexmk -8bit -interaction=nonstopmode -pdf -xelatex -bibtex -shell-escape"
              (concat "-output-directory=" build-directory)
              "-f" file)
        " ")))
  (rename-file file (file-name-as-directory build-directory) t))

(defun org-export/init-fast (build-directory)
  (setq package-user-dir (file-truename build-directory))
  (package-initialize)
  (if (file-exists-p %config) (load-file %config)))

(defun org-export/export (argv)
  (defvar build-directory %build-directory)
  (defvar format-1 nil)
  (defvar format-2 nil)
  (defvar prev-arg nil)
  (defvar files '())
  (dolist (arg argv)
    (progn
      (cond
        ((not prev-arg) t)
        ((string-equal prev-arg "-o") (setq format-1 arg))
        ((string-equal prev-arg "-O") (setq format-2 arg))
        ((string-equal prev-arg "-d") (setq build-directory arg))
        ((not (string-prefix-p "-" arg)) (push arg files))
        (t t))
      (setq prev-arg arg)))
  (message (format "files: %s" files))
  (message (format "output-format: %s" format-1))
  (message (format "final-format: %s" format-2))
  (message (format "build-directory: %s" build-directory))
  (org-export/init-fast build-directory)
  (if (or (null files) (null format-1))
    (usage))
  (dolist (file files)
    (progn
      (org-export/export-file file format-1)
      (make-directory build-directory t)
      (defvar output-file
        (concat (file-name-sans-extension file) "." (org-export/format->extension format-1)))
      (defvar convert
        (intern-soft (concat "org-export/" format-1 "->" format-2)))
      (defvar convert-default
        (intern-soft (concat "org-export/default-" format-1 "->" format-2)))
      (cond
        ((and (string-equal format-1 "beamer") (string-equal format-2 "pdf"))
         (cond
           ((fboundp 'org-export/beamer->pdf)
            (org-export/beamer->pdf output-file build-directory))
           ((fboundp 'org-export/latex->pdf)
            (org-export/latex->pdf output-file build-directory))
           (t (org-export/default-latex->pdf output-file build-directory))))
        ((fboundp convert) (funcall convert output-file build-directory))
        ((fboundp convert-default) (funcall convert-default output-file build-directory))
        ((null format-2) (rename-file output-file (file-name-as-directory build-directory) t))
        (t
          (progn
            (message (format "Unable to find conversion function org-export/%s->%s"
                             format-1 format-2))
            (kill-emacs 1)))))))

(defun org-export/publish (argv)
  (defvar build-directory %build-directory)
  (defvar prev-arg nil)
  (dolist (arg argv)
    (progn
      (cond
        ((not prev-arg) t)
        ((string-equal prev-arg "-d") (setq build-directory arg))
        (t t))
      (setq prev-arg arg)))
  (message (format "build-directory: %s" build-directory))
  (org-export/init-fast build-directory)
  (org-publish-all t))

(defun org-export/execute (argv)
  (defvar build-directory %build-directory)
  (defvar prev-arg nil)
  (dolist (arg argv)
    (progn
      (cond
        ((not prev-arg) t)
        ((string-equal prev-arg "-d") (setq build-directory arg))
        (t t))
      (setq prev-arg arg)))
  (message (format "build-directory: %s" build-directory))
  (org-export/init-fast build-directory)
  (defun buffer-whole-string (buffer)
    (with-current-buffer buffer
                         (save-restriction
                           (widen)
                           (buffer-substring-no-properties (point-min) (point-max)))))
  (message (format "Executing %s, line %s" (elt argv 0) (elt argv 1)))
  (find-file (elt argv 0))
  (let ((line (elt argv 1)))
    (cond ((string-equal line "")
           (org-babel-execute-buffer))
          ((string-prefix-p "+" line)
           (progn
             (goto-char (point-min))
             (forward-line (string-to-number line))
             (org-babel-execute-src-block)))
          (t (progn
               (message (format ("Bad line argument: %s. Must be +XXX." line)))
               (kill-emacs 1)))))
  (message (format "Output: %s"
                   (buffer-whole-string "*Org-Babel Error Output*"))))

(progn
  ;; silence load messages
  (setq force-load-messages nil)
  (if (< (length argv) 2) (usage))
  (defvar action (elt argv 1))
  (message (format "action: %s" action))
  (cond
    ((string-equal action "init") (org-export/init (cddr argv)))
    ((string-equal action "export") (org-export/export (cddr argv)))
    ((string-equal action "publish") (org-export/publish (cddr argv)))
    ((string-equal action "execute") (org-export/execute (cddr argv)))
    (t (usage))))
