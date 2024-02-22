#!/bin/bash

make
TO_WATCH=`find .  -maxdepth 1 -type f -name '*.md' `
while inotifywait -e modify $TO_WATCH ; do
  make
done
