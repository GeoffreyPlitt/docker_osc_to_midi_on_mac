#!/bin/bash

set -ex

jackd -d dummy &
JACK_PID=$!
echo "JACK PID: $JACK_PID"

sleep 3

jack_lsp -c

PORT=9000
echo "Starting OSC traffic monitor on port $PORT..."
# socat -v UDP-LISTEN:9000,fork - &
oscdump $PORT &

OSC_MONITOR_PID=$!

# Keep container running and show OSC traffic
trap "kill $OSC_MONITOR_PID $JACK_PID 2>/dev/null || true; exit 0" INT TERM

# Wait for processes
wait $OSC_MONITOR_PID