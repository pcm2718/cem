;;;; cem.el

;;;; TODO Current plan:
;;;;      1. Come up with a file format. Emacs is more stable than a
;;;;      browser, and CEM runs browsers, not visa versa. Emacs is a modern Lisp Machine.
;;;;      2. Bolt on rudimentry controls, including flatlining and resuscitation.
;;;;      3. Get controls working backwards through the browser via plugins.
;;;;      4. Get the display looking nice.
;;;;      5. Fine tune things like incognito and windowing behavior.
;;;;      6. ???
;;;;      7. PROFIT!!!

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

;;;; Special thanks to hexl.el , which was and continues to be very
;;;; instructive.



;;; Prerequisites

(require 'json)



;;; Variables (most of them)

(defvar cem-sample-session '(:group (:name "Bob")
                                    (:elements (:window (:browser 'chrome)
                                                        (:elements (:tab (:url "https://xkcd.com"))
                                                                   (:tab (:url "https://loper-os.com")))))))



;;; Functions (including Macros)

;; TODO Use special-mode instead?
;; (define-derived-mode cem-mode fundamental-mode "CEM"
;;   "cem-mode"
;;   ;; (define-key cem-mode-map "g" 'cem-outline)
;;   ;; (define-key cem-mode-map [return] 'cem-RET))
;;   (set (make-local-variable 'cem-session) (read (current-buffer)))
;;   (message (prin1-to-string cem-session)))

;;;###autoload
(define-derived-mode cem-mode fundamental-mode "CEM"
  "cem-mode"
  (set (make-local-variable 'cem-session) (read (current-buffer)))
  (cem-cemify-buffer))

;; TODO Add revert hooks?

(defvar cem-in-save-buffer nil)

;; TODO Fix cem-save-buffer .
(defun cem-save-buffer ()
  "Save the session to the visited file if modified."
  (interactive)
  (unless cem-in-save-buffer 
    ;; TODO Docs say this line is sketchy, will investigate.
    (restore-buffer-modified-p
     (if (buffer-modified-p)
         (let ((buf (generate-new-buffer " cem"))
               (name (buffer-name))
               (start (point-min))
               (end (point-max))
               modified)
           (with-current-buffer buf
             (insert-buffer-substring name start end))
           ;; TODO Print to buffer from cem-session ? Add custom
           ;; human-friendly printing later.
           ;(insert-string (prin1 cem-session))
           (cem-decemify-buffer)
           ;; Prevent infinite recursion.
           ;; TODO Why would this cause recursion, does save-buffer
           ;; call cem-save-buffer ?
           (let ((cem-in-save-buffer t))
             (save-buffer))
           (setq modified (buffer-modified-p))
           (delete-region (point-min) (point-max))
           (insert-buffer-substring buf start end)
           (kill-buffer buf)
           modified)
       (message "(No changes need to be saved)")
       nil))
    ;; Return t to indicate we have saved.
    t))

;; TODO Add cem-find-file ?

;; TODO Add cem-mode-exit ?

;; (defun cem-item-at-point ()
;;   "Return the cem item at point."
;;   (interactive)
;;   (if (eq 0 (cem-level-at-point))
;;       cem-session
;;     (let ((parent (cem-parent-at-point))))
;;     (cons (cem-)())
;;       (cem-level-at-point))
;;   (cem-level-at-point)
;;   )

;; (defun cem-parent-at-point ()
;;   "Return the parent of the cem item at point."
;;   (interactive)
;;   )

;; (defun cem-level-at-point ()
;;   "Return the depth of the cem item at point.")

;; (defun cem-element-index-at-point ()
;;   "Return the index of the cem item at point (based on counting to the parent.)")

(defvar cem-mode-map
  (let ((map (make-keymap)))
    (define-key map "\C-x\C-s" 'cem-save-buffer)
    map))


(defun cem-cemify-buffer ()
  (interactive)
  ;; (set (make-local-variable 'cem-session) (read (current-buffer)))
  (erase-buffer)
  (cem-session-insert))

(defun cem-session-insert ()
  (cem-item-insert cem-session 0))

;; (defmacro cem-keyword-case (x &rest args)
;;   `(let ((gensym)))
;;   (let ((q x)
;;         (y ()))
;;     `(cond ,@(dolist (z args y)
;;                (setq y (cons `((eq (car z) ))(append  (list (list ))))))

(defun cem-item-insert (x level)
  (let ((y (car x)))
    (cond ((eq :group y) (cem-group-insert x level))
          ((eq :window y) (cem-window-insert x level))
          ((eq :tab y) (cem-tab-insert x level)))
        ;; TODO Add error cond.
          ))

(defmacro cem-insert-gen (xsym levelsym &rest body)
  `(lambda (,xsym ,levelsym)
     ;; TODO Add code to record point at beginning of insert, for
     ;; spreading the cem-item property over multi-line inserts.
     ,@body
     ;; TODO Questionable.
     (insert "\n")
     (put-text-property (line-beginning-position 0) (+ 1 (line-end-position 0)) 'cem-item ,xsym)
     ;; TODO Gensym probably needed for element.
     (dolist (element (cdr (assoc :elements (cdr ,xsym))))
       (cem-item-insert element (+ 1 ,levelsym)))))

(defalias 'cem-group-insert
  (cem-insert-gen x l
                  (cem-indent-insert l) (cem-assoc-insert :name (cdr x))))

(defalias 'cem-window-insert
  (cem-insert-gen x l
                  (cem-indent-insert l)))

(defalias 'cem-tab-insert
  (cem-insert-gen x l
                  (cem-indent-insert l) (cem-assoc-insert :url (cdr x))))

(defun cem-indent-insert (l)
  (dotimes (i l) (insert "  ")))
                
(defun cem-assoc-insert (key list)
  (insert (cadr (assoc key list))))

;; (cem-item-insert cem-sample-session 0)



;;; CEM session file interaction

(defun cem-session-file-load (filename)
  ;; TODO Hackneyed read approach, there's got to be a function for
  ;; reading from a file.
  (set 'cem-session (with-temp-buffer
                      (insert-file-contents filename)
                      (read current))))

(defun cem-session-file-save ())

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

(provide 'cem-mode)
