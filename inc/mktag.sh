#!/bin/sh
echo -n "Generating tags ... "
tar xf ../../../inc/mktag.tar || exit 1
cat ../../../inc/maketag.gen > maketag.gen || exit 1
sh maketag.gen
rm -f maketag.1 maketag.2 maketag.3 maketag.4 maketag.gen
echo "done"
