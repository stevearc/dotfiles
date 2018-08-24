let b:neoformat_enabled_css = ['prettier']

command! SortCSSBraceContents :g#\({\n\)\@<=#.,/}/sort
