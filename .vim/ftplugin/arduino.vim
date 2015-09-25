let g:arduino_serial_cmd = 'picocom {port} -b {baud} -l'

function! b:MyStatusLine()
  let port = arduino#GetPort()
  let line = '%f [' . g:arduino_board . '] [' . g:arduino_programmer . ']'
  if !empty(port)
    let line = line . ' (' . port . ':' . g:arduino_serial_baud . ')'
  endif

  return line
endfunction
setl statusline=%!b:MyStatusLine()

nnoremap <buffer> <leader>ac :wa<CR>:ArduinoVerify<CR>
nnoremap <buffer> <leader>au :wa<CR>:ArduinoUpload<CR>
nnoremap <buffer> <leader>ad :wa<CR>:ArduinoUploadAndSerial<CR>
nnoremap <buffer> <leader>ab :ArduinoChooseBoard<CR>
nnoremap <buffer> <leader>ap :ArduinoChooseProgrammer<CR>
