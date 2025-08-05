#!/bin/bash

set -ex

jackd -d dummy &
JACK_PID=$!
echo "JACK PID: $JACK_PID"

sleep 3

jack_lsp -c

# Pong responder is already in container from Dockerfile
# No need to copy or chmod

# Start pong responder for latency monitoring
echo "Starting pong responder for latency monitoring..."
./pong_responder.sh &
PONG_PID=$!

# Start OSC monitoring on the main port
echo "Starting OSC traffic monitor on port 9000..."
oscdump 9000 &
OSC_MONITOR_PID=$!

echo "Listening for OSC messages and responding to pings..."
echo "Docker container ready for OSC communication!"
echo "  - Main OSC traffic: port 9000"
echo "  - Ping/pong latency: port 9002"

# Keep container running and show OSC traffic
trap "echo 'Stopping container...'; kill $PONG_PID $OSC_MONITOR_PID 2>/dev/null || true; exit 0" INT TERM

# Wait for processes
wait $PONG_PID $OSC_MONITOR_PID

kill $JACK_PID 2>/dev/null || echo "Process cleanup completed"