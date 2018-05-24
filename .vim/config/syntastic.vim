" Syntastic (which we really only need for omnisharp)
let g:syntastic_cs_checkers = ['code_checker']
let g:syntastic_check_on_wq = 0
let g:syntastic_mode_map = {
    \ "mode": "passive",
    \ "active_filetypes": ["cs"] }
