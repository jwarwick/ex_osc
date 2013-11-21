defmodule OSC.Message do
  @moduledoc """
  Parse and construct OSC Messages.
  Message specification here: 
  http://archive.cnmat.berkeley.edu/OpenSoundControl/OSC-spec.html
  """

  @doc """
  Parse an OSC message into components
  """
  def parse(msg) do
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
    [address_pattern, rest] = String.split msg, <<0>>, global: false
    rest = String.lstrip rest, 0
    {address_pattern, rest}
  end

  defp split_type_tag( {address_pattern, rest} ) do
    [type_tag, arguments] = String.split rest, <<0>>, global: false
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
    len = size(arguments) - null_count
    :binary.part arguments, null_count, len
  end

  defp extra_nulls(type_tag) do
    osc_len = string_size type_tag
    type_len = 1 + size type_tag
    osc_len - type_len
  end

  # osc strings must be multiples of 4 bytes (padded with trailing \0)
  # and must end with at \0
  defp string_size(str) when size(str) < 4, do: 4
  defp string_size(str) do
    str_size = 1 + size(str)
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

  defp get_next_value(?i, <<value :: [signed, big, size(32)], rest :: binary>>) do
    {{:osc_integer, value}, rest}
  end

  defp get_next_value(?f, <<value :: [float, size(32)], rest :: binary>>) do
    {{:osc_float, value}, rest}
  end

  defp get_next_value(?s, arguments) do
    [string, rest] = String.split arguments, <<0>>, global: false
    rest = remove_extra_nulls string, rest
    {{:osc_string, string}, rest}
  end

  defp get_next_value(?b, <<len :: [signed, big, size(32)], value :: [binary, size(len)], rest :: binary>>) do
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

  defp pad_string(str) do
    str = str <> <<0>>
    add_nulls str
  end

  defp add_nulls(x) when 0 == rem(size(x), 4), do: x
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
    {tags <> <<?i>>, args <> <<value :: [signed, big, size(32)]>>}
  end

  defp construct_args({:osc_float, value}, {tags, args}) do
    {tags <> <<?f>>, args <> <<value :: [float, size(32)]>>}
  end

  defp construct_args({:osc_string, value}, {tags, args}) do
    {tags <> <<?s>>, args <> pad_string(value)}
  end

  defp construct_args({:osc_blob, value}, {tags, args}) do
    {tags <> <<?b>>, args <> <<size(value) :: [signed, big, size(32)]>> <> add_nulls(value)}
  end
end

