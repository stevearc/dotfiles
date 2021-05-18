let g:arduino_serial_cmd = 'picocom {port} -b {baud} -l'

function! ArduinoStatusLine()
  let port = arduino#GetPort()
  let line = '[' . g:arduino_board . '] [' . g:arduino_programmer . ']'
  if !empty(port)
    let line = line . ' (' . port . ':' . g:arduino_serial_baud . ')'
  endif
  return line
endfunction
augroup ArduinoStatusLine
  autocmd! * <buffer>
  autocmd BufWinEnter <buffer> setlocal stl=%f\ %h%w%m%r\ %{ArduinoStatusLine()}\ %=\ %(%l,%c%V\ %=\ %P%)
augroup END

nnoremap <buffer> <leader>ac :wa<CR>:ArduinoVerify<CR>
nnoremap <buffer> <leader>au :wa<CR>:ArduinoUpload<CR>
nnoremap <buffer> <leader>ad :wa<CR>:ArduinoUploadAndSerial<CR>
nnoremap <buffer> <leader>ab :ArduinoChooseBoard<CR>
nnoremap <buffer> <leader>ap :ArduinoChooseProgrammer<CR>
