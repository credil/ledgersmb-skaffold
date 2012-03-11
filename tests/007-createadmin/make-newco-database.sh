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
    --user ${owner}:${pass} "${url}/setup.pl" 