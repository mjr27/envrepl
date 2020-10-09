import ../../src/replacer
import strformat
import tables

proc assertProcessedTo (table: ReplacementTableRef, tpl: string, expected: string) = 
    doAssert (expected == table.replaceIn(tpl)), fmt"`{expected}` != `{table.replaceIn(tpl)}`"

template assertDoesNotChange (table: ReplacementTableRef, tpl: string) = 
    doAssert tpl ==  table.replaceIn(tpl)


template process(env: openArray[tuple[key, value: TaintedString]], options: ReplacementTableOptions, body: untyped) = 
    block:
        let table = newReplacementTable(env, options)
        proc eq(tpl, expected: string) = 
            table.assertProcessedTo tpl, expected
        proc same(tpl: string) = 
            table.assertDoesNotChange tpl
        body

let
    env = [("REACT_VAR", "value"), ("OTHER_VAR", "value2")]

process(env, (
    stripPrefix: false,
    variablePrefix: "",
    macroPrefix: "$"
)) do:
    eq "", ""
    eq "", ""
    eq "x", "x"
    eq "$REACT_VAR", "$REACT_VAR"
    eq "${REACT_VAR}", "value"
    eq "${OTHER_VAR}", "value2"
    same "${REACTVAR}"
    same "${REACT?VAR}"
    same "${REACT_VAr}"
    eq "${ REACT_VAR }", "${ REACT_VAR }"
    eq " ${REACT_VAR} ", " value "

process(env, (
    stripPrefix: false,
    variablePrefix: "REACT_",
    macroPrefix: "@"
)) do:
    eq "@{REACT_VAR}", "value"
    same "@{OTHER_VAR}"

process(env, (
    stripPrefix: true,
    variablePrefix: "REACT_",
    macroPrefix: "$"
)) do :
    eq "${VAR}", "value"
    same "${REACT_VAR}"
    same "${OTHER_VAR}"

process(env, (
    stripPrefix: true,
    variablePrefix: "REACT_",
    macroPrefix: "$"
)) do:
    eq "${VAR}", "value"
    same "${REACT_VAR}"
    same "${OTHER_VAR}"


process(env, (
    stripPrefix: false,
    variablePrefix: "",
    macroPrefix: "$"
)) do:
    eq "${VAR}", "${VAR}"
    eq "${REACT_VAR}", "value"
    eq "${OTHER_VAR}", "value2"
    eq "${TEST}", "${TEST}"

process(env, (
    stripPrefix: true,
    variablePrefix: "REACT_",
    macroPrefix: "$"
)) do:
    eq "${VAR}", "value"
    eq "${REACT_VAR}", "${REACT_VAR}"
    eq "${OTHER_VAR}", "${OTHER_VAR}"
    eq "${TEST}", "${TEST}"

process(env, (
    stripPrefix: true,
    variablePrefix: "REACT_",
    macroPrefix: "_"
)) do:
    eq "_{VAR:default}", "value"
    eq "_{VAR2:default}", "default"
