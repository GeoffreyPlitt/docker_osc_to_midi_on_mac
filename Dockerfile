FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    jackd2 \
    liblo-tools \
    bc \
    && rm -rf /var/lib/apt/lists/*

COPY container_action.sh .
COPY pong_responder.sh .
RUN chmod +x container_action.sh pong_responder.sh

CMD ["./container_action.sh"]