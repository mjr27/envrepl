import argparse
import os
import sequtils

type 
  CommandType* = enum
    ctPipe,
    ctBatch

  CommandLineArguments* = object
    prefix*: string
    prefixCharacter*: string
    stripPrefix*: bool
    verbose*: bool
    skipMissing*: bool
    case kind*: CommandType 
    of ctPipe: discard
    of ctBatch:
      paths*: seq[string]

iterator expandPatterns(patterns: openArray[string]): string = 
  for pattern in patterns:
    for s in walkPattern(absolutePath(pattern)):
      yield s

proc findFiles(patterns: openArray[string]): seq[string] = 
  var fileSet = newSeq[string]()
  for entry in expandPatterns(patterns):
    if existsFile(entry):
      fileSet.add(entry)
    elif existsDir(entry):
      for file in walkDirRec(entry):
        fileSet.add(file)
  return fileSet.deduplicate()

proc parseCommandLineOrQuit*() : CommandLineArguments = 
  var cliArgs : CommandLineArguments
  let myParser = newParser("envrepl"):
    help("Replaces environment variables in specified files")
    option("-c", "--character", help="Variable expanded character (for variables like ${VAR} it should be $)", default = "$")
    option("-p", "--prefix", help="Prefix of environment variables to include. E.g REACT_APP_")
    flag("-m", "--skip-missing", help="Do not substitute missing variables without default values.")
    flag("-s", "--strip-prefix", help="Strip prefix on replace. If prefix is `REACT_APP_`, then `${VAR}` will be taken from `env.REACT_APP_VAR`")
    flag("-v", "--verbose", help="Verbose logging")
    command("batch"):
      arg("files", help="List of files or directories to process", nargs = -1)
      run:
        cliArgs = CommandLineArguments(
          kind: ctBatch,
          paths: findFiles(opts.files),
          prefixCharacter: opts.parentOpts.character,
          skipMissing: opts.parentOpts.skipmissing,
          prefix: opts.parentOpts.prefix,
          stripPrefix: opts.parentOpts.stripPrefix,
          verbose: opts.parentOpts.verbose
        )
    command("pipe"):
      discard
    run:
      cliArgs.prefixCharacter = opts.character
      cliArgs.skipMissing = opts.skipmissing
      cliArgs.prefix = opts.prefix
      cliArgs.stripPrefix = opts.stripPrefix
      cliArgs.verbose= opts.verbose
  myParser.run(os.commandLineParams())
  return cliArgs
