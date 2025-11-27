#!/bin/bash

FILE="$1"

# 1) Normalize masterNN- → (remove prefix)
sed -i 's/include::master[0-9]\+-/include::/' "$FILE"

# remove amendment record and add it to the end of the adoc
if grep -q 'include::.*amendment_record\.adoc' "$FILE"; then
  sed -i '/include::.*amendment_record\.adoc/d' "$FILE"
  {
    echo
    echo "include::amendment_record.adoc[leveloffset=+1]"
  } >> "$FILE"
fi

