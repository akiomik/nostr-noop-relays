FROM ghcr.io/gleam-lang/gleam:v0.32.4-erlang-slim as builder

WORKDIR /usr/src/app
COPY . .
RUN gleam build

EXPOSE 8080

ENTRYPOINT ["gleam", "run"]
