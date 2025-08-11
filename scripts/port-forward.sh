#!/bin/bash

# Create a new tmux session named 'temporal'
tmux new-session -d -s temporal

# Split the window vertically (side by side)
tmux split-window -h

# Run the first script in the left pane (pane 0)
tmux send-keys -t temporal:0.0 './scripts/port-forward-temporal-server.sh' Enter

# Run the second script in the right pane (pane 1)
tmux send-keys -t temporal:0.1 './scripts/port-forward-temporal-web.sh' Enter

# Attach to the session to view both panes
tmux attach-session -t temporal
