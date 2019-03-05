defmodule Spandex.Strategy.Ets do
  @moduledoc """
  This stores traces in the local process dictionary, scoped by the
  tracer running the trace, such that you could have multiple traces
  going at one time by using a different tracer.
  """
  @behaviour Spandex.Strategy

  @impl Spandex.Strategy
  def trace_active?(trace_key), do: :ets.lookup(ensure_ets_table(), trace_key) != []

  @impl Spandex.Strategy
  def get_trace(trace_key) do
    case :ets.lookup(ensure_ets_table(), trace_key) do
      [{_, trace}] -> {:ok, trace}
      _ -> {:error, :no_trace_context}
    end
  catch
    _kind, _reason -> {:error, :no_trace_context}
  end

  @impl Spandex.Strategy
  def put_trace(trace_key, trace) do
    :ets.insert(ensure_ets_table(), {trace_key, trace})
    {:ok, trace}
  catch
    kind, reason -> {kind, reason}
  end

  @impl Spandex.Strategy
  def delete_trace(trace_key) do
    case get_trace(trace_key) do
      {:ok, trace} ->
        :ets.delete(ensure_ets_table(), trace_key)
        {:ok, trace}

      {:error, reason} ->
        {:error, reason}
    end
  catch
    kind, reason -> {kind, reason}
  end

  @impl Spandex.Strategy
  def generate_trace_key(_tracer), do: :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false)

  defp ensure_ets_table do
    case :ets.info(:spandex_ets) do
      :undefined ->
        :ets.new(:spandex_ets, [
          :named_table,
          :public,
          write_concurrency: true,
          read_concurrency: true
        ])

      _ ->
        :spandex_ets
    end
  end
end
