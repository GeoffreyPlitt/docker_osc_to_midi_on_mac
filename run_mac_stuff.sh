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

echo "COMING SOON"
sleep 60