FROM denoland/deno:debian AS builder

WORKDIR /usr/src/app
COPY . .

RUN deno cache main.ts

FROM denoland/deno:distroless

ENV DENO_DIR=/deno-dir
COPY --from=builder /deno-dir /deno-dir

WORKDIR /usr/src/app
COPY --from=builder /usr/src/app .

EXPOSE 8080

ENTRYPOINT ["deno", "run", "--allow-net=0.0.0.0:8080", "main.ts"]
