#!/bin/sh

where=$(pwd)
while [ ! -f can-o-pg.settings ]; do
    if [ -f etc ]; then echo "failed to find top"; exit 3; fi
    cd ..
done
TOP=$(pwd)

### 
cd tests/07-createadmin

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

# load that COA and COA_LC
curl -s --include \
     --data-urlencode "s_user=${owner}" \
     --data-urlencode "s_password=${pass}" \
     --data-urlencode "database=${database}" \
     --data-urlencode "coa_lc=ca" \
     --data-urlencode "chart=English_General.sql" \
     --data-urlencode "action=select_coa" \
    --user ${owner}:${pass} "${url}/setup.pl" >/dev/null

# now create the admin
curl -s --include \
     --data-urlencode "s_user=${owner}" \
     --data-urlencode "s_password=${pass}" \
     --data-urlencode "database=${database}" \
     --data-urlencode "action=save_user" \
     --data-urlencode "username=guy" \
     --data-urlencode "password=smiley" \
     --data-urlencode "import=1" \
     --data-urlencode "salutation_id=3" \
     --data-urlencode "first_name=Guy" \
     --data-urlencode "last_name=Smiley" \
     --data-urlencode "employeenumber=1" \
     --data-urlencode "country_id=38" \
     --data-urlencode "perms=1" \
    --user ${owner}:${pass} "${url}/setup.pl" |
    perl -f ${TOP}/http-sanity.pl | \
    tee OUTPUT/result07.txt | \
    diff -b -u - expected07.txt


