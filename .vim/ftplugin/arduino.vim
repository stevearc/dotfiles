let g:arduino_serial_cmd = 'picocom {port} -b {baud} -l'

function! b:MyStatusLine()
  return '%f [' . g:arduino_board . '] (' . g:arduino_serial_baud . ')'
endfunction
setl statusline=%!b:MyStatusLine()

nnoremap <buffer> <leader>m :ArduinoVerify<CR>
nnoremap <buffer> <leader>u :ArduinoUpload<CR>
nnoremap <buffer> <leader>d :ArduinoUploadAndSerial<CR>
nnoremap <buffer> <leader>b :ArduinoChooseBoard<CR>
