import os
import regex
import streams
import strutils
import tables


type
    ReplacementTableRef* = ref object
      replacements: TableRef[string, string]
      prefixCharacter: string
      regex: Regex
      skipMissing: bool



proc tryGetValue(table: ReplacementTableRef, key: string, value: var string): bool = 
  if table.replacements.hasKey(key):
    value  = table.replacements[key]
    return true
  return false

proc newReplacementTable*(
  skipMissing: bool, 
  prefix: string, 
  stripPrefix: bool,
  prefixCharacter: string,
  env: openArray[tuple[key, value: TaintedString]]): ReplacementTableRef = 
  new(result)
  new(result.replacements)
  result.skipMissing = skipMissing
  result.prefixCharacter = prefix
  if prefixCharacter.len != 1:
    quit "Prefix character may contain single character only, but contains " & $(prefix.len)
  result.regex = re(r"(\x" & toHex((int)prefixCharacter[0], 2) & r"\{([\w\d_]+)(?::(.*?))?\})")
  for envKey, envValue in env.items:
    if envKey.startsWith(prefix):
      var key = envKey
      if stripPrefix:
        key = key.substr(prefix.len)
      result.replacements[key] = envValue


proc replaceCallback(replacements: ReplacementTableRef, m: RegexMatch, s: string) : string = 
  let
    defaultGroup = m.group(2)
    variableName = s[m.group(1)[0]]
    defaultValue = if defaultGroup.len > 0: s[defaultGroup[0]] else: ""
  var replacement: string
  if replacements.tryGetValue(variableName, replacement):
    return replacement
  elif defaultValue != "":
    return defaultValue
  else:
    if replacements.skipMissing: 
      return s[m.group(0)[0]]
    else:
      return defaultValue

proc batchReplace(line: string, replacements: ReplacementTableRef): string = 
  proc replaceCallbackLocal(m: RegexMatch, s: string) : string = replaceCallback(replacements, m, s)
  return line.replace(replacements.regex, replaceCallbackLocal);

proc replace*(replacements: ReplacementTableRef, inputFile: Stream, outputFile: Stream) = 
  var line = ""
  while inputFile.readLine(line):
    outputFile.writeLine line.batchReplace(replacements)

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
