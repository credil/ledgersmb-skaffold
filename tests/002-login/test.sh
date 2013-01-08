#!/bin/sh

where=$(pwd)
while [ ! -f can-o-pg.settings ]; do
    if [ -f etc ]; then echo "failed to find top"; exit 3; fi
    cd ..
done
TOP=$(pwd)
cd tests/002-login

unset MAKEFLAGS
unset MAKELEVEL
owner=$(cd ${TOP} && make dbuser)
pass=$(cd ${TOP} && make dbpass)
url=$(cd ${TOP}  && make url)

mkdir -p OUTPUT

curl -s --include --user ${owner}:${pass} "${url}/login.pl?action=authenticate&company=template1" | \
    perl -f ${TOP}/http-sanity.pl | \
    tee OUTPUT/result02.txt | \
    diff - expected02.txt

