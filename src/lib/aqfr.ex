
defmodule Aqfr.Exec do
  @moduledoc """
  Run, and pipe as required resulting output across, graph of shell commands
  tagged for interrelationship, received as list of strings from init module
  """

  @doc """
  Receive :for pid list and retain with command, then receive :pre value,
  pipe to command and send output to each process with pid in :for list
  """
  def handle_exec(cmd, for \\ []) do
    receive do
      {:for, for} ->
        handle_exec(cmd, for)
      {:pre, pre} ->
        all = if nil != pre, do: "echo \"#{String.trim(pre)}\" | #{cmd}", else: cmd
        res =
          all
          |> String.to_charlist
          |> :os.cmd
          |> to_string()
          |> String.trim()
        Enum.each(for, &(if nil != &1, do: send(&1, {:pre, res}), else: IO.puts(res)))
        handle_exec(cmd, for)
      after
        1_000 -> nil
    end
  end

  @doc """
  Send to first process in command graph empty :pre value to begin flow
  """
  def invoke_cmd0(map) do
    map
    |> Enum.at(0)
    |> elem(1)
    |> Map.get(:pid)
    |> send({:pre, nil})
  end

  @doc """
  Mapper: send to each process spawned the corresponding :for pid list
  """
  def supply_for({k, v}) do
    pid = Map.get(v, :pid)
    for = Map.get(v, :for)
    send(pid, {:for, for})
    {k, v}
  end

  @doc """
  Send to each process spawned the corresponding :for pid list, via .map
  """
  def supply_fors(map) do
    map
    |> Enum.map(&Aqfr.Exec.supply_for/1)
    |> Enum.into(%{})
  end

  @doc """
  Reducer: replace in map entry tuple each :for identifier with given pid
  """
  def update_for(tpl, acc) do
    {k, v} = tpl
    for = Enum.map(
      Map.get(v, :for),
      &(if "" == &1, do: nil, else: Map.get(acc, &1) |> Map.get(:pid))
    )
    val = Map.put(v, :for, for)
    Map.put(acc, k, val)
  end

  @doc """
  Replace in each map entry each :for identifier with given pid, via .map
  """
  def update_fors(map) do
    Enum.reduce(map, map, &Aqfr.Exec.update_for/2)
  end

  @doc """
  Mapper: spawn process for map entry tuple and extend with pid returned
  """
  def spawn_proc({k, v}) do
    pid = spawn(Aqfr.Exec, :handle_exec, [Map.get(v, :cmd)])
    val = Map.put(v, :pid, pid)
    {k, val}
  end

  @doc """
  Spawn process for each map entry and extend with pid returned, via .map
  """
  def spawn_procs(map) do
    map
    |> Enum.map(&Aqfr.Exec.spawn_proc/1)
    |> Enum.into(%{})
  end

  @doc """
  Get list of identifiers in string
  """
  def get_idents(str) do
    tag = "@"
    list = String.split(str, tag)
    Enum.slice(list, 1, length(list) - 1)
  end

  @doc """
  Reducer: convert argument from string to map entry keyed by identifier
  """
  def mapify_arg(arg, acc) do
    arg_parts = String.split(arg, " ")
    key =
      arg_parts
      |> Enum.at(0)
      |> Aqfr.Exec.get_idents()
      |> Enum.at(0)
    cmd = Enum.slice(arg_parts, 1, length(arg_parts) - 2)
    for =
      arg_parts
      |> Enum.at(-1)
      |> Aqfr.Exec.get_idents()
    val = %{
      :cmd => Enum.join(cmd, " "),
      :for => for
    }
    Map.put(acc, key, val)
  end

  @doc """
  Convert argument list of strings to map with substrings, via .reduce
  """
  def mapify_args(args) do
    Enum.reduce(args, %{}, &Aqfr.Exec.mapify_arg/2)
  end

  @doc """
  Perform primary tasks
  """
  def run(args) do
    args
    |> Aqfr.Exec.mapify_args()
    |> Aqfr.Exec.spawn_procs()
    |> Aqfr.Exec.update_fors()
    |> Aqfr.Exec.supply_fors()
    |> Aqfr.Exec.invoke_cmd0()
  end

end

defmodule Aqfr.Init do
  @moduledoc """
  Handle CLI options requested, pass remaining args to Exec module and delay
  """

  @doc """
  Get argument list with each use of default tag updated to new, via .map
  """
  def update_args(tag, args) do
    Enum.map(args, &(String.replace(&1, tag, "@")))
  end

  @doc """
  CLI option applicator: get existing args with new tag
  """
  def apply_tags(args, i) do
    tag = Enum.at(args, i + 1)
    args_0 = if i > 0, do: Enum.slice(args, 0, i), else: []
    args_1 = Enum.slice(args, i + 2, length(args) - 1)
    args_reduced = args_0 ++ args_1
    Aqfr.Init.update_args(tag, args_reduced)
  end

  @doc """
  CLI option handler: apply tags option else return args unchanged
  """
  def handle_tags(args) do
    handle_opt(args, ["-t", "--tags"], &Aqfr.Init.apply_tags/2)
  end

  @doc """
  Get argument list of strings filtered from lines of content in file
  """
  def read_argfile(filename) do
    {_, content} = File.read(filename)
    String.split(content, "\n")
    |> Enum.filter(&("" != &1))
  end

  @doc """
  CLI option applicator: get args extended from argfile
  """
  def apply_file(args, i) do
    filename = Enum.at(args, i + 1)
    args_0 = if i > 0, do: Enum.slice(args, 0, i), else: []
    args_1 = Enum.slice(args, i + 2, length(args) - 1)
    args_argfile = Aqfr.Init.read_argfile(filename)
    args_0 ++ args_1 ++ args_argfile
  end

  @doc """
  CLI option handler: apply file option else return args unchanged
  """
  def handle_file(args) do
    handle_opt(args, ["-f", "--file"], &Aqfr.Init.apply_file/2)
  end

  @doc """
  CLI option applicator: print usage then exit
  """
  def apply_help(_args, _i) do
    IO.puts("Usage: aqfr <cmds> / --file/-f <name> [--tags/-t <used>] / --help/-h")
    System.halt(0)
  end

  @doc """
  CLI option handler: apply help option else return args unchanged
  """
  def handle_help(args) do
    handle_opt(args, ["-h", "--help"], &Aqfr.Init.apply_help/2)
  end

  @doc """
  Apply CLI option if flag in args and return new or existing args
  """
  def handle_opt(args, flags, apply) do
    i = Enum.find_index(args, &(&1 in flags))
    if nil != i do
      apply.(args, i)
    else
      args
    end
  end

  @doc """
  Pass initial argument list through CLI option handlers
  """
  def handle_opts(args) do
    Aqfr.Init.handle_help(args)
    |> Aqfr.Init.handle_file()
    |> Aqfr.Init.handle_tags()
  end

  @doc """
  Handle CLI options and run exec module
  """
  def run() do
    System.argv()
    |> handle_opts()
    |> Aqfr.Exec.run()
  end

end

#Aqfr.Init.run()
