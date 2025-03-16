#!/bin/zsh

# Start a new tmux session named "blaze-backend"
tmux new-session -d -s blaze-backend

# Create a window for Sidekiq and run the command
tmux rename-window -t blaze-backend:0 "sidekiq"
tmux send-keys -t blaze-backend:0 "cd ~/Developer/Blaze/blaze-on-rails && bundle exec sidekiq" C-m

# Create a window for AnyCable and run the command
tmux new-window -t blaze-backend:1 -n "anycable"
tmux send-keys -t blaze-backend:1 "cd ~/Developer/Blaze/blaze-on-rails && bundle exec anycable --server-command \"anycable-go --headers=origin --port 3334 --max_message_size 300000 --enable_ws_compression\"" C-m

# Create a window for Rails and run the command
tmux new-window -t blaze-backend:2 -n "rails"
tmux send-keys -t blaze-backend:2 "cd ~/Developer/Blaze/blaze-on-rails && bundle exec rails s" C-m

# Attach to the tmux session
tmux attach -t blaze-backend
