FROM docker.io/golang:1.24.2@sha256:d9db32125db0c3a680cfb7a1afcaefb89c898a075ec148fdc2f0f646cc2ed509 AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY ./cmd ./cmd

RUN go build -o ./build/main ./cmd/...

# ---

FROM gcr.io/distroless/base-debian12@sha256:27769871031f67460f1545a52dfacead6d18a9f197db77110cfc649ca2a91f44
WORKDIR /app

LABEL image.registry=ghcr.io
LABEL image.name=markormesher/tfl-to-mqtt

COPY --from=builder /app/build/main /usr/local/bin/tfl-to-mqtt

CMD ["/usr/local/bin/tfl-to-mqtt"]
