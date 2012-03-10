#!/bin/sh

where=$(pwd)
while [ ! -f can-o-pg.settings ]; do
    if [ -f etc ]; then echo "failed to find top"; exit 3; fi
    cd ..
done
TOP=$(pwd)

### 
cd tests/04-makenew

unset MAKEFLAGS
unset MAKELEVEL
owner=ledgersmb
pass=$(cd ${TOP} && make dbpass)
url=$(cd ${TOP}  && make url)

echo "DROP DATABASE newco;" | (cd ${TOP} && make psql )

database=newco

mkdir -p OUTPUT

curl -s --include \
     --data-urlencode "s_user=${owner}" \
     --data-urlencode "s_password=${pass}" \
     --data-urlencode "database=${database}" \
     --data-urlencode "action=create_db" \
    --user ${owner}:${pass} "${url}/setup.pl" | \
    perl -f ${TOP}/http-sanity.pl | \
    tee OUTPUT/result04.txt | \
    diff - expected04.txt


