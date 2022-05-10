defmodule Ubuntu do
  @moduledoc """
  Tools for Ubuntu interop.

  TODO: Write a doc about what read modes mean.

  NB! It's called "Ubuntu", not "Linux" or "Unix" to emphasise the fact that we only support Ubuntu LTS.
  Flavours of things differ, we can't rely on shell builtins being the same or ping having the same syntax.
  """
  import Algae
  import Witchcraft.Functor
  alias Uptight.Text, as: T
  alias Uptight.Result
  alias Ubuntu.ResponseRun, as: Resp
  require Logger

  import Kernel, except: [<>: 2]
  import Witchcraft.Semigroup

  @default_timeout 200
  @minimum_timeout 10
  @timeout_reduction_factor 10

  @dialyzer {:no_return, {:new, 0}}
  @dialyzer {:no_return, {:new, 1}}

  defdata do
    command :: %Ubuntu.Command{}
    read :: :no_read | :secret_read | :echo_read \\ :no_read
    timeout :: non_neg_integer() \\ 100
  end

  @spec new!(%Ubuntu.Command{}, atom(), atom() | non_neg_integer()) :: %Ubuntu{
          :command => %Ubuntu.Command{},
          :read => atom(),
          :timeout => non_neg_integer()
        }
  def new!(cmd = %Ubuntu.Command{}, read \\ :no_read, timeout \\ @default_timeout)
      when is_atom(read) do
    %__MODULE__{command: cmd, read: read, timeout: timeout}
  end

  @spec shoot!(Ubuntu.Command.t(), atom | non_neg_integer) :: Ubuntu.ResponseRun.t()
  def shoot!(cmd = %Ubuntu.Command{}, timeout \\ @default_timeout) do
    cmd |> __MODULE__.new!(:no_read, timeout) |> __MODULE__.run!()
  end

  @spec sys!(Uptight.Text.t(), maybe_improper_list, atom, atom | non_neg_integer) ::
          Ubuntu.ResponseRun.t()
  def sys!(t, args, read \\ :no_read, timeout \\ @default_timeout) do
    t
    |> (fn x -> Ubuntu.Path.whereis(x) |> Result.from_ok() end).()
    |> Ubuntu.Command.new!(args)
    |> new!(read, timeout)
    |> run!()
  end

  @doc """
  1. Get stdin data from the argument and, perhaps read it (depending on read mode).
  2. If stdin is present, pipe it into the rendered command.
  3. Receive from the port repeatedly.
  4. When timed out (default: 200ms), return everything, the port has sent to us.
  5. Force close the port.

  NB! This really has to be rewritten to use tasks to make these invocations async and with a better default timeouts.

  We also need to work on making the way run expects input flexible. For instance, terminate on any input, set up a stream, etc.

  ## Examples
      iex> Ubuntu.run!(
      ...>  Ubuntu.new!(
      ...>    Ubuntu.Command.new!(
      ...>      Ubuntu.Path.whereis(Uptight.Text.new!("echo")) |> Uptight.Result.from_ok(),
      ...>      [
      ...>        Uptight.Text.new!(~s{-n}),
      ...>        Uptight.Text.new!(~s{hello, "escaped" world!!}),
      ...>      ]),
      ...>      :no_read
      ...>    )
      ...> ).data
      [%Uptight.Text{text: ~s{hello, "escaped" world!!}}]

      iex> Ubuntu.run!(
      ...>   Ubuntu.new!(
      ...>     Ubuntu.Command.new!(
      ...>       Witchcraft.Semigroup.append(
      ...>         Ubuntu.Path.priv_dir(:ubuntu),
      ...>         ["scripts", "yggremote"] |> Witchcraft.Functor.map(&Uptight.Text.new!/1) |> Ubuntu.Path.new!()
      ...>       ),
      ...>       ["ozols.doma.dev"] |> Witchcraft.Functor.map(&Uptight.Text.new!/1)
      ...>     ),
      ...>     :no_read,
      ...>     300
      ...>   )
      ...> ).data
      [%Uptight.Text{text: ~s{202:9557:aae7:88f8:cfcc:1b63:3dce:7475}}]
  """
  @spec run!(Ubuntu.t(), Uptight.Text.t()) :: Ubuntu.ResponseRun.t()
  def run!(%Ubuntu{command: command, read: read, timeout: timeout}, stdin = %T{} \\ %T{text: ""}) do
    ## Maybe some day we'll have something like "run_task" or something.
    ## Relevant reading: https://www.theerlangelist.com/article/spawn_or_not
    ##
    # @spec run_link(__MODULE__.t(), T.t()) :: Resp.t()

    # Logger.notice("About to run #{command |> Ubuntu.Command.render() |> T.un()}")

    stdin =
      case read do
        :no_read ->
          stdin

        :secret_read ->
          Logger.notice("Enter secret")
          :io.get_password() |> List.to_string() |> T.new!()

        :echo_read ->
          Logger.notice("Enter a line to be piped into STDIN")
          IO.read(:line) |> String.trim() |> T.new!()
      end

    p =
      Port.open(
        {:spawn_executable, command.path |> Ubuntu.Path.render() |> T.un()},
        [:binary, args: command.args |> map(&T.un/1)]
      )

    Port.command(p, (stdin |> T.un()) <> "\n")

    res = naive_run_receive_loop(Resp.new!(p, []), command, timeout)

    try do
      Port.close(p)
    rescue
      # I meaaaan
      _ -> :ok
    end

    res
  end

  @spec naive_run_receive_loop(any, any, non_neg_integer) :: any
  def naive_run_receive_loop(acc, command, timeout) do
    # Logger.debug("#{inspect(command |> Ubuntu.Command.render())} has timeout #{inspect(timeout)}")

    receive do
      {port, {:data, data}} ->
        if port == acc.port do
          # Logger.debug("#{inspect(command |> Ubuntu.Command.render())} got data")

          %Resp{
            acc
            | data: acc.data <> (data |> String.trim() |> String.split("\n") |> map(&T.new!/1))
          }
          # TODO: If we insist on having this sort of generic naive receive loop
          # which consumes whole stdout instead of streaming it, we should at
          # least provide the user with strategies for the timeout shrinking.
          |> naive_run_receive_loop(
            command,
            max(@minimum_timeout, div(timeout, @timeout_reduction_factor))
          )
        else
          # TODO: WTF, was I high when I wrote this? This whole thing has to be refactored a lot
          # Like why the fuck we get a message from a wrong PID and we restart timer? Lol.
          # Good thing it'll never happen.
          # Probably even crashing is a better idea tbh...
          naive_run_receive_loop(acc, command, timeout)
        end
    after
      timeout ->
        # Logger.debug("#{inspect(command |> Ubuntu.Command.render())} has timed out")
        acc
    end
  end

  @spec get_home :: Uptight.Text.t()
  def get_home() do
    ((Ubuntu.Path.scripts_dir() <> (["getHome" |> T.new!()] |> Ubuntu.Path.new!()))
     |> Ubuntu.Command.new!([])
     |> Ubuntu.new!()
     |> Ubuntu.run!()).data
    |> hd()
  end
end
