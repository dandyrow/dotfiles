" Vim syntax file for PMD (Page Metadata) files
" Language: JSON with embedded JavaScript in <% %> tags

if exists("b:current_syntax")
  finish
endif

" Include JavaScript syntax
unlet! b:current_syntax
syntax include @JavaScript syntax/javascript.vim
unlet! b:current_syntax

" JSON structural elements
syntax match jsonNoise /\%(:\|,\)/
syntax region jsonFold matchgroup=jsonBraces start="{" end=/}\(\\_s\+\ze\("\|{\)\)\@!/ transparent fold
syntax region jsonFold matchgroup=jsonBraces start="\[" end=/]\(\\_s\+\ze"\)\@!/ transparent fold

" JSON escape sequences
syntax match jsonEscape "\\[\"\\/bfnrt]" contained
syntax match jsonEscape "\\u\x\{4}" contained

" JSON keys
syn match jsonKeywordMatch /"\([^"]\|\\\"\)\+"[[:blank:]\r\n]*\:/ contains=jsonKeyword
syn region jsonKeyword matchgroup=jsonQuote start=/"/ end=/"\ze[[:blank:]\r\n]*\:/ contained

" JSON strings - simple definition
syn match jsonStringMatch /"\([^"]\|\\\"\)\+"\ze[[:blank:]\r\n]*[,}\]]/ contains=jsonString
syn region jsonString matchgroup=jsonQuote start=/"/ end=/"/ skip=/\\./ contains=jsonEscape contained

" JavaScript code regions using containedin to embed in strings
" This is the key: containedin tells Vim this region can appear inside jsonString
syntax region pmdJavaScriptCode matchgroup=pmdDelimiter start="<%\s*" end="\s*%>" contains=@JavaScript containedin=jsonString,jsonKeyword keepend

" JSON numbers
syntax match jsonNumber "-\=\<\%(0\|[1-9]\d*\)\%(\.\d\+\)\=\%([eE][-+]\=\d\+\)\=\>\ze[[:blank:]\r\n]*[,}\]]"

" JSON Boolean
syn match jsonBoolean /\(true\|false\)\(\\_s\+\ze"\)\@!/

" JSON Null
syntax keyword jsonNull null

" Sync from start for accuracy
syntax sync fromstart

" Highlighting
highlight default link jsonNoise Delimiter
highlight default link jsonBraces Delimiter
highlight default link jsonKeyword Label
highlight default link jsonString String
highlight default link jsonQuote Delimiter
highlight default link jsonEscape Special
highlight default link jsonNumber Number
highlight default link jsonBoolean Boolean
highlight default link jsonNull Function
highlight default link pmdDelimiter Special

let b:current_syntax = "pmd"

