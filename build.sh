#!/usr/bin/env bash
set -ex

make clean test all
cp jnc/target/bin/jnc bin
cp jstdlib/target/lib/jstdlib.o lib
make not_quite_lisp
