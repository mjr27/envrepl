import os
import streams
import strutils
import tables

type
  ReplacementTableRef* = ref object
    replacements: TableRef[string, string]
    prefixCharacter: string

  ReplacementTableOptions* = tuple
    stripPrefix: bool
    variablePrefix: string
    macroPrefix: string

proc tryGetValue(table: ReplacementTableRef, key: string, value: var string): bool = 
  if table.replacements.hasKey(key):
    value  = table.replacements[key]
    return true
  return false

template slice(s: string, index: Natural, length: Natural): string =  s.substr(index, index + length - 1)

proc newReplacementTable(
  prefix: string, 
  stripPrefix: bool,
  prefixCharacter: string,
  env: openArray[tuple[key, value: TaintedString]]): ReplacementTableRef = 
  new(result)
  new(result.replacements)
  result.prefixCharacter = prefixCharacter
  if prefixCharacter.len != 1:
    quit "Prefix character may contain single character only, but contains " & $(prefix.len)
  for envKey, envValue in env.items:
    if envKey.startsWith(prefix):
      var key = envKey
      if stripPrefix:
        key = key.substr(prefix.len)
      result.replacements[key] = envValue

proc newReplacementTable*(env: openArray[tuple[key, value: TaintedString]], options: ReplacementTableOptions): ReplacementTableRef = 
  newReplacementTable(
    options.variablePrefix, 
    options.stripPrefix, 
    options.macroPrefix, 
    env
  )

proc newReplacementTable*(env: openArray[tuple[key, value: TaintedString]]): ReplacementTableRef = 
  let options = (
    stripPrefix: false,
    variablePrefix: "",
    macroPrefix: "$"
  )
  newReplacementTable(env, options)


proc parseVariableName(buffer: string, start: Natural, variableName: var string, defaultValue: var string, length: var int) : bool = 
  const maxVarLength = 128
  var 
    index = start
    eof = true
  
  while index < buffer.len:
    let c = buffer[index]
    if isAlphaNumeric(c) or c == '_':
      variableName.add(c)
      inc index
    else:
      eof = false
      break
  
  if eof: return false

  if variableName.len > maxVarLength or variableName.len <= 2: 
    return false

  if buffer[index] == '}':
    length = index - start + 1
    return true

  if buffer[index] == ':':
    inc index
    eof = true
    while index < buffer.len:
      let c = buffer[index]
      if c == '}':
        eof = false
        break
      if c == '\\':
        defaultValue.add(buffer[index + 1])
        inc index, 2
        continue
      defaultValue.add(c)
      inc index
    if eof: return false
    length = index - start + 1
    return true
  return false

proc replaceIn*(replacements: ReplacementTableRef, line: string): string  {.noSideEffect.} = 
  let 
    startMarker = replacements.prefixCharacter & "{"
    startMarkerLen  = startMarker.len
    subLast = line.len - startMarkerLen + 1
  result = ""
  var start = 0;
  while start <= subLast:
    if startMarker != line.slice(start, startMarkerLen): 
      result.add(line[start])
      inc start
      continue
    var
      varLength = 0
      variableName = "" 
      variableValue = ""
      defaultValue = ""
    if not parseVariableName(line, start + 2, variableName, defaultValue, varLength):
      result.add(line[start])
      inc start
      continue

    if (replacements.tryGetValue(variableName, variableValue)):
      result.add(variableValue)
    elif defaultValue != "":
      result.add(defaultValue)
    else: 
      result.add(line.slice(start, varLength + 2))

    start += varLength + 2

proc replace*(replacements: ReplacementTableRef, inputFile: Stream, outputFile: Stream) = 
  var line = ""
  while inputFile.readLine(line):
    outputFile.writeLine replacements.replaceIn(line)

proc batchReplace*(replacements: ReplacementTableRef, pathList: openArray[string]) = 
  for file in pathList:
    let 
      tmpFileName = file & ".tmp"
      readStream = newFileStream(file, FileMode.fmRead)
      writeStream = newFileStream(tmpFileName, FileMode.fmWrite)

    replacements.replace(readStream, writeStream)
    readStream.close()
    writeStream.close()
    os.moveFile(tmpFileName, file)
