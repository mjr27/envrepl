import os
import streams
import sequtils

import ./clitools
import ./replacer

when isMainModule:
  let cliArgs = parseCommandLineOrQuit()
  let replacementTable = newReplacementTable(cliArgs.skipMissing, cliArgs.prefix, cliArgs.stripPrefix, prefixCharacter=cliArgs.prefixCharacter, toSeq(envPairs))

  if cliArgs.kind == ctPipe:
    replacementTable.replace(newFileStream(stdin), newFileStream(stdout))
  else:
    replacementTable.batchReplace(cliArgs.paths)
