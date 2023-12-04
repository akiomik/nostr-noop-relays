require Logger

defmodule RelayWeb.NostrSocket do
  @behaviour Phoenix.Socket.Transport

  def child_spec(_opts) do
    # We won't spawn any process, so let's ignore the child spec
    :ignore
  end

  def connect(state) do
    # Callback to retrieve relevant data from the connection.
    # The map contains options, params, transport and endpoint keys.
    {:ok, state}
  end

  def init(state) do
    # Now we are effectively inside the process that maintains the socket.
    {:ok, state}
  end

  def handle_in(req = {"[\"REQ\"," <> _, _opts}, state) do
    Logger.debug("req: #{req}")
    payload = Jason.decode!(req, keys: :atoms)
    sub_id = Enum.at(payload, 1)
    {:reply, :ok, {:text, ~s(["EOSE","#{sub_id}"])}, state}
  end

  def handle_in({req = "[\"EVENT\"," <> _, _opts}, state) do
    Logger.debug("event: #{req}")
    payload = Jason.decode!(req, keys: :atoms)
    ev = Enum.at(payload, 1)
    {:reply, :ok, {:text, ~s(["OK","#{ev[:id]}",true,""])}, state}
  end

  def handle_in({_, _opts}, state) do
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
