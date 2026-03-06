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
  :ensure nil
  :bind (("C-c C-s" . speedbar-get-focus)
         ("C-c C-S" . speedbar))
  :config
  (setq speedbar-frame-parameters
        '((min-width . 30)
          (width . 30)
          (min-height . 0.4)
          (height . 0.4)
          (left-fringe . 0)
          (right-fringe . 0)
          (vertical-scroll-bar . nil)
          (horizontal-scroll-bar . nil)
          (unsplittable . t)
          (menu-bar-lines . 0)
          (tool-bar-lines . 0)))

  (setq speedbar-use-images t)
  (setq speedbar-tag-hierarchy-method nil)
  (setq speedbar-update-flag t)
  (setq speedbar-use-imenu-flag t)
  (setq speedbar-show-unknown-files t)

  ;; Supported extensions
  (speedbar-add-supported-extension
   '(".c" ".cpp" ".h" ".hpp" ".js" ".ts" ".tsx" ".el" ".py" ".go" ".rs"))

  ;; Auto-open in projects
  (add-hook 'find-file-hook
            (lambda ()
              (when (and (buffer-file-name)
                         (vc-backend (buffer-file-name))
                         (not (get-buffer "*Speedbar*")))
                (speedbar 1))))

  ;; Faces
  (custom-set-faces
   '(speedbar-directory-face ((t (:foreground "#8be9fd" :weight bold))))
   '(speedbar-file-face ((t (:foreground "#f8f8f2"))))
   '(speedbar-selected-face ((t (:foreground "#ff79c6" :weight bold :underline t))))
   '(speedbar-tag-face ((t (:foreground "#50fa7b"))))))

(use-package dashboard
  :ensure t
  :config
  (setq dashboard-startup-banner 'logo          ; or 'nil or a path to your own image/ascii
        dashboard-center-content t
        dashboard-show-shortcuts t
        dashboard-set-init-info t
        dashboard-set-file-icons t              ; needs all-the-icons
        dashboard-set-navigator-buttons t

        dashboard-items '((recents   . 8)
                          (projects  . 5)
                          (agenda    . 5)       ; if you use org-agenda
                          (bookmarks . 5)))

  ;; Set the title
  (setq dashboard-banner-logo-title "Welcome to Emacs.")

  (setq dashboard-footer-messages '("Speak friend and enter."))

  ;; Optional: keep your centered header idea as custom banner
  ;; (setq dashboard-startup-banner "/path/to/your-big-art.txt")

  (dashboard-setup-startup-hook))

;; Integrate clang-format
(use-package clang-format
  :ensure t
  :bind ("C-c f" . clang-format-buffer)
  :config)

; Show line numbers in all programming modes
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; Highlights matching parentheses, brackets, and braces
(show-paren-mode 1)

;; Off-screen parentheses in echo area
(setq show-paren-style 'mixed)

;; Show current function in mode-line
(which-function-mode 1)

;; Main code font
(set-frame-font "Cascadia Code" nil t)

;; Fancy font for comments
(custom-set-faces
 '(font-lock-comment-face
   ((t (:family "Lucida Fax"
		:slant italic)))))

(use-package company
  :ensure t
  :hook (prog-mode . company-mode)
  :config
  (setq company-idle-delay 0.1            ; faster popup
        company-minimum-prefix-length 1
        company-tooltip-align-annotations t
        company-tooltip-limit 12
        company-selection-wrap-around t
        company-dabbrev-downcase nil
        company-dabbrev-ignore-case t
        company-dabbrev-code-ignore-case t
        company-show-quick-access t))     ; numbers for quick select

;; ── web-mode for HTML + embedded JS templates (EJS, ERB, etc.) ──
(use-package web-mode
  :ensure t
  :mode
  ("\\.ejs\\'" . web-mode)
  ("\\.mjs\\'" . web-mode)
  :config
  (setq web-mode-engines-alist
        (cons '("ejs" . "\\.ejs\\'") web-mode-engines-alist))

  ;; Tell web-mode that .mjs files contain only JavaScript code
  (add-to-list 'web-mode-content-types-alist '("javascript" . "\\.mjs\\'"))

  (setq web-mode-markup-indent-offset 2      ; HTML
        web-mode-code-indent-offset    2      ; JS / script
        web-mode-css-indent-offset     2)

  (setq web-mode-enable-auto-pairing t
        web-mode-enable-auto-closing t
        web-mode-enable-auto-opening   nil
        web-mode-enable-current-element-highlight t))

;; Set up flymake for syntax checks
(use-package flymake
  :hook (prog-mode . flymake-mode)
  :config
  (setq flymake-no-changes-timeout 0.3
        flymake-fringe-indicator-position 'left-fringe
        flymake-error-bitmap 'flymake-double-arrow-fringe-bitmap))

;; Configure eglot for C/C++, JavaScript
(use-package eglot
  :ensure t
  :hook
  ;; Auto-start Eglot in these modes
  ((c-mode c++-mode
    js-mode js-ts-mode
    typescript-mode typescript-ts-mode
    tsx-ts-mode
    web-mode) . eglot-ensure)

  :config
  ;; C / C++ server
  (add-to-list 'eglot-server-programs
               '((c-mode c++-mode)
                 . ("clangd" "--background-index" "--clang-tidy")))

  ;; JavaScript / TypeScript server
  (add-to-list 'eglot-server-programs
               '((js-mode js-ts-mode
			  typescript-mode typescript-ts-mode
			  tsx-ts-mode)
                 . ("typescript-language-server" "--stdio")))
  
  ;; web-mode / EJS
  (add-to-list 'eglot-server-programs
               '((web-mode :language-id "javascript")
                 . ("typescript-language-server" "--stdio")))

  ;; Optional: shared Eglot settings (faster startup, cleaner logs)
  (setq eglot-autoshutdown t
        eglot-events-buffer-size 2000000
        eglot-ignored-server-capabilities
        '(:documentHighlightProvider :foldingRangeProvider)))

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

;; Create a function for creating a .clang-format file
(defun my/create-clang-format-file ()
  "Create a .clang-format file with Allman + 2-space style.
Prompts for directory (defaults to current buffer's directory or default-directory)."
  (interactive)
  (let* ((default-dir
          (or (when (buffer-file-name) (file-name-directory (buffer-file-name)))
              default-directory
              "~/"))
         (target-dir
          (read-directory-name "Create .clang-format in directory: "
                               default-dir default-dir t))
         (target-file (expand-file-name ".clang-format" target-dir)))

    ;; Warn if file already exists
    (when (file-exists-p target-file)
      (unless (y-or-n-p (format "File %s already exists. Overwrite? " target-file))
        (user-error "Aborted")))

    ;; Write the file
    (with-temp-file target-file
      (insert "---
# Start from LLVM
BasedOnStyle: LLVM

# Core indentation
IndentWidth: 2
TabWidth: 2
UseTab: Never
ContinuationIndentWidth: 2

# Allman brace style: opening brace ALWAYS on new line
BreakBeforeBraces: Allman

# Case labels indented +2
IndentCaseLabels: true

# Access modifiers (public:, private:, protected:)
AccessModifierOffset: 0

# Inside class members
IndentAccessModifiers: false   # keeps public:/private: at class level

# Don't collapse short blocks/functions
AllowShortBlocksOnASingleLine: false
AllowShortFunctionsOnASingleLine: None
AllowShortLambdasOnASingleLine: All

# Other useful defaults (adjust freely)
ColumnLimit: 64                # or 0 for unlimited
PointerAlignment: Left         # or Right / Middle - your preference
ReferenceAlignment: Pointer    # usually good with Left pointers
SortIncludes: false            # avoids unwanted reordering
"))

    (message "Created .clang-format in %s" target-dir)

    ;; Optional: offer to open it
    (when (y-or-n-p "Open the new .clang-format file? ")
      (find-file target-file))))

(global-set-key (kbd "C-c C-f") 'my/create-clang-format-file)
