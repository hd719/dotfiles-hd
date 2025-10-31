#!/bin/zsh

# Start a new tmux session named "blaze"
tmux new-session -d -s blaze

# Create a window for Sidekiq and run the command
tmux rename-window -t blaze:1 "sidekiq"
tmux send-keys -t blaze:1 "cd ~/Developer/Blaze/blaze-on-rails && bundle exec sidekiq" C-m

# Create a window for AnyCable and run the command
tmux new-window -t blaze:2 -n "anycable"
tmux send-keys -t blaze:2 "cd ~/Developer/Blaze/blaze-on-rails && bundle exec anycable --server-command \"anycable-go --headers=origin --port 3334 --max_message_size 300000 --enable_ws_compression\"" C-m

# Create a window for Rails and run the command
tmux new-window -t blaze:3 -n "rails"
tmux send-keys -t blaze:3 "cd ~/Developer/Blaze/blaze-on-rails && bundle exec rails s" C-m


tmux new-window -t blaze:4 -n "monospace-dev"
tmux send-keys -t blaze:4 "cd ~/Developer/Blaze/monospace && nvm use 18.17.1; pnpm run dev" C-m

tmux new-window -t blaze:5 -n "monospace-worker"
tmux send-keys -t blaze:5 "cd ~/Developer/Blaze/monospace && nvm use 18.17.1; pnpm start-worker" C-m

tmux new-window -t blaze:6 -n "blaze-fe"
tmux send-keys -t blaze:6 "cd ~/Developer/Blaze/almanac-editor/apps/blaze && nvm use 18.17.1; pnpm i; pnpm exec vite" C-m

# Attach to the tmux session
tmux attach -t blaze
