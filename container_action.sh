#!/bin/bash

set -ex

jackd -d dummy &
JACK_PID=$!
echo "JACK PID: $JACK_PID"

sleep 3

jack_lsp -c

echo "COMING SOON"
sleep 10

kill $JACK_PID 2>/dev/null || echo "Process cleanup completed"