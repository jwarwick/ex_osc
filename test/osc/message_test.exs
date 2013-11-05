defmodule OSC.MessageTest do
  use ExUnit.Case

  test "parses a simple osc message" do
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

end

