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
    call filter(qflist, '!s:is_comment_line(v:val)')
    call setqflist(qflist)
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