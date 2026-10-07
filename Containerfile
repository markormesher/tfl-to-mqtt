FROM docker.io/golang:1.27.1@sha256:1e93e00a31255c07e9a34c4207f3006e1501730c5323697cee7dfb827fdae44c AS builder
WORKDIR /app

ARG CGO_ENABLED=0

COPY go.mod go.sum ./
RUN go mod download

COPY ./cmd ./cmd

RUN go build -o ./build/main ./cmd/...

# ---

FROM ghcr.io/markormesher/scratch:v0.4.28@sha256:4741727f246543706664e27cae7e5cf42ed3184ede63f14201713e5628b11dfd
WORKDIR /app

COPY --from=builder /app/build/main /usr/local/bin/tfl-to-mqtt

CMD ["/usr/local/bin/tfl-to-mqtt"]

LABEL image.name=markormesher/tfl-to-mqtt
LABEL image.registry=ghcr.io
LABEL org.opencontainers.image.description=""
LABEL org.opencontainers.image.documentation=""
LABEL org.opencontainers.image.title="tfl-to-mqtt"
LABEL org.opencontainers.image.url=""
LABEL org.opencontainers.image.vendor=""
LABEL org.opencontainers.image.version=""
