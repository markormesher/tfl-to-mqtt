FROM docker.io/golang:1.25.3@sha256:7d73c4c57127279b23f3f70cbb368bf0fe08f7ab32af5daf5764173d25e78b74 AS builder
WORKDIR /app

ARG CGO_ENABLED=0

COPY go.mod go.sum ./
RUN go mod download

COPY ./cmd ./cmd

RUN go build -o ./build/main ./cmd/...

# ---

FROM ghcr.io/markormesher/scratch:v0.4.2@sha256:d6e4bea349b975ed5f3a124fc63c8dae0a67507d081bed206de9e50b6bcbe87f
WORKDIR /app

LABEL image.registry=ghcr.io
LABEL image.name=markormesher/tfl-to-mqtt

COPY --from=builder /app/build/main /usr/local/bin/tfl-to-mqtt

CMD ["/usr/local/bin/tfl-to-mqtt"]
