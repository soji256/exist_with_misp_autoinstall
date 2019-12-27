#!/bin/bash

################################################################
#
# API Keys
#
################################################################
#[DB]
DBUSER_ADMIN=root
DBPASSWORD_ADMIN=xxxxxxxxxxxxxxxxxxx

#[malshare]
MALSHARE_API_KEY=xxxxxxxxxxxxxxxxxxx

#[twitter]
# CK = Consumer API keys
# CS = Consumer API secret key
# AT = Access token 
# AS = Access token secret
TWITTER_CK=xxxxxxxxxxxxxxxxxxx
TWITTER_CS=xxxxxxxxxxxxxxxxxxx
TWITTER_AT=xxxxxxxxxxxxxxxxxxx
TWITTER_AS=xxxxxxxxxxxxxxxxxxx

#[vt]
VT_APIKEY=xxxxxxxxxxxxxxxxxxx

#[AbuseIPDB]
ABUSE_API_KEY=xxxxxxxxxxxxxxxxxxx

#[inoreader]
inoreader_AppID=xxxxxxxxxxxxxxxxxxx
inoreader_AppKey=xxxxxxxxxxxxxxxxxxx
inoreader_Email=xxxxxxxxxxxxxxxxxxx
inoreader_Passwd=xxxxxxxxxxxxxxxxxxx

#[shodan]
shodan_API_KEY=xxxxxxxxxxxxxxxxxxx

#[censys]
censys_API_ID=xxxxxxxxxxxxxxxxxxx
censys_SECRET=xxxxxxxxxxxxxxxxxxx

#[auth-hunter00]
CK0=xxxxxxxxxxxxxxxxxxx
CS0=xxxxxxxxxxxxxxxxxxx
AT0=xxxxxxxxxxxxxxxxxxx
AS0=xxxxxxxxxxxxxxxxxxx

#[auth-hunter01]
CK1=xxxxxxxxxxxxxxxxxxx
CS1=xxxxxxxxxxxxxxxxxxx
AT1=xxxxxxxxxxxxxxxxxxx
AS1=xxxxxxxxxxxxxxxxxxx

#[auth-hunter02]
CK2=xxxxxxxxxxxxxxxxxxx
CS2=xxxxxxxxxxxxxxxxxxx
AT2=xxxxxxxxxxxxxxxxxxx
AS2=xxxxxxxxxxxxxxxxxxx

#[auth-hunter03]
CK3=xxxxxxxxxxxxxxxxxxx
CS3=xxxxxxxxxxxxxxxxxxx
AT3=xxxxxxxxxxxxxxxxxxx
AS3=xxxxxxxxxxxxxxxxxxx

#[auth-hunter04]
CK4=xxxxxxxxxxxxxxxxxxx
CS4=xxxxxxxxxxxxxxxxxxx
AT4=xxxxxxxxxxxxxxxxxxx
AS4=xxxxxxxxxxxxxxxxxxx

################################################################
#
# MISP
#
################################################################

export MISP_AUTHKEY=$(mysql -N -B -u $DBUSER_ADMIN -p$DBPASSWORD_ADMIN -e "use misp;select authkey from users where email = \"admin@admin.test\";")

curl --header "Authorization: ${MISP_AUTHKEY}" --header "Accept: application/json" --header "Content-Type: application/json" http://localhost/feeds/enable/1 
curl --header "Authorization: ${MISP_AUTHKEY}" --header "Accept: application/json" --header "Content-Type: application/json" http://localhost//feeds/fetchFromFeed/1
curl --header "Authorization: ${MISP_AUTHKEY}" --header "Accept: application/json" --header "Content-Type: application/json" http://localhost/feeds/enable/2
curl --header "Authorization: ${MISP_AUTHKEY}" --header "Accept: application/json" --header "Content-Type: application/json" http://localhost//feeds/fetchFromFeed/2
curl --header "Authorization: ${MISP_AUTHKEY}" --header "Accept: application/json" --header "Content-Type: application/json" http://localhost/feeds/enable/66
curl --header "Authorization: ${MISP_AUTHKEY}" --header "Accept: application/json" --header "Content-Type: application/json" http://localhost//feeds/fetchFromFeed/66

################################################################
#
# EXIST
#
################################################################

cd /opt/exist/

########################
### insert2db
########################
cp scripts/insert2db/conf/insert2db.conf.template scripts/insert2db/conf/insert2db.conf
# Set EXIST Path
sed -i -e "s/path\/to\/your\/exist/opt\/exist/" scripts/insert2db/conf/insert2db.conf
# MISP API （URL/Authkey）
sed -i -e "s/YOUR_MISP_URL/localhost\//" scripts/insert2db/conf/insert2db.conf
sed -i -e "s/YOUR_MISP_API_KEY/${MISP_AUTHKEY}/" scripts/insert2db/conf/insert2db.conf
# Malshare API（API Key）
sed -i -e "/\[malshare\]/,/api_key = YOUR_API_KEY/c[malshare]\napi_key = ${MALSHARE_API_KEY}" scripts/insert2db/conf/insert2db.conf
# AbuseIPDB API（API Key）
sed -i -e "/\[abuse\]/,/api_key = YOUR_API_KEY/c[abuse]\napi_key = ${ABUSE_API_KEY}" scripts/insert2db/conf/insert2db.conf
# Twitter API（Consumer API keys, Access token）
sed -i -e "s/YOUR_CK/${TWITTER_CK}/" -e "s/YOUR_CS/${TWITTER_CS}/" -e "s/YOUR_AT/${TWITTER_AT}/" -e "s/YOUR_AS/${TWITTER_AS}/" scripts/insert2db/conf/insert2db.conf
# inoreader API
sed -i -e "/\[inoreader\]/,/Passwd = YOUR_PASSWD/c[inoreader]\nAppID = ${inoreader_AppID}\nAppKey = ${inoreader_AppKey}\nEmail = ${inoreader_Email}\nPasswd = ${inoreader_Passwd}" scripts/insert2db/conf/insert2db.conf

# Cron
tmp_cronfile=$(mktemp)
cat <<EOL >> ${tmp_cronfile}
MAILTO = ''
LANG=ja_JP.UTF-8

# EXIST
*/2 * * * * cd /opt/exist/; source venv-exist/bin/activate; bash -l -c 'python3 scripts/hunter/twitter/tw_watchhunter.py'
*/5 * * * * cd /opt/exist/; source venv-exist/bin/activate; bash -l -c 'python3 scripts/hunter/threat/th_watchhunter.py'

*/3 * * * * cd /opt/exist/; source venv-exist/bin/activate; bash -l -c 'python3 scripts/insert2db/twitter/insert2db.py'
*/3 * * * * cd /opt/exist/; source venv-exist/bin/activate; bash -l -c 'python3 scripts/insert2db/news/insert2db.py'
*/3 * * * * cd /opt/exist/; source venv-exist/bin/activate; bash -l -c 'python3 scripts/insert2db/vuln/insert2db.py'
*/20 * * * * cd /opt/exist/; source venv-exist/bin/activate; bash -l -c 'python3 scripts/insert2db/reputation/insert2db.py'
*/40 * * * * cd /opt/exist/; source venv-exist/bin/activate; bash -l -c 'python3 scripts/insert2db/exploit/insert2db.py'
00 05 * * * cd /opt/exist/; source venv-exist/bin/activate; bash -l -c 'python3 scripts/insert2db/threat/insert2db.py'
00 05 * * * cd /opt/exist/; bash -l -c 'scripts/url/delete_webdata.sh'
00 05 * * * cd /opt/exist/; bash -l -c 'scripts/url/delete_oldtaskresult.sh'
0 */2 * * * curl --header "Authorization: ${MISP_AUTHKEY}" --header "Accept: application/json" --header "Content-Type: application/json" http://localhost//feeds/fetchFromAllFeeds
EOL
crontab -u root ${tmp_cronfile}
rm -f ${tmp_cronfile}

# Hunter config 
cd /opt/exist/
cp scripts/hunter/conf/hunter.conf.template scripts/hunter/conf/hunter.conf

# Set EXIST Path
sed -i -e "s/path\/to\/your\/exist/opt\/exist/" scripts/hunter/conf/hunter.conf

# Change Number of Twitter Hunters (19 -> 5)
sed -i -e  "s/randint(0,18)/randint(0,4)/g" scripts/hunter/twitter/tw_hunter.py

# Twitter API for Hunters
sed -i "/\[auth-hunter00\]/,/AS = YOUR_AS/c[auth-hunter00]\nCK = ${CK0}\nCS = ${CS0}\nAT = ${AT0}\nAS = ${AS0}" scripts/hunter/conf/hunter.conf
sed -i "/\[auth-hunter01\]/,/AS = YOUR_AS/c[auth-hunter01]\nCK = ${CK1}\nCS = ${CS1}\nAT = ${AT1}\nAS = ${AS1}" scripts/hunter/conf/hunter.conf
sed -i "/\[auth-hunter02\]/,/AS = YOUR_AS/c[auth-hunter02]\nCK = ${CK2}\nCS = ${CS2}\nAT = ${AT2}\nAS = ${AS2}" scripts/hunter/conf/hunter.conf
sed -i "/\[auth-hunter03\]/,/AS = YOUR_AS/c[auth-hunter03]\nCK = ${CK3}\nCS = ${CS3}\nAT = ${AT3}\nAS = ${AS3}" scripts/hunter/conf/hunter.conf
sed -i "/\[auth-hunter04\]/,/AS = YOUR_AS/c[auth-hunter04]\nCK = ${CK4}\nCS = ${CS4}\nAT = ${AT4}\nAS = ${AS4}" scripts/hunter/conf/hunter.conf

####################################
### exist.conf
####################################
cp conf/exist.conf.template conf/exist.conf
# VirusTotal
sed -i -e  "s/YOUR_KEY/${VT_APIKEY}/" conf/exist.conf
# geoip
cd /opt/exist/
wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz
gzip -d GeoLite2-City.mmdb.gz
sed -i -e "s/path\/to\/your\/GeoLite2-City.mmdb/opt\/exist\/GeoLite2-City.mmdb/" conf/exist.conf
# shodan
sed -i -e "/\[shodan\]/,/apikey = YOUR_API_KEY/c[shodan]\nbaseURL = https://api.shodan.io/shodan/host/\napikey = ${shodan_API_KEY}" conf/exist.conf
# censys
sed -i -e "/\[censys\]/,/secret = YOUR_SECRET/c[censys]\nbaseURL = https://censys.io/api/v1/\napi_id = ${censys_API_ID}\nsecret = ${censys_SECRET}" conf/exist.conf
# abuse
sed -i -e "/\[abuse\]/,/apikey = YOUR_API_KEY/c[abuse]\nbaseURL = https://api.abuseipdb.com/api/v2/check\napikey = ${ABUSE_API_KEY}" conf/exist.conf

