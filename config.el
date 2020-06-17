;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; You do not need to run 'doom sync' after modifying this file!

(setq
 user-full-name "Rakhim Davketkaliyev"
 user-mail-address "rakhim@rakhim.org"

 doom-font (font-spec :family "SF Mono" :size 16)
 projectile-project-search-path '("~/code/" "~/Dropbox/Projects/Codexpanse/Codexpanse Courses/")
 dired-dwim-target t
 doom-theme 'doom-one-light
 evil-respect-visual-line-mode t

 org-bullets-bullet-list '("·")
 org-directory "~/Dropbox/Org/"
 my-braindump-directory (concat org-directory "braindump")
 my-journal-dir (concat org-directory "journal"))

;; Movement
(global-set-key (kbd "s-<up>") 'evil-goto-first-line)
(global-set-key (kbd "s-<down>") 'end-of-buffer)

;; Buffers and windows navigation
(global-set-key (kbd "s-<") 'previous-buffer)
(global-set-key (kbd "s->") 'next-buffer)
(global-set-key (kbd "s-t") 'evil-window-vsplit)
(global-set-key (kbd "s-w") 'evil-window-delete)
(global-set-key (kbd "s-W") 'delete-other-windows)
(global-set-key (kbd "s-o") 'other-window)

;; Search
;; (global-set-key (kbd "s-F") '+ivy/project-search)

;; Undo
(global-set-key (kbd "s-z") 'undo-fu-only-undo)
(global-set-key (kbd "s-r") 'undo-fu-only-redo)

(map! :leader
      :prefix "s"
      :desc "Search brain" "b" #'(lambda () (interactive) (counsel-rg nil org-directory)))

(defun org-journal-find-location ()
  (org-journal-new-entry t) (goto-char (point-min)))

;; Org and ecosystem
(global-set-key (kbd "s-=") 'org-capture)

(after! org
  (map! :map org-mode-map
        :n "M-j" #'org-metadown
        :n "M-k" #'org-metaup
        :ne "C-s-<down>" #'org-narrow-to-subtree
        :ne "C-s-<up>" #'widen)

  (setq
   org-image-actual-width 400
   org-capture-templates
        '(("t" "TODO in Journal" entry
           (function org-journal-find-location)
           "** TODO %i%?" :empty-lines 1)

          ("j" "Journal" entry
           (function org-journal-find-location)
           "** %(format-time-string org-journal-time-format)\n%i%?" :empty-lines 1))))

(use-package! ox-hugo
  :after ox)

(after! (org ox-hugo)
  (defun rakhim/conditional-hugo-enable ()
    (save-excursion
      (if (cdr (assoc "SETUPFILE" (org-roam--extract-global-props '("SETUPFILE"))))
          (org-hugo-auto-export-mode +1)
        (org-hugo-auto-export-mode -1))))
  (add-hook 'org-mode-hook #'rakhim/conditional-hugo-enable))

(after! (org org-roam)
  (defun rakhim/org-roam-export-all ()
    "Re-exports all Org-roam files to Hugo markdown."
    (interactive)
    (dolist (f (org-roam--list-all-files))
      (with-current-buffer (find-file f)
        (when (s-contains? "SETUPFILE" (buffer-string))
          (org-hugo-export-wim-to-md)))))

  (defun rakhim/org-roam--backlinks-list (file)
    (when (org-roam--org-roam-file-p file)
      (mapcar #'car (org-roam-db-query [:select :distinct [from]
                                        :from links
                                        :where (= to $s1)
                                        :and from :not :like $s2] file "%private%"))))

  (defun rakhim/org-export-preprocessor (_backend)
    (when-let ((links (rakhim/org-roam--backlinks-list (buffer-file-name))))
      (insert "\n** Backlinks\n")
      (dolist (link links)
        (insert (format "- [[file:%s][%s]]\n"
                        (file-relative-name link org-roam-directory)
                        (org-roam--get-title-or-slug link))))))

  (add-hook 'org-export-before-processing-hook #'rakhim/org-export-preprocessor))

(use-package! org-download
  :after org
  :config
  (setq-default org-download-image-dir "./attachments/")
  (setq-default org-download-method 'directory)
  (setq-default org-download-heading-lvl nil)
  (setq org-download-annotate-function (lambda (_link) ""))
  (setq-default org-download-timestamp "%Y-%m-%d_%H-%M-%S_"))

(use-package! deft
  :defer t
  :custom
  (deft-recursive t)
  (deft-extensions '("txt" "md" "org"))
  (deft-directory my-braindump-directory))

(use-package! org-roam
  :commands (org-roam-insert org-roam-find-file org-roam)
  :init
  (setq org-roam-directory my-braindump-directory)
  (map! :leader
        :prefix "r"
        :desc "Org-Roam-Insert" "i" #'org-roam-insert
        :desc "Org-Roam-Find" "f" #'org-roam-find-file
        :desc "Org-Roam-Buffer" "r" #'org-roam)
  :config
  (setq org-roam-capture-templates
        '(("l" "lit" plain (function org-roam--capture-get-point)
           "%?"
           :file-name "${slug}"
           :head "#+setupfile:./hugo_setup.org
#+hugo_slug: ${slug}
#+title: ${title}\n"
           :unnarrowed t)
          ;; ("p" "private" plain (function org-roam-capture--get-point)
          ;;  "%?"
          ;;  :file-name "private/${slug}"
          ;;  :head "#+title: ${title}\n"
          ;;  :unnarrowed t)
          )))

(use-package! org-journal
  :after org
  :init
  (map! :leader
        :prefix "j"
        :desc "Today journal file" "t" #'org-journal-open-current-journal-file
        :desc "New journal entry" "j" )
  :custom
  (org-journal-file-format "%Y-%m-%d.org")
  (org-journal-date-format "%A, %d/%m/%Y")
  (org-journal-dir my-journal-dir))

(map! :ne "M-/" #'comment-or-uncomment-region)

;; `nil', `relative'.
(setq display-line-numbers-type t)

;; Jumping between marks
(defun my-pop-local-mark-ring ()
  (interactive)
  (set-mark-command t))

(defun unpop-to-mark-command ()
  "Unpop off mark ring. Does nothing if mark ring is empty."
  (interactive)
      (when mark-ring
        (setq mark-ring (cons (copy-marker (mark-marker)) mark-ring))
        (set-marker (mark-marker) (car (last mark-ring)) (current-buffer))
        (when (null (mark t)) (ding))
        (setq mark-ring (nbutlast mark-ring))
        (goto-char (marker-position (car (last mark-ring))))))

(global-set-key (kbd "s-,") 'my-pop-local-mark-ring)
(global-set-key (kbd "s-.") 'unpop-to-mark-command)


(defun smart-join-line (beg end)
  "If in a region, join all the lines in it. If not, join the current line with the next line."
  (interactive "r")
  (if mark-active
      (join-region beg end)
      (top-join-line)))

(defun top-join-line ()
  "Join the current line with the next line."
  (interactive)
  (delete-indentation 1))

(defun join-region (beg end)
  "Join all the lines in the region."
  (interactive "r")
  (if mark-active
      (let ((beg (region-beginning))
            (end (copy-marker (region-end))))
        (goto-char beg)
        (while (< (point) end)
          (join-line 1)))))

(global-set-key (kbd "s-j") 'smart-join-line)

;; Markdown
(defun markdown-export-html-to-clipboard (lines-to-skip)
  "Export Markdown to HTML while skipping first lines-to-skip, copy to cliboard"
  (interactive)
  (markdown-kill-ring-save)
  (let ((oldbuf (current-buffer)))
    (save-current-buffer
      (set-buffer "*markdown-output*")
      (if lines-to-skip
          (progn
            (goto-char (point-min))
            (kill-whole-line)))
      (with-no-warnings (mark-whole-buffer))
      (evil-yank-lines (point-min) (point-max)))))

(defun markdown-export-html-to-clipboard-full ()
  (interactive)
  (markdown-export-html-to-clipboard nil))

(defun markdown-export-html-to-clipboard-no-1st-line ()
  (interactive)
  (markdown-export-html-to-clipboard 1))

(use-package markdown-mode
  :defer t
  :init
  (map! :leader
        :prefix "e"
        :desc "Export HTML to clipboard" "O" #'markdown-export-html-to-clipboard-full
        :desc "Export HTML (no 1st line)" "o" #'markdown-export-html-to-clipboard-no-1st-line)
  (map! :desc "Narrow to subtree" "C-s-<down>" #'markdown-narrow-to-subtree
        :desc "Widen" "C-s-<up>" #'widen))


;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
