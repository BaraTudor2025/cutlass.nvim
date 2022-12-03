local cutlass = {}

local function with_defaults(options)
  local flip = function(t)
    local flipped = {}
    for _, value in pairs(t) do
      flipped[value] = true
    end

    return flipped
  end

  return {
    cut_key = options.cut_key or nil,
    override_del = options.override_del or nil,
    exclude = options.exclude and flip(options.exclude) or {},
    change_register = '"'..(options.change_register or '_'), -- c/C
    delete_register = '"'..(options.delete_register or '_'), -- d/D
    select_register = '"'..(options.select_register or '_'), -- select-mode
  }
end

local keymap_opts = { noremap = true, silent = true }
local map = vim.api.nvim_set_keymap

function cutlass.setup(options)
  cutlass.options = with_defaults(options or {})

  cutlass.override_delete_and_change_bindings()
  cutlass.override_select_bindings()
  cutlass.create_cut_bindings()
end

function cutlass.override_delete_and_change_bindings()
  local opts = cutlass.options
  for _, mode in pairs({ "x", "n" }) do
    for _, lhs in pairs({ "c", "C", "s", "S", "d", "D", "x", "X" }) do
      if not opts.exclude[mode .. lhs] and vim.fn.maparg(lhs, mode) == "" then
        local reg = '"_'
        if lhs == "c" or lhs == "C" then
          reg = opts.change_register
        end
        if lhs == "d" or lhs == "D" then
          reg = opts.delete_register
        end
        map(mode, lhs, reg .. lhs, keymap_opts)
      end
    end
  end

  if cutlass.options.override_del == true then
    map("n", "<Del>", '"_x', keymap_opts)
    map("x", "<Del>", '"_x', keymap_opts)
  end
end

function cutlass.override_select_bindings()
  -- Add a map for every printable character to copy to black hole register
  local reg = cutlass.options.select_register
  for char_nr = 33, 126 do
    local char = vim.fn.nr2char(char_nr)
    if not cutlass.options.exclude["s" .. char] then
      map("s", char, '<c-o>'..reg..'c' .. char == "\\" and "\\\\" or char, keymap_opts)
    end
  end

  if not cutlass.options.exclude["s<bs>"] then
    map("s", "<bs>", '<c-o>'..reg..'c', keymap_opts)
  end

  if not cutlass.options.exclude["s<space>"] then
    map("s", "<space>", '<c-o>'..reg..'c<space>', keymap_opts)
  end
end

function cutlass.create_cut_bindings()
  if nil == cutlass.options.cut_key then
    return
  end

  map("n", cutlass.options.cut_key, "d", keymap_opts)
  map("x", cutlass.options.cut_key, "d", keymap_opts)
  map("n", cutlass.options.cut_key .. cutlass.options.cut_key, "dd", keymap_opts)
  map("n", string.upper(cutlass.options.cut_key), "D", keymap_opts)
end

return cutlass
