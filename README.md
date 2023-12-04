# nostr-noop-relays

A collection of the noop relay implementations for Nostr.

This repository focuses on comparing approaches by language and framework and testing for minimum configuration overhead.

## What is the noop relay?

The noop relay is a kind of Nostr relay that works with the minimum specifications defined in the [NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md).
It responds OK to EVENT but does not persist the event, and only responds EOSE to REQ.

## Supported languages and frameworks

| Language | Framework | WebSocket   | JSON   |
| -------- | --------- | ----------- | ------ |
| bun      | stdlib    | stdlib      | stdlib |
| deno     | stdlib    | stdlib      | stdlib |
| elixir   | phoenix   | cowboy      | jason  |
| gleam    | mist      | mist        | stdlib |
| rust     | tokio     | tungstenite | serde  |
| zig      | zap       | zap         | stdlib |
