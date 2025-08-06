#!/bin/bash

set -ex

# Start JACK with dummy driver (perfect for containers - still processes MIDI)
jackd -d dummy -r 48000 -p 1024 &
JACK_PID=$!
echo "JACK PID: $JACK_PID"

sleep 3

jack_lsp -c

PORT=9000

# OSC2MIDI - Listen for OSC messages with verbosity and monitor mode (just print, don't create MIDI)
stdbuf -o0 -e0 osc2midi -v -mon -p $PORT -m /multitimbral.omm 2>&1 | \
  grep '/midi/' | \
  egrep --line-buffered -v 'clock|active_sensing' | \
  stdbuf -o0 sed 's/^/[osc2midi] /' &
OSC2MIDI_PID=$!
sleep 2

# No MIDI ports in monitor mode, skip checking

# Since we're in monitor mode, no MIDI ports will be created
echo "Running in monitor mode - OSC messages will be printed to stdout"

# Keep container running and show OSC traffic
trap "kill $OSC2MIDI_PID $MIDI_DUMP_PID $JACK_PID 2>/dev/null || true; exit 0" INT TERM

# Wait for processes
wait $OSC2MIDI_PID