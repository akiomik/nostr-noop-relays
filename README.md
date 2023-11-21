# nostr-noop-relays

A collection of noop relay implementations for Nostr.

This repository focuses on comparing approaches by language and framework and testing for minimum configuration overhead.

| Language | Framework | WebSocket   | JSON   |
| -------- | --------- | ----------- | ------ |
| bun      | stdlib    | stdlib      | stdlib |
| deno     | stdlib    | stdlib      | stdlib |
| elixir   | phoenix   | cowboy      | jason  |
| gleam    | mist      | mist        | stdlib |
| rust     | tokio     | tungstenite | serde  |
| zig      | zap       | zap         | stdlib |
