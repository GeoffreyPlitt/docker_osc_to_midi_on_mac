# docker_audio_to_mac

This repository demonstrates low-latency bidirectional mapping of multitimbral MIDI input/output from Mac to a Docker container as OSC messages.
The Mac "owns" the midi deviec and the docker just sends/receives OSC.

## Quick Start

1. **Install dependencies**:
   ```bash
   pip install honcho
   brew install gum  # For interactive MIDI device selection
   ```

2. **Run the complete demo**:
   ```bash
   ./go.sh
   ```
   This will:
   - Interactively select your USB MIDI device
   - Start the complete OSC2MIDI bridge
   - Launch Docker container with OSC client

## Testing

### Interactive Mode (Recommended)
```bash
./go.sh
```

### Non-Interactive Mode (for CI/automation)
```bash
echo "test" | ./go.sh  # Automatically selects first MIDI device
```

### Quick Test (10 seconds)
```bash
timeout 10 bash -c 'echo "test" | ./go.sh'
```

## Individual Components

- **Mac Host**: Runs osc2midi bridge with interactive MIDI device selection
- **Docker Container**: OSC client with latency monitoring and traffic logging
- **OSC2MIDI Mapping**: 8-channel multitimbral note mapping + reverb control
- **Latency Monitor**: Ping/pong measurement every 10 seconds

### Mac Components:
- `find_midi_devices.sh` - Interactive USB MIDI device selector
- `mappings.omm` - OSC2MIDI configuration for 8 channels + reverb + ping
- `ping_sender.sh` - Sends latency ping every 10 seconds
- `run_mac_stuff.sh` - Main Mac orchestration script

### Docker Components:
- `pong_responder.sh` - Responds to pings and calculates latency
- `container_action.sh` - Main Docker container script
- JACK audio server for low-latency processing

## Script Call Tree

```
./go.sh
├── sources: ./find_midi_devices.sh
└── exec: honcho start
    ├── mac: ./run_mac_stuff.sh
    │   └── ./ping_sender.sh (backgrounded)
    │
    └── container: ./run_docker_stuff.sh
        └── ./run_docker.sh
            ├── sources: ./docker_config.sh
            ├── docker build (uses Dockerfile)
            │   └── copies into image:
            │       ├── container_action.sh
            │       └── pong_responder.sh
            └── docker run: ./container_action.sh
                └── ./pong_responder.sh (backgrounded)
```

**Mapping Examples:**
- MIDI Notes: `/midi/1 60 100` → Channel 1, Middle C, Velocity 100
- Reverb: `/reverb/2 0.7` → Channel 2, 70% reverb
- Latency: `/ping <timestamp>` → `/pong <timestamp> <latency_ms>`

## Requirements

- Docker
- Python with pip (for honcho)
- Homebrew
