defmodule OSC.MessageTest do
  use ExUnit.Case

  test "parses a simple integer osc message" do
    msg = <<"/ab", 0, ",", 0,  0, 0>>
    assert {"/ab", []} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",i", 0, 0, 1000 :: signed-big-size(32)>>
    assert {"/ab", [{:osc_integer, 1000}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",ii", 0, 1000 :: signed-big-size(32), 16 :: signed-big-size(32)>>
    assert {"/ab", [{:osc_integer, 1000}, {:osc_integer, 16}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",iii", 0, 0, 0, 0, 1000 :: signed-big-size(32),
            16 :: signed-big-size(32), 17 :: signed-big-size(32) >>
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
    msg = <<"/ab", 0, ",if", 0, 1000 :: signed-big-size(32), 0x43dc0000 :: size(32)>>
    {path, [{int_key, int_value}, {float_key, float_value}]} = OSC.Message.parse(msg)
    assert "/ab" = path
    assert :osc_integer = int_key
    assert 1000 = int_value
    assert :osc_float = float_key
    assert_in_delta 440.0, float_value, 0.001
  end

  test "parses a string message" do
    msg = <<"/ab", 0, ",s", 0, 0, "john", 0, 0, 0, 0>>
    assert {"/ab", [{:osc_string, "john"}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",s", 0, 0, "hello", 0, 0, 0>>
    assert {"/ab", [{:osc_string, "hello"}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",s", 0, 0, "ab", 0, 0>>
    assert {"/ab", [{:osc_string, "ab"}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",s", 0, 0, "bob", 0>>
    assert {"/ab", [{:osc_string, "bob"}]} = OSC.Message.parse(msg)
  end

  test "parses a blob message" do
    msg = <<"/ab", 0, ",b", 0, 0, 0x04 :: signed-big-size(32), 0xbc :: signed-big-size(32)>>
    assert {"/ab", [{:osc_blob, <<0xbc :: signed-big-size(32)>>}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",b", 0, 0, 0x05 :: signed-big-size(32), 0xbc :: signed-big-size(40), 0, 0, 0>>
    assert {"/ab", [{:osc_blob, <<0xbc :: signed-big-size(40)>>}]} = OSC.Message.parse(msg)
  end

  test "parses a blob and an int" do
    msg = <<"/ab", 0, ",bi", 0, 0x05 :: signed-big-size(32), 0xbc :: signed-big-size(40), 0, 0, 0, 1000 :: signed-big-size(32)>>
    assert {"/ab", [{:osc_blob, <<0xbc :: signed-big-size(40)>>}, {:osc_integer, 1000}]} = OSC.Message.parse(msg)
  end

  test "parses true/false/null/impulse" do
    msg = <<"/ab", 0, ",T", 0, 0>>
    assert {"/ab", [{:osc_true}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",F", 0, 0>>
    assert {"/ab", [{:osc_false}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",N", 0, 0>>
    assert {"/ab", [{:osc_null}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",I", 0, 0>>
    assert {"/ab", [{:osc_impulse}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",iT", 0, 1000 :: signed-big-size(32)>>
    assert {"/ab", [{:osc_integer, 1000}, {:osc_true}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",FiT", 0, 0, 0, 0, 1000 :: signed-big-size(32)>>
    assert {"/ab", [{:osc_false}, {:osc_integer, 1000}, {:osc_true}]} = OSC.Message.parse(msg)
  end

  test "parses a color" do
    msg = <<"/ab", 0, ",r", 0, 0, 0x01020304::size(32)>>
    assert {"/ab", [{:osc_rgba, [red: 0x01, green: 0x02, blue: 0x03, alpha: 0x04]}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",ri", 0, 0x01020304::size(32), 1000 :: signed-big-size(32)>>
    assert {"/ab", [{:osc_rgba, [red: 0x01, green: 0x02, blue: 0x03, alpha: 0x04]}, {:osc_integer, 1000}]} = OSC.Message.parse(msg)
  end

  test "parses a midi message" do
    msg = <<"/ab", 0, ",m", 0, 0, 0x01020304::size(32)>>
    assert {"/ab", [{:osc_midi, [port_id: 0x01, status: 0x02, data1: 0x03, data2: 0x04]}]} = OSC.Message.parse(msg)

    msg = <<"/ab", 0, ",mi", 0, 0x01020304::size(32), 1000 :: signed-big-size(32)>>
    assert {"/ab", [{:osc_midi, [port_id: 0x01, status: 0x02, data1: 0x03, data2: 0x04]}, {:osc_integer, 1000}]} = OSC.Message.parse(msg)
  end

  test "parses a timetag" do
    msg = <<"/ab", 0, ",t", 0, 0, 0xc50204ecec42ee92::size(64)>>
    assert {"/ab", [{:osc_timetag, {{2004, 9, 27}, {3, 18, 4}}}]} = OSC.Message.parse(msg)
  end

  test "parses a bundle" do
    msg = <<"#bundle", 0, 214, 80, 122, 226, 215, 103, 64, 0, 24::size(32)-signed, "/greeting", 0, 0, 0, ",is", 0, 0, 0, 0, 72, "bob", 0>>
    assert {:osc_bundle, {:osc_timetag, {{2013, 12, 9}, {17, 22, 42}}},
        [{"/greeting", [osc_integer: 72, osc_string: "bob"]}]} = OSC.Message.parse(msg)
  end

  test "construct a simple message" do
    assert <<"/ab", 0, ",", 0, 0, 0>> = OSC.Message.construct("/ab", [])

    assert <<"/ab", 0, ",I", 0, 0>> = OSC.Message.construct("/ab", [{:osc_impulse}])
    assert <<"/ab", 0, ",I", 0, 0>> = OSC.Message.construct("/ab", {:osc_impulse})
    assert <<"/ab", 0, ",II", 0>> = OSC.Message.construct("/ab", [{:osc_impulse}, {:osc_impulse}])

    assert <<"/ab", 0, ",T", 0, 0>> = OSC.Message.construct("/ab", {:osc_true})
    assert <<"/ab", 0, ",F", 0, 0>> = OSC.Message.construct("/ab", {:osc_false})
    assert <<"/ab", 0, ",N", 0, 0>> = OSC.Message.construct("/ab", {:osc_null})
    assert <<"/ab", 0, ",IF", 0>> = OSC.Message.construct("/ab", [{:osc_impulse}, {:osc_false}])
  end

  test "construct a message with args" do
    assert <<"/ab", 0, ",i", 0, 0, 1000 :: signed-big-size(32)>> =
              OSC.Message.construct("/ab", {:osc_integer, 1000})

    assert <<"/ab", 0, ",f", 0, 0, 0x43, 0xdc, 0, 0>> =
              OSC.Message.construct("/ab", [{:osc_float, 440.0}])
  end

  test "construct a string message" do
    assert <<"/ab", 0, ",s", 0, 0, "john", 0, 0, 0, 0>> =
              OSC.Message.construct("/ab", [{:osc_string, "john"}])

    assert <<"/ab", 0, ",s", 0, 0, "hello", 0, 0, 0>> =
              OSC.Message.construct("/ab", [{:osc_string, "hello"}])

    assert <<"/ab", 0, ",s", 0, 0, "ab", 0, 0>> =
              OSC.Message.construct("/ab", [{:osc_string, "ab"}])

    assert <<"/ab", 0, ",s", 0, 0, "bob", 0>> =
              OSC.Message.construct("/ab", [{:osc_string, "bob"}])
  end

  test "construct a blob message" do
    assert <<"/ab", 0, ",b", 0, 0, 0x04 :: signed-big-size(32), 0xbc :: signed-big-size(32)>> =
              OSC.Message.construct("/ab", [{:osc_blob, <<0xbc :: signed-big-size(32)>>}])

    assert <<"/ab", 0, ",b", 0, 0, 0x05 :: signed-big-size(32), 0xbc :: signed-big-size(40), 0, 0, 0>> =
              OSC.Message.construct("/ab", [{:osc_blob, <<0xbc :: signed-big-size(40)>>}])
  end

  test "construct a blob and an int message" do
    assert <<"/ab", 0, ",bi", 0, 0x05 :: signed-big-size(32), 0xbc :: signed-big-size(40), 0, 0, 0, 1000 :: signed-big-size(32)>> =
           OSC.Message.construct("/ab", [{:osc_blob, <<0xbc :: signed-big-size(40)>>}, {:osc_integer, 1000}])
  end

  test "construct an rgba message" do
    assert <<"/ab", 0, ",r", 0, 0, 0x01020304::size(32)>> =
    OSC.Message.construct("/ab", [{:osc_rgba, [red: 0x01, green: 0x02, blue: 0x03, alpha: 0x04]}])

    assert <<"/ab", 0, ",r", 0, 0, 0x01000304::size(32)>> =
    OSC.Message.construct("/ab", [{:osc_rgba, [red: 0x01, blue: 0x03, alpha: 0x04]}])

    assert <<"/ab", 0, ",r", 0, 0, 0x00000000::size(32)>> =
    OSC.Message.construct("/ab", [{:osc_rgba, []}])
  end

  test "construct a midi message" do
    assert <<"/ab", 0, ",m", 0, 0, 0x01020304::size(32)>> =
    OSC.Message.construct("/ab", [{:osc_midi, [port_id: 0x01, status: 0x02, data1: 0x03, data2: 0x04]}])
  end

  test "construct a timetag" do
    assert <<"/ab", 0, ",t", 0, 0, 0xc50204ec00000000::size(64)>> =
      OSC.Message.construct("/ab", [{:osc_timetag, {{2004, 9, 27}, {3, 18, 4}}}])
  end

  test "construct a bundle" do
    assert <<"#bundle", 0, 214, 80, 122, 226, 0, 0, 0, 0, 24::size(32)-signed, "/greeting", 0, 0, 0, ",is", 0, 0, 0, 0, 72, "bob", 0>> =
    OSC.Message.construct(:osc_bundle, {:osc_timetag, {{2013, 12, 9}, {17, 22, 42}}},
        [{"/greeting", [osc_integer: 72, osc_string: "bob"]}])

    assert <<"#bundle", 0, 214, 80, 122, 226, 0, 0, 0, 0, 20::size(32)-signed, "/greeting", 0, 0, 0, ",s", 0, 0, "bob", 0>> =
    OSC.Message.construct(:osc_bundle, {:osc_timetag, {{2013, 12, 9}, {17, 22, 42}}},
        [{"/greeting", osc_string: "bob"}])
  end
end
