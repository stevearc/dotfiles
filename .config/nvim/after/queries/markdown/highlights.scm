; extends

; Needs https://github.com/nvim-treesitter/nvim-treesitter/issues/4181
; (([(list_marker_star) (list_marker_minus)] @punctuation.special @conceal_star (#offset! @conceal_star 0 0 0 -1)) (#set! conceal "•"))

; Checkbox list items
((task_list_marker_unchecked) @punctuation.special @conceal (#set! conceal ""))
((task_list_marker_checked) @punctuation.special @conceal (#set! conceal ""))

; Use box drawing characters for tables
(pipe_table_header ("|") @punctuation.special @conceal (#set! conceal "┃"))
(pipe_table_delimiter_row ("|") @punctuation.special @conceal (#set! conceal "┃"))
(pipe_table_delimiter_cell ("-") @punctuation.special @conceal (#set! conceal "━"))
(pipe_table_row ("|") @punctuation.special @conceal (#set! conceal "┃"))

; Block quotes
((block_quote_marker) @conceal (#set! conceal "▍"))
((block_quote
  (paragraph (inline
    (block_continuation) @conceal (#set! conceal "▍")
  ))
))

; Needs https://github.com/neovim/neovim/issues/11711
; (fenced_code_block) @codeblock
