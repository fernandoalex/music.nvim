local M = {}

-- @param script string
function M.call_music(script)
    os.execute('osascript -e \'' .. script .. '\'')
end

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

-- @param music_list string
-- @return table
function M.make_music_to_list(music_list)
    local music_table = {}

    for chunk in music_list:gmatch("[^,]+") do
        chunk = chunk:match("^%s*(.-)%s*$")
        assert(
            chunk:match("^(.-)\t+(.*)$"),
            "Expected a tab-separated title and artist, but got: " .. chunk
        )
        local title, artist = chunk:match("^(.-)\t+(.*)$")
        table.insert(music_table, { title, artist })
    end

    return music_table
end

function M.fetch_music_from_playlist(playlist_name)
    local music_list = {}
    local script = [[
    osascript -e 'tell application "Music"
      set songList to {}
      set theTracks to tracks of playlist "]] .. playlist_name .. [["
      repeat with aTrack in theTracks
        set songInfo to {name of aTrack & "\t" & artist of aTrack}
        set end of songList to songInfo
      end repeat
      return songList
    end tell'
    ]]
    local handle = io.popen(script)
    local result = handle:read("*a")
    print(result)
    handle:close()

    M.make_music_to_list(result)

    return music_list
end

function M.play_playlist(playlist_name)
    local script = string.format('tell application "Music" to play (some playlist whose name is "%s")', playlist_name)
    M.call_music(script)
    M.call_music([[tell application "Music" to shuffle enabled]])
end

-- @param optional? song {name: string, playlist: string}
function M.play_track(song)
    if not song or song == "" then
        M.call_music([[tell application "Music" to play]])
        return nil
    end
    local script = string.format(
        [[tell application "Music" to play track "%s" of playlist "%s"]],
        song.name, song.playlist
    )
    M.call_music(script)
end

function M.pause_track()
    M.call_music([[tell application "Music" to pause]])
end

function M.next_track()
    M.call_music([[tell application "Music" to next track]])
end

function M.previous_track()
    M.call_music([[tell application "Music" to previous track]])
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

function M.show_songs_in_new_buffer()
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
                print(selection[1])
                local songs = M.fetch_music_from_playlist(selection[1])
                local formatted_lines = {}
                print(songs)
                for _, item in ipairs(songs) do
                    table.insert(formatted_lines, string.format('{title: "%s", artist: "%s"}', item.title, item.artist))
                end
                vim.cmd("vnew")
                print(formatted_lines)
                vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
                return true
            end)
            return true
        end,
    }):find()
end

return M
