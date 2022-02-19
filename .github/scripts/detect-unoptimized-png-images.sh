#!/bin/bash -e
###############################################################################
# This test runs "optipng" on every PNG image and detects non-optimized ones.
###############################################################################

# Report failure if filesize of the image was reduced by more than THRESHOLD percent:
THRESHOLD=1

# Run optipng with "-o1", which is much faster than default (-o2)
OPTIPNG_COMMAND="optipng -o1"

###############################################################################

fails=0

IFS=$'\n' # To iterate over filenames with spaces.
for FILENAME in $(find . -name '*.png'); do
	unset IFS
	PERCENT=$($OPTIPNG_COMMAND $FILENAME 2>&1 | grep 'Output file size' | grep -E -o '([0-9.]+)%' | cut -d% -f1)

	if [ "x$PERCENT" != 'x' ]; then
		if [ $(echo "$PERCENT > $THRESHOLD" | bc) -eq 1 ]; then
			echo "Error: $FILENAME is not optimized: can reduce by $PERCENT% with lossless compression." >&2
			fails=$(( fails + 1 ))
		fi
	fi
done

if [ $fails -gt 0 ]; then
	echo "Test failed: found $fails unoptimized image(s)." >&2
	exit 1
fi

# Success.
exit 0
