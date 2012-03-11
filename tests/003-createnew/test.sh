#!/bin/sh

where=$(pwd)
while [ ! -f can-o-pg.settings ]; do
    if [ -f etc ]; then echo "failed to find top"; exit 3; fi
    cd ..
done
TOP=$(pwd)

### 
cd tests/003-createnew

unset MAKEFLAGS
unset MAKELEVEL
owner=ledgersmb
pass=$(cd ${TOP} && make dbpass)
url=$(cd ${TOP}  && make url)

database=notyetexist

mkdir -p OUTPUT

curl -s --include \
     --data-urlencode "s_user=${owner}" \
     --data-urlencode "s_password=${pass}" \
     --data-urlencode "database=${database}" \
     --data-urlencode "action=login" \
    --user ${owner}:${pass} "${url}/setup.pl" | \
    perl -f ${TOP}/http-sanity.pl | \
    tee OUTPUT/result03.txt | \
    diff - expected03.txt


