nmap <buffer> <CR> <Plug>(scnvim-send-block)
imap <buffer> <c-CR> <Plug>(scnvim-send-block)
xmap <buffer> <CR> <Plug>(scnvim-send-selection)
nmap <buffer> <F1> <cmd>call scnvim#install()<CR><cmd>SCNvimStart<CR><cmd>SCNvimStatusLine<CR>
nmap <buffer> <F2> <cmd>SCNvimStop<CR>
nmap <buffer> <F12> <Plug>(scnvim-hard-stop)
nmap <buffer> <leader><space> <Plug>(scnvim-postwindow-toggle)
nmap <buffer> <leader>g <cmd>call scnvim#sclang#send('s.plotTree;')<CR>
nmap <buffer> <leader>s <cmd>call scnvim#sclang#send('s.scope;')<CR>
nmap <buffer> <leader>f <cmd>call scnvim#sclang#send('FreqScope.new;')<CR>
nmap <buffer> <leader>r <cmd>SCNvimRecompile<CR>
nmap <buffer> <leader>m <cmd>call scnvim#sclang#send('Master.gui;')<CR>

setlocal stl=%f\ %h%w%m%r\ %{scnvim#statusline#server_status()}\ %=\ %(%l,%c%V\ %=\ %P%)

setlocal fdm=marker
setlocal fmr={{{,}}}

augroup StartSCNvim
  autocmd! * <buffer>
  autocmd WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&filetype") == "scnvim"|q|endif
augroup END

augroup ClostPostWindowIfLast
  autocmd!
  autocmd WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&filetype") == "scnvim"|q|endif
augroup END

let b:neoformat_run_all_formatters = 1
let b:neoformat_basic_format_retab = 1
let b:neoformat_basic_format_trim = 1
augroup scfmt
  autocmd! * <buffer>
  autocmd BufWritePre <buffer> Neoformat
augroup END
