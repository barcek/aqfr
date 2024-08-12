defmodule Aqfr.Test do

  use ExUnit.Case

  doctest Aqfr.Main
  doctest Aqfr.Opts
  doctest Aqfr.Cmds
  doctest Aqfr.Core

  @expected_cmds '4\n2\n'
  @expected_help 'Usage: aqfr <cmds> / --file/-f <name> [--tags/-t <used>] / --help/-h\n'

  test "aqfr, no options" do

    provided = '../aqfr "@1 ls test @2@3" "@2 wc -l @" "@3 grep exs @2"'
    obtained = run(provided)

    assert @expected_cmds == obtained
  end

  test "aqfr, option 'file'" do

    provided_word = "../aqfr --file test/args_file.txt"
    obtained_word = run(provided_word)

    provided_char = "../aqfr -f test/args_file.txt"
    obtained_char = run(provided_char)

    assert @expected_cmds == obtained_word
    assert @expected_cmds == obtained_char
  end

  test "aqfr, option 'tags'" do

    provided_word = '../aqfr --tags TAG "TAG1 ls test TAG2TAG3" "TAG2 wc -l TAG" "TAG3 grep exs TAG2"'
    obtained_word = run(provided_word)

    provided_char = '../aqfr -t TAG "TAG1 ls test TAG2TAG3" "TAG2 wc -l TAG" "TAG3 grep exs TAG2"'
    obtained_char = run(provided_char)

    assert @expected_cmds == obtained_word
    assert @expected_cmds == obtained_char
  end

  test "aqfr, option 'help'" do

    provided_word = "../aqfr --help"
    obtained_word = run(provided_word)

    provided_char = "../aqfr -h"
    obtained_char = run(provided_char)

    assert @expected_help == obtained_word
    assert @expected_help == obtained_char
  end

  test "aqfr, options, two ('file', 'tags')" do

    provided = "../aqfr --file test/args_file_tags.txt --tags TAG"
    obtained = run(provided)

    assert @expected_cmds == obtained
  end

  test "aqfr, options, two + 'help'" do

    provided = "../aqfr --file test/args_file_tags.txt --tags TAG --help"
    obtained = run(provided)

    assert @expected_help == obtained
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
