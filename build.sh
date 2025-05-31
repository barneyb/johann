#!/usr/bin/env bash
set -ex

git restore bin/jnc lib/jstdlib.o
make clean test all
cp jnc/target/bin/jnc bin
cp jstdlib/target/lib/jstdlib.o lib
if ! make clean test all not_quite_lisp; then
    set +x
    echo
    echo "Failed to re-build"
    echo
    git restore bin/jnc lib/jstdlib.o
    exit 1
fi
