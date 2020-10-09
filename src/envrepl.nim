import os
import streams
import sequtils

import ./clitools
import ./replacer

when isMainModule:
  let 
    cliArgs = parseCommandLineOrQuit()
    options = (
      stripPrefix: cliArgs.stripPrefix,
      variablePrefix: cliArgs.prefix,
      macroPrefix: cliArgs.prefixCharacter
    )
  let replacementTable = newReplacementTable(toSeq(envPairs), options)

  if cliArgs.kind == ctPipe:
    replacementTable.replace(newFileStream(stdin), newFileStream(stdout))
  else:
    replacementTable.batchReplace(cliArgs.paths)
