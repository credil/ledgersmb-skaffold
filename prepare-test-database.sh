#!/bin/sh

# Script to explain the steps to take when installing LedgerSMB
# tsearch2.sql is in /usr/share/postgresql/XX/contrib,
#  and in debian can be found in postgresql-contrib-XX
# Default variable values section

owner=ledgersmb
pass=LEDGERSMBINITIAL
host=$(make dbpath)
port=5432
srcdir=ledgersmb
dstdir=public
coa=$srcdir/sql/coa/us/chart/General.sql
gifi=
pgsql_contrib_dir=ignore
ADMIN_FIRSTNAME='Default'
ADMIN_MIDDLENAME=NULL
ADMIN_LASTNAME='Admin'
ADMIN_USERNAME='admin'
ADMIN_PASSWORD='admin'
#PSQL='su postgres -c "psql -U postgres -d postgres "'
PSQL="make psql"

company_name=bigcocom
extension=""
for pgsql_contrib_dir in /usr/share/postgresql/*/extension 
do
  for found in ${pgsql_contrib_dir}/tsearch2*
  do
    if [ -f $found ]; then extension="tsearch2 "; fi
  done
done

if [ -z "$extension" ]; then
    for pgsql_contrib_dir in /usr/share/postgresql/*/contrib ignore
      do
      for found in ${pgsql_contrib_dir}/tsearch2*
        do
        if [ -f $found ]; then break 2; fi
      done
    done
    echo pgsql_contrib_dir: $pgsql_contrib_dir
fi

# Usage explanation section

# Function to remove unnecessary chatter from PSQL, as well as
# some notices and errors that the user doesn't need to worry about
unchatter () {
sed -re "/^[[:space:]]*(\
CREATE (TABLE|FUNCTION|TYPE|DOMAIN|OPERATOR|ROLE|SEQUENCE|INDEX|AGGREGATE|\
DATABASE|VIEW|TRIGGER|RULE|LANGUAGE)|\
COMMENT|GRANT|REVOKE|SET|setval|ALTER TABLE|COMMIT|BEGIN|INSERT 0|\
account_(heading_)?save|\
admin__(save_user|add_user_to_role)|\
You are now connected to database|\
NOTICE:.*does not exist|\
NOTICE:.*will create implicit|\
NOTICE:.*type.*gtrgm|\
NOTICE:.*type.*tsvector|\
DETAIL: *Creating a shell type definition|\
ERROR:  language \"plpgsql\" already exists|\
[[:space:]0-9-]*$|\
\([0-9[:space:]]+rows?\)\
)/d" -
}

# Extract options and setup variables
if ! options=$( getopt -u -l company:,coa:,gifi:,srcdir:,dstdir:,password:,host:,port:,help,progress,pgsql-contrib: '' "$@" )
then
  exit 1
fi

set -- $options
while test $# -gt 0 ;
do

  shift_args=2
  case "$1" in
    --)
        shift_args=1
        ;;
    --company)
	company_name=$2
#	break
	;;
    --coa)
        coa=$2
#	break
	;;
    --gifi)
	gifi=$2
#	break
	;;
    --srcdir)
	srcdir=$2
#	break
	;;
    --dstdir)
	dstdir=$2
#	break
	;;
    --password)
	pass=$2
#	break
	;;
    --host)
	host=$2
#	break
	;;
    --port)
	port=$2
#	break
	;;
    --pgsql-contrib)
        pgsql_contrib_dir=$2
#	break
	;;
    --progress)
        progress=yes
        shift_args=1
#	break
	;;
    --help)
	usage
	exit 0;;
  esac
  shift $shift_args
done

if test -z "$company_name"
then
  echo "missing or empty --company option"
  usage
  exit 1
fi

if test "$pgsql_contrib_dir" = "ignore"
then
  echo "missing argument --pgsql-contrib!"
  usage
  exit 1
fi

if ! test -f $srcdir/sql/modules/LOADORDER
then
  echo "missing file $srcdir/sql/modules/LOADORDER! (use --srcdir argument)"
  usage
  exit 1
fi

psql_args="-h $host -p $port -U $owner"
#psql_cmd="psql $psql_args -d $company_name"


if test -n "$progress"
then
  # Use shell command-echoing to "report progress"
  set -x
fi

sed -e "s|WORKING_DIR|$dstdir|g" \
   $srcdir/ledgersmb-httpd.conf.template >$dstdir/ledgersmb-httpd.conf
cat <<EOF | $PSQL 2>&1 | unchatter
CREATE ROLE $owner WITH SUPERUSER LOGIN NOINHERIT ENCRYPTED PASSWORD '$pass';
CREATE DATABASE $company_name WITH ENCODING = 'UNICODE' OWNER = $owner TEMPLATE = template0;
\\c $company_name
CREATE LANGUAGE plpgsql;
EOF

PGPASSWORD=$pass
export PGPASSWORD

PSQLUSER="-U $owner" 
DATABASE=$company_name 
export PSQLUSER DATABASE
psql_cmd="make psql"


#createdb $psql_args -O $owner -E UNICODE $company_name
#createlang $psql_args plpgsql $company_name

# Load the required PostgreSQL contribs, on 9.1, not necessary.
if [ -z "$extension" ]; then
    if ! test "x$pgsql_contrib_dir" = "xignored"
        then
        for contrib in tsearch2.sql pg_trgm.sql tablefunc.sql
        do
          cat $pgsql_contrib_dir/$contribit | $psql_cmd 2>&1 | unchatter
        done
    fi
fi

# Load the base file(s)
# -- Basic database structure
echo -n Loading core...
cat $srcdir/sql/Pg-database.sql | $psql_cmd 2>&1 | unchatter
echo done.
# -- Additional database structure
for module in `grep -v -E '^[[:space:]]*#' $srcdir/sql/modules/LOADORDER`
do
  echo -n Loading $module...
  cat $srcdir/sql/modules/$module | $psql_cmd 2>&1 | unchatter
  echo done.
done

echo -n Loading Roles.sql...
# -- Authorizations
sed -e "s/<?lsmb dbname ?>/$company_name/g" $srcdir/sql/modules/Roles.sql >/tmp/lsmb-roles$$.sql
#echo file is: /tmp/lsmb-roles$$.sql
#$psql_cmd
cat /tmp/lsmb-roles$$.sql | $psql_cmd 2>&1 | unchatter
echo done.

if ! test "$coa" = "none" ; then
  # Load a chart of accounts
  echo -n Loading $coa...
  cat $coa | $psql_cmd 2>&1 | unchatter
  if test -n "$gifi" ; then
      echo cone
      echo -n Loading $gifi...
    cat $gifi | $psql_cmd 2>&1 | unchatter
  fi
  echo done.
fi

cat <<EOF | $psql_cmd 2>&1 | unchatter
\\COPY language FROM stdin WITH DELIMITER '|'
`$srcdir/tools/generate-language-table-contents.pl $srcdir/locale/po`
EOF


cat <<CREATE_USER | $psql_cmd 2>&1 | unchatter
SELECT admin__save_user(NULL,
                         person__save(NULL,
                                      3,
                                      '$ADMIN_FIRSTNAME',
                                      '$ADMIN_MIDDLENAME',
                                      '$ADMIN_LASTNAME',
                                      (SELECT id FROM country
                                       WHERE short_name = 'US')),
                         '$ADMIN_USERNAME',
                         '$ADMIN_PASSWORD',
                         TRUE);

SELECT admin__add_user_to_role('$ADMIN_USERNAME', rolname)
FROM pg_roles
WHERE rolname like 'lsmb_${company_name}_%';

CREATE_USER
