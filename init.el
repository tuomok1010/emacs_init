;;; -*- lexical-binding: t -*-

;; Configure Visual Studio debugger (Windows)
(defvar my/devenv-path
  "C:/Program Files/Microsoft Visual Studio/2022/Community/Common7/IDE/devenv.exe"
  "Full path to devenv.exe.")

(defun my/debug-exe ()
  "Launch VS debugger on an executable (detached).
Prompts for the exe, checks executability, kills *VS Debugger* buffer on exit."
  (interactive)
  (let* ((exe (read-file-name "Executable: " nil nil t))
         (buf (get-buffer-create "*VS Debugger*"))
         (cmd (format "start \"\" \"%s\" /debugexe \"%s\""
                      my/devenv-path exe)))
    (unless (file-executable-p exe)
      (unless (y-or-n-p (format "%s not executable – launch anyway? " exe))
        (user-error "Debug aborted")))
    (let ((proc (start-process-shell-command "vs-debugger" buf cmd)))
      (set-process-sentinel
       proc
       (lambda (p _)
         (when (memq (process-status p) '(exit signal))
           (kill-buffer (process-buffer p))
           (message "VS Debugger terminated – buffer cleaned."))))
      (message "VS Debugger launched: %s  (F5 to run)" exe))))

(global-set-key (kbd "C-c d") #'my/debug-exe)

;; Disable auto-save files (#file.c#)
(setq auto-save-default nil)          ; disable #file.c#
(setq auto-save-list-file-prefix nil) ; disable .saves-… directory

;; No backup files (file.c~)
(setq make-backup-files nil)          ; disable file.c~

;; No lock files (.#file.c)
(setq create-lockfiles nil)           ; disable .#file.c

;; Get rid of default startup screen
(setq inhibit-startup-message t)

;; Start Emacs with a fully maximized frame
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; Remove toolbar
(tool-bar-mode -1)

;; Use short y-n queries
(setopt use-short-answers t)

;; Highlight current line globally
(global-hl-line-mode 1)
(set-face-attribute 'hl-line nil :underline nil)
(set-face-background 'hl-line "#2d2d2d")

;; Remember cursor position in files
(save-place-mode 1)

;; Window switching with labels
(use-package ace-window
  :ensure t
  :init (global-set-key [remap other-window] 'ace-window))

;; Command pop-ups
(use-package which-key
  :ensure t
  :config (which-key-mode))

;; Use speedbar as a file explorer
(use-package speedbar
  :ensure nil ;; Built-in, no need to install
  :bind (("C-x t t" . speedbar) ("C-x t y" . speedbar-get-focus))
  :config
  (require 'speedbar)
  (setq speedbar-frame-parameters
        `((width . 30)                                       ;; Fixed width
          (height . ,(window-text-height (selected-window))) ;; Initially set to the height of the text area
	  (left-fringe . 10)
	  (right-fringe . 10)
	  (internal-border-width . 0)
          (parent-frame . ,(selected-frame))                 ;; Set as child of main frame
	  (keep-ratio . t)                                   ;; Ensure resizing with the parent
          (minibuffer . nil)                                 ;; No minibuffer
          (unsplittable . t)                                 ;; Prevent splitting
	  (name . "File Explorer")                           ;; Give it a nice name
          (menu-bar-lines . 0)))                             ;; Disable menu bar
  (setq speedbar-directory-unshown-regexp "^\\(CVS\\|RCS\\|SCCS\\|\\.\\.*\\)$")
  (setq speedbar-update-flag t)
  (setq speedbar-use-imenu-flag t) ;; Use imenu for C/C++ tags
  (setq speedbar-tag-hierarchy-method '(speedbar-prefix-group-tag-hierarchy))
  (setq speedbar-show-unknown-files t) ;; Highlight current function in speedbar
  (speedbar-add-supported-extension '(".c" ".cpp" ".h" ".hpp"))
  (with-eval-after-load 'ace-window
    (add-to-list 'aw-ignored-buffers 'speedbar-mode)))

 ;; Customize speedbar
 '(speedbar-button-face ((t (:foreground "#00ff00" :weight bold))))
 '(speedbar-file-face ((t (:foreground "#ffffff" :background "#3c3c3c"))))
 '(speedbar-directory-face ((t (:foreground "#66d9ef" :weight bold))))
 '(speedbar-selected-face ((t (:foreground "#ffffff" :background "#5f5faf" :weight bold))))

;; Define a custom style: Allman braces + 2-space indent
(c-add-style "allman-2"
             '("bsd"                            ; start from bsd → { on new line
               (c-basic-offset . 2)             ; 2-space indentation
               (indent-tabs-mode . nil)         ; use spaces, not tabs
               (c-offsets-alist
               (statement-block-intro . +) 
               (substatement-open . 0)         ; { after if/else on new line
               (defun-open . 0)                ; { for functions on new line
               (brace-list-open . 0)           ; { for arrays/structs
               (block-open . 0)                ; general block open
	       (case-label . +)                ; case 1: → +2
               (statement-case-intro . +)      ; first line in case block
               (statement-case-open . 0)       ; after case
	       (inclass . +)                   ; indent inside class
	       (access-label . 0)              ; make sure access labels are not indented
	       )))

;; Tell Emacs: c-indent-region exists and will be loaded when needed
(autoload 'c-indent-region "cc-cmds" "Indent C code." t)

;; Format entire buffer
(defun my/format-c-buffer ()
  "Re-indent entire buffer using current c-style (allman-2)."
  (interactive)
  (save-excursion
    (c-indent-region (point-min) (point-max))))

;; Bind the format function
(global-set-key (kbd "C-c f") 'my/format-c-buffer)

; Show line numbers in all programming modes
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; Apply to C and C++ files
(add-hook 'c-mode-common-hook
          (lambda ()
            (c-set-style "allman-2")))

;; Highlights matching parentheses, brackets, and braces
(show-paren-mode 1)

; Off-screen parentheses in echo area
(setq show-paren-style 'mixed)

; Show current function in mode-line
(which-function-mode 1)

;; Company mode for autocompletion
(use-package company
  :ensure t
  :hook (prog-mode . company-mode))

;; Set up flymake for syntax checks
(use-package flymake
  :hook (prog-mode . flymake-mode)
  :config
  (setq flymake-no-changes-timeout 0.5) ;; Faster diagnostics
  (setq flymake-fringe-indicator-position 'left-fringe))

;; Configure eglot for C/C++
(use-package eglot
  :ensure t
  :hook ((c-mode c++-mode) . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               '((c-mode c++-mode) . ("clangd" "--background-index" "--clang-tidy"))))

;; Shorthand for compiling
(global-set-key (kbd "C-c c") 'compile)

;; Jump to function with imenu
(global-set-key (kbd "C-c j") 'imenu)

;; Use skeleton for snippets.
(use-package skeleton
  :ensure nil ;; skeleton is built-in
  :bind
  (("C-c s m" . skeleton-c-main)
   ("C-c s f" . skeleton-c-function)
   ("C-c s i" . skeleton-c-if)
   ("C-c s e" . skeleton-c-else)
   ("C-c s I" . skeleton-c-if-else)
   ("C-c s E" . skeleton-c-else-if)
   ("C-c s s" . skeleton-c-switch)
   ("C-c s F" . skeleton-c-for)
   ("C-c s w" . skeleton-c-while)
   ("C-c s W" . skeleton-c-do-while)
   ("C-c s t" . skeleton-c-typedef-struct)
   ("C-c s T" . skeleton-c-struct)
   ("C-c s c" . skeleton-c-class)
   ("C-c s C" . skeleton-c-class-filled)
   ("C-c s n" . skeleton-c-namespace)
   ("C-c s h" . skeleton-c-header-guard))
  :config


  ;; --- Skeleton Definitions ---
  (define-skeleton skeleton-c-main
    "Insert a C/C++ main function skeleton."
    nil
    "int main(int argc, char *argv[])" ?\n
    "{" > ?\n
    > _ ?\n
    > "return 0;" ?\n
    "}" > \n)
    
  (define-skeleton skeleton-c-function
    "Insert a C/C++ function skeleton."
    "Return type: "
    str " " (setq v1 (skeleton-read "Function name: "))
    "(" (skeleton-read "Arguments: ") ")" ?\n
    "{" > ?\n
    > _ ?\n
    "}" > \n)

  (define-skeleton skeleton-c-if
    "Insert a C/C++ if statement skeleton."
    "Condition: "
    "if(" str ")" ?\n
    "{" > ?\n
    > _ ?\n
    "}" > \n)

  (define-skeleton skeleton-c-else
    "Insert a C/C++ else statement skeleton."
    nil
    "else" ?\n
    "{" > ?\n
    > _ ?\n
    "}" > \n)

  (define-skeleton skeleton-c-if-else
    "Insert a C/C++ if-else statement skeleton."
    "Condition: "
    "if(" str ")" ?\n
    "{" > ?\n
    > _ ?\n
    "}" > \n
    "else" ?\n
    "{" > ?\n
    > _ ?\n
    "}" > \n)

  (define-skeleton skeleton-c-else-if
    "Insert a C/C++ else-if statement skeleton."
    "Condition: "
    "else if(" str ")" ?\n
    "{" > ?\n
    > _ ?\n
    "}" > \n)

  (define-skeleton skeleton-c-switch
    "Insert a C/C++ switch statement skeleton."
    "Condition: "
    "switch(" str ")" ?\n
    "{" > ?\n
    > "case " _ ?\n
    "{" > ?\n
    > _ ?\n
    "} break;" > ?\n
    "}" > \n)

  (define-skeleton skeleton-c-for
    "Insert a C/C++ for loop skeleton."
    "Condition: "
    "for(" str ")" ?\n
    "{" > ?\n
    > _ ?\n
    "}" > \n)

  (define-skeleton skeleton-c-while
    "Insert a C/C++ while loop skeleton."
    "Condition: "
    "while(" str ")" ?\n
    "{" > ?\n
    > _ ?\n
    "}" > \n)

  (define-skeleton skeleton-c-do-while
    "Insert a C/C++ do while loop skeleton."
    "Condition: "
    "do" ?\n
    "{" > ?\n
    > _ ?\n
    "}" > " while(" str ");" \n)

  (define-skeleton skeleton-c-typedef-struct
    "Insert a C/C++ struct skeleton."
    "Name: "
    "typedef struct" ?\n
    "{" > ?\n
    > _ ?\n
    "} " > str ";" \n)

  (define-skeleton skeleton-c-struct
    "Insert a C/C++ struct skeleton."
    "Name: "
    "struct " str ?\n
    "{" > ?\n
    > _ ?\n
    "};" > \n)

  (define-skeleton skeleton-c-class
    "Insert a C/C++ class skeleton."
    "Name: "
    "class " str ?\n
    "{" > \n
    > "public:" \n
    > _ \n
    > "private:" ?\n
    "};" > \n)

  (define-skeleton skeleton-c-class-filled
    "Insert a C/C++ class skeleton with constructors and destructor"
    "Name: "
    "class " str ?\n
    "{" > \n
    > "public:" \n
    > str "();" \n
    > str "(const " str "& other);" \n
    > "~" str "();"\n
    > _ \n
    > "private:" ?\n
    "};" > \n)

  (define-skeleton skeleton-c-namespace
    "Insert a C/C++ namespace skeleton."
    "Name: "
    "namespace " str ?\n
    "{" > ?\n
    > _ ?\n
    "}" > \n)

  (define-skeleton skeleton-c-header-guard
    "Insert C/C++ header guard using current filename."
    nil
    (let* ((file (or buffer-file-name "default.h"))
           (name (file-name-nondirectory file))
           (base (file-name-sans-extension name))
           (ext (or (file-name-extension name) ""))
           (guard (upcase (replace-regexp-in-string "[^A-Za-z0-9]" "_" base))))
      (unless (member ext '("h" "hpp" "hxx" "hh"))
	(setq guard (concat guard "_" (upcase ext))))
      (skeleton-insert
       `(nil
	 "#ifndef " ,guard "_H\n"
	 "#define " ,guard "_H\n"
	 "\n"
	 _ "\n"   ; ← Cursor goes here!
	 "\n"
	 "#endif /* " ,guard "_H */\n"))))
)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes '(wombat))
 '(package-selected-packages '(ace-window company)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; !!!!!!!!!!!!! FROM THIS POINT DOWNWARDS, IT'S ALL ABOUT THE CONFIG OF THE DASHBOARD !!!!!!!!!!!!!!!!!!!

(recentf-mode 1)
(setq recentf-max-saved-items 100)

;; Centering & Wrapping
(defun my/center-text (text width)
  "Center TEXT in WIDTH."
  (let ((padding (max 0 (/ (- width (string-width text)) 2))))
    (concat (make-string padding ?\s) text)))

;; Header
(defun my/dashboard-insert-header (width)
  "Insert massive block-art 'EMACS EDITOR' header."
  (let ((art-lines '(
"███████╗███╗   ███╗ █████╗  ██████╗███████╗    ███████╗██████╗ ██╗████████╗ ██████╗ ██████╗ "
"██╔════╝████╗ ████║██╔══██╗██╔════╝██╔════╝    ██╔════╝██╔══██╗██║╚══██╔══╝██╔═══██╗██╔══██╗"
"█████╗  ██╔████╔██║███████║██║     ███████╗    █████╗  ██║  ██║██║   ██║   ██║   ██║██████╔╝"
"██╔══╝  ██║╚██╔╝██║██╔══██║██║     ╚════██║    ██╔══╝  ██║  ██║██║   ██║   ██║   ██║██╔══██╗"
"███████╗██║ ╚═╝ ██║██║  ██║╚██████╗███████║    ███████╗██████╔╝██║   ██║   ╚██████╔╝██║  ██║"
"╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝    ╚══════╝╚═════╝ ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝"
                     )))
    (dolist (line art-lines)
      (insert (propertize (my/center-text line width)
                          'face '(:height 1.4 :weight ultra-bold)))
      (insert "\n"))
    (insert "\n\n\n")))  ; Extra spacing below

;; Recent Files
(defun my/dashboard-insert-files (width)
  "Insert Recent Files — one per line."
  (let ((header (my/center-text "══════════ ✦ ✦  Recent Files   ✦ ✦ ══════════" width)))
    (insert (propertize (concat header "\n\n") 'face '(:height 1.3 :weight bold)))
    (dolist (file (seq-take recentf-list 5))
      (when (file-exists-p file)
        (let* ((display-name (abbreviate-file-name file))
               (centered (my/center-text (concat "• " display-name) width)))
          (insert-text-button centered
                              'action (lambda (_) (find-file file))
                              'follow-link t
                              'face '(:foreground "#66d9ef" :underline t))
          (insert "\n\n"))))))

;; Main Dashboard
(defun my/custom-dashboard ()
  "Create the ultimate dashboard."
  (with-current-buffer (get-buffer-create "*scratch*")
    (let ((inhibit-read-only t)
          (width (frame-width)))
      (erase-buffer)
      (my/dashboard-insert-header width)
      (my/dashboard-insert-files width)
      (goto-char (point-min))
      (setq buffer-read-only t))))

;; Run on startup
(add-hook 'emacs-startup-hook #'my/custom-dashboard)
