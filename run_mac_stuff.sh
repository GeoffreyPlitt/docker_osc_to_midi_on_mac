#!/bin/bash

set -ex

echo "Setting up Mac host dependencies..."

if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew not found. Please install Homebrew first:"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
fi

echo "Checking and installing dependencies..."

# Check if osc2midi is installed, install if not
if ! command -v osc2midi &> /dev/null; then
    echo "osc2midi not found. Installing osc2midi..."
    git clone https://github.com/GeoffreyPlitt/OSC2MIDI
    cd OSC2MIDI
    mkdir build
    cd build
    cmake ..
    make
    sudo make install
    cd ../../
    rm -rf OSC2MIDI
    echo "osc2midi installation completed."
else
    echo "osc2midi is installed."
fi

# MIDI device already selected in go.sh
echo "Starting OSC2MIDI bridge..."

# Check if JACK is already running
if ! jack_lsp &>/dev/null; then
    echo "Starting JACK with Core Audio and Core MIDI..."
    jackd -d coreaudio -r 44100 -p 256 &
    JACK_PID=$!
    sleep 2
    
    # Load Core MIDI driver
    jack_load coremidi -t slave
    sleep 1
else
    echo "JACK is already running"
fi

# Start OSC server for receiving pong responses
echo "Starting OSC server on port 9001..."
oscdump 9001 &
OSC_SERVER_PID=$!

# Start osc2midi with verbose logging and our mapping file
echo "Starting osc2midi with verbose logging..."
osc2midi -v -m ./mappings.omm -name "osc2midi" -p 9000 -a "127.0.0.1:9001" &
OSC2MIDI_PID=$!

sleep 2

# List available JACK MIDI ports
echo "Available JACK MIDI ports:"
jack_lsp -t 2>/dev/null | grep midi || echo "No MIDI ports found in JACK"

# Try to connect MIDI hardware to osc2midi
# This would need proper JACK MIDI port names

# Start ping sender for latency monitoring
echo "Starting latency ping sender..."
./ping_sender.sh &
PING_PID=$!

# Keep everything running
echo "OSC2MIDI bridge running. Press Ctrl+C to stop."
echo "Play notes on your MIDI device to test!"
echo "OSC messages on port 9000, responses on port 9001"

# Wait for interrupt
trap "echo 'Stopping...'; kill $OSC2MIDI_PID $PING_PID $OSC_SERVER_PID 2>/dev/null || true; exit 0" INT
wait