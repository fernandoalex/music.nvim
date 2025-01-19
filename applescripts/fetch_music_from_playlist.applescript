on run {thePlaylistName}
tell application "Music"
      set songList to {}
      set theTracks to tracks of playlist thePlaylistName
      repeat with aTrack in theTracks
        set songInfo to {name of aTrack & "\t" & artist of aTrack}
        set end of songList to songInfo
      end repeat
      set AppleScript's text item delimiters to ASCII character 10
      return songList as text
end tell
end run
