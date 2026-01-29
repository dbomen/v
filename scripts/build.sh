#!/bin/bash

RED='\033[0;31m'
NC='\033[0m'

printhelp() {
    echo -e "USAGE:"
    echo -e "${RED}build from files:${NC} $0 files file1.a file2.b ..."
    echo -e "${RED}build project:${NC} $0 project"
    exit 1
}

if [[ "$1" == "files" ]]; then
    shift # exclude "files"

    if [[ -z "$1" ]]; then printhelp; fi

    # copy .asm files
    echo "[build] Copying files..."
    cp "$@" .

    # compile .asm files
    objs=()
    for f in "$@"; do
        base="$(basename "$f")"
        echo "[build] Assembling ${base}"
        java -cp sictools.jar sic.Asm "$base"

        obj="${base%.asm}.obj"
        objs+=( "$obj" )
    done

    # link .obj files
    echo "[build] Linking..."
    java -cp sictools.jar sic.Link -o out.obj "${objs[@]}"

    # remove everything but out.obj
    echo "[build] Cleaning up..."
    for o in *.obj; do
        [[ "$o" == "out.obj" ]] && continue
        rm -f "$o"
    done
    rm -f *.asm *.lst *.log

elif [[ "$1" == "project" ]]; then
    # TODO: build the project
    echo "TODO: build the project"
else
    printhelp
fi

