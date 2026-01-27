#!/bin/bash

osascript <<EOF
tell application "iTerm"
    activate

    -- Get the current window, or create one if missing
    set W to current window
    if W = missing value then set W to create window with default profile

    -- Create tab for Sidekiq
    set T1 to W's current tab
    tell T1
        tell session 1
            write text "cd ~/Developer/Blaze/blaze-on-rails"
            write text "bundle exec sidekiq"
        end tell
    end tell

    -- Create tab for AnyCable
    set T2 to create tab with default profile
    tell T2
        tell session 1
            write text "cd ~/Developer/Blaze/blaze-on-rails"
            write text "bundle exec anycable --server-command \"anycable-go --headers=origin --port 3334 --max_message_size 300000 --enable_ws_compression\""
        end tell
    end tell

    -- Create tab for Rails
    set T3 to create tab with default profile
    tell T3
        tell session 1
            write text "cd ~/Developer/Blaze/blaze-on-rails"
            write text "bundle exec rails s"
        end tell
    end tell

    -- Create tab for Monospace Dev
    set T4 to create tab with default profile
    tell T4
        tell session 1
            write text "cd ~/Developer/Blaze/monospace"
            write text "nvm use 18.17.1; pnpm run dev"
        end tell
    end tell

    -- Create tab for Monospace Worker
    set T5 to create tab with default profile
    tell T5
        tell session 1
            write text "cd ~/Developer/Blaze/monospace"
            write text "nvm use 18.17.1; pnpm start-worker"
        end tell
    end tell

    -- Create tab for Blaze Frontend
    set T6 to create tab with default profile
    tell T6
        tell session 1
            write text "cd ~/Developer/Blaze/almanac-editor/apps/blaze"
            write text "nvm use 18.17.1; pnpm i; pnpm exec vite"
        end tell
    end tell
end tell
EOF
