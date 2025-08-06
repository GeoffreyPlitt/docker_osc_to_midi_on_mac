#!/bin/bash

set -ex

jackd -d dummy &
JACK_PID=$!
echo "JACK PID: $JACK_PID"

sleep 3

jack_lsp -c

# Start OSC monitoring on the main port
echo "Starting OSC traffic monitor on port 9000..."
oscdump 9000 &
OSC_MONITOR_PID=$!

# Keep container running and show OSC traffic
trap "kill $OSC_MONITOR_PID $JACK_PID 2>/dev/null || true; exit 0" INT TERM

# Wait for processes
wait $OSC_MONITOR_PID