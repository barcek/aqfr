# aqfr

Multipath command line piping.

## How?

Run the `aqfr` command followed by one string for each command to be invoked. Begin each string with `@<i>`, where `@` is simply the default tag and `<i>` the preferred identifier for the command. End each string with one of the following substrings:

- the tag and identifier for each command to which the output should be passed, run together if more than one pair, e.g. `@b@c` to pass the output to the commands with the identifiers `b` and `c`
- the default tag `@` alone if the output is not to be passed

For example:

```shell
aqfr "@1 cmd... @2" "@2 cmd... @3@4" "@3 cmd... @4" "@4 cmd... @"
```

This passes the output from command `1` to command `2`, the output from command `2` to commands `3` and `4`, and the output from command `3` to command `4`, the output of which is not passed on.

### Note

Be aware that aqfr generates and passes strings to the shell. As with any use of the shell, and any use of intermediary code invoking the shell, care should be taken. The aqfr source code should be reviewed before proceeding and any intended use of aqfr should first be tested in a context in which no harm can be done.

## Script

The script can be run with the command `./aqfr` while in the same directory, and from elsewhere using the pattern `path/to/aqfr`, by first making it executable, if not already, with `chmod +x aqfr`. Once executable, it can be run from any directory with `aqfr` by placing it in the '/bin' or '/usr/bin' directory.

The hashbang at the top of the file assumes the presence of Elixir.
