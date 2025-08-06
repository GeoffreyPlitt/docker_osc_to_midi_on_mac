#!/bin/bash

# Interactive launcher script
# First select MIDI device, then run honcho

set -e

echo "=== OSC2MIDI Bridge Setup ==="
echo "First, let's select your MIDI device..."

# Run MIDI device selection interactively and source the exports
source ./find_midi_devices.sh

echo ""
echo "Now starting the complete system..."
echo "Press Ctrl+C to stop everything"
echo ""

# Start honcho with the system
exec honcho start