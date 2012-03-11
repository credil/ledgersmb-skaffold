#!/bin/sh

where=$(pwd)
while [ ! -f can-o-pg.settings ]; do
    if [ -f etc ]; then echo "failed to find top"; exit 3; fi
    cd ..
done
TOP=$(pwd)

### 
cd tests/008-firstlogin

unset MAKEFLAGS
unset MAKELEVEL
owner=ledgersmb
pass=$(cd ${TOP} && make dbpass)
url=$(cd ${TOP}  && make url)

(echo "DROP DATABASE newco;" | (cd ${TOP} && make psql ) || exit 0)

database=newco

mkdir -p OUTPUT

. ../007-createadmin/make-newco-database.sh >/dev/null


login=guy
passwd=smiley

curl -s --include \
    --user ${login}:${passwd} "${url}/login.pl?action=authenticate&company=newco" | \
    perl -f ${TOP}/http-sanity.pl | \
    tee OUTPUT/result008a.txt | \
    diff -b -u - expected008a.txt

# should capture the cookie and use it...