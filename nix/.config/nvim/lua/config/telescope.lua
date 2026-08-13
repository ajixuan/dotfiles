local builtin = require('telescope.builtin')

vim.keymap.set('n', '<C-p>', function()
  builtin.find_files({
    hidden = true,
    file_ignore_patterns = { '%.git/' },
  })
end, { desc = 'Telescope find files (incl. hidden & ignored)' })

vim.keymap.set('n', '<leader>fg', function()
  builtin.live_grep({ additional_args = {
    '--hidden',
    '--glob', '!**/.git/**',
    '--glob', '!**/node_modules/**',
    '--glob', '!**/.venv/**',
    '--glob', '!**/.terraform/**',
    '--glob', '!**/dist/**',
    '--glob', '!**/build/**',
  }})
end, { desc = 'Telescope live grep' })

vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

vim.keymap.set('n', '<leader>fd', function()
  builtin.diagnostics()
end, { desc = 'Telescope workspace diagnostics' })

vim.keymap.set('n', '<leader>fD', function()
  builtin.diagnostics({ severity = vim.diagnostic.severity.ERROR })
end, { desc = 'Telescope workspace diagnostic errors only' })

vim.keymap.set('n', '<leader>fF', function()
  local pickers    = require('telescope.pickers')
  local finders    = require('telescope.finders')
  local sorters    = require('telescope.sorters')
  local conf       = require('telescope.config').values
  local make_entry = require('telescope.make_entry')

  local function build_pattern(name)
    if not name or name == '' then return nil end
    local n = name:gsub('([%[%]%^%$%(%)%.%*%+%?%-\\])', '\\%1')
    -- Match common function-definition patterns across languages:
    --   keyword-style:  function/def/func/fn/defn/sub/method NAME
    --   binding-style:  (const|let|var) NAME =
    --   assignment:     NAME = function(...)  |  NAME = (args) => ...  |  NAME = (args) -> ...
    return table.concat({
      '(function|def|func|fn|defn|sub|method)\\s+' .. n .. '\\b',
      '(const|let|var)\\s+' .. n .. '\\s*=',
      '\\b' .. n .. '\\s*[:=]\\s*(async\\s+)?(function\\b|\\([^)]*\\)\\s*(=>|->))',
    }, '|')
  end

  local opts = { cwd = vim.loop.cwd() }

  local live_finder = finders.new_job(
    function(prompt)
      local pattern = build_pattern(prompt)
      if not pattern then return nil end
      return {
        'rg', '--color=never', '--no-heading', '--with-filename',
        '--line-number', '--column', '--smart-case', '--hidden',
        '--glob', '!.git/', '-e', pattern,
      }
    end,
    make_entry.gen_from_vimgrep(opts),
    nil,
    opts.cwd
  )

  pickers.new(opts, {
    prompt_title = 'Function definitions (live)',
    finder       = live_finder,
    previewer    = conf.grep_previewer(opts),
    sorter       = sorters.highlighter_only(opts),
  }):find()
end, { desc = 'Telescope search function definition across project' })
