FROM rust:1.74-slim-buster as builder

WORKDIR /usr/src/app
COPY . .
RUN cargo install --path .

FROM gcr.io/distroless/cc-debian12

COPY --from=builder /usr/local/cargo/bin /usr/local/bin
EXPOSE 8080
ENV RUST_LOG=info
ENTRYPOINT ["rust-tokio-tungstenite-serde-relay"]
