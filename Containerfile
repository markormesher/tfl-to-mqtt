FROM docker.io/golang:1.25.3@sha256:8c945d3e25320e771326dafc6fb72ecae5f87b0f29328cbbd87c4dff506c9135 AS builder
WORKDIR /app

ARG CGO_ENABLED=0

COPY go.mod go.sum ./
RUN go mod download

COPY ./cmd ./cmd

RUN go build -o ./build/main ./cmd/...

# ---

FROM ghcr.io/markormesher/scratch:v0.4.3@sha256:d2489417468b5842c0c1aa461e8e3e636ac0b306794577501199bcbc59048e3a
WORKDIR /app

LABEL image.registry=ghcr.io
LABEL image.name=markormesher/tfl-to-mqtt

COPY --from=builder /app/build/main /usr/local/bin/tfl-to-mqtt

CMD ["/usr/local/bin/tfl-to-mqtt"]
