# git-crypt.sh

A reimplementation of [git-crypt](https://github.com/AGWA/git-crypt) in bash
script.

## Feature set

Supported subcommands:

- `init`
- `unlock` with an explicit keyfile.
- `export-key`
- `smudge`, `clean`, `diff` for github integration

Most notably, there is no support for the additional GPG functionality of
`git-crypt`.

## Dependencies

Bash (not any portable POSIX shell), and the OpenSSL CLI tool.

## Performance

It's slow. Use the real `git-crypt` if possible, this is meant to be used as a
stop-gap measure.
