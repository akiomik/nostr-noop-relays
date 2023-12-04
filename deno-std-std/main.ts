Deno.serve({
  port: 8080,
  handler: async (request) => {
    if (request.headers.get("upgrade") !== "websocket") {
      return;
    }

    const { socket, response } = Deno.upgradeWebSocket(request);

    socket.onopen = () => {
      console.log("CONNECTED");
    };
    socket.onmessage = (event) => {
      try {
        const payload = JSON.parse(event.data);
        if (payload[0] === 'EVENT') {
          ws.send(`["OK","${payload[1].id}",true,""]`);
        } else if (payload[0] === 'REQ') {
          ws.send(`["EOSE","${payload[1]}"]`);
        }
      } catch (e) {}
    };
    socket.onclose = () => console.log("DISCONNECTED");
    socket.onerror = (error) => console.error("ERROR:", error);

    return response;
  },
});
