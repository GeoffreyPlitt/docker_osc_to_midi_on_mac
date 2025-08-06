#!/bin/bash

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo "Error: gum is not installed. Please install it with:"
    echo "brew install gum"
    exit 1
fi

echo "Finding USB MIDI devices..."

# Collect MIDI devices in an array
devices=()
device_ids=()

# Get all USB devices and check each one for MIDI capability
while IFS= read -r line; do
    # Extract device ID (format: Bus XXX Device XXX: ID XXXX:XXXX)
    device_id=$(echo "$line" | awk '{print $6}')
    vendor_id=$(echo "$device_id" | cut -d: -f1)
    product_id=$(echo "$device_id" | cut -d: -f2)
    
    # Get detailed USB info for this device
    usb_detail=$(lsusb -v -d "$device_id" 2>/dev/null)
    
    # Check if this device has MIDI interfaces (precise Class 1, SubClass 3, plus MIDI/audio strings)
    if echo "$usb_detail" | grep -qE "bInterfaceClass\s+1\s" && \
       echo "$usb_detail" | grep -qE "bInterfaceSubClass\s+3\s" && \
       echo "$usb_detail" | grep -qi "midi\|audio"; then
        
        # Extract manufacturer and product name from system_profiler
        manufacturer=$(system_profiler SPUSBDataType | grep -B5 -A5 "$vendor_id" | grep "Manufacturer:" | head -1 | sed 's/.*Manufacturer: //' | sed 's/ *$//')
        product_name=$(system_profiler SPUSBDataType | grep -B10 -A2 "$device_id" | grep -E "^\s*[^:]*:$" | tail -1 | sed 's/://g' | sed 's/^ *//')
        
        # Clean up names
        if [ -z "$manufacturer" ]; then
            manufacturer="Unknown"
        fi
        if [ -z "$product_name" ]; then
            product_name="Unknown Device"
        fi
        
        # Add to arrays
        device_display="$manufacturer - $product_name"
        devices+=("$device_display")
        device_ids+=("$device_id")
    fi
done < <(lsusb)

# Check if any MIDI devices were found
if [ ${#devices[@]} -eq 0 ]; then
    echo "No USB MIDI devices found."
    exit 1
fi

# Use gum to let user select a device or auto-select if piped input
echo "Select a MIDI device:"
if [ -t 0 ]; then
    # Interactive mode - TTY available
    selected_index=$(printf '%s\n' "${devices[@]}" | gum choose --selected.foreground="#00ff00" | while read -r line; do
        for i in "${!devices[@]}"; do
            if [[ "${devices[$i]}" == "$line" ]]; then
                echo "$i"
                break
            fi
        done
    done)
else
    # Non-interactive mode - use first device
    echo "Non-interactive mode detected, using first available MIDI device:"
    selected_index=0
    printf '%s\n' "${devices[@]}" | head -1
fi

# Get the selected device ID
DEVICE_ID="${device_ids[$selected_index]}"

if [ -n "$DEVICE_ID" ]; then
    echo
    echo "Selected device: ${devices[$selected_index]} ($DEVICE_ID)"
    echo "=========================="
    
    # Get Core MIDI device index (extract from device list, skipping header)
    CORE_MIDI_INDEX=$(./m2o --list 2>/dev/null | grep -E '^\s*\([0-9]+\):' | sed -n "$((selected_index + 1))p" | grep -oE '\([0-9]+\)' | tr -d '()' || echo "-1")
    
    if [ -z "$CORE_MIDI_INDEX" ] || [ "$CORE_MIDI_INDEX" = "-1" ]; then
        echo "Warning: Could not find Core MIDI device at position $((selected_index + 1))"
        CORE_MIDI_INDEX=-1
    else
        echo "Using Core MIDI device index: $CORE_MIDI_INDEX"
    fi
    
    # Export for use by other scripts
    export MIDI_DEVICE_ID="$DEVICE_ID"
    export MIDI_DEVICE_NAME="${devices[$selected_index]}"
    export CORE_MIDI_INDEX="$CORE_MIDI_INDEX"
    echo MIDI_DEVICE_ID="$MIDI_DEVICE_ID"
    echo MIDI_DEVICE_NAME="$MIDI_DEVICE_NAME"
    echo CORE_MIDI_INDEX="$CORE_MIDI_INDEX"
    
    # Extract key info efficiently
    lsusb -v -d "$DEVICE_ID" 2>/dev/null | awk '
    /idVendor/ { vendor = $0; gsub(/^[ \t]+/, "", vendor) }
    /idProduct/ { product = $0; gsub(/^[ \t]+/, "", product) }
    /bcdUSB/ { usb = $2 }
    /MaxPower/ { power = $2 }
    /iSerial/ && $3 { serial = $3 }
    /bInterfaceClass.*1/ { midi_class = "✓ MIDI Audio Class" }
    /bInterfaceSubClass.*3/ { midi_subclass = "✓ MIDI Streaming" }
    /bEndpointAddress.*0x.*OUT/ { ep_out++ }
    /bEndpointAddress.*0x.*IN/ { ep_in++ }
    END {
        print vendor; print product
        print "USB Version:", usb, "| Power:", power "mA"
        if (serial) print "Serial:", serial
        print midi_class; print midi_subclass
        if (ep_out || ep_in) printf "Endpoints: %d OUT, %d IN\n", ep_out, ep_in
    }'
else
    echo "No device selected."
    exit 1
fi