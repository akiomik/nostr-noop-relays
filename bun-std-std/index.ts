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
        if (payload[0] === 'EVENT') {
          ws.send(`["OK","${payload[1].id}",true,""]`);
        } else if (payload[0] === 'REQ') {
          ws.send(`["EOSE","${payload[1]}"]`);
        }
      } catch (e) {}
    },
    open(ws) {},
    close(ws, code, message) {},
    drain(ws) {},
  },
});
