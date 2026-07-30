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
