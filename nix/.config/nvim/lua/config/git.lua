local function commit_url_under_cursor()
  local word = vim.fn.expand('<cword>')
  if not word:match('^%x+$') or #word < 7 then
    vim.notify('Not a commit hash under cursor: ' .. word, vim.log.levels.WARN)
    return
  end

  local buf_dir = vim.fn.expand('%:p:h')
  if buf_dir == '' then buf_dir = vim.fn.getcwd() end

  local sha = vim.fn.systemlist({ 'git', '-C', buf_dir, 'rev-parse', word })[1]
  if vim.v.shell_error ~= 0 or not sha or sha == '' then
    vim.notify('git rev-parse failed for ' .. word, vim.log.levels.WARN)
    return
  end

  local remote = vim.fn.systemlist({ 'git', '-C', buf_dir, 'remote', 'get-url', 'origin' })[1]
  if vim.v.shell_error ~= 0 or not remote or remote == '' then
    vim.notify('No origin remote', vim.log.levels.WARN)
    return
  end

  local base
  local host, path = remote:match('^git@([^:]+):(.+)$')
  if host then
    path = path:gsub('%.git$', '')
    if host == 'ssh.dev.azure.com' then
      local org, proj, repo = path:match('^v3/([^/]+)/([^/]+)/(.+)$')
      if org then
        base = string.format('https://dev.azure.com/%s/%s/_git/%s', org, proj, repo)
      end
    else
      base = string.format('https://%s/%s', host, path)
    end
  else
    local url = remote:gsub('^ssh://', 'https://'):gsub('^git://', 'https://')
    url = url:gsub('%.git$', '')
    url = url:gsub('^(https?://)[^/@]+@', '%1')
    base = url
  end

  if not base then
    vim.notify('Could not parse remote: ' .. remote, vim.log.levels.WARN)
    return
  end

  local segment = base:match('bitbucket%.org') and 'commits' or 'commit'
  local url = string.format('%s/%s/%s', base, segment, sha)

  vim.fn.setreg('+', url)
  vim.fn.setreg('*', url)
  vim.notify(url)
end

vim.keymap.set('n', '<leader>gy', commit_url_under_cursor,
  { desc = 'Yank commit URL for hash under cursor' })

local function diff_current_file(staged)
  local file = vim.fn.expand('%:p')
  if file == '' then
    vim.notify('No file in current buffer', vim.log.levels.WARN)
    return
  end
  local flag = staged and '--staged ' or ''

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width, height = height, col = col, row = row,
    border = 'rounded', style = 'minimal',
    title = staged and ' git diff --staged ' or ' git diff ',
    title_pos = 'center',
  })
  vim.api.nvim_win_set_option(win, 'winhighlight',
    'NormalFloat:NormalFloat,FloatBorder:FloatBorder')

  vim.fn.jobstart(
    'git -c delta.side-by-side=false diff --no-ext-diff ' .. flag .. '-- ' .. vim.fn.shellescape(file),
    { term = true }
  )
  vim.keymap.set({ 'n', 't' }, 'q', '<cmd>close<cr>',
    { buffer = buf, nowait = true, silent = true })
  vim.cmd('startinsert')
end

vim.keymap.set('n', '<leader>gd', function() diff_current_file(false) end,
  { desc = 'Show git diff of current file' })
vim.keymap.set('n', '<leader>gD', function() diff_current_file(true) end,
  { desc = 'Show git diff --staged of current file' })

-- Full-file blame: scroll-bound side panel with one blame entry per line.
-- Press q in the panel to close it. Inline blame comes from git-blame.nvim.
local function blame_file()
  local src = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(src)
  if file == '' then return end
  local out = vim.fn.systemlist({ 'git', '-C', vim.fn.fnamemodify(file, ':h'), 'blame',
    '--date=short', '-w', '--', file })
  if vim.v.shell_error ~= 0 then
    vim.notify('git blame failed: ' .. table.concat(out, '\n'), vim.log.levels.WARN)
    return
  end
  local lines, width = {}, 0
  for _, l in ipairs(out) do
    -- strip the trailing "<lineno>) <code>" so only the blame info remains
    local info = l:match('^(.-)%s+%d+%) ') or l
    info = info:gsub('%(', ''):gsub('%s+$', '')
    lines[#lines + 1] = info
    width = math.max(width, vim.fn.strdisplaywidth(info))
  end
  local src_win = vim.api.nvim_get_current_win()
  local view = vim.fn.winsaveview()
  vim.cmd('vertical leftabove new')
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype, vim.bo[buf].bufhidden = 'nofile', 'wipe'
  vim.bo[buf].modifiable = false
  local win = vim.api.nvim_get_current_win()
  vim.wo[win].number, vim.wo[win].wrap, vim.wo[win].foldcolumn = false, false, '0'
  vim.api.nvim_win_set_width(win, math.min(width + 1, 70))
  for _, w in ipairs({ win, src_win }) do vim.wo[w].scrollbind = true end
  vim.cmd('syncbind')
  vim.api.nvim_win_call(win, function() vim.fn.winrestview({ topline = view.topline, lnum = view.lnum }) end)
  vim.keymap.set('n', 'q', function()
    vim.wo[src_win].scrollbind = false
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, nowait = true, silent = true })
  vim.api.nvim_set_current_win(src_win)
end

vim.keymap.set('n', '<leader>gb', blame_file, { desc = 'Git blame every line (side panel)' })
vim.keymap.set('n', '<leader>gi', '<cmd>GitBlameToggle<cr>', { desc = 'Toggle inline git blame' })
vim.keymap.set('n', '<leader>gB', '<cmd>GitBlameOpenCommitURL<cr>',
  { desc = 'Open blamed commit of current line in browser' })
