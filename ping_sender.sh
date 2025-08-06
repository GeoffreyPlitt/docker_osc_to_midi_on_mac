#!/bin/bash

# Ping sender for latency monitoring
# Sends ping with timestamp to Docker container every 10 seconds

set -e

HOST="127.0.0.1"
PORT="9004"  # Direct to Docker container, not through osc2midi

echo "Starting ping sender to $HOST:$PORT (every 10 seconds)..."

while true; do
    # Get current timestamp in seconds (as integer for oscsend)
    TIMESTAMP=$(date +%s)
    
    # Send ping message to Docker container
    oscsend "$HOST" "$PORT" "/ping" "f" "$TIMESTAMP"
    
    echo "Sent ping: $TIMESTAMP"
    
    # Wait 10 seconds before next ping
    sleep 10
done