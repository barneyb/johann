#!/usr/bin/env zsh
set -e

cd "$(dirname "$0")"
TARGET=target
mkdir -p "$TARGET"

ACTION="doc"
if [ "$1" = "-u" ]; then
    ACTION="undoc"
    shift
fi
if [ "$1" = "--undoc" ]; then
    ACTION="undoc"
    shift
fi

find documentation/docs/ -name '*.jn.md' -exec rm {} \;

if [ "$ACTION" = "doc" ]; then
    for f in $(ls jnc/*.jn | sort -df); do
        (
            echo "---\ntitle: $(basename "$f" | cut -d . -f 1)\n---"
            echo "<!--{johanndoc:$f}-->\n<!--{/johanndoc}-->"
        ) > documentation/docs/system/compiler/$(basename "$f" | tr '[:upper:]' '[:lower:]').md
    done

    for f in $(ls jstdlib/*.jn | sort -df); do
        (
            echo "---\ntitle: $(basename "$f" | cut -d . -f 1)\n---"
            echo "<!--{johanndoc:$f}-->\n<!--{/johanndoc}-->"
        ) > documentation/docs/library/$(basename "$f" | tr '[:upper:]' '[:lower:]').md
    done
fi

for DOC_FILE in `grep -lF '<!--{johanndoc:' documentation/**/*.md`; do
    echo "processing $DOC_FILE"
    THRU=0
    while true; do
        THRU=$(( THRU + 1 ))
        LINE=$(tail -n +$THRU $DOC_FILE | grep -En '<!--[{]johanndoc:.+[}]-->' | head -n 1 | cut -d : -f 1)
        if [[ -z "$LINE" ]]; then
            break;
        fi
        THRU=$(( THRU + LINE - 1 ))
        FILE=$(head -n $THRU $DOC_FILE | tail -n1 | cut -d '{' -f 2 | cut -d : -f 2 | cut -d '}' -f 1)
        STEM=$(echo "$FILE" | rev | cut -d / -f 1 | rev | cut -d . -f 1)
        echo "  ${ACTION}umenting '$STEM' (from $FILE)"
        END_LINE=$(tail -n +$THRU $DOC_FILE | grep -En '<!--[{]/johanndoc(:.*)?[}]-->' | head -n 1 | cut -d : -f 1)
        if [ -z "$END_LINE" ]; then
            echo "File '$FILE' opened line $THRU is never closed"
            exit 4
        fi
        END_FILE=$(tail -n +$(( THRU + END_LINE - 1 )) $DOC_FILE | head -n1 | cut -d '{' -f 2 | cut -d : -f 2 | cut -d '}' -f 1)
        if [ "$END_FILE" != "$FILE" ] && [ "$END_FILE" != "/johanndoc" ]; then
            echo "File '$FILE' opened line $THRU mis-closed by '$END_FILE' on line $((THRU + END_LINE - 1))"
            exit 4
        fi
        is_pre=nope
        {
            head -n $THRU $DOC_FILE
            if [ "$ACTION" = "doc" ]; then
                TMP="$TARGET/$STEM"
                rm -rf $TMP
                mkdir -p "$TMP"
                echo
                DOC=""
                do_file=yes
                while IFS= read -r line; do
                    if [ "$line" = "#" ]; then
                        DOC="$DOC\n\n"
                        continue
                    elif [[ "$line" =~ ^#.* ]]; then
                        if [[ "$line" =~ '^# +```' ]]; then
                            nl="\n"
                            if [[ "$is_pre" = "yes" ]]; then
                                is_pre=nope
                            else
                                is_pre=yes
                            fi
                        elif [[ "$line" =~ '^# +(\*|\d+.) ' ]]; then
                            nl="\n"
                        elif [[ "$is_pre" == "yes" ]]; then
                            nl="\n"
                        else
                            nl=" "
                        fi
                        if [ -n "$DOC" ]; then
                            DOC="$DOC$nl"
                        fi
                        DOC="$DOC${line:2}"
                        continue
                    elif [[ "$line" =~ ^pub ]]; then
                        type=$(echo "$line" | cut -d ' ' -f 2)
                        name=$(echo "$line" | cut -d ' ' -f 3 | cut -d '(' -f 1)
                        line=$(echo "$line" | cut -d '{' -f 1)
                        if ! echo "$line" | grep -F '_(' > /dev/null; then
                            if [[ "$type" = "fn" ]]; then
                                fn="`echo "$line" | sed -E -e 's/[^a-zA-Z0-9_]/-/g'`.fn.txt"
                                echo '### `'"$name"'`'"\n\n"'`'"$line"'`'"\n\n$DOC\n" > $TMP/$fn
                            else
                                echo '### `'"$name"'`'"\n\n"'`'"$line"'`'"\n\n$DOC\n"
                            fi
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
                ls $TMP/*.fn.txt | xargs cat
            fi
            echo "<!--{/johanndoc:$FILE}-->"
            tail -n +$(( THRU + END_LINE )) $DOC_FILE
        } > $TARGET/tmp.md
        cp $TARGET/tmp.md $DOC_FILE
    done
done

if [ "$ACTION" = "undoc" ]; then
    exit
fi

if [ "$CI" = "true" ]; then
    exit
fi

JNC=./jnc/target/bin/jnc
if [ ! -f "$JNC" ]; then
    make -C jnc all
fi
OUT=$TARGET/out
mkdir -p "$OUT"
cat > $OUT/fixtures.jn << EOF
    pub char* GREETING = "Hello, world!\n";
    pub fn add(int a, int b) {
        return a + b;
    }
EOF
$JNC < $OUT/fixtures.jn > $OUT/fixtures.s
gcc -o $OUT/fixtures.o -c $OUT/fixtures.s
for BLOCK in `grep -HnE '^\`\`\`johann$' documentation/**/*.md | cut -d : -f 1,2`; do
    DOC_FILE=$(echo $BLOCK | cut -d : -f 1)
    LINE=$(echo $BLOCK | cut -d : -f 2)
    LINE=$(( LINE + 1 ))
    NLINES=$(tail -n +$LINE $DOC_FILE | grep -nEm1 '^```$' | cut -d : -f 1)
    NLINES=$(( NLINES - 1 ))
    echo "$DOC_FILE from $LINE for $NLINES"
    ROOT="$OUT/$(echo $DOC_FILE | tr -cs '[:alnum:]' "_")_$LINE"
    tail -n +$LINE $DOC_FILE | head -n $NLINES > ${ROOT}.jn
    if ! grep -F 'fn ' ${ROOT}.jn > /dev/null; then
        # need to wrap with prelude
        rm -f ${ROOT}.p.jn
        echo "struct ArrayList;" >> ${ROOT}.p.jn
        echo "pub fn main() {" >> ${ROOT}.p.jn
        cat ${ROOT}.jn >> ${ROOT}.p.jn
        echo "}" >> ${ROOT}.p.jn
        mv ${ROOT}.p.jn ${ROOT}.jn
    fi
    $JNC < ${ROOT}.jn > ${ROOT}.s
    if grep -F 'fn main' ${ROOT}.jn > /dev/null; then
        gcc -o ${ROOT}.out ${ROOT}.s ./lib/jstdlib.o $OUT/fixtures.o
        echo "goober!" | ./${ROOT}.out
    else
        gcc -o ${ROOT}.o -c ${ROOT}.s
    fi
done
