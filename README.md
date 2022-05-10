# Ubuntu

Wrappers to run stuff on Ubuntu Linux, along with some convenience tools.
So far, the only supported way to read data from STDOUT of launched programs is an exponential speed-up of a timeout.

# Examples

## Get directory listing

```
iex(1)> alias Uptight.Text, as: T
```

_Ubuntu_ is an "uptight" library. It uses [Text](https://hexdocs.pm/uptight/Uptight.Text.html) from the [Text](https://hexdocs.pm/uptight/Uptight.Text.html) / [Binary](https://hexdocs.pm/uptight/Uptight.Binary.html) / [BaseN](https://hexdocs.pm/uptight/Uptight.BaseN.html) family of modules. With `Text`, there are two patterns: `"string" |> Text.new!()` (using offensive constructor to wrap a UTF-8 string) and `["foo", "bar"] |> Witchcraft.Functor.map(&T.new!/1)`, to apply the same constructor over a list of UTF-8 strings.

With "Text" aliased as "T", we can now use `Ubuntu.Path.whereis/1` to locate where a certain binary is in Ubuntu. We're using [nix flakes](https://github.com/congnivore/nix-home), so our `ls` turns out to be residing in nix store!

```
iex(2)> ls_path = Ubuntu.Path.whereis("ls" |> T.new!()) |> Uptight.Result.from_ok()
%Ubuntu.Path{
  path: [
    %Uptight.Text{text: ""},
    %Uptight.Text{text: "nix"},
    %Uptight.Text{text: "store"},
    %Uptight.Text{text: "5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0"},
    %Uptight.Text{text: "bin"},
    %Uptight.Text{text: "ls"}
  ]
}
```

We used `Result.from_ok` because defensive functions are meant to always return `Uptight.Result` in "uptight" Elixir.

Now let's finally stir up a function that has `ls_path` baked in and can get an unsafe (plain Elixir) UTF-8 string, returning a directory listing. Note that the result of this function is something of type `Ubuntu.Command`.

```
iex(3)> mk_ls = fn x -> Ubuntu.Command.new(ls_path, [T.new!(x)]) end
```

Here it is! Now let's use `Ubuntu.shoot!/1` to run a one-shot command. The parameters of the runner are inferred, observe debug output to learn about the defaults:

```
iex(4)> Ubuntu.shoot!(mk_ls.("."))

13:35:12.104 [notice] About to run /nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls "."
13:35:12.105 [debug] %Uptight.Text{text: "/nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls \".\""} has timeout 200
13:35:12.106 [debug] %Uptight.Text{text: "/nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls \".\""} got data
13:35:12.106 [debug] %Uptight.Text{text: "/nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls \".\""} has timeout 20
13:35:12.127 [debug] %Uptight.Text{text: "/nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls \".\""} has timed out
%Ubuntu.ResponseRun{
data: [
  %Uptight.Text{text: "README.md"},
  %Uptight.Text{text: "_build"},
  %Uptight.Text{text: "deps"},
  %Uptight.Text{text: "flake.lock"},
  %Uptight.Text{text: "flake.nix"},
  %Uptight.Text{text: "lib"},
  %Uptight.Text{text: "mix.exs"},
  %Uptight.Text{text: "mix.lock"},
  %Uptight.Text{text: "priv"},
  %Uptight.Text{text: "test"}
],
port: #Port<0.17>
}
```

The output of running a one-shot command is something of type `Ubuntu.ResponseRun`, which contains a reference to erlang port through which the command was executed, as well as a line-by-line STDOUT capture of running the command. STDERR, at the moment, is discarded.

`Ubuntu.shoot!()` takes the second argument -- timeout in milliseconds to wait for the initial data to start arriving over port. Observe:

```
iex(5)> Ubuntu.shoot!(mk_ls.("/home/sweater/github")) |> Map.get(:data) |> Enum.count()

13:35:54.171 [notice] About to run /nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls "/home/sweater/github"
13:35:54.171 [debug] %Uptight.Text{text: "/nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls \"/home/sweater/github\""} has timeout 200
13:35:54.172 [debug] %Uptight.Text{text: "/nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls \"/home/sweater/github\""} got data
13:35:54.172 [debug] %Uptight.Text{text: "/nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls \"/home/sweater/github\""} has timeout 20
13:35:54.193 [debug] %Uptight.Text{text: "/nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls \"/home/sweater/github\""} has timed out
63
iex(6)> Ubuntu.shoot!(mk_ls.("/home/sweater/github"), 1) |> Map.get(:data) |> Enum.count()

13:36:20.190 [notice] About to run /nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls "/home/sweater/github"
13:36:20.191 [debug] %Uptight.Text{text: "/nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls \"/home/sweater/github\""} has timeout 1
13:36:20.192 [debug] %Uptight.Text{text: "/nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls \"/home/sweater/github\""} got data
13:36:20.192 [debug] %Uptight.Text{text: "/nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls \"/home/sweater/github\""} has timeout 10
13:36:20.203 [debug] %Uptight.Text{text: "/nix/store/5imadx3sbb1f2gqhxhw5rq5idwqj4mib-coreutils-9.0/bin/ls \"/home/sweater/github\""} has timed out
63
```

As you can see, on the computer on which I have tested the second argument for listing, even 1 msec was enough to produce an output of 63 lines.
