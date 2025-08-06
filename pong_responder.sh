#!/bin/bash

# Pong responder for latency monitoring
# Listens for ping messages and responds with pong, calculating latency

set -e

MAC_HOST="host.docker.internal"
MAC_PORT="9001"
LISTEN_PORT="9004"  # Use different port to avoid conflict with Mac ping sender

EXISTING_PID=$(lsof -ti:$LISTEN_PORT 2>/dev/null || true)
if [ -n "$EXISTING_PID" ]; then
    echo "Killing process $EXISTING_PID using port $LISTEN_PORT"
    kill -9 $EXISTING_PID 2>/dev/null || true
    sleep 1
fi

echo "Starting pong responder listening on port $LISTEN_PORT..."
echo "Will respond to Mac at $MAC_HOST:$MAC_PORT"

# Start oscdump in background to listen for ping messages
oscdump "$LISTEN_PORT" | while read -r line; do
    # Check if this is a ping message
    if echo "$line" | grep -q "/ping"; then
        # Extract timestamp from the ping message (integer format)
        PING_TIMESTAMP=$(echo "$line" | grep -o '[0-9]\+' | tail -1)
        
        if [ -n "$PING_TIMESTAMP" ]; then
            # Get current time
            CURRENT_TIME=$(date +%s)
            
            # Calculate latency in seconds 
            LATENCY=$(echo "$CURRENT_TIME - $PING_TIMESTAMP" | bc)
            
            # Send pong response back to Mac
            oscsend "$MAC_HOST" "$MAC_PORT" "/pong" "f" "$PING_TIMESTAMP" "f" "$LATENCY"
            
            printf "Ping received: %s, Latency: %s seconds\n" "$PING_TIMESTAMP" "$LATENCY"
        fi
    fi
done