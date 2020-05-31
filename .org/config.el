(org-mode)
(require 'ob)
;; activate Babel languages
(require 'ob-shell)
(require 'ob-C)
(require 'ob-R)
(require 'ob-emacs-lisp)
(require 'ob-dot)
(require 'ob-latex)
(require 'ob-scheme)
(require 'ox-latex)
;; XeLaTeX class
(add-to-list 'org-latex-classes
             '("scrartcl"
               "\\documentclass{scrartcl}
               [DEFAULT-PACKAGES]
               [PACKAGES]
               [EXTRA]"
               ("\\section{%s}" . "\\addsec{%s}")
               ("\\subsection{%s}" . "\\subsection*{%s}")
               ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
               ("\\paragraph{%s}" . "\\paragraph*{%s}")
               ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
'(org-latex-listings t)
(setq org-beamer-frame-default-options "label=")
;; move table/figure captions to the bottom
(setq org-latex-caption-above nil)
;; preserve original image width
(setq org-latex-image-default-width nil)
;; highlight LaTeX code fragments
(setq org-highlight-latex-and-related '(latex entities))
;; XeLaTeX export settings
;; sane listings default parameters
(add-to-list 'org-latex-packages-alist '("" "listings"))
(setq org-latex-listings 'listings)
(setq org-latex-listings-options
      '(("inputencoding" "utf8")
        ("basicstyle" "\\ttfamily")
        ("texcl" "true")
        ("literate" "{-}{-}1")
        ("tabsize" "4")
        ("escapechar" "@")))
;; auto-detect document language
(setq org-latex-hyperref-template
      "\\hypersetup{\n pdfauthor={%a},\n pdftitle={%t},\n pdfkeywords={%k},\n pdfsubject={%d},\n pdfcreator={%c},\n pdflang={%L},\n unicode={true}\n}\n\\setdefaultlanguage{%l}\n")
;; do not include obsolete packages
(setq org-latex-default-packages-alist
      '(("" "graphicx")
        ("" "booktabs")
        ("" "amsmath")
        ("" "amssymb")
        ("" "hyperref")
        ("" "tikz")
        ("" "cite")
        ("" "url")
        ("" "polyglossia")))
;; booktabs tables
(setq org-export-latex-tables-hline "\\midrule")
(setq org-export-latex-tables-tstart "\\toprule")
(setq org-export-latex-tables-tend "\\bottomrule")
;; automatically evaluate code on export
(setq org-confirm-babel-evaluate nil)
(setq org-export-babel-evaluate t)
(require 'org-ref)
(setq reftex-default-bibliography '("~/org/bibliograhy.bib"))
;; see org-ref for use of these variables
(setq org-ref-bibliography-notes "~/org/bibliography.org"
      org-ref-default-bibliography '("~/org/bibliography.bib")
      org-ref-pdf-directory "~/bibliography/")
(require 'ox-beamer)
(setq org-export-with-broken-links t)
