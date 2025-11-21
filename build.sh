#!/usr/bin/env bash
set -ex

git restore bin/jnc lib/jstdlib.o

NOW="$(date +%Y%m%d-%H%M%S)"
TAG="build-$NOW"
if git diff --quiet && git diff --staged --quiet; then
    # working copy is clean
    git tag $TAG
else
    # working copy is dirty
    git commit -am "for build: $NOW"
    git tag $TAG
    git reset --soft HEAD^
fi
git branch -f auto-build $TAG
# only keep the last few build tags
git tag --list 'build-*' \
    | sort -nr \
    | tail +20 \
    | xargs git tag -d

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
