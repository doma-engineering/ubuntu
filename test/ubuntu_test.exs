defmodule UbuntuTest do
  @moduledoc """
  Tests for tight stuff.
  """
  use ExUnit.Case, async: true
  doctest Ubuntu.Path
  doctest Ubuntu.Command
  doctest Ubuntu
end
