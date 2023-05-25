function! ddc#ui#inline#visible() abort
  return s:->get('inline_popup_id', -1) > 0
endfunction

function! ddc#ui#inline#_show(pos, items, highlight) abort
  if has('nvim')
    if 's:ddc_namespace'->exists()
      call nvim_buf_clear_namespace(0, s:ddc_namespace, 0, -1)
    else
      let s:ddc_namespace = nvim_create_namespace('ddc')
    endif
  endif

  if a:items->empty() || mode() !=# 'i'
    return
  endif

  const complete_str = ddc#util#get_input('')[a:pos :]
  const remaining = a:items[0].word[complete_str->len():]

  if remaining ==# ''
    return
  endif

  " Head matched: Follow cursor text
  const head_matched = a:items[0].word->stridx(complete_str) == 0
        \ && '.'->col() == '$'->col()

  const has_inline = has('nvim-0.10')
  const word = head_matched || has_inline ? remaining : a:items[0].word

  if has('nvim')
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
  else
    const col = head_matched ? '.'->col() : '$'->col() + 1
    const winopts = #{
          \   pos: 'topleft',
          \   line: '.'->line(),
          \   col: col,
          \   highlight: a:highlight,
          \ }

    " Use popup instead
    if s:inline_popup_id > 0
      call popup_move(s:inline_popup_id, winopts)
      call popup_settext(s:inline_popup_id, [word])
    else
      let s:inline_popup_id = popup_create([word], winopts)
    endif
  endif
endfunction

function! ddc#ui#inline#_hide() abort
  if !('s:inline_popup_id'->exists())
    return
  endif

  if '*nvim_buf_set_virtual_text'->exists()
    if !('s:ddc_namespace'->exists())
      let s:ddc_namespace = nvim_create_namespace('ddc')
    endif

    call nvim_buf_clear_namespace('%'->bufnr(), s:ddc_namespace, 0, -1)
  elseif s:->get('inline_popup_id', -1) > 0
    call popup_close(s:inline_popup_id)
  endif

  let s:inline_popup_id = -1
endfunction
