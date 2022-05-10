defmodule Ubuntu.Command do
  @moduledoc """
  A single ubuntu command.
  """
  import Algae
  import Uptight.Fold
  import Witchcraft.Functor
  import Kernel, except: [<>: 2]
  import Witchcraft.Semigroup
  alias Uptight.Text, as: T

  defdata do
    path :: Ubuntu.Path.t()
    args :: list(Uptight.Text.t())
  end

  @spec new!(Ubuntu.Path.t(), maybe_improper_list) :: Ubuntu.Command.t()
  def new!(p = %Ubuntu.Path{}, as) when is_list(as) do
    %__MODULE__{path: p, args: as}
  end

  @doc """
  Render Ubuntu command.

  ## Eamples
      iex> Ubuntu.Command.render(%Ubuntu.Command{ path: %Ubuntu.Path{path: [Uptight.Text.new!(""), Uptight.Text.new!("bin"), Uptight.Text.new!("ls")]}, args: [Uptight.Text.new!("/"), Uptight.Text.new!("/home")] })
      %Uptight.Text{text: ~s{/bin/ls "/" "/home"}}
  """
  @spec render(__MODULE__.t()) :: T.t()
  def render(%__MODULE__{path: p, args: args}) do
    cmd_path = p |> Ubuntu.Path.render()
    args = args |> map(&escape_argument/1) |> intercalate(T.new!(" "))
    cmd_path <> T.new!(" ") <> args
  end

  # Not sure if we need this, TODO: check how Port handles this.
  defp escape_argument(arg) do
    q = ~s{"}
    eq = ~s{\\"}
    arg |> map(fn x -> q <> String.replace(x, q, eq) <> q end)
  end
end
