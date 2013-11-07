defmodule OSC.Message do
  @moduledoc """
  Parse and contruct OSC Messages.
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

  defp remove_extra_nulls(type_tag, arguments) do
    extra_null_count = extra_nulls type_tag
    len = size(arguments) - extra_null_count
    :binary.part arguments, extra_null_count, len
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

end

