#!/usr/bin/env bash
set -e

function nope() {
    set +x
    echo
    echo "${2} Refusing to proceed."
    echo
    exit $1
}

cd "$(dirname "$0")"

# version numbers
LINE=$(grep -Fn '% ./jnc/target/bin/jnc --version' README.md | cut -d : -f 1)
{
    head -n $LINE README.md
    ./bin/jnc --version
    LINE=$(( LINE + 4))
    tail -n +$LINE README.md | head -n 1
    LINE=$(( LINE + 4))
    echo "pub fn main(){}" | ./bin/jnc | head -n 3
    tail -n +$LINE README.md
} > tmp.md
mv tmp.md README.md

# johanndoc
THRU=0
while true; do
    THRU=$((THRU + 1))
    LINE=$(tail -n +$THRU README.md | grep -En '<!--[{]johanndoc:.+[}]-->' | head -n 1 | cut -d : -f 1)
    if [[ -z "$LINE" ]]; then
        break;
    fi
    THRU=$((THRU + LINE - 1))
    {
        head -n $THRU README.md
        FILE=$(head -n $THRU README.md | tail -n1 | cut -d '{' -f 2 | cut -d : -f 2 | cut -d '}' -f 1)
        STEM=$(echo "$FILE" | rev | cut -d / -f 1 | rev | cut -d . -f 1)
        echo
        echo '### `'"$STEM"'`'
        echo
        DOC=""
        do_file=yes
        while IFS= read -r line; do
            if [[ "$line" =~ ^#.* ]]; then
                DOC="$DOC${line:2} "
                continue
            elif [[ "$line" =~ ^pub.fn ]]; then
                line=$(echo "$line" | cut -d '{' -f 1 | cut -d ';' -f 1)
                if ! echo "$line" | grep -F '_(' > /dev/null; then
                    echo '* `'"$line"'`'" - $DOC"
                fi
                do_file=nope
            elif [[ "$do_file" = "yes" ]]; then
                echo "$DOC"
                echo
                do_file=nope
            fi
            DOC=""
        done < "$FILE"
        echo
        echo "<!--{/johanndoc:$FILE}-->"
        END_LINE=$(tail -n +$THRU README.md | grep -En '<!--[{]/johanndoc(:.+)?[}]-->' | head -n 1 | cut -d : -f 1)
        if [[ -z "$END_LINE" ]]; then
            nope 10 "Failed to find /johanndoc for '$FILE'"
        fi
        tail -n +$((THRU + END_LINE)) README.md
    } > tmp.md
    mv tmp.md README.md
done

# system software
LINE=$(grep -Fn '<!--{systemsoftware}-->' README.md | cut -d : -f 1)
{
    head -n $LINE README.md
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
    LINE=$(grep -Fn '<!--{/systemsoftware}-->' README.md | cut -d : -f 1)
    tail -n +$LINE README.md
} > tmp.md
mv tmp.md README.md
