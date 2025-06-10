#!/usr/bin/env zsh
set -e

cd "$(dirname "$0")"

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
        echo "  documenting '$STEM' (from $FILE)"
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
        {
            head -n $THRU $DOC_FILE
            echo
            echo '### `'"$STEM"'`'
            echo
            DOC=""
            do_file=yes
            while IFS= read -r line; do
                if [ "$line" = "#" ]; then
                    DOC="$DOC\n\n"
                    continue
                elif [[ "$line" =~ ^#.* ]]; then
                    if [ -n "$DOC" ]; then
                        DOC="$DOC "
                    fi
                    DOC="$DOC${line:2}"
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
            tail -n +$(( THRU + END_LINE )) $DOC_FILE
        } > tmp.md
        mv tmp.md $DOC_FILE
    done
done
