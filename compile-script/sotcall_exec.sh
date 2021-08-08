#!/bin/bash
# use this script to invoke, for parameter with space
Arg0Index=$#
Arg0="${@:$Arg0Index}"
let ExeIndex=Arg0Index-1
TargetExe="${@:$ExeIndex:1}"

exec -a "$Arg0" "$TargetExe" "${@:0:$ExeIndex}"