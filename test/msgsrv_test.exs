defmodule MsgsrvTest do
  use ExUnit.Case
  doctest Msgsrv

  test "greets the world" do
    assert Msgsrv.hello() == :world
  end
end
