defmodule OSC.MessageTest do
  use ExUnit.Case

  test "parses a simple integer osc message" do
    msg = <<"/ab", 0, ",", 0,  0, 0>>
    assert {"/ab", []} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",i", 0, 0, 1000 :: [signed, big, size(32)]>>
    assert {"/ab", [{:osc_integer, 1000}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",ii", 0, 1000 :: [signed, big, size(32)], 16 :: [signed, big, size(32)]>>
    assert {"/ab", [{:osc_integer, 1000}, {:osc_integer, 16}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",iii", 0, 0, 0, 0, 1000 :: [signed, big, size(32)],
            16 :: [signed, big, size(32)], 17 :: [signed, big, size(32)] >>
    assert {"/ab", [{:osc_integer, 1000}, {:osc_integer, 16}, {:osc_integer, 17}]} = OSC.Message.parse(msg)
  end

  test "parses a simple float osc message" do
    msg = <<"/ab", 0, ",f", 0, 0, 0x43, 0xdc, 0, 0>>
    assert {"/ab", [{:osc_float, 440.0}]} = OSC.Message.parse(msg)
    
    msg = <<"/ab", 0, ",f", 0, 0, 0x40, 0xb5, 0xb2, 0x2d>>
    {path, [{key, value}]} = OSC.Message.parse(msg)
    assert "/ab" = path
    assert :osc_float = key
    assert_in_delta 5.678, value, 0.001

    msg = <<"/ab", 0, ",f", 0, 0, 0x3f, 0x9d, 0xf3, 0xb6>>
    {path, [{key, value}]} = OSC.Message.parse(msg)
    assert "/ab" = path
    assert :osc_float = key
    assert_in_delta 1.234, value, 0.001
  end

  test "parses combined message" do
    msg = <<"/ab", 0, ",if", 0, 1000 :: [signed, big, size(32)], 0x43dc0000 :: size(32)>>
    {path, [{int_key, int_value}, {float_key, float_value}]} = OSC.Message.parse(msg)
    assert "/ab" = path
    assert :osc_integer = int_key
    assert 1000 = int_value
    assert :osc_float = float_key
    assert_in_delta 440.0, float_value, 0.001
  end

end

