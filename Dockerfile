FROM debian:bookworm-slim

# Install runtime dependencies and build tools for osmid
RUN apt-get update && apt-get install -y \
    jackd2 \
    liblo-tools \
    socat \
    bc \
    git \
    cmake \
    g++ \
    libasound2-dev \
    libx11-dev \
    && rm -rf /var/lib/apt/lists/*

# Build and install osmid from GeoffreyPlitt's fork
RUN git clone https://github.com/GeoffreyPlitt/osmid.git /tmp/osmid && \
    cd /tmp/osmid && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/osmid

# Build and install osc2midi from source
RUN apt-get update && apt-get install -y \
    liblo-dev \
    libjack-jackd2-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/* && \
    git clone https://github.com/ssj71/OSC2MIDI.git /tmp/osc2midi && \
    cd /tmp/osc2midi && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/osc2midi

COPY container_action.sh .
RUN chmod +x container_action.sh

CMD ["./container_action.sh"]