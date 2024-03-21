local M = {}

function M.fetch_playlists()
  local playlists = {}
  local handle = io.popen('osascript -e \'tell application "Music" to get name of playlists\'')
  local result = handle:read("*a") -- Read the entire output as a single string
  handle:close()
  for playlist in string.gmatch(result, '([^,]+)') do
    table.insert(playlists, playlist:match("^%s*(.-)%s*$")) -- Trim whitespace
  end
  return playlists
end

function M.play_playlist(playlist_name)
  local script = string.format('tell application "Music" to play (some playlist whose name is "%s")', playlist_name)
  os.execute('osascript -e \'' .. script .. '\'')
  os.execute('osascript -e \'tell application "Music" to shuffle enabled\'')
end

function M.play_track()
  os.execute('osascript -e \'tell application "Music" to play\'')
end

function M.pause_track()
  os.execute('osascript -e \'tell application "Music" to pause\'')
end

function M.next_track()
  os.execute('osascript -e \'tell application "Music" to next track\'')
end

function M.previous_track()
  os.execute('osascript -e \'tell application "Music" to previous track\'')
end

function M.open_playlist_picker()
  local playlists = M.fetch_playlists()
  require('telescope.pickers').new({}, {
    prompt_title = "playlist:",
    finder = require('telescope.finders').new_table({
      results = playlists,
    }),
    sorter = require('telescope.config').values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      local action_state = require('telescope.actions.state')
      local actions = require('telescope.actions')
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        M.play_playlist(selection[1])
      end)
      return true
    end,
  }):find()
end

return M
