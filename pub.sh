#!/usr/bin/env bash
set -ex

git restore bin/jnc lib/jstdlib.o
make clean all
rm bin/jnc lib/jstdlib.o
cp jnc/target/bin/jnc bin
cp jstdlib/target/lib/jstdlib.o lib
