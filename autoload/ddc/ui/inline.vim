function! ddc#ui#inline#visible() abort
  return s:->get('inline_popup_id', -1) > 0
endfunction

function! ddc#ui#inline#_show(pos, items, highlight) abort
  const complete_str = ddc#util#get_input('')[a:pos :]
  const remaining = a:items[0].word[complete_str->len():]

  if a:items->empty() || remaining ==# ''
    call ddc#ui#inline#_hide()
    return
  endif

  const is_cmdline = mode() ==# 'c'

  " Head matched: Follow cursor text
  const head_matched = a:items[0].word->stridx(complete_str) == 0
        \ && (is_cmdline ? getcmdpos() == getcmdline()->len() + 1 :
        \                  '.'->col() == '$'->col())

  const has_inline = has('nvim-0.10')
  const word = head_matched || has_inline ? remaining : a:items[0].word
  const cmdline_pos = &lines - [1, &cmdheight]->max()

  if has('nvim')
    if is_cmdline
      " Use floating window
      const col = (head_matched ? getcmdpos() : getcmdline()->len()) + 1
      let winopts = #{
            \   relative: 'editor',
            \   width: word->strdisplaywidth(),
            \   height: 1,
            \   row: cmdline_pos,
            \   col: col,
            \   anchor: 'NW',
            \   style: 'minimal',
            \ }

      if ddc#ui#inline#visible()
        " Reuse the window
        call nvim_win_set_config(s:inline_popup_id, winopts)
      else
        " NOTE: It cannot set in nvim_win_set_config()
        let winopts.noautocmd = v:true

        if !('s:inline_popup_buf'->exists())
          const s:inline_popup_buf = nvim_create_buf(v:false, v:true)
        endif

        let s:inline_popup_id = nvim_open_win(
              \ s:inline_popup_buf, v:false, winopts)

        " NOTE: nvim_win_set_option() causes title flicker...
        let highlight = 'Normal:' .. a:highlight
        if &hlsearch
          " Disable 'hlsearch' highlight
          let highlight ..= ',Search:None,CurSearch:None'
        endif
        call nvim_win_set_option(
              \ s:inline_popup_id, 'winhighlight', highlight)
        call nvim_win_set_option(
              \ s:inline_popup_id, 'wrap', v:false)
        call nvim_win_set_option(
              \ s:inline_popup_id, 'scrolloff', 0)
        call nvim_win_set_option(
              \ s:inline_popup_id, 'statusline', &l:statusline)
      endif

      call nvim_buf_set_lines(s:inline_popup_buf, 0, -1, v:true, [word])
    else
      if 's:ddc_namespace'->exists()
        call nvim_buf_clear_namespace(0, s:ddc_namespace, 0, -1)
      else
        let s:ddc_namespace = nvim_create_namespace('ddc')
      endif

      " Use virtual text
      const col = head_matched || has_inline ? '.'->col() - 1 : 0
      const virt_text_pos =
            \ head_matched ? 'overlay' : has_inline ? 'inline' : 'eol'
      const options = #{
            \   virt_text: [[word, a:highlight]],
            \   virt_text_pos: virt_text_pos,
            \   hl_mode: 'combine',
            \   priority: 0,
            \   right_gravity: !head_matched,
            \ }
      call nvim_buf_set_extmark(
            \ 0, s:ddc_namespace, '.'->line() - 1, col, options)

      if !head_matched && has_inline
        " It needs update
        autocmd InsertCharPre * ++once call ddc#ui#inline#_hide()
      endif

      let s:inline_popup_id = 1
    endif
  else
    " Use popup window instead
    const col =
          \ is_cmdline ?
          \   (head_matched ? getcmdpos() : getcmdline()->len()) + 1 :
          \ head_matched ? '.'->col() : '$'->col() + 1
    const winopts = #{
          \   pos: 'topleft',
          \   line: is_cmdline ? cmdline_pos : '.'->line(),
          \   col: col,
          \   highlight: a:highlight,
          \ }

    if ddc#ui#inline#visible()
      call popup_move(s:inline_popup_id, winopts)
      call popup_settext(s:inline_popup_id, [word])
    else
      let s:inline_popup_id = popup_create([word], winopts)
    endif
  endif

  if is_cmdline
    " NOTE: ddc#hide() does not work.  I don't know why.
    autocmd ddc CmdlineLeave <buffer> ++once call ddc#ui#inline#_hide()
  endif

  if !has('nvim') || is_cmdline
    redraw
  endif
endfunction

function! ddc#ui#inline#_hide() abort
  if !ddc#ui#inline#visible()
    return
  endif

  if has('nvim')
    if mode() ==# 'c'
      call nvim_win_close(s:inline_popup_id, v:true)
    else
      if !('s:ddc_namespace'->exists())
        let s:ddc_namespace = nvim_create_namespace('ddc')
      endif

      call nvim_buf_clear_namespace('%'->bufnr(), s:ddc_namespace, 0, -1)
    endif
  else
    call popup_close(s:inline_popup_id)
  endif

  redraw

  let s:inline_popup_id = -1
endfunction
