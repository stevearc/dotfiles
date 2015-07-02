let g:arduino_serial_cmd = 'picocom {port} -b {baud} -l'

function! b:MyStatusLine()
  let port = arduino#GetPort()
  let line = '%f [' . g:arduino_board . '] ('
  if !empty(port)
    let line = line . port . ':'
  endif
  let line = line . g:arduino_serial_baud . ')'
  return line
endfunction
setl statusline=%!b:MyStatusLine()

nnoremap <buffer> <leader>m :ArduinoVerify<CR>
nnoremap <buffer> <leader>u :ArduinoUpload<CR>
nnoremap <buffer> <leader>d :ArduinoUploadAndSerial<CR>
nnoremap <buffer> <leader>b :ArduinoChooseBoard<CR>
