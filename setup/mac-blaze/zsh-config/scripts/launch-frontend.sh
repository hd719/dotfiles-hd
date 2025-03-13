#!/bin/bash

# # Directory to cd into
DIR="/Users/hameldesai/Developer/Blaze/almanac-editor/apps/blaze"

osascript <<EOF
tell application "iTerm"
    activate

    -- Get the current window, or create one if missing
    set W to current window
    if W = missing value then set W to create window with default profile

    -- Get the current tab
    set T to W's current tab

    -- Write commands to each session in the tab
    tell session 1 of T
        write text "cd ~/Developer/Blaze/almanac-editor/apps/blaze"
        write text "nvm use 18.17.1; pnpm i; pnpm exec vite"
    end tell
end tell
EOF
