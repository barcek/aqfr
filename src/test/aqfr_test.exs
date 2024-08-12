defmodule Aqfr.Test do

  use ExUnit.Case

  doctest Aqfr.Main
  doctest Aqfr.Opts
  doctest Aqfr.Cmds
  doctest Aqfr.Core

  @provided_cmds ["@1 ls test @2@3", "@2 wc -l @", "@3 grep exs @2"]
  @expected_core '4\n2\n'
  @expected_help 'Usage: aqfr <cmds> / --file/-f <name> [--tags/-t <used>] / --help/-h\n'

  test "Opts, no options" do

    provided_zero = []
    expected_zero = provided_zero
    obtained_zero = Aqfr.Opts.parse(provided_zero)

    provided_cmds = @provided_cmds
    expected_cmds = provided_cmds
    obtained_cmds = Aqfr.Opts.parse(provided_cmds)

    assert expected_zero == obtained_zero
    assert expected_cmds == obtained_cmds
  end

  test "Opts, option 'file'" do

    provided_word = ["--file", "test/args_file.txt"]
    expected_word = @provided_cmds
    obtained_word = Aqfr.Opts.parse(provided_word)

    provided_char = ["-f", "test/args_file.txt"]
    expected_char = @provided_cmds
    obtained_char = Aqfr.Opts.parse(provided_char)

    assert expected_word == obtained_word
    assert expected_char == obtained_char
  end

  test "Opts, option 'tags'" do

    provided_word = ["--tags", "TAG", "TAG1 ls test TAG2TAG3", "TAG2 wc -l TAG", "TAG3 grep exs TAG2"]
    expected_word = @provided_cmds
    obtained_word = Aqfr.Opts.parse(provided_word)

    provided_char = ["-t", "TAG", "TAG1 ls test TAG2TAG3", "TAG2 wc -l TAG", "TAG3 grep exs TAG2"]
    expected_char = @provided_cmds
    obtained_char = Aqfr.Opts.parse(provided_char)

    assert expected_word == obtained_word
    assert expected_char == obtained_char
  end

  test "Opts, options, two ('file', 'tags')" do

    provided = ["--file", "test/args_file_tags.txt", "--tags", "TAG"]
    expected = @provided_cmds
    obtained = Aqfr.Opts.parse(provided)

    assert expected == obtained
  end

  test "Cmds" do

    expected = %{
      "1" => %{
        cmd: "ls test",
        for: ["2", "3"]
      },
      "2" => %{
        cmd: "wc -l",
        for: [""]
      },
      "3" => %{
        cmd: "grep exs",
        for: ["2"]
      }
    }
    obtained = Aqfr.Cmds.parse(@provided_cmds)

    assert expected == obtained
  end

  test "aqfr, no options" do

    provided = '../aqfr "@1 ls test @2@3" "@2 wc -l @" "@3 grep exs @2"'
    expected = @expected_core
    obtained = run(provided)

    assert expected == obtained
  end

  test "aqfr, option 'file'" do

    provided_word = "../aqfr --file test/args_file.txt"
    expected_word = @expected_core
    obtained_word = run(provided_word)

    provided_char = "../aqfr -f test/args_file.txt"
    expected_char = @expected_core
    obtained_char = run(provided_char)

    assert expected_word == obtained_word
    assert expected_char == obtained_char
  end

  test "aqfr, option 'tags'" do

    provided_word = '../aqfr --tags TAG "TAG1 ls test TAG2TAG3" "TAG2 wc -l TAG" "TAG3 grep exs TAG2"'
    expected_word = @expected_core
    obtained_word = run(provided_word)

    provided_char = '../aqfr -t TAG "TAG1 ls test TAG2TAG3" "TAG2 wc -l TAG" "TAG3 grep exs TAG2"'
    expected_char = @expected_core
    obtained_char = run(provided_char)

    assert expected_word == obtained_word
    assert expected_char == obtained_char
  end

  test "aqfr, option 'help'" do

    provided_word = "../aqfr --help"
    expected_word = @expected_help
    obtained_word = run(provided_word)

    provided_char = "../aqfr -h"
    expected_char = @expected_help
    obtained_char = run(provided_char)

    assert expected_word == obtained_word
    assert expected_char == obtained_char
  end

  test "aqfr, options, two ('file', 'tags')" do

    provided = "../aqfr --file test/args_file_tags.txt --tags TAG"
    expected = @expected_core
    obtained = run(provided)

    assert expected == obtained
  end

  test "aqfr, options, two + 'help'" do

    provided = "../aqfr --file test/args_file_tags.txt --tags TAG --help"
    expected = @expected_help
    obtained = run(provided)

    assert expected == obtained
  end

  def run(provided) do
    port = Port.open({:spawn, provided}, [])
    await(port)
  end

  def await(port) do
    receive do
      {^port, {:data, obtained}} ->
        await(port, obtained)
    end
  end

  def await(port, previous) do
    receive do
      {^port, {:data, obtained}} ->
        previous ++ obtained
      after 100 ->
        previous
    end
  end
end
