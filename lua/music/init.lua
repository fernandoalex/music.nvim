-- TODO break this into multiple files because this is a mess
local M = {}

local function get_repo_root_dir()
    local current_file = debug.getinfo(1, "S").source:match("@(.*)")
    local current_dir = vim.fn.fnamemodify(current_file, ":h")
    -- Up one level from 'init.lua' => my_plugin/, then up again => repo root.
    local root_dir = vim.fn.fnamemodify(current_dir, ":h:h")
    return root_dir
end

M.repo_root = get_repo_root_dir()
M.applescripts_dir = M.repo_root .. "/applescripts"

local function run_applescript(script_name, ...)
    local script_path = M.applescripts_dir .. "/" .. script_name

    -- Build our shell command. We pass each argument to AppleScript in turn.
    -- AppleScript will receive them in `on run {arg1, arg2, ...}`.
    local cmd = string.format("osascript %q", script_path)
    for _, arg in ipairs({ ... }) do
        cmd = cmd .. " " .. string.format("%q", arg)
    end
    cmd = cmd .. " 2>&1"

    local pipe = assert(io.popen(cmd, "r"))
    local output = pipe:read("*a") or ""
    pipe:close()

    return output
end

-- @param script string
function M.call_music(script)
    os.execute('osascript -e \'' .. script .. '\'')
end

function M.fetch_playlists()
    local cmd = [[osascript -e 'tell application "Music" to get name of playlists']]
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    local playlists = {}
    for playlist in result:gmatch('([^,]+)') do
        table.insert(playlists, playlist:match("^%s*(.-)%s*$")) -- Trim whitespace
    end
    return playlists
end

-- @param music_list string
-- @return table
function M.make_music_to_list(music_list)
    local music_table = {}

    for chunk in music_list:gmatch("[^\r\n]+") do
        chunk = chunk:match("^%s*(.-)%s*$")
        assert(
            chunk:match("^(.-)\t(.*)$"),
            "Expected a tab-separated title and artist, but got: " .. chunk
        )
        local title, artist = chunk:match("^(.-)\t(.*)$")
        table.insert(music_table, { title = title, artist = artist })
    end

    return music_table
end

-- @param playlist_name string
-- @return table
function M.fetch_music_from_playlist(playlist_name)
    local result = run_applescript("fetch_music_from_playlist.applescript", playlist_name)
    return M.make_music_to_list(result)
end

-- @param playlist_name string
function M.play_playlist(playlist_name)
    -- TODO move this to scripts folder
    local script = string.format([[
        tell application "Music"
            set shuffle enabled to true
            set shuffle mode to songs
            play (some playlist whose name is "%s")
        end tell
    ]], playlist_name)
    M.call_music(script)
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

-- Play a selected playlist
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
                local songs = M.fetch_music_from_playlist(selection[1])
                local formatted_lines = {}
                for _, item in ipairs(songs) do
                    table.insert(formatted_lines, string.format('{title: "%s", artist: "%s"}', item.title, item.artist))
                end
                vim.cmd("vnew")
                vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
                return true
            end)
            return true
        end,
    }):find()
end

return M
