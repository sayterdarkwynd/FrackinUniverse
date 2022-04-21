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

# If some image wasn't added/modified compared to the master branch, then it won't be checked,
# because we have 30k+ images, and rechecking them every time would take ~8 minutes.
git fetch --depth=1 origin master
FILES=$(git diff origin/master --name-only --no-renames --diff-filter=ACM | grep -E '\.png$' | sort)

if [ "x$FILES" == 'x' ]; then
	echo "Nothing to check: no images changed since the master branch."
	exit 0
fi

echo "Checking PNG images: $FILES"

for FILENAME in $FILES; do
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
