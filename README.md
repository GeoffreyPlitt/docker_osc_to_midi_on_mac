# Docker OSC to MIDI on Mac

This repository demonstrates low-latency bidirectional mapping of multitimbral MIDI input/output from Mac to a Docker container as OSC messages.
The Mac "owns" the MIDI device and the Docker container sends/receives OSC.

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

## Architecture

### Data Flow
1. **MIDI Input** (Mac) → `m2o` (osmid) → **OSC Messages** → Docker Container
2. Docker Container receives OSC on port 9000
3. `osc2midi` converts OSC to MIDI using mapping rules
4. JACK audio server processes MIDI events

### Individual Components

- **Mac Host**: Runs osmid's `m2o` bridge to convert MIDI to OSC
  - Interactive MIDI device selection via `gum`
  - Sends OSC messages in format: `/midi/{channel}/{message_type}`
  
- **Docker Container**: Runs OSC2MIDI to receive and process OSC messages
  - JACK audio server with dummy driver (no physical audio hardware needed)
  - Mapping file supports all MIDI channels (0-15)
  - Monitor mode available for debugging

### Mac Components:
- `find_midi_devices.sh` - Interactive USB MIDI device selector using `gum`
- `run_mac_stuff.sh` - Main Mac orchestration script
- `m2o` - MIDI to OSC converter (built from GeoffreyPlitt's osmid fork)

### Docker Components:
- `container_action.sh` - Main Docker container script
- `multitimbral.omm` - OSC2MIDI mapping configuration
- JACK audio server for MIDI processing
- `osc2midi` - OSC to MIDI converter

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

## Debugging

Run `echo whatever | ./go.sh` to start it with your default midi device.

## Requirements

- Docker
- Python with pip (for honcho)
- Homebrew
