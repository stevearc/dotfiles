;; extends

; Needs https://github.com/nvim-treesitter/nvim-treesitter/issues/4181
; (([(list_marker_star) (list_marker_minus)] @punctuation.special @conceal_star (#offset! @conceal_star 0 0 0 -1)) (#set! conceal "•"))

((task_list_marker_unchecked) @punctuation.special @conceal (#set! conceal ""))
((task_list_marker_checked) @punctuation.special @conceal (#set! conceal ""))

((block_quote_marker) @conceal (#set! conceal "▍"))
((block_quote
  (paragraph (inline
    (block_continuation) @conceal (#set! conceal "▍")
  ))
))

; Needs https://github.com/neovim/neovim/issues/11711
; (fenced_code_block) @codeblock
