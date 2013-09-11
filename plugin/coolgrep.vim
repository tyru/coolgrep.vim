" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if get(g:, 'loaded_coolgrep', 0) || &cp
    finish
endif
let g:loaded_coolgrep = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

function! s:cmd_coolgrep(vimgrep, args)
    " Execute :vimgrep
    execute (a:vimgrep ? 'vimgrep' : 'grep') a:args
    " Get rid of comment lines.
    let qflist = getqflist()
    if empty(qflist)
        return
    endif
    if !a:vimgrep
        let [opt, greppat] = s:parse_grep_args(a:args)
        call s:set_cols_of_qflist(qflist, opt, greppat)
    endif
    call filter(qflist, '!s:is_comment_line(v:val)')
    call setqflist(qflist)
    " Rethrow QuickFixCmdPost because qflist is changed.
    execute "doautocmd QuickFixCmdPost" (a:vimgrep ? 'vimgrep' : 'grep')
endfunction

function! s:parse_grep_args(args)
    let opt = {'ignorecase': 0}
    let word = ''
    let args = a:args
    while args !=# ''
        let args = substitute(args, '^\s\+', '', '')
        if args[0] ==# '-'
            if args =~# '^\(-i\|--ignore-case\)'
                let opt.ignorecase = 1
            endif
            let args = substitute(args, '^\S\+', '', '')
        elseif args[0] ==# '"' || args[0] ==# "'"
            let word = matchstr(args, '^['.args[0].']\zs[^'.args[0].']*\ze['.args[0].']')
            break
        else
            let word = matchstr(args, '^\S\+')
            break
        endif
    endwhile
    return [opt, word]
endfunction

function! s:set_cols_of_qflist(qflist, opt, greppat)
    " TODO: Convert grep regexp pattern to Vim regexp pattern.
    let pat = '\v'.(a:opt.ignorecase ? '\c' : '\C').a:greppat
    for qf in a:qflist
        let idx = match(qf.text, pat)
        if idx >=# 0
            let qf.col = idx + 1
        endif
        " let qf.vcol = ...
    endfor
endfunction

function! s:is_comment_line(qf)
    let qf = a:qf
    let line = getbufline(qf.bufnr, qf.lnum)
    let synstack = s:synbufstack(qf.bufnr, qf.lnum, qf.col)
    let is_comment = 'synIDattr(synIDtrans(v:val), "name") ==# "Comment"'
    return !empty(filter(synstack, is_comment))
endfunction

function! s:synbufstack(bufnr, lnum, col)
    if bufnr('%') !=# a:bufnr
        " bufnr
        let prev_bufnr = bufnr('%')
        " view
        let view = winsaveview()
        " bufhidden
        let save_bufhidden = &l:bufhidden
        let &l:bufhidden = 'hide'
        " Change current buffer.
        execute a:bufnr 'buffer'
    endif
    try
        return synstack(a:lnum, a:col)
    finally
        if exists('prev_bufnr')
            " bufhidden
            let &l:bufhidden = save_bufhidden
            " view
            call winrestview(view)
            " bufnr
            execute prev_bufnr 'buffer'
        endif
    endtry
endfunction

command! -nargs=* CoolVimGrep
\   call s:cmd_coolgrep(1, <q-args>)

command! -nargs=* CoolGrep
\   call s:cmd_coolgrep(0, <q-args>)



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
