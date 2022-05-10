defmodule Ubuntu.Path do
  @moduledoc """
  A filesystem path.

  Since there is no way to guarantee correctness of 1-ary constructor (new), we forget its argument, if any, and return an empty path.
  """
  import Algae
  import Uptight.Fold
  import Witchcraft.Functor

  import Kernel, except: [<>: 2]
  import Witchcraft.Semigroup

  alias Uptight.Text, as: T
  alias Ubuntu.Path, as: P
  alias Uptight.Result

  import ExUnit.Assertions

  defdata(list(Uptight.Text.t()))

  @spec new(list(Uptight.Text.t())) :: __MODULE__.t()
  def new(_ \\ []) do
    mk([])
  end

  @spec mk(list(Uptight.Text.t())) :: Result.t()
  def mk(xs), do: Result.new(fn -> new!(xs) end)

  @spec new!(list(T.t())) :: __MODULE__.t()
  def new!(xs) when is_list(xs), do: %__MODULE__{path: map(xs, &assert_wrapped_text!/1)}

  defp assert_wrapped_text!(x) do
    assert %T{} = x, "Ubuntu.Path only accepts %Uptight.Text{}"
    x
  end

  @spec from_raw_strings(list(String.t())) :: __MODULE__.t()
  def from_raw_strings(xs) do
    map(xs, &T.new!/1) |> __MODULE__.new!()
  end

  @spec root() :: __MODULE__.t()
  def root() do
    __MODULE__.new!([T.new!(""), T.new!("")])
  end

  @spec priv_dir(atom()) :: __MODULE__.t()
  def priv_dir(app \\ :ubuntu) do
    app
    |> :code.priv_dir()
    |> List.to_string()
    |> String.split("/")
    |> map(&T.new!/1)
    |> __MODULE__.new!()
  end

  @spec scripts_dir(atom()) :: __MODULE__.t()
  def scripts_dir(app \\ nil) do
    priv_dir(app) <> new!(["scripts" |> T.new!()])
  end

  @doc """
  Finds an executable if it's on PATH using System.find_executable and wraps it into Ubuntu.Path.

  ## Examples
      iex> Ubuntu.Path.whereis(%Uptight.Text{text: "whereis"}) |> Uptight.Result.from_ok()
      %Ubuntu.Path{path: [
        %Uptight.Text{text: ""},
        %Uptight.Text{text: "usr"},
        %Uptight.Text{text: "bin"},
        %Uptight.Text{text: "whereis"}
      ]}
  """
  @spec whereis(T.t()) :: Result.t()
  def whereis(%T{text: x}) do
    Result.new(fn ->
      System.find_executable(x)
      |> String.split("/")
      |> map(&T.new!/1)
      |> __MODULE__.new!()
    end)
  end

  @doc """
  Render path as text.

  ## Example
      iex> Ubuntu.Path.root()
      %Ubuntu.Path{path: [
        %Uptight.Text{text: ""},
        %Uptight.Text{text: ""}
      ]}

      iex> Ubuntu.Path.root() |> Ubuntu.Path.render()
      %Uptight.Text{text: "/"}
  """
  @spec render(__MODULE__.t()) :: T.t()
  def render(%P{path: xs}) do
    xs |> intercalate(T.new!("/"))
  end
end

import TypeClass
use Witchcraft

#############
# Generator #
#############

defimpl TypeClass.Property.Generator, for: Ubuntu.Path do
  @spec generate(Ubuntu.Path.t()) :: Ubuntu.Path.t()
  def generate(_) do
    [[], [""], ["", ""], ["", "tmp", "tempFile"], ["", "tmp", "tempDir", "something"]]
    |> Enum.random()
    |> Enum.map(fn x -> %Uptight.Text{text: x} end)
    |> (fn x -> %Ubuntu.Path{path: x} end).()
  end
end

##########
# Setoid #
##########

definst Witchcraft.Setoid, for: Ubuntu.Path do
  @spec equivalent?(Ubuntu.Path.t(), Ubuntu.Path.t()) :: boolean()
  def equivalent?(%Ubuntu.Path{path: x0}, %Ubuntu.Path{path: x1}),
    do: Witchcraft.Setoid.equivalent?(x0, x1)
end

#######
# Ord #
#######

definst Witchcraft.Ord, for: Ubuntu.Path do
  @spec compare(Ubuntu.Path.t(), Ubuntu.Path.t()) :: :greater | :lesser | :equal
  def compare(%Ubuntu.Path{path: x0}, %Ubuntu.Path{path: x1}),
    do: Witchcraft.Ord.compare(x0, x1)
end

#############
# Semigroup #
#############

definst Witchcraft.Semigroup, for: Ubuntu.Path do
  @spec append(Ubuntu.Path.t(), Ubuntu.Path.t()) :: Ubuntu.Path.t()
  def append(%Ubuntu.Path{path: x0}, %Ubuntu.Path{path: x1}), do: %Ubuntu.Path{path: x0 <> x1}
end

##########
# Monoid #
##########

definst Witchcraft.Monoid, for: Ubuntu.Path do
  @spec empty(Ubuntu.Path.t()) :: Ubuntu.Path.t()
  def empty(%Ubuntu.Path{path: x}), do: %Ubuntu.Path{path: Witchcraft.Monoid.empty(x)}
end

###########
# Functor #
###########

definst Witchcraft.Functor, for: Ubuntu.Path do
  @spec map(Ubuntu.Path.t(), (binary() -> binary())) :: Ubuntu.Path.t()
  def map(%Ubuntu.Path{path: x}, f), do: %Ubuntu.Path{path: Witchcraft.Functor.map(x, f)}
end

############
# Foldable #
############

definst Witchcraft.Foldable, for: Ubuntu.Path do
  @spec right_fold(Ubuntu.Path.t(), any(), (any(), any() -> any())) :: any()
  def right_fold(%{path: x}, acc0, f) do
    f.(x, acc0)
  end
end

###############
# Traversable #
###############

definst Witchcraft.Traversable, for: Ubuntu.Path do
  @spec traverse(Ubuntu.Path.t(), (any() -> Witchcraft.Traversable.t())) ::
          Witchcraft.Traversable.t()
  def traverse(%Ubuntu.Path{path: xs}, f) do
    map(f.(xs), &Ubuntu.Path.new!/1)
  end
end
