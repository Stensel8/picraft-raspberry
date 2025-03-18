#!/bin/bash
# Script to pre-generate chunks for overworld, nether and the_end

# Overworld
tmux send-keys -t mc-server "chunky world world" ENTER
tmux send-keys -t mc-server "chunky radius 10000" ENTER
tmux send-keys -t mc-server "chunky start" ENTER
tmux send-keys -t mc-server "chunky confirm" ENTER

# Nether
tmux send-keys -t mc-server "chunky world world_nether" ENTER
tmux send-keys -t mc-server "chunky radius 10000" ENTER
tmux send-keys -t mc-server "chunky start" ENTER
tmux send-keys -t mc-server "chunky confirm" ENTER

# The End
tmux send-keys -t mc-server "chunky world world_the_end" ENTER
tmux send-keys -t mc-server "chunky radius 10000" ENTER
tmux send-keys -t mc-server "chunky start" ENTER
tmux send-keys -t mc-server "chunky confirm" ENTER
