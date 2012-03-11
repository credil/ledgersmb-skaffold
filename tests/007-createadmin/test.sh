#!/bin/sh

where=$(pwd)
while [ ! -f can-o-pg.settings ]; do
    if [ -f etc ]; then echo "failed to find top"; exit 3; fi
    cd ..
done
TOP=$(pwd)

### 
cd tests/007-createadmin

unset MAKEFLAGS
unset MAKELEVEL
owner=ledgersmb
pass=$(cd ${TOP} && make dbpass)
url=$(cd ${TOP}  && make url)

echo "DROP DATABASE newco;" | (cd ${TOP} && make psql )

database=newco

mkdir -p OUTPUT

. make-newco-database.sh |
    perl -f ${TOP}/http-sanity.pl | \
    tee OUTPUT/result07.txt | \
    diff -b -u - expected07.txt


