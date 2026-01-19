;; inherits: comment
;; extends


;; @todo, @unused

((tag
  (name) @comment.attodo @nospell
  ("(" @punctuation.bracket
    (user) @constant
    ")" @punctuation.bracket)?
  ":" @punctuation.delimiter)
  (#any-of? @comment.attodo "@todo" "@unused"))

("text" @comment.attodo @nospell
  (#any-of? @comment.attodo "@todo" "@unused"))

;; @note, @question, @deprecated

((tag
  (name) @comment.atnote @nospell
  ("(" @punctuation.bracket
    (user) @constant
    ")" @punctuation.bracket)?
  ":" @punctuation.delimiter)
  (#any-of? @comment.atnote "@note" "@question" "@deprecated"))

("text" @comment.atnote @nospell
  (#any-of? @comment.atnote "@note" "@question" "@deprecated"))

((tag
  (name) @comment.warning @nospell
  ("(" @punctuation.bracket
    (user) @constant
    ")" @punctuation.bracket)?
  ":" @punctuation.delimiter)
  (#any-of? @comment.warning "@important" "@hack" "@slow"))

("text" @comment.warning @nospell
  (#any-of? @comment.warning "@important" "@hack" "@slow"))

;; @important

((tag
  (name) @comment.important @nospell
  ("(" @punctuation.bracket
    (user) @constant
    ")" @punctuation.bracket)?
  ":" @punctuation.delimiter)
  (#any-of? @comment.important "@important"))

("text" @comment.important @nospell
  (#any-of? @comment.important "@important"))

;; @hack

((tag
  (name) @comment.hack @nospell
  ("(" @punctuation.bracket
    (user) @constant
    ")" @punctuation.bracket)?
  ":" @punctuation.delimiter)
  (#any-of? @comment.hack "@hack"))

("text" @comment.hack @nospell
  (#any-of? @comment.hack "@hack"))

;; @slow, @fix, @leak

((tag
  (name) @comment.aterror @nospell
  ("(" @punctuation.bracket
    (user) @constant
    ")" @punctuation.bracket)?
  ":" @punctuation.delimiter)
  (#any-of? @comment.aterror "@slow" "@fix" "@leak" "@ugly"))

("text" @comment.aterror @nospell
  (#any-of? @comment.aterror "@slow" "@fix" "@leak" "@ugly"))

;; @nocheckin

((tag
  (name) @comment.nocheckin @nospell
  ("(" @punctuation.bracket
    (user) @constant
    ")" @punctuation.bracket)?
  ":" @punctuation.delimiter)
  (#any-of? @comment.nocheckin "@nocheckin"))

("text" @comment.nocheckin @nospell
  (#any-of? @comment.nocheckin "@nocheckin"))
