#!/usr/bin/env bash
set -ex

function nope() {
    set +x
    echo
    echo "${2} Refusing to proceed."
    echo
    exit $1
}

BRANCH="$(git name-rev --name-only --exclude 'remotes/*' HEAD)"
if [ "${BRANCH}" != "master" ]; then
    nope 1 "You can only release from 'master', not '${BRANCH}'."
fi

if ! git diff --quiet; then
    nope 2 "Working copy is dirty!"
fi

git fetch

if [ "$(git rev-parse origin/master)" != "$(git merge-base master origin/master)" ]; then
    nope 6 "Your 'master' is out of date; need to pull and merge."
fi

# build
make clean
if ! git diff --quiet; then
    nope 3 "Clean created dirtiness?!"
fi
make test all
if ! git diff --quiet; then
    nope 4 "Build created dirtiness?!"
fi
cp jnc/target/bin/jnc bin
cp jstdlib/target/lib/jstdlib.o lib
git add --force bin/jnc lib/jstdlib.o

# update readme
LINE=$(grep -Fn '% ./jnc/target/bin/jnc --version' README.md | cut -d : -f 1)
head -n $LINE README.md > tmp.md
./bin/jnc --version >> tmp.md
LINE=$(( LINE + 4))
tail -n +$LINE README.md >> tmp.md
mv tmp.md README.md
git add README.md

# commit and tag
VERSION=$(./bin/jnc -v | cut -d ' ' -f 2 | cut -d - -f 1)
git commit -a -m "Add v${VERSION} release binaries"
make clean test all
if ! git diff --quiet; then
    nope 5 "Release created dirtiness?!"
fi
git tag -a -m "Release v${VERSION}" "v${VERSION}"

git push --follow-tags
