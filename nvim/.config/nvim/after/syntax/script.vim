" Vim syntax file for .script files
" Language: JavaScript (Workday Extend)

if exists("b:current_syntax")
  finish
endif

" Load base JavaScript syntax
runtime! syntax/javascript.vim

" Template string literals with backticks (can contain {{}} interpolation)
syntax region scriptTemplateString matchgroup=scriptTemplateDelim start="`" end="`" contains=scriptTemplateInterpolation

" {{}} interpolation within template strings
syntax region scriptTemplateInterpolation matchgroup=scriptInterpolationDelim start="{{" end="}}" contains=@JavaScript,scriptReservedWord contained

" Script-specific reserved words (Workday scripting extensions)
syntax keyword scriptReservedWord empty contained

" Highlighting
highlight default link scriptTemplateString String
highlight default link scriptTemplateDelim String
highlight default link scriptInterpolationDelim Special
highlight default link scriptReservedWord Keyword

let b:current_syntax = "script"

