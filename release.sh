#!/usr/bin/env bash
set -ex

function nope() {
    set +x
    echo
    echo "${2} Refusing to proceed."
    echo
    exit $1
}

cd "$(dirname "$0")"

BRANCH="$(git name-rev --name-only --exclude 'remotes/*' HEAD)"
if [ "${BRANCH}" != "master" ]; then
    nope 1 "You can only release from 'master', not '${BRANCH}'."
fi

if ! git diff --quiet; then
    nope 2 "Working copy is dirty."
fi

if git log --oneline | grep -E 'fixup|WIP|DEV'; then
    nope 9 "Found temp commits in log."
fi

if ! grep -qE '^### Bleeding Edge' documentation/docs/versions/index.md; then
    nope 10 "No docs for this release."
fi

git fetch

if [ "$(git rev-parse origin/master)" != "$(git merge-base master origin/master)" ]; then
    nope 6 "Your 'master' is out of date; need to pull and merge."
fi

# build
make clean
if ! git diff --quiet; then
    nope 3 "Clean created dirtiness"
fi
make test all
if ! git diff --quiet; then
    nope 4 "Build created dirtiness"
fi
cp jnc/target/bin/jnc bin
strip bin/jnc
cp jstdlib/target/lib/jstdlib.o lib
cp jstdlib/target/lib/jstdlib.jnh lib
if ! make clean test all not_quite_lisp; then
    nope 7 "Not Quite Lisp doesn't work anymore"
fi
git add --force bin/jnc lib/jstdlib.o lib/jstdlib.jnh

./johanndoc.sh

# version numbers
DOC_FILE=documentation/docs/system/index.md
LINE=$(grep -Fn '% ./jnc/target/bin/jnc --version' $DOC_FILE | cut -d : -f 1)
{
    head -n $LINE $DOC_FILE
    ./bin/jnc --version
    LINE=$(( LINE + 4 ))
    tail -n +$LINE $DOC_FILE | head -n 1
    LINE=$(( LINE + 4 ))
    echo "pub fn main(){}" | ./bin/jnc | head -n 3
    tail -n +$LINE $DOC_FILE
} > tmp.md
mv tmp.md $DOC_FILE

# system software
DOC_FILE=documentation/docs/system/index.md
LINE=$(grep -Fn '<!--{systemsoftware}-->' $DOC_FILE | cut -d : -f 1)
{
    head -n $LINE $DOC_FILE
    echo '```'
    echo '% uname -a'
    uname -a
    echo "%"
    echo '% make --version'
    make --version
    echo "%"
    echo '% gcc --version'
    gcc --version
    echo "%"
    echo '% ld -v'
    ld -v 2>&1
    echo '```'
    LINE=$(grep -Fn '<!--{/systemsoftware}-->' $DOC_FILE | cut -d : -f 1)
    tail -n +$LINE $DOC_FILE
} > tmp.md
mv tmp.md $DOC_FILE

# update release history
VERSION="v$(./bin/jnc -v | cut -d ' ' -f 2 | cut -d - -f 1)"
DOC_FILE=documentation/docs/versions/index.md
LINE=$(grep -Fn '### Bleeding Edge' $DOC_FILE | cut -d : -f 1)
if [ -z "$LINE" ]; then
    nope 8 "Didn't find 'Bleeding Edge' heading in release history to promote."
fi
{
    LINE=$(( LINE - 1 ))
    head -n $LINE $DOC_FILE
    echo '[//]: # (### Bleeding Edge)'
    echo
    echo '### `'"$VERSION"'`'
    echo
    LINE=$(( LINE + 3 ))
    tail -n +$LINE $DOC_FILE
} > tmp.md
mv tmp.md $DOC_FILE

git add documentation

# commit and tag
git commit -a -m "Add ${VERSION} release binaries"
make clean test all
if ! git diff --quiet; then
    nope 5 "Release created dirtiness"
fi
git tag -a -m "Release ${VERSION}" "${VERSION}"
