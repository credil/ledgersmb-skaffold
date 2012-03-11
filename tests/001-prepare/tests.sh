#!/bin/sh

while [ ! -f can-o-pg.settings ]; do
    if [ -f etc ]; then echo "failed to find top"; exit 3; fi
    cd ..
done
TOP=$(pwd)
make stop

set -e
rm -rf run
make
sleep 1
./prepare-test-database.sh
