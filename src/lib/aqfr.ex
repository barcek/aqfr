
defmodule Aqfr.Main do
  @moduledoc """
  Run primary flow to parse CLI arguments and start core module
  """

  @tag "@"
  @lag 1_000

  @doc """
  Return default command string indicator
  """
  def tag(), do: @tag

  @doc """
  Return default process completion delay
  """
  def lag(), do: @lag

  @doc """
  Pipe CLI arguments through modules
  """
  def run() do
    System.argv()
    |> Aqfr.Opts.parse()
    |> Aqfr.Cmds.parse()
    |> Aqfr.Core.start()
  end

end

defmodule Aqfr.Opts do
  @moduledoc """
  Parse CLI arguments for any options and return result
  """

  @text_usage "Usage: aqfr <cmds> / --file/-f <name> [--tags/-t <used>] / --help/-h"
  @flags_file ["-f", "--file"]
  @flags_tags ["-t", "--tags"]
  @flags_help ["-h", "--help"]

  @doc """
  Pipe CLI arguments through option handlers
  """
  def parse(args) do
    args
    |> handle_help()
    |> handle_file()
    |> handle_tags()
  end

  defp handle_opt(args, flags, apply) do
    i = Enum.find_index(args, &(&1 in flags))
    if nil != i do
      apply.(args, i)
    else
      args
    end
  end

  defp handle_help(args) do
    handle_opt(args, @flags_help, &apply_help/2)
  end

  defp apply_help(_args, _i) do
    IO.puts(@text_usage)
    System.halt(0)
  end

  defp handle_file(args) do
    handle_opt(args, @flags_file, &apply_file/2)
  end

  defp apply_file(args, i) do
    filename = Enum.at(args, i + 1)
    args_0 = if i > 0, do: Enum.slice(args, 0, i), else: []
    args_1 = Enum.slice(args, i + 2, length(args) - 1)
    args_argfile = read_argfile(filename)
    args_0 ++ args_1 ++ args_argfile
  end

  defp read_argfile(filename) do
    {_, content} = File.read(filename)
    String.split(content, "\n")
    |> Enum.filter(&("" != &1))
  end

  defp handle_tags(args) do
    handle_opt(args, @flags_tags, &apply_tags/2)
  end

  defp apply_tags(args, i) do
    tag = Enum.at(args, i + 1)
    args_0 = if i > 0, do: Enum.slice(args, 0, i), else: []
    args_1 = Enum.slice(args, i + 2, length(args) - 1)
    args_reduced = args_0 ++ args_1
    update_args(tag, args_reduced)
  end

  defp update_args(tag, args) do
    Enum.map(args, &(String.replace(&1, tag, Aqfr.Main.tag)))
  end

end

defmodule Aqfr.Cmds do
  @moduledoc """
  Parse CLI arguments for commands and return result
  """

  @doc """
  Reduce CLI arguments to map for command extraction
  """
  def parse(args) do
    Enum.reduce(args, %{}, &mapify_arg/2)
  end

  defp mapify_arg(arg, acc) do
    arg_parts = String.split(arg, " ")
    key =
      arg_parts
      |> Enum.at(0)
      |> get_idents()
      |> Enum.at(0)
    cmd = Enum.slice(arg_parts, 1, length(arg_parts) - 2)
    for =
      arg_parts
      |> Enum.at(-1)
      |> get_idents()
    val = %{
      :cmd => Enum.join(cmd, " "),
      :for => for
    }
    Map.put(acc, key, val)
  end

  defp get_idents(str) do
    list = String.split(str, Aqfr.Main.tag)
    Enum.slice(list, 1, length(list) - 1)
  end

end

defmodule Aqfr.Core do
  @moduledoc """
  Run, and pipe as required resulting output across, graph of shell commands
  tagged for interrelationship, received as list of strings from main module
  """

  @doc """
  Pipe command map through tasks and invoke initial
  """
  def start(args) do
    args
    |> spawn_procs()
    |> update_fors()
    |> supply_fors()
    |> invoke_cmd0()
  end

  defp spawn_procs(map) do
    map
    |> Enum.map(&spawn_proc/1)
    |> Enum.into(%{})
  end

  defp spawn_proc({k, v}) do
    pid = spawn(Aqfr.Core, :handle_exec, [Map.get(v, :cmd)])
    val = Map.put(v, :pid, pid)
    {k, val}
  end

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
        Aqfr.Main.lag -> nil
    end
  end

  defp update_fors(map) do
    Enum.reduce(map, map, &update_for/2)
  end

  defp update_for(tpl, acc) do
    {k, v} = tpl
    for = Enum.map(
      Map.get(v, :for),
      &(if "" == &1, do: nil, else: Map.get(acc, &1) |> Map.get(:pid))
    )
    val = Map.put(v, :for, for)
    Map.put(acc, k, val)
  end

  defp supply_fors(map) do
    map
    |> Enum.map(&supply_for/1)
    |> Enum.into(%{})
  end

  defp supply_for({k, v}) do
    pid = Map.get(v, :pid)
    for = Map.get(v, :for)
    send(pid, {:for, for})
    {k, v}
  end

  defp invoke_cmd0(map) do
    map
    |> Enum.at(0)
    |> elem(1)
    |> Map.get(:pid)
    |> send({:pre, nil})
  end

end

#Aqfr.Main.run()
