#!/bin/sh

where=$(pwd)
while [ ! -f can-o-pg.settings ]; do
    if [ -f etc ]; then echo "failed to find top"; exit 3; fi
    cd ..
done
TOP=$(pwd)

### 
cd tests/006-locale

unset MAKEFLAGS
unset MAKELEVEL
owner=ledgersmb
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
    --user ${owner}:${pass} "${url}/setup.pl" >/dev/null

# load that COA
curl -s --include \
     --data-urlencode "s_user=${owner}" \
     --data-urlencode "s_password=${pass}" \
     --data-urlencode "database=${database}" \
     --data-urlencode "coa_lc=ca" \
     --data-urlencode "chart=English_General.sql" \
     --data-urlencode "action=select_coa" \
    --user ${owner}:${pass} "${url}/setup.pl" |
    perl -f ${TOP}/http-sanity.pl | \
    tee OUTPUT/result06.txt | \
    diff -b -u - expected06.txt


