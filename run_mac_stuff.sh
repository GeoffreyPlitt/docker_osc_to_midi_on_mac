#!/bin/bash

set -e

echo "Setting up Mac host dependencies..."

if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew not found. Please install Homebrew first:"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
fi

# Check for osmid (Core MIDI - preferred over osc2midi)
if [ -f "./o2m" ] && [ -f "./m2o" ]; then
    echo "osmid is installed (preferred for macOS Core MIDI)."
else
    echo "osmid not found. Installing osmid from GeoffreyPlitt's fork..."
    
    # Build osmid from GeoffreyPlitt's fixed fork
    TEMP_DIR=$(mktemp -d)
    echo "Cloning osmid to $TEMP_DIR..."
    git clone https://github.com/GeoffreyPlitt/osmid.git "$TEMP_DIR/osmid"
    cd "$TEMP_DIR/osmid"
    mkdir build
    cd build
    echo "Building osmid..."
    cmake ..
    make
    
    # Install binaries to local directory
    echo "Installing osmid binaries to project directory..."
    cp o2m m2o /Users/giro/docker_osc_to_midi_on_mac/
    cd /Users/giro/docker_osc_to_midi_on_mac
    rm -rf "$TEMP_DIR"
    echo "osmid installation completed."
fi

echo "Starting OSC server..."
oscdump 9001 &
OSC_SERVER_PID=$!

echo "Starting osmid m2o bridge (Core MIDI)..."

# Use CORE_MIDI_INDEX from device selection, fallback to 0
MIDI_INDEX=${CORE_MIDI_INDEX:-0}

M2O_CMD="./m2o --midiin $MIDI_INDEX --oschost 127.0.0.1 --oscport 9000 --monitor 1"
echo "DEBUG: About to run: $M2O_CMD"
$M2O_CMD &
M2O_PID=$!

# Wait for interrupt
trap "echo 'Stopping...'; kill $M2O_PID $OSC_SERVER_PID $JACK_PID 2>/dev/null || true; exit 0" INT
wait