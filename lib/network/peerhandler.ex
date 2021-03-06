# Diode Server
# Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
# Licensed under the Diode License, Version 1.0
defmodule Network.PeerHandler do
  use Network.Handler
  alias Chain.BlockCache, as: Block
  alias Object.Server, as: Server
  alias Model.KademliaSql

  # @hello 0
  # @response 1
  # @find_node 2
  # @find_value 3
  # @store 4
  # @publish 5
  @hello :hello
  @response :response
  @find_node :find_node
  @find_value :find_value
  @store :store

  @publish :publish
  @ping :ping
  @pong :pong

  def find_node, do: @find_node
  def find_value, do: @find_value
  def store, do: @store
  def publish, do: @publish
  def ping, do: @ping
  def pong, do: @pong

  def do_init(state) do
    send_hello(
      Map.merge(state, %{
        calls: :queue.new(),
        blocks: [],
        random_blocks: 0,
        stable: false,
        msg_count: 0,
        start_time: System.os_time(:second),
        server: nil
      })
    )
  end

  def ssl_options(opts) do
    Network.Server.default_ssl_options(opts)
    |> Keyword.put(:packet, 4)
  end

  def handle_cast({:rpc, call}, state) do
    send!(state, call)
    calls = :queue.in({call, nil}, state.calls)
    {:noreply, %{state | calls: calls}}
  end

  def handle_call({:rpc, call}, from, state) do
    send!(state, call)
    calls = :queue.in({call, from}, state.calls)
    {:noreply, %{state | calls: calls}}
  end

  defp encode(msg) do
    BertInt.encode!(msg)
  end

  defp decode(msg) do
    BertInt.decode!(msg)
  end

  defp send_hello(state) do
    {:ok, {addr, _port}} = :ssl.sockname(state.socket)
    hello = Diode.self(:erlang.list_to_binary(:inet.ntoa(addr)))

    send!(state, [@hello, Object.encode!(hello), Chain.genesis_hash()])

    receive do
      {:ssl, _socket, msg} ->
        msg = decode(msg)

        case hd(msg) do
          @hello ->
            handle_msg(msg, state)

          _ ->
            log(state, "expected hello message, but got ~p", [msg])
            {:stop, :normal, state}
        end
    after
      3_000 ->
        log(state, "expected hello message, timeout")
        {:stop, :normal, state}
    end
  end

  def handle_info({:ssl, _sock, omsg}, state) do
    msg = decode(omsg)

    # log(state, format("Received ~p bytes on ~p: ~180p", [byte_size(omsg), _sock, msg]))

    state = %{state | msg_count: state.msg_count + 1}

    # We consider this connection stable after at least 5 minutes and 10 messages
    state =
      if state.stable == false and
           state.msg_count > 10 and
           state.start_time + 300 < System.os_time(:second) do
        GenServer.cast(Kademlia, {:stable_node, state.node_id, state.server})
        %{state | stable: true}
      else
        state
      end

    case handle_msg(msg, state) do
      {reply, state} when not is_atom(reply) ->
        send!(state, reply)
        {:noreply, state}

      other ->
        other
    end
  end

  def handle_info({:ssl_closed, info}, state) do
    log(state, "Connection closed by remote. info: ~0p", [info])
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    log(state, "unhandled info: ~180p", [msg])
    {:noreply, state}
  end

  defp handle_msg([@hello, server, genesis_hash], state) do
    genesis = Chain.genesis_hash()

    if genesis != genesis_hash do
      log(state, "wrong genesis: ~p ~p", [
        Base16.encode(genesis),
        Base16.encode(genesis_hash)
      ])

      {:stop, :normal, state}
    else
      GenServer.cast(
        self(),
        {:rpc, [Network.PeerHandler.publish(), Block.export(Chain.peak_block())]}
      )

      if Map.has_key?(state, :peer_port) do
        {:noreply, state}
      else
        server = Object.decode!(server)
        id = Wallet.address!(state.node_id)
        ^id = Object.key(server)

        port = Server.peer_port(server)

        log(state, "hello from: #{Wallet.printable(state.node_id)}")
        state = Map.put(state, :peer_port, port)
        GenServer.cast(Kademlia, {:register_node, state.node_id, server})
        {:noreply, %{state | server: server}}
      end
    end
  end

  defp handle_msg([@find_node, id], state) do
    nodes =
      Kademlia.find_node_lookup(id)
      |> Enum.filter(fn node -> not KBuckets.is_self(node) end)

    {[@response, @find_node | nodes], state}
  end

  defp handle_msg([@find_value, id], state) do
    reply =
      case KademliaSql.object(id) do
        nil ->
          nodes =
            Kademlia.find_node_lookup(id)
            |> Enum.filter(fn node -> not KBuckets.is_self(node) end)

          [@response, @find_node | nodes]

        value ->
          [@response, @find_value, value]
      end

    {reply, state}
  end

  defp handle_msg([@store, key, value], state) do
    KademliaSql.put_object(key, value)
    {[@response, @store, "ok"], state}
  end

  defp handle_msg([@ping], state) do
    {[@response, @ping, @pong], state}
  end

  defp handle_msg([@pong], state) do
    {[@response, @pong, @ping], state}
  end

  defp handle_msg([@publish, %Chain.Transaction{} = tx], state) do
    if Chain.Transaction.valid?(tx) do
      Chain.Pool.add_transaction(tx)
      {[@response, @publish, "ok"], state}
    else
      {[@response, @publish, "error"], state}
    end
  end

  defp handle_msg([@publish, blocks], state) when is_list(blocks) do
    # For better resource usage we only let one process sync at full
    # throttle
    len = length(state.blocks)
    Chain.throttle_sync(len > 10, "Downloading #{len}")

    # Actual syncing
    Enum.reduce_while(blocks, {"ok", state}, fn block, {_, state} ->
      case handle_msg([@publish, block], state) do
        {response, state} ->
          # If we receive a batch that contains a random block, we skip the batch, and
          # when blocks have been reset we hast reached a known block
          if state.random_blocks == 0 and state.blocks != [] do
            {:cont, {response, state}}
          else
            {:halt, {[@response, @publish, "ok"], state}}
          end

        # Any kind of other errors
        other ->
          {:halt, other}
      end
    end)
  end

  defp handle_msg([@publish, %Chain.Block{} = block], state) do
    block = Block.export(block)

    case Chain.block_by_hash?(Chain.Block.hash(block)) do
      false ->
        handle_block(Block.parent(block), block, state)

      true ->
        log(state, "Chain.add_block: Skipping existing block #{Block.printable(block)}")
        # delete backup list on first successfull block
        {[@response, @publish, "ok"], %{state | blocks: []}}
    end
  end

  defp handle_msg([@response, @publish, "missing_parent", parent_hash], state) do
    # if there is a missing parent we're batching 65k blocks at once
    parents =
      Enum.reduce_while(Chain.blocks(parent_hash), [], fn block, blocks ->
        next = [Block.export(block) | blocks]

        if byte_size(:erlang.term_to_binary(next)) > 260_000 do
          {:halt, next}
        else
          {:cont, next}
        end
      end)
      |> Enum.reverse()

    case parents do
      [] ->
        # Responding to initial call, removing it from the stack
        # e.g. from kademlia.ex `GenServer.cast(pid, {:rpc, msg})`
        err = :io_lib.format("missing_parent ~p but there is no such parent", [parent_hash])
        :io.format("~s~n", [err])
        respond(state, err)

      _other ->
        # Creating a second round to finish this, need to
        # retop the last call
        {{:value, call}, calls} = :queue.out(state.calls)
        calls = :queue.in(call, calls)
        send!(state, [@publish, parents])
        {:noreply, %{state | calls: calls}}
    end
  end

  defp handle_msg([@response, @find_value, value], state) do
    respond(state, {:value, value})
  end

  defp handle_msg([@response, _cmd | rest], state) do
    respond(state, rest)
  end

  defp handle_msg(msg, state) do
    log(state, "Unhandled: #{inspect(msg)}")
    {:noreply, state}
  end

  # Block is based on unknown predecessor
  # keep block in block backup list
  defp handle_block(nil, block = %Chain.Block{}, state) do
    ret =
      case state.blocks do
        [] ->
          {0, [block]}

        blocks ->
          if Block.parent_hash(hd(blocks)) == Chain.Block.hash(block) do
            {0, [block | blocks]}
          else
            # this happens when there is a new top block created on the remote side
            if Block.parent_hash(block) == Block.hash(List.last(blocks)) do
              {0, blocks ++ [block]}
            else
              # is this a randomly broadcasted block or a chain re-org?
              # assuming reorg after n blocks
              if state.random_blocks < 5 do
                log(state, "ignoring wrong ordered block [~p]", [state.random_blocks + 1])
                {state.random_blocks + 1, blocks}
              else
                log(state, "restarting sync because of random blocks [~p]", [
                  state.random_blocks + 1
                ])

                {:error, :too_many_random_blocks}
              end
            end
          end
      end

    case ret do
      {:error, reason} ->
        {:stop, {:sync_error, reason}, state}

      {random_blocks, blocks} ->
        {[@response, @publish, "missing_parent", Block.parent_hash(hd(blocks))],
         %{state | blocks: blocks, random_blocks: random_blocks}}
    end
  end

  defp handle_block(_parent, block, state) do
    if Chain.import_blocks([block | state.blocks]) do
      # delete backup list on first successfull block
      {[@response, @publish, "ok"], %{state | blocks: []}}
    else
      err = "sync failed"
      {:stop, {:validation_error, err}, state}
    end
  end

  defp respond(state, msg) do
    {{:value, {_call, from}}, calls} = :queue.out(state.calls)

    if from != nil do
      :ok = GenServer.reply(from, msg)
    end

    {:noreply, %{state | calls: calls}}
  end

  defp send!(%{socket: socket}, data) do
    raw = encode(data)
    # log(state, format("Sending ~p bytes: ~p", [byte_size(raw), data]))
    :ok = :ssl.send(socket, raw)
  end

  def on_nodeid(nil) do
    :ok
  end

  def on_nodeid(node) do
    OnCrash.call(fn reason ->
      :io.format("Node ~p down for: ~180p~n", [Wallet.printable(node), reason])
      GenServer.cast(Kademlia, {:failed_node, node})
    end)
  end
end
