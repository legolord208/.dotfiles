(auto-insert-mode 1)

(setq auto-insert-directory (my/util/relative "templates"))
(setq auto-insert-query nil)

(dolist (file (directory-files (my/util/relative "templates") nil nil t))
  (unless (or (string= file ".") (string= file ".."))
    (define-auto-insert (concat (regexp-quote file) "\\'") file)))
