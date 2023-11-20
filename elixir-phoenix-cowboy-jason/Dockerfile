FROM elixir:1.15-slim AS builder

ENV MIX_ENV=prod
WORKDIR /usr/src/app

COPY mix.exs mix.lock .
RUN mix deps.get

COPY . .
RUN mix release

FROM elixir:1.15-slim

ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=FI/jaDYRUyowuE86CEUqyRhPariBbUJa+gs4whHnhBAAOCNH7556Gnt88z7U6GVf
WORKDIR /app

# RUN apt-get update -y && apt-get install -y openssl \
#     && apt-get clean \
#     && rm -f /var/lib/apt/lists/*_*
COPY --from=builder /usr/src/app/_build/prod/rel/* .

EXPOSE 8080

CMD ["/app/bin/relay", "start"]
