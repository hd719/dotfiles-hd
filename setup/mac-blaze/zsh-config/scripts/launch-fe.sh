tmux new-session -d -s blaze-fe

tmux rename-window -t blaze:6 "dev"
tmux send-keys -t blaze:6 "cd ~/Developer/Blaze/monospace && nvm use 18.17.1; pnpm run dev" C-m

# Attach to the tmux session
tmux attach -t blaze-fe
