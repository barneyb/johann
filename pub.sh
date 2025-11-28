#!/usr/bin/env bash
set -ex

git restore --staged bin/jnc lib/jstdlib.o lib/jstdlib.jnh
git restore bin/jnc lib/jstdlib.o lib/jstdlib.jnh
make clean all
rm bin/jnc lib/jstdlib.o lib/jstdlib.jnh
cp jnc/target/bin/jnc bin
cp jstdlib/target/lib/jstdlib.o lib
cp jstdlib/target/lib/jstdlib.jnh lib
