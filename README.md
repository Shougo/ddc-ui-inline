# ddc-ui-inline

inline UI for ddc.vim

## Required

### denops.vim

https://github.com/vim-denops/denops.vim

### ddc.vim

https://github.com/Shougo/ddc.vim

## Configuration

```vim
call ddc#custom#patch_global('ui', 'inline')
inoremap <expr><C-t>       ddc#map#insert_item(0, "\<C-e>")

" Cancel
inoremap <C-e>   <Cmd>call ddc#hide('Manual')<CR>
```
