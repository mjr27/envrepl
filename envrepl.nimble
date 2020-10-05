# Package

version       = "0.1.0"
author        = "Kyrylo Kobets"
description   = "Envsubst replacement"
license       = "MIT"
srcDir        = "src"
bin           = @["envrepl"]



# Dependencies

requires "nim >= 1.2.6"
requires "argparse >= 0.10.1"
requires "regex >= 0.16"



proc configureRelease() = 
    switch("opt", "size")
    switch("passL", "-s")
    switch("obj_checks", "off")
    switch("field_checks", "off")
    switch("range_checks", "off")
    switch("bound_checks", "off")
    switch("overflow_checks", "off")
    switch("assertions", "off")
    switch("stacktrace", "on")
    switch("linetrace", "off")
    switch("debugger", "off")
    switch("line_dir", "off")
    switch("dead_code_elim", "on")
    switch("debug", "off")
    switch("verbose", "off")
    switch("d", "release")

task release, "release build":
    configureRelease()
    setCommand "build"

task static, "static release build. Musl if possible":
    let exe = findExe("musl-gcc")
    if exe != "":
        switch("gcc.exe", exe)
        switch("gcc.linkerexe", exe)
    switch("passL", "-static")
    configureRelease()
    setCommand "build"
