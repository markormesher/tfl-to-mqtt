FROM docker.io/golang:1.23.4 AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY ./cmd ./cmd

RUN go build -o ./build/main ./cmd/...

# ---

FROM gcr.io/distroless/base-debian12@sha256:1aae189e3baecbb4044c648d356ddb75025b2ba8d14cdc9c2a19ba784c90bfb9
WORKDIR /app

LABEL image.registry=ghcr.io
LABEL image.name=markormesher/tfl-to-mqtt

COPY --from=builder /app/build/main /usr/local/bin/tfl-to-mqtt

CMD ["/usr/local/bin/tfl-to-mqtt"]
