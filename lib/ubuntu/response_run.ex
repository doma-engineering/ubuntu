defmodule Ubuntu.ResponseRun do
  @moduledoc """
  Data type to represent the response from an executed command.
  """

  import Witchcraft.Foldable

  import Algae

  alias Uptight.Text, as: T
  alias Uptight.Result

  @dialyzer {:no_return, {:new, 0}}
  @dialyzer {:no_return, {:new, 1}}

  defdata do
    port :: port()
    data :: list(T.t())
  end

  @spec new(any, any) :: Result.t()
  def new(port, data), do: Result.new(fn -> new!(port, data) end)

  @spec new!(any, any) :: Ubuntu.ResponseRun.t()
  def new!(port, data) when is_port(port) do
    %__MODULE__{port: port, data: data}
  end

  @spec get(__MODULE__.t()) :: list(T.t())
  def get(resp) do
    resp.data
  end

  @spec squash(__MODULE__.t()) :: T.t()
  def squash(resp) do
    get(resp) |> fold()
  end
end
