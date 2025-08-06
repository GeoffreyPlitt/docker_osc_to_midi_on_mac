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

- **Mac Host**: Runs osmid "m2o" bridge with interactive MIDI device selection
- **Docker Container**: Runs OSC2MIDI with mapping file specifying 8-channel multitimbral notes + reverb control

### Mac Components:
- `find_midi_devices.sh` - Interactive USB MIDI device selector
- `mappings.omm` - OSC2MIDI configuration for 8 channels, etc
- `run_mac_stuff.sh` - Main Mac orchestration script

### Docker Components:
- `container_action.sh` - Main Docker container script
- JACK audio server for low-latency processing

## Script Call Tree

```
./go.sh
├── sources: ./find_midi_devices.sh
└── exec: honcho start
    ├── mac: ./run_mac_stuff.sh
    │
    └── container: ./run_docker_stuff.sh
        └── ./run_docker.sh
            ├── sources: ./docker_config.sh
            ├── docker build (uses Dockerfile)
            │   └── copies into image:
            │       ├── container_action.sh
            └── docker run: ./container_action.sh
```

**Mapping Examples:**
- MIDI Notes: `/midi/1 60 100` → Channel 1, Middle C, Velocity 100
- Reverb: `/reverb/2 0.7` → Channel 2, 70% reverb

## Requirements

- Docker
- Python with pip (for honcho)
- Homebrew
