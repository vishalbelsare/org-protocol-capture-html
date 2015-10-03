;;; org-protocol-capture-html --- Capture HTML with org-protocol

;;; Commentary:
;; This makes it possible to capture HTML into Org-mode with
;; org-protocol by passing it through Pandoc to convert the HTML into
;; Org syntax. You can use a JavaScript function like the ones found
;; here[0] to get the HTML from the browser's selection, or here's one
;; that seems to work:
;;
;; function () {var html = ""; if (typeof window.getSelection != "undefined") {var sel = window.getSelection(); if (sel.rangeCount) {var container = document.createElement("div"); for (var i = 0, len = sel.rangeCount; i < len; ++i) {container.appendChild(sel.getRangeAt(i).cloneContents());} html = container.innerHTML;}} else if (typeof document.selection != "undefined") {if (document.selection.type == "Text") {html = document.selection.createRange().htmlText;}} return html;}();
;;
;; [0] http://stackoverflow.com/a/6668159/712624

;;; Code:
(defun org-protocol-capture-html-with-pandoc (data)
  "Process an org-protocol://capture-html:// URL.

This function is basically a copy of `org-protocol-do-capture', but
it passes the captured content (not the URL or title) through
Pandoc, converting HTML to Org-mode."
  ;; It would be nice to not basically duplicate
  ;; `org-protocol-do-capture', but passing the data back to that
  ;; function would require re-encoding the data into a URL string
  ;; with Emacs after Pandoc converts it.  Since we've already split
  ;; it up, we might as well go ahead and run the capture directly.
  (let* ((parts (org-protocol-split-data data t org-protocol-data-separator))
	 (template (or (and (>= 2 (length (car parts))) (pop parts))
		       org-protocol-default-template-key))
	 (url (org-protocol-sanitize-uri (car parts)))
	 (type (if (string-match "^\\([a-z]+\\):" url)
		   (match-string 1 url)))
	 (title (or (cadr parts) ""))
	 (content (or (caddr parts) ""))
	 (orglink (org-make-link-string
		   url (if (string-match "[^[:space:]]" title) title url)))
	 (query (or (org-protocol-convert-query-to-plist (cadddr parts)) ""))
	 (org-capture-link-is-already-stored t)) ;; avoid call to org-store-link

    (setq org-stored-links
          (cons (list url title) org-stored-links))
    (kill-new orglink)

    (with-temp-buffer
      (insert content)
      (if (not (= 0 (call-process-region
                     (point-min) (point-max)
                     "pandoc" t t nil "--no-wrap" "-f" "html" "-t" "org")))
          (message "Pandoc failed: " (buffer-string))
        (progn
          ;; Pandoc succeeded
          (org-store-link-props :type type
                                :link url
                                :description title
                                :orglink orglink
                                :initial (buffer-string))
          (raise-frame)
          (funcall 'org-capture nil template))))
    nil))

(add-to-list 'org-protocol-protocol-alist
             '("capture-html"
               :protocol "capture-html"
               :function org-protocol-capture-html-with-pandoc
               :kill-client t))

(provide 'org-protocol-capture-html)
;;; org-protocol-capture-html ends here
