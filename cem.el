;;;; cem.el

;;;; TODO Figure out a good way to have the program interact with
;;;; chromix-server, then we should have a functioning prototype, sans
;;;; mode definition and keymap .

;;;; TODO Figure out how to, if possible, get chromi to activly notify
;;;; Emacs of events to improve synchronization.

;;;; TODO Add support for multiple Chrome profiles.

;;;; TODO Add support for spreading a session across multiple CEM
;;;; buffers.

;;;; TODO Add support for tracking history and bookmarks, eventually
;;;; to integrate with Chrome and supplant Chrome's native system.

;;;; TODO Figure out why call-process doesn't like spaces in
;;;; arguments.

;;;; TODO Add double dash prefixes to internal symbols, update to
;;;; Emacs Lisp Coding Conventions.

;;; Prerequisites

(require 'json)

;;; CEM chromix-server interaction

(defun cem-chromix-server-start ()
  (interactive)
  (start-process "chromix-server" "*chromix-server*" "chromix-server"))

(defun cem-chromix-server-stop ()
  (interactive)
  (delete-process "chromix-server"))

;; TODO May want to add accomodation for multiple server processes.
;; (defmacro cem-with-chromix-server (&rest x)
;;   `(if (get-process "chromix-server")
;;        ;; Just progn x if the server exists.
;;        (progn ,@x)
;;      ;; Start the server, progn x, and then kill the server.
;;      (prog2
;;          ;; Start chromix-server.
;;          (start-process "chromix-server" "*chromix-server*" "chromix-server")
;;          (progn ,@x)
;;        ;; Kill chromix-server. TODO If an instance of chromix-server was created locally, kill it.
;;        (delete-process "chromix-server"))))

;; (defun chromix-with-all-list ()
;;   (with-temp-buffer
;;     (insert-file-contents "withalllist_0.txt")
;;     ;; TODO Maybe this should return the first line and second header
;;     ;; as well.
;;     (beginning-of-buffer)
;;     (kill-whole-line)
;;     (kill-word 3)
;;     (buffer-string)))

(defun cem-chromix-with-all-list ()
  ;; TODO Switch to talking directly to chromix-server.
  (with-temp-buffer
  ;(with-current-buffer (get-buffer-create "*xkcd*")
    ;; TODO Add error code check.
    (call-process "chromix" nil t nil "raw" "chrome.windows.getAll" "{\"populate\":true}")
    (buffer-string)))



;;; CEM Buffer Generation

;; (defmacro cem-cdrassoc (x y)
;;   `(cdr (assoc ,x ,y)))

(defun cem-json-tab-outline (jt)
  ;; TODO Stick body of function into this let and make an alteration
  ;; to get bold on selected tabs.
  ;; (let ((insert (if (eq (cdr (assoc 'selected jt)) :json-false) 'insert 'insert))))
  (insert "tab " (number-to-string (cdr (assoc 'id jt))) " \"" (cdr (assoc 'url jt)) "\" \"" (cdr (assoc 'title jt)) "\"")
  (newline))

(defun cem-json-window-outline (jw)
  (insert "window " (number-to-string (cdr (assoc 'id jw))))
  (newline)
  (mapc 'cem-json-tab-outline (cdr (assoc 'tabs jw)))
  ;(newline)
  )

(defun cem-json-listing-outline (jl)
  (mapc 'cem-json-window-outline jl))

;; TODO Add some kind of handler for non-existent chromix-server
;; instance.
(defun cem-outline ()
  (interactive)
  (with-current-buffer (get-buffer-create "*cem*")
    (erase-buffer)
    (cem-json-listing-outline (json-read-from-string (chromix-with-all-list)))))



;;; CEM Buffer Interaction

(defun cem-window-focus ()
  ;; TODO For now, return the command as a string.
  ;; TODO Use drawAttention instead of focused ?
  ;; TODO Switch to talking directly to chromix-server.
  ;; TODO Add error check.
  (call-process "chromix" nil nil nil "raw" "chrome.windows.update" (progn (forward-word 2) (word-at-point)) "{\"focused\":true}"))

(defun cem-window-dwim ()
  (cem-window-focus))

(defun cem-tab-open ())

(defun cem-tab-close ())

(defun cem-tab-remove ())

(defun cem-tab-focus ()
  ;; TODO For now, return the command as a string.
  ;; TODO Switch to talking directly to chromix-server.
  ;; TODO Add error check.
  ;; TODO Find a better way to set up the window focus.
  (save-excursion
    (search-backward "window")
    ;; TODO Change this to cem-window-focus .
    (cem-RET))
  (call-process "chromix" nil nil nil "raw" "chrome.tabs.update" (progn (forward-word 2) (word-at-point)) "{\"selected\":true}"))

(defun cem-tab-dwim ()
  (cem-tab-focus))

(defun cem-RET ()
  (interactive)
  ;; TODO I'll put a full parser in here later, but for now I'll just
  ;; do the simplest thing that could possibly work; I'll look at the
  ;; first word on a line to see whether a tab or window is under
  ;; point, look at the second word for an index/windowID , and ignore
  ;; the rest
  (save-excursion
    (let* ((wot (progn (back-to-indentation) (intern (word-at-point)))))
      ;;   (x (progn (forward-word 2) (string-to-number (word-at-point)))))
      (case wot
        ;; If the first word on the line is "window", use window
        ;; behavior.
        ('window (cem-window-dwim))
        ;; If the first word on the line is "tab", use tab behavior.
        ('tab (cem-tab-dwim))
        ;; TODO Add safety default case.
        ))))



;;; CEM User Commands
;;; TODO Add working "restarter".

;; A simple restarter.
;; (defun cem-reboot ()
;;   ;; Start chromix-server.
;;   (start-process "chromix-server" "*chromix-server*" "chromix-server")
;;   ;; Get a listing of open tabs and put it in *otb* .
;;   (with-current-buffer (get-buffer-create "*otb*")
;;     (insert (shell-command-to-string "chromix with all list"))
;;     ;; TODO Shut down Chromium.
;;     ;; (shell-command-to-string "chromix with all close")
;;     ;; TODO Restart Chromium.
;;     ;; (shell-command-to-string "chromium &")
;;     ;; TODO Reopen listed tabs in *otb* .
;;     ;;
;;     ;;
;;     ;; TODO Clear *otb* .
;;     ;; (erase-buffer))
;;     )
;;   ;; Kill chromix-server.
;;   (delete-process "chromix-server"))



;;; CEM Mode Definition, Entry and Providence

;; (defvar cem-mode-hook nil)

;; (defvar wpdl-mode-map
;;   (let ((map (make-sparse-keymap)))
;;     (define-key map "RET" 'cem-RET)
;;     map)
;;   "Keymap for CEM major mode.")

;; TODO Use special-mode instead?
(define-derived-mode cem-mode fundamental-mode "CEM"
  "cem-mode"
  (define-key cem-mode-map "g" 'cem-outline)
  (define-key cem-mode-map [return] 'cem-RET))

(defun cem ()
  "Start a CEM instance in a new buffer."
  (interactive)
  (cem-chromix-server-start)
  (switch-to-buffer (get-buffer-create "*cem*"))
  (cem-mode))

(provide 'cem-mode)
