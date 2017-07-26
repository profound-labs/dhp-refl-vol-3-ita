#!/bin/bash

cat manuscript/tex/versepages.tex |\
sed '/begin[{]dhpVerse/{
    N;N;
    s/^.*[}][{]\([0-9-]\+\)[}].*\n\\label[{]\(dhp-[0-9]\+\)[}].*\n\(.\+\) *\\* *$/\1 \& \3 \& \\pageref{\2}\\\\/;
    s/^\([0-9]\+-\)[0-9]*\([0-9] \)/\1\2/;
}' |\
grep -E '^[0-9-]+ &' | sort -h |\
sed -e 's/\\\\ &/ \&/; s/^/v. /;' > index

