(require 'package)
(add-to-list 'package-archives
	     '("melpa" . "http://melpa.org/packages/"))

(package-initialize)

(when (< emacs-major-version 24)
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))

(require 'use-package)
(require 'subr-x)

(load "~/.emacs.local" 'missing-ok)

(setq custom-file (concat dotfiles-repo-path "emacs/custom.el"))
(load custom-file)

(setenv "SSH_ASKPASS" "git-gui--askpass")

(setq
 backup-by-copying t
 backup-directory-alist '(("." . "~/.saves"))
 delete-old-versions t
 kept-new-versions 6
 kept-old-versions 2
 version-control t)

(setq scroll-step 1)
(setq scroll-conservatively 10000)
(setq auto-window-vscroll nil)

(toggle-scroll-bar -1)

(setq-default indent-tabs-mode nil)

(setq show-paren-delay 0)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
(global-set-key (kbd "S-<delete>") 'kill-whole-line)
(global-set-key (kbd "<f5>") 'projectile-compile-project)
(global-set-key (kbd "C-;") (lambda () (interactive) (end-of-line) (insert ";")))

(setq-default cursor-type `(bar . 2))

(global-auto-revert-mode)

(delete-selection-mode 1)

(prefer-coding-system 'utf-8)
(set-language-environment "UTF-8")

(defun move-line-up ()
  (interactive)
  (transpose-lines 1)
  (forward-line -2))

(global-set-key (kbd "M-<up>") 'move-line-up)

(defun move-line-down ()
  (interactive)
  (forward-line 1)
  (transpose-lines 1)
  (forward-line -1))

(global-set-key (kbd "M-<down>") 'move-line-down)

(defun custom-move-to-beginning-of-line ()
  (interactive "^")
  (let ((point-before-move (point)))
    (back-to-indentation)
    (when (= point-before-move (point))
      (move-beginning-of-line nil))))

(global-set-key (kbd "C-a") 'custom-move-to-beginning-of-line)
(global-set-key (kbd "<home>") 'custom-move-to-beginning-of-line)


(defun scala-split-or-merge-package ()
  (interactive)
  (let ((package-line-regexp "^\\s-*package\\s-+\\sw+\\(\\s-*\\.\\s*\\sw+\\)*")
        (line (thing-at-point 'line t)))
    (when (string-match package-line-regexp line)
      (let* ((pos (current-column))
             (stop-pos (cl-position ?. line :end pos :from-end t)))
        (if stop-pos
            (progn
              (delete-region (+ stop-pos (line-beginning-position)) (line-end-position))
              (insert ?\n "package " (substring line (+ stop-pos 1) -1)))
          (let ((before (point)))
            (previous-line)
            (if (string-match package-line-regexp
                                (thing-at-point 'line t))
                (let ((path-start (progn (string-match "package\\s-+\\(\\sw\\)" line)
                                         (match-beginning 1))))
                  (next-line)
                  (delete-region (line-beginning-position)
                                 (line-end-position))
                  (previous-line)
                  (end-of-line)
                  (insert ?. (substring line path-start -1))
                  (delete-region (line-end-position)
                                 (+ 1 (line-end-position))))
              (goto-char before))))))))

(defun toggle-window-split ()
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
             (next-win-buffer (window-buffer (next-window)))
             (this-win-edges (window-edges (selected-window)))
             (next-win-edges (window-edges (next-window)))
             (this-win-2nd (not (and (<= (car this-win-edges)
                                         (car next-win-edges))
                                     (<= (cadr this-win-edges)
                                         (cadr next-win-edges)))))
             (splitter
              (if (= (car this-win-edges)
                     (car (window-edges (next-window))))
                  'split-window-horizontally
                'split-window-vertically)))
        (delete-other-windows)
        (let ((first-win (selected-window)))
          (funcall splitter)
          (if this-win-2nd (other-window 1))
          (set-window-buffer (selected-window) this-win-buffer)
          (set-window-buffer (next-window) next-win-buffer)
          (select-window first-win)
          (if this-win-2nd (other-window 1))))))

(global-set-key (kbd "C-x |") 'toggle-window-split)

(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))
    
(setq mouse-wheel-progressive-speed nil)

(setq read-file-name-completion-ignore-case 't)

(use-package recentf
  :config
  (recentf-mode 1)
  (setq recentf-max-menu-items 25)
  (global-set-key (kbd "C-x C-r") 'recentf-open-files))

(use-package company
  :bind (:map company-active-map
              ("<escape>" . company-abort))
  :config
  (add-hook 'after-init-hook 'global-company-mode)
  (global-set-key (kbd "C-c SPC") 'company-complete))

(use-package scala-mode
  :bind (:map scala-mode-map
              ("C-c ." . scala-split-or-merge-package)))

(use-package git-gutter
  :config
  (global-git-gutter-mode t)
  (set-face-background 'git-gutter:modified "#ffcc66")
  (set-face-background 'git-gutter:added    "#99cc99")
  (set-face-background 'git-gutter:deleted  "#f2777a"))

(use-package indent-guide
  :config
  (indent-guide-global-mode)  
  (setq-default indent-guide-recursive t)
  (setq-default indent-guide-char "│"))

(use-package expand-region
  :bind (("C-c w" . er/expand-region)))

(use-package magit
  :bind (("C-x g" . magit-status)))

(use-package hydra
  :config
  (defhydra hydra-resize (global-map "C-c C-r")
    "resize window"
    (">" enlarge-window)
    ("<" shrink-window)))

(use-package paredit
  :config
  (unbind-key "C-<right>" paredit-mode-map)
  (unbind-key "C-<left>" paredit-mode-map))

(use-package projectile
  :bind (:map projectile-mode-map
         ("C-c p" . projectile-command-map))
  :config
  (add-to-list 'projectile-globally-ignored-file-suffixes ".class"))

(use-package ensime
  :config
  (setq ensime-startup-notification nil))

(use-package avy
  :bind (("C-c '" . avy-goto-char-2)
	 ("C-c \"" . avy-goto-char)))

(use-package ido
  :config
  (ido-mode t))

(use-package yasnippet
  :config
  (yas-global-mode 1)
  :bind (("C-<tab>" . yas-expand)))

;; HTML + JS editting stuff
(use-package company-tern
  :config
  (add-to-list 'company-backends 'company-tern))

(use-package emmet-mode
  :config
  (add-hook 'html-mode-hook 'emmet-mode))

(use-package web-mode
  :config
  (add-hook 'web-mode-hook 'emmet-mode))

;; Org mode stuff
(use-package org
  :config
  (setq org-support-shift-select t))

;; LaTeX stuff
(use-package latex
  :config
  (when (string-equal "windows-nt" system-type)
    (setq doc-view-ghostscript-program "gswin64c")))


;; Haskell
(use-package haskell-mode
  :config
  (add-hook 'haskell-mode-hook 'interactive-haskell-mode)
  (add-hook 'haskell-mode-hook 'haskell-indentation-mode))

(use-package popup-imenu
  :bind (("C-c i" . popup-imenu)))

(use-package smartparens
  :config
  (smartparens-global-mode nil)
  (sp-local-pair 'latex-mode "\\[" "\\]")
  (add-hook 'emacs-lisp-mode-hook
            (lambda ()
              (sp-pair "'" nil :actions :rem))))


(use-package dashboard
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-items '((recents . 5)
                          (bookmarks . 5)
                          (projects . 5)
                          (registers . 5))))

(use-package zzz-to-char
  :bind (("M-z" . #'zzz-up-to-char)))
