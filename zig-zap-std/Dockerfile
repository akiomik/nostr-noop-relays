FROM debian:bookworm-slim as builder

RUN apt update && apt install -y curl xz-utils

ENV PATH=/zig-linux-aarch64-0.11.0:$PATH
RUN curl https://ziglang.org/download/0.11.0/zig-linux-aarch64-0.11.0.tar.xz -O && \
    tar xf zig-linux-aarch64-0.11.0.tar.xz

WORKDIR /usr/src/app

COPY . .
RUN zig build -Doptimize=ReleaseFast

FROM gcr.io/distroless/base-debian12

COPY --from=builder /usr/src/app/zig-out/bin /usr/local/bin

ENTRYPOINT ["relay"]
