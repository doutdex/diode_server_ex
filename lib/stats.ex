# Diode Server
# Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
# Licensed under the Diode License, Version 1.0
defmodule Stats do
  use GenServer

  def init(_args) do
    :timer.send_interval(1000, :tick)

    {:ok,
     %{
       show: false,
       counters: %{},
       done_counters: %{}
     }}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__, hibernate_after: 5_000)
  end

  def incr(metric, value \\ 1) do
    cast(fn state ->
      counters = Map.update(state.counters, metric, value, fn i -> i + value end)
      %{state | counters: counters}
    end)
  end

  def get(metric, default \\ 0) do
    GenServer.call(__MODULE__, :get)
    |> Map.get(metric, default)
  end

  def tc(metric, fun) do
    {_time, ret} = tc!(metric, fun)
    ret
  end

  def tc!(metric, fun) do
    {0, fun.()}
  end

  # def tc!(metric, fun) do
  #   parent = Process.get(__MODULE__, "")
  #   name = "#{parent}/#{metric}"
  #   Process.put(__MODULE__, name)
  #   {time, ret} = :timer.tc(fun)
  #   incr("#{name}_time", time)
  #   incr("#{name}_cnt")
  #   Process.put(__MODULE__, parent)
  #   {time, ret}
  # end

  def toggle_print() do
    cast(fn state ->
      %{state | show: !state.show}
    end)
  end

  defp cast(fun) do
    GenServer.cast(__MODULE__, {:cast, fun})
  end

  def handle_cast({:cast, fun}, state) do
    {:noreply, fun.(state)}
  end

  def handle_call(:get, _from, state) do
    {:reply, state.done_counters, state}
  end

  def handle_info(:tick, state) do
    if state.show do
      :io.format(" Stats~n")
      :io.format("====================================================================~n")

      for {key, value} <- Enum.sort(state.done_counters) do
        :io.format("| ~s: ~14B |~n", [String.pad_trailing("#{key}", 48), value])
      end

      :io.format("====================================================================~n~n")
    end

    {:noreply, %{state | done_counters: state.counters, counters: %{}}}
  end
end
