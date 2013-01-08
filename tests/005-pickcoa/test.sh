#!/bin/sh

where=$(pwd)
while [ ! -f can-o-pg.settings ]; do
    if [ -f etc ]; then echo "failed to find top"; exit 3; fi
    cd ..
done
TOP=$(pwd)

### 
cd tests/005-pickcoa

unset MAKEFLAGS
unset MAKELEVEL
owner=$(cd ${TOP} && make dbuser)
pass=$(cd ${TOP} && make dbpass)
url=$(cd ${TOP}  && make url)

echo "DROP DATABASE newco;" | (cd ${TOP} && make psql )

database=newco

mkdir -p OUTPUT

# create the database (same as -04)
curl -s --include \
     --data-urlencode "s_user=${owner}" \
     --data-urlencode "s_password=${pass}" \
     --data-urlencode "database=${database}" \
     --data-urlencode "action=create_db" \
    --user ${owner}:${pass} "${url}/setup.pl" >/dev/null

# create the database using CA Chart-of-Accounts
curl -s --include \
     --data-urlencode "s_user=${owner}" \
     --data-urlencode "s_password=${pass}" \
     --data-urlencode "database=${database}" \
     --data-urlencode "coa_lc=ca" \
     --data-urlencode "action=select_coa" \
    --user ${owner}:${pass} "${url}/setup.pl" |
    perl -f ${TOP}/http-sanity.pl | \
    tee OUTPUT/result05.txt | \
    diff -b -u - expected05.txt


