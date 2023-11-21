Bun.serve({
  port: 8080,
  fetch(req, server) {
    if (server.upgrade(req)) {
      return;
    }

    return new Response("Upgrade failed", { status: 500 });
  },
  websocket: {
    message(ws, message) {
      try {
        const payload = JSON.parse(String(message));
        ws.send(`["OK","${payload[1].id}",true,""]`);
      } catch (e) {}
    },
    open(ws) {},
    close(ws, code, message) {},
    drain(ws) {},
  },
});
