#!/bin/bash

set -ex

# Start JACK with dummy driver (perfect for containers - still processes MIDI)
jackd -d dummy -r 48000 -p 1024 &
JACK_PID=$!
echo "JACK PID: $JACK_PID"

sleep 3

jack_lsp -c

PORT=9000

# Listen for OSC messages with verbosity and unbuffered output
stdbuf -o0 -e0 osc2midi -v -p $PORT -name "OSC_Bridge" -m /multitimbral.omm -o2m 2>&1 | stdbuf -o0 sed 's/^/[osc2midi] /' &
OSC2MIDI_PID=$!
sleep 2

#list available JACK MIDI ports.
jack_lsp -t | grep midi

# Show all JACK connections
jack_lsp -c | grep -A2 "OSC_Bridge"

# First try aseqdump if available (shows ALSA MIDI events)
which aseqdump && (echo "Starting aseqdump..." && aseqdump -p 0 2>&1 | stdbuf -o0 sed 's/^/[aseqdump] /' &)

# Monitor MIDI events from the OSC_Bridge output with unbuffered output
echo "Starting jack_midi_dump..."
stdbuf -o0 -e0 jack_midi_dump "OSC_Bridge:midi_out" 2>&1 | stdbuf -o0 sed 's/^/[jack_midi_dump] /' &
MIDI_DUMP_PID=$!

# Also add oscdump for debugging OSC messages coming in
# NOTE: Can't run this as it conflicts with osc2midi on port 9000
# stdbuf -o0 -e0 oscdump $PORT 2>&1 | stdbuf -o0 sed 's/^/[oscdump] /' &
# OSCDUMP_PID=$!

# Keep container running and show OSC traffic
trap "kill $OSC2MIDI_PID $MIDI_DUMP_PID $JACK_PID 2>/dev/null || true; exit 0" INT TERM

# Wait for processes
wait $OSC2MIDI_PID