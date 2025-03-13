#!/bin/bash

# # Directory to cd into
DIR="/Users/hameldesai/Developer/Blaze/monospace"

osascript <<EOF
tell application "iTerm"
    activate

    -- Get the current window, or create one if missing
    set W to current window
    if W = missing value then set W to create window with default profile

    -- Split horizontally 2 times
    tell W's current session
        split horizontally with default profile
    end tell

    -- Get the current tab
    set T to W's current tab

    -- Write commands to each session in the tab
    tell session 1 of T
        write text "cd ~/Developer/Blaze/monospace"
        write text "nvm use 18.17.1; pnpm run dev"
    end tell
    tell session 2 of T
        write text "cd ~/Developer/Blaze/monospace"
        write text "nvm use 18.17.1; pnpm start-worker"
    end tell
end tell
EOF
