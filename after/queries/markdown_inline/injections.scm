; Override: keep HTML injection but remove LaTeX injection
; so $ and % in financial text render normally
((html_tag) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined))
