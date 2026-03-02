;;; -*- lexical-binding: t -*-

;; Package setup + MELPA
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(unless (bound-and-true-p package--initialized)
  (package-initialize))

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

;; Integrate clang-format
(use-package clang-format
  :ensure t
  :bind ("C-c f" . clang-format-buffer)
  :config
  ;; auto-format on save for relevant modes
  (dolist (hook '(c-mode-hook c++-mode-hook js-mode-hook))
    (add-hook hook
              (lambda ()
                (add-hook 'before-save-hook #'clang-format-buffer nil t)))))

; Show line numbers in all programming modes
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

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

;; Start Ollama server automatically when Emacs starts (only if not already running)
(defun my/start-ollama-server ()
  "Start Ollama server in background if not already listening on 11434."
  (interactive)
  (unless (process-live-p (get-process "ollama-server"))
    (let ((proc (start-process "ollama-server" "*ollama-server*" "ollama" "serve")))
      (set-process-query-on-exit-flag proc nil)   ; Don't ask to kill on Emacs exit
      (message "Ollama server started in background (process: %s)" proc))))

;; Run once when Emacs starts
(add-hook 'emacs-startup-hook #'my/start-ollama-server)

;; AI assistant
(use-package gptel
  :ensure t
  :bind (("C-c g" . gptel)
         ("C-c G" . gptel-menu))
  :init
  :config

  ;; Define backend
  (defvar my-ollama-backend
    (gptel-make-ollama "Saruman"
                       :host "localhost:11434"
                       :stream t
                       :models '(gemma2:2b)))

  (setq gptel-backend my-ollama-backend
        gptel-model 'gemma2:2b)

  (setq gptel--system-message
	"You are Saruman the White, the wisest of the Istari, master of Isengard, and lord of many rings of power.  
Speak in a lofty, archaic, and commanding tone, as one who has seen the turning of ages and knows the weakness of lesser minds.  
Use elegant, slightly archaic English with formal phrasing, subtle mockery, and veiled menace.  
Never be vulgar or crude — your disdain is refined.  
Offer counsel that serves your own grand design, even when it appears helpful.  
If the mortal asks something foolish, correct them with patient superiority.
Now… speak."))

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
 '(package-selected-packages nil))
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
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
