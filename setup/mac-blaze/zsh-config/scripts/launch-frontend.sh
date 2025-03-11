#!/bin/bash

# # Directory to cd into
DIR="/Users/hameldesai/Developer/Blaze/almanac-editor/apps/blaze"

osascript <<EOF
tell application "iTerm"
    activate

    -- Get the current window, or create one if missing
    set W to current window
    if W = missing value then set W to create window with default profile

    -- Split horizontally 1 times
    tell W's current session
        split horizontally with default profile
    end tell

    -- Get the current tab
    set T to W's current tab

    -- Write commands to each session in the tab
    tell session 1 of T
        write text "cd ~/Developer/Blaze/almanac-editor/apps/blaze"
        write text "nvm use 16.5.0; pnpm i; pnpm exec vite"
    end tell
    tell session 2 of T
        write text "cd ~/Developer/Blaze/almanac-editor/apps/blaze"
    end tell
end tell
EOF
