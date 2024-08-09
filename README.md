# aqfr

Multipath command line piping.

## Why?

To pipe commands not only as a single sequence, but across a more complex graph. Not a pipeline, but pipework.

## How?

Run the `aqfr` command, passing one string for each command in the graph.

Begin each string with `@<i>`, where `@` is simply the default tag and `<i>` the preferred identifier for the command. End each string with one of the following substrings:

- the tag and identifier for each command to which the output should be passed, run together if more than one pair, e.g. `@b@c` to pass the output to the commands with the identifiers `b` and `c`
- the default tag `@` alone if the output is not to be passed

For example:

```shell
aqfr "@1 cmd... @2" "@2 cmd... @3@4" "@3 cmd... @4" "@4 cmd... @"
```

This passes the output from command `1` to command `2`, the output from command `2` to commands `3` and `4`, and the output from command `3` to command `4`, the output of which is not passed on.

Alternatively, the commands can be read from a file (see [Options](#options) below), for ease of storage and reuse and to avoid the need to quote.

### Note

Be aware that aqfr generates and passes strings to the shell. As with any use of the shell, and any use of intermediary code invoking the shell, care should be taken. The aqfr source code should be reviewed before proceeding and any intended use of aqfr should first be tested in a context in which no harm can be done.

## Script

The script can be run with the command `./aqfr` while in the same directory, and from elsewhere using the pattern `path/to/aqfr`, by first making it executable, if not already, with `chmod +x aqfr`. Once executable, it can be run from any directory with `aqfr` by placing it in the '/bin' or '/usr/bin' directory.

The hashbang at the top of the file assumes the presence of Elixir.

### Making changes

The 'src' directory contains a Mix project, with the primary aqfr source file at 'src/lib/aqfr.ex'. This setup allows the script to be developed and tested with the use of the Mix build tool.

The output file can be produced by running the shell script at 'src/get'. This obtains the version number from 'src/mix.exs', creates the output file in the root directory with initial content, then copies in the content of the primary file, uncomments the final line and makes the output file executable.

Running the tests after making changes and adding tests to cover new behaviour is recommended.

#### Tests

The tests can be run from within the 'src' directory with the following command:

```shell
mix test
```

The tests depend on the presence of the output file in the root directory and the args files in 'src/test'.

## Options

The following can be passed to `aqfr`:

- `--file` / `-f`, to read commands from a named file, where the file contains one unquoted command per line, e.g. `aqfr -f args.txt`
- `--tags` / `-t`, to identify a non-default tag, where used, e.g. `aqfr -t TAG`
- `--help` / `-h`, to show usage then exit

## Development plan

The following are possible next steps in the development of the code base. The general medium-term aim is a convenient command line multiplier with major use cases covered. Pull requests are welcome for these and any other potential improvements.

- revise the script timeout to account for process completion
- add doctests and fuller test coverage
- provide error handling
