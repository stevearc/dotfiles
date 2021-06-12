let g:arduino_serial_cmd = 'picocom {port} -b {baud} -l'

nnoremap <buffer> <leader>ac :wa<CR>:ArduinoVerify<CR>
nnoremap <buffer> <leader>au :wa<CR>:ArduinoUpload<CR>
nnoremap <buffer> <leader>ad :wa<CR>:ArduinoUploadAndSerial<CR>
nnoremap <buffer> <leader>ab :ArduinoChooseBoard<CR>
nnoremap <buffer> <leader>ap :ArduinoChooseProgrammer<CR>
