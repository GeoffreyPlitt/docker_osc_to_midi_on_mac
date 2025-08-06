FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    jackd2 \
    liblo-tools \
    socat \
    bc \
    && rm -rf /var/lib/apt/lists/*

COPY container_action.sh .
RUN chmod +x container_action.sh

CMD ["./container_action.sh"]