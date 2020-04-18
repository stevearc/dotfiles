" Flow coverage utility functions
" TODO support different buffers

let g:flow_coverage_enabled = get(g:, 'flow_coverage_enabled', v:false)
let g:flow_coverage_uncovered_texthl = 'ALEError'
let g:flow_coverage_empty_texthl = 'ALEWarning'

let s:bufMap = {}
let s:ns_id = 0
let s:sign_id_gen = 0

function! s:GetSignID() abort
  let s:sign_id_gen += 1
  return s:sign_id_gen
endfunction

function! s:HighlightRange(range, texthl) abort
  let l:start = get(a:range, 'start')
  let l:end = get(a:range, 'end')
  let l:start_line = get(l:start, 'line')
  let l:start_character = get(l:start, 'character')
  let l:end_line = get(l:end, 'line')
  let l:end_character = get(l:end, 'character')
  let l:curline = l:start_line

  " Highlight lines
  while l:curline <= l:end_line
    let l:start_col = l:curline == l:start_line ? l:start_character : 0
    let l:end_col = l:curline == l:end_line ? l:end_character : -1
    let s:ns_id = nvim_buf_add_highlight(0, s:ns_id, a:texthl, l:curline, l:start_col, l:end_col)
    let l:curline += 1
  endwhile

  " Place sign
  let l:sign_id = s:GetSignID()
  exe 'sign place ' . l:sign_id . ' line=' . (l:start_line + 1) . ' name=FlowUntyped buffer=' . bufnr('')
  let l:signs = get(b:, 'flow_coverage_signs', [])
  let b:flow_coverage_signs = add(l:signs, l:sign_id)
endfunction

function! s:HandleCoverage(output, ...) abort
  let l:quiet = get(a:000, 0)

  if has_key(a:output, 'result')
    let l:result = get(a:output, 'result')
    let b:flow_coverage_message = get(l:result, 'defaultMessage')
    let b:flow_coverage_percent = get(l:result, 'coveredPercent')
    let l:ranges = get(l:result, 'uncoveredRanges', [])
    call flow#hideCoverage()
    if !empty(l:ranges)
      for l:range_obj in l:ranges
        let l:range = get(l:range_obj, 'range')
        call s:HighlightRange(l:range, g:flow_coverage_uncovered_texthl)
      endfor
    endif
  elseif has_key(a:output, 'error')
    let l:error = get(a:output, 'error')
    let l:code = get(l:error, 'code')
    " Don't print error if LSP is not started
    if l:code == -32603
      let l:quiet = v:true
    endif
    let l:message = get(l:error, 'message')
    if !l:quiet
      echoerr l:message
    endif
    return v:null
  else
    if !l:quiet
      echoerr 'Unknown output type: ' . json_encode(a:output)
    endif
    return v:null
  endif
endfunction

function! flow#textDocumentIdentifier() abort
  let l:filename = LSP#filename()
  return 'file://' . l:filename
endfunction

function! flow#typeCoverage() abort
  let l:Callback = function('s:HandleCoverage')
  let l:params = {
    \ 'textDocument': {
      \ 'uri': flow#textDocumentIdentifier()
      \ }
    \ }
  return LanguageClient#Call('textDocument/typeCoverage', l:params, l:Callback)
endfunction

function! flow#hideCoverage() abort
  call nvim_buf_clear_namespace(0, s:ns_id, 0, -1)
  let l:signs = get(b:, 'flow_coverage_signs', [])
  for l:sign in l:signs
    exe 'sign unplace ' . l:sign . ' buffer=' . bufnr('')
  endfor
  let b:flow_coverage_signs = []
endfunction

function! flow#isCoverageEnabled() abort
  if has_key(b:, 'flow_coverage_enabled')
    return b:flow_coverage_enabled
  else
    return g:flow_coverage_enabled
  endif
endfunction

function! flow#recheckCoverage() abort
  let l:enabled = flow#isCoverageEnabled()
  if l:enabled
    call flow#typeCoverage()
  else
    call flow#hideCoverage()
  endif
endf

function! flow#enableCoverage() abort
  let b:flow_coverage_enabled = v:true
  call flow#recheckCoverage()
endfunction

function! flow#disableCoverage() abort
  let b:flow_coverage_enabled = v:false
  call flow#hideCoverage()
endfunction

function! flow#toggleCoverage() abort
  let l:enabled = flow#isCoverageEnabled()
  if l:enabled
    call flow#disableCoverage()
  else
    call flow#enableCoverage()
  endif
endfunction

function! flow#enableGlobalCoverage() abort
  let g:flow_coverage_enabled = v:true
  call flow#recheckCoverage()
  " TODO recheck in all buffers
endfunction

function! flow#disableGlobalCoverage() abort
  let g:flow_coverage_enabled = v:false
  call flow#hideCoverage()
  " TODO hide in all buffers
endfunction

function! flow#toggleGlobalCoverage() abort
  let l:enabled = g:flow_coverage_enabled
  if l:enabled
    call flow#disableGlobalCoverage()
  else
    call flow#enableGlobalCoverage()
  endif
endfunction
