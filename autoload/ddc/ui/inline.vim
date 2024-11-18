function! ddc#ui#inline#visible() abort
  return s:->get('inline_popup_id', -1) > 0
endfunction

function! ddc#ui#inline#_show(pos, items, highlight) abort
  " NOTE: When doing a change motion (i.e. cwabc<esc>) and repeating with ".",
  " it would trigger.
  if mode() ==# 'n'
    return
  endif

  const complete_str = ddc#util#get_input('')[a:pos :]
  const remaining = a:items[0].word[complete_str->len():]

  if a:items->empty() || remaining ==# ''
    call ddc#ui#inline#_hide()
    return
  endif

  const is_cmdline = mode() ==# 'c'

  " Head matched: Follow cursor text
  const at_eol =
        \   is_cmdline
        \ ? getcmdpos() == getcmdline()->len() + 1
        \ : '.'->col() == '$'->col()
  const has_inline = has('nvim-0.10')
  const head_matched = a:items[0].word->stridx(complete_str) == 0
        \ && (!is_cmdline || getcmdpos() == getcmdline()->len() + 1)
        \ && (has_inline || at_eol)
  const word = head_matched ? remaining : a:items[0].word

  if has('nvim')
    if is_cmdline
      " Use floating window
      let [row, col] = s:get_cmdline_pos(head_matched)

      let winopts = #{
            \   relative: 'editor',
            \   width: word->strdisplaywidth(),
            \   height: 1,
            \   row: row,
            \   col: col,
            \   anchor: 'NW',
            \   style: 'minimal',
            \   zindex: 9999,
            \ }

      if ddc#ui#inline#visible()
        " Reuse the window
        call nvim_win_set_config(s:inline_popup_id, winopts)
      else
        " NOTE: It cannot set in nvim_win_set_config()
        let winopts.noautocmd = v:true

        if !'s:inline_popup_buf'->exists()
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
      const col = '.'->col() - 1
      const virt_text_pos =
            \   head_matched && at_eol
            \ ? 'overlay'
            \ : has_inline && !at_eol
            \ ? 'inline'
            \ : 'eol'
      const prefix =
            \ virt_text_pos == 'inline' && word != remaining
            \ ? ' '
            \ : ''
      const options = #{
            \   virt_text: [[prefix . word, a:highlight]],
            \   virt_text_pos: virt_text_pos,
            \   hl_mode: 'combine',
            \   priority: 0,
            \   right_gravity: !at_eol,
            \ }
      call nvim_buf_set_extmark(
            \ 0, s:ddc_namespace, '.'->line() - 1, col, options)

      if virt_text_pos == 'inline'
        " It needs update
        autocmd InsertCharPre * ++once call ddc#ui#inline#_hide()
      endif

      let s:inline_popup_id = 1
    endif
  else
    " Use popup window instead
    if is_cmdline
      let [row, col] = s:get_cmdline_pos(head_matched)
    else
      let row = '.'->line()
      let col = head_matched ? '.'->col() + 1 : '$'->col() + 1
    endif

    const winopts = #{
          \   pos: 'topleft',
          \   line: row,
          \   col: col,
          \   highlight: a:highlight,
          \   zindex: 9999,
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

  redraw
endfunction

function! ddc#ui#inline#_hide() abort
  if !ddc#ui#inline#visible()
    return
  endif

  call s:close_popup(s:inline_popup_id)

  let s:inline_popup_id = -1
endfunction
function! s:close_popup(id) abort
  try
    if has('nvim')
      if mode() ==# 'c'
        call nvim_win_close(a:id, v:true)
      else
        if !'s:ddc_namespace'->exists()
          let s:ddc_namespace = nvim_create_namespace('ddc')
        endif

        call nvim_buf_clear_namespace('%'->bufnr(), s:ddc_namespace, 0, -1)
      endif
    else
      call popup_close(a:id)
    endif

    redraw
  catch /E523:\|E565:\|E5555:\|E994:/
    " Ignore "Not allowed here"

    " Close the popup window later
    call timer_start(100, { -> s:close_popup(a:id) })
  endtry
endfunction

" returns [border_left, border_top, border_right, border_bottom]
function s:get_border_size(border) abort
  if a:border->type() == v:t_string
    return a:border ==# 'none' ? [0, 0, 0, 0] : [1, 1, 1, 1]
  elseif a:border->type() == v:t_list && !a:border->empty()
    return [
          \   s:get_borderchar_width(a:border[3 % len(a:border)]),
          \   s:get_borderchar_height(a:border[1 % len(a:border)]),
          \   s:get_borderchar_width(a:border[7 % len(a:border)]),
          \   s:get_borderchar_height(a:border[5 % len(a:border)]),
          \ ]
  else
    return [0, 0, 0, 0]
  endif
endfunction

function s:get_cmdline_pos(head_matched) abort
  if '*cmdline#_get'->exists() && !cmdline#_get().pos->empty()
    const [cmdline_left, cmdline_top, cmdline_right, cmdline_bottom]
          \ = s:get_border_size(cmdline#_options().border)

    let pos = cmdline#_get().pos->copy()
    let pos[0] += cmdline_top + cmdline_bottom
    let pos[1] += cmdline_left

    let row = pos[0]
    if has('nvim')
      let row -= 1
    endif

    let col = cmdline#_get().prompt->strlen() + pos[1]
    if !has('nvim')
      let col += 1
    endif
  else
    let row = &lines - [1, &cmdheight]->max()
    let col =
          \   exists('*getcmdprompt') && getcmdprompt() !=# ''
          \ ? getcmdprompt()->len()
          \ : 1
    if !has('nvim')
      let col += 1
    endif
  endif

  let col += a:head_matched ? getcmdpos() - 1 : getcmdline()->len() + 1

  return [row, col]
endfunction
