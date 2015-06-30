let g:arduino_serial_cmd = 'picocom {port} -b {baud} -l'

function! b:MyStatusLine()
  return '%f [' . g:arduino_board . '] (' . g:arduino_serial_baud . ')'
endfunction
setl statusline=%!b:MyStatusLine()

nmap <leader>m :make!<CR>
nmap <leader>u :call ArduinoUpload()<CR>
nmap <leader>d :call ArduinoUploadAndSerial()<CR>
nmap <leader>b :call ArduinoChooseBoard()<CR>
