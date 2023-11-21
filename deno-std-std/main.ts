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
        socket.send(`["OK","${payload[1].id}",true,""]`);
      } catch (e) {}
    };
    socket.onclose = () => console.log("DISCONNECTED");
    socket.onerror = (error) => console.error("ERROR:", error);

    return response;
  },
});
