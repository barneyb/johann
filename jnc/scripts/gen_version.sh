#!/usr/bin/env bash

BASE="0."
TS=$(date -u -Iseconds)
DATE=$(echo "$TS" | cut -c 1-4,6-7,9-10)
SHORT_HASH=$(git rev-parse --short HEAD)
HASH=$(git rev-parse HEAD)
printf "pub char* JNC_SHORT_VERSION = \"jnc %s%s-%s\";\n" "$BASE" "$DATE" "$SHORT_HASH"
printf "pub char* JNC_LONG_VERSION  = \"jnc %s%s\\\nbuild_time: %s\\\ncommit_hash: %s\";\n" "$BASE" "$DATE" "$TS" "$HASH"
