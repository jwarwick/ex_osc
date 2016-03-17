defmodule OSC.Message do
  @moduledoc """
  Parse and construct OSC Messages.
  Message specification here:
  http://archive.cnmat.berkeley.edu/OpenSoundControl/OSC-spec.html
  """
  use Bitwise

  @doc """
  Parse an OSC message into components
  """
  def parse(<<"#bundle", 0, secs::32, usecs::32, rest::binary>>) do
    {:osc_bundle, {:osc_timetag, translate_sntp_time(secs, usecs)},
      parse_bundle_element(rest, [])}
  end

  def parse(msg), do: parse_element(msg)

  defp parse_bundle_element(<<>>, acc), do: Enum.reverse acc

  defp parse_bundle_element(<<elt_size :: size(32)-signed, data :: size(elt_size)-unit(8)-binary, rest::binary>>, acc) do
    parse_bundle_element(rest, [parse_element(data) | acc])
  end

  defp parse_element(msg) do
    {address_pattern, type_tag_list, arguments} = split_parts msg
    args = construct_arguments(type_tag_list, arguments)
    {address_pattern, args}
  end

  defp split_parts(msg) do
    msg
      |> split_address
      |> split_type_tag
  end

  defp split_address(msg) do
    [address_pattern, rest] = String.split msg, <<0>>, parts: 2
    rest = String.lstrip rest, 0
    {address_pattern, rest}
  end

  defp split_type_tag( {address_pattern, rest} ) do
    [type_tag, arguments] = String.split rest, <<0>>, parts: 2
    arguments = remove_extra_nulls type_tag, arguments
    type_tag = normalize_type_tag type_tag
    {address_pattern, type_tag, arguments}
  end

  defp normalize_type_tag(type_tag) do
    type_tag
      |> String.lstrip(?,)
      |> :binary.bin_to_list
  end

  defp remove_extra_nulls(string, arguments) do
    extra_null_count = extra_nulls string
    remove_leading_nulls(arguments, extra_null_count)
  end

  defp remove_leading_nulls(arguments, null_count) do
    len = byte_size(arguments) - null_count
    binary_part arguments, null_count, len
  end

  defp extra_nulls(type_tag) do
    osc_len = string_size type_tag
    type_len = 1 + byte_size type_tag
    osc_len - type_len
  end

  # osc strings must be multiples of 4 bytes (padded with trailing \0)
  # and must end with at \0
  defp string_size(str) when byte_size(str) < 4, do: 4
  defp string_size(str) do
    str_size = 1 + byte_size(str)
    4 * (div(str_size, 4) + 1)
  end

  # osc blobs must be multiples of 4 bytes (padded with trailing \0)
  defp blob_size(len) when len <= 4, do: 4
  defp blob_size(len) do
    4 * (div(len, 4) + 1)
  end

  defp construct_arguments(args, list), do: do_construct_arguments(args, list, [])

  defp do_construct_arguments([], _args, result), do: Enum.reverse result
  defp do_construct_arguments([tag | tail], arguments, result) do
    {value, remaining_args} = get_next_value tag, arguments
    do_construct_arguments tail, remaining_args, [value | result]
  end

  defp get_next_value(?i, <<value :: signed-big-size(32), rest :: binary>>) do
    {{:osc_integer, value}, rest}
  end

  defp get_next_value(?f, <<value :: float-size(32), rest :: binary>>) do
    {{:osc_float, value}, rest}
  end

  defp get_next_value(?s, arguments) do
    [string, rest] = String.split arguments, <<0>>, parts: 2
    rest = remove_extra_nulls string, rest
    {{:osc_string, string}, rest}
  end

  defp get_next_value(?b, <<len :: signed-big-size(32), value :: binary-size(len), rest :: binary>>) do
    padded_len = blob_size(len)
    rest = remove_leading_nulls rest, padded_len - len
    {{:osc_blob, value}, rest}
  end

  defp get_next_value(?T, arguments) do
    {{:osc_true}, arguments}
  end

  defp get_next_value(?F, arguments) do
    {{:osc_false}, arguments}
  end

  defp get_next_value(?N, arguments) do
    {{:osc_null}, arguments}
  end

  defp get_next_value(?I, arguments) do
    {{:osc_impulse}, arguments}
  end

  defp get_next_value(?r, <<r, g, b, a, rest :: binary>>) do
    {{:osc_rgba, [red: r, green: g, blue: b, alpha: a]}, rest}
  end

  defp get_next_value(?m, <<port, status, data1, data2, rest::binary>>) do
    {{:osc_midi, [port_id: port, status: status, data1: data1, data2: data2]}, rest}
  end

  defp get_next_value(?t, <<secs::32, usecs::32, rest::binary>>) do
    {{:osc_timetag, translate_sntp_time(secs, usecs)}, rest}
  end

  defp translate_sntp_time(secs, usecs) do
    :calendar.now_to_universal_time(sntp_time_to_now(secs, usecs))
  end

  defp sntp_time_to_now(sec, usec) do
    t = case sec &&& 0x80000000 do
      0 -> sec + 2085978496 # use base: 7-Feb-2036 @ 06:28:16 UTC
      _ -> sec - 2208988800  # use base: 1-Jan-1900 @ 01:00:00 UTC
    end

    {div(t, 1000000), rem(t, 1000000), round((usec * 1000000) / (bsl(1,32)))}
  end


  @doc """
  Construct an OSC message
  """
  def construct(path, args) when is_list(args) do
    padded_path = pad_string path
    {type_tags, arguments} = Enum.reduce args, {<<?,>>, <<>>}, &(construct_args/2)
    padded_tags = pad_string type_tags
    padded_path <> padded_tags <> arguments
  end
  def construct(path, args) when is_tuple(args) do
    construct(path, [args])
  end
  def construct(:osc_bundle, {:osc_timetag, datetime}, data) do
    bins = do_construct_bundle(data, [])
    {secs, usecs} = datetime |> datetime_to_now |> now_to_sntp_time
    acc = <<"#bundle", 0, secs::32, usecs::32>>
    Enum.reduce(bins, acc, fn(v,acc) -> acc <> v end)
  end

  defp do_construct_bundle([], acc), do: Enum.reverse acc
  defp do_construct_bundle([{path, args} | rest], acc) do
    result = construct(path, args)
    result_size = byte_size(result)
    do_construct_bundle(rest, [<<result_size :: size(32)-signed>> <> result | acc])
  end

  defp pad_string(str) do
    str = str <> <<0>>
    add_nulls str
  end

  defp add_nulls(x) when 0 == rem(byte_size(x), 4), do: x
  defp add_nulls(x), do: add_nulls(x <> <<0>>)

  defp construct_args({:osc_impulse}, {tags, args}) do
    {tags <> <<?I>>, args}
  end

  defp construct_args({:osc_true}, {tags, args}) do
    {tags <> <<?T>>, args}
  end

  defp construct_args({:osc_false}, {tags, args}) do
    {tags <> <<?F>>, args}
  end

  defp construct_args({:osc_null}, {tags, args}) do
    {tags <> <<?N>>, args}
  end

  defp construct_args({:osc_integer, value}, {tags, args}) do
    {tags <> <<?i>>, args <> <<value :: signed-big-size(32)>>}
  end

  defp construct_args({:osc_float, value}, {tags, args}) do
    {tags <> <<?f>>, args <> <<value :: float-size(32)>>}
  end

  defp construct_args({:osc_string, value}, {tags, args}) do
    {tags <> <<?s>>, args <> pad_string(value)}
  end

  defp construct_args({:osc_blob, value}, {tags, args}) do
    {tags <> <<?b>>, args <> <<byte_size(value) :: signed-big-size(32)>> <> add_nulls(value)}
  end

  defp construct_args({:osc_rgba, colors}, {tags, args}) do
    {tags <> <<?r>>, args <>
      <<value_or_zero(colors[:red]), value_or_zero(colors[:green]),
      value_or_zero(colors[:blue]), value_or_zero(colors[:alpha])>>}
  end

  defp construct_args({:osc_midi, values}, {tags, args}) do
    {tags <> <<?m>>, args <> <<values[:port_id], values[:status], values[:data1], values[:data2]>>}
  end

  defp construct_args({:osc_timetag, datetime}, {tags, args}) do
    {secs, usecs} = datetime |> datetime_to_now |> now_to_sntp_time
    {tags <> <<?t>>, args <> <<secs::32, usecs::32>>}
  end

  defp value_or_zero(nil), do: 0
  defp value_or_zero(value), do: value

  defp now_to_sntp_time({_,_,usec} = now) do
    secsSinceJan1900 = bor(0x80000000,
      (:calendar.datetime_to_gregorian_seconds(:calendar.now_to_universal_time(now)) - 59958230400))

    {secsSinceJan1900, round(usec * bsl(1, 32) / 1000000)}
  end

  defp datetime_to_now(datetime) do
    seconds = :calendar.datetime_to_gregorian_seconds(datetime) - 62167219200
    ## 62167219200 == calendar:datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})
    {div(seconds, 1000000), rem(seconds, 1000000), 0}
  end
end
