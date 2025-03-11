#!/bin/bash

# # Directory to cd into
DIR="/Users/hameldesai/Developer/Blaze/blaze-on-rails"

osascript <<EOF
tell application "iTerm"
    activate

    -- Get the current window, or create one if missing
    set W to current window
    if W = missing value then set W to create window with default profile

    -- Split horizontally 3 times
    tell W's current session
        split horizontally with default profile
        split horizontally with default profile
    end tell

    -- Get the current tab
    set T to W's current tab

    -- Write commands to each session in the tab
    tell session 1 of T
        write text "cd ~/Developer/Blaze/blaze-on-rails"
        write text "bundle exec sidekiq"
    end tell
    tell session 2 of T
        write text "cd ~/Developer/Blaze/blaze-on-rails"
        write text "bundle exec anycable --server-command \"anycable-go --headers=origin --port 3334 --max_message_size 300000 --enable_ws_compression\""
    end tell
    tell session 3 of T
        write text "cd ~/Developer/Blaze/blaze-on-rails"
        write text "bundle exec rails s"
    end tell
end tell
EOF
