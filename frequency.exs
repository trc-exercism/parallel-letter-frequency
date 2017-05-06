defmodule Frequency do

  @whitespaces [" "]
  @punctuation ~w(! . ,)
  @numbers ~w(0 1 2 3 4 5 6 7 8 9)

  @doc """
  Count letter frequency in parallel.

  Returns a map of characters to frequencies.

  The number of worker processes to use can be set with 'workers'.
  """
  @spec frequency([String.t], pos_integer) :: map
  def frequency(texts, workers) do
    cond do
      Enum.empty?(texts) -> %{}
      true -> _merge_results(_get_results(texts, workers))
    end
  end

  defp _merge_results(frequency_maps) do
    frequency_maps
      |> Enum.reduce(%{}, fn(f_map, acc) -> Map.merge(f_map, acc, fn(_key, v1, v2) -> v1 + v2 end) end)
  end

  defp _get_results(texts, workers) do
    _get_task_results(Task.yield_many(_get_tasks(texts, workers)))
  end

  defp _get_task_results(tasks) do
    tasks
      |> Enum.map(fn({_task, {_status, result}}) -> result end)
  end

  defp _get_tasks(texts, workers) do
    _get_chunks(texts, workers)
      |> Enum.reduce([], fn(chunk, acc) -> acc ++ [Task.async(fn -> _get_clean_submap(chunk) end)] end)
  end

  defp _get_chunks(texts, workers) do
    _chunkify(Enum.join(texts), _chunk_size(texts, workers))
  end

  defp _chunk_size(texts, workers) do
    trunc(Float.ceil(String.length(Enum.join(texts)) / workers))
  end

  defp _chunkify(content, chunk_size) do
    Enum.chunk(to_charlist(content), chunk_size, chunk_size, [])
  end

  defp _get_clean_submap(list_of_characters) do
    _get_base_submap(list_of_characters)
      |> Map.drop(@whitespaces ++ @numbers ++ @punctuation)
  end

  defp _get_base_submap(list_of_characters) do
    Enum.reduce(
      list_of_characters,
      %{},
      fn(character, acc) -> Map.merge(acc, _get_short_map(acc, String.downcase(<<character :: utf8>>))) end
    )
  end

  defp _get_short_map(map, key) do
    %{ key => _get_map_value(map, key) + 1 }
  end

  defp _get_map_value(current_map, key) do
    cond do
      Map.has_key?(current_map, key) -> current_map[key]
      true -> 0
    end
  end

end
