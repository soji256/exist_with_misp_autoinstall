#!/bin/bash

################################################################
#
# MISP
#
################################################################
# Dwonload install script
wget https://raw.githubusercontent.com/vodkappa/misp-install-centos-7/master/misp.install.sh
wget https://raw.githubusercontent.com/vodkappa/misp-install-centos-7/master/misp.variables.sh

# Modify the php version （rh-php56 -> rh-php72)
sed -i -e "s/rh-php56/rh-php72/g" misp.variables.sh
sed -i -e "s/rh-php56/rh-php72/g" misp.install.sh
sed -i -e "s/yum install python-importlib/##yum install python-importlib/g" misp.install.sh

# Set the DB Charset
CHANGE_DB_CHARSET_TO_UTF8='sed -i -e "$(grep \\\\[mysqld\\\\] -n /etc/my.cnf.d/server.cnf | cut -d : -f 1)a character-set-server=utf8" /etc/my.cnf.d/server.cnf'
sed -i -e "$(grep 'systemctl enable mariadb.service' -n misp.install.sh | cut -d : -f 1)i $CHANGE_DB_CHARSET_TO_UTF8" misp.install.sh

# DB Security setting
sed -i -e "s/mysql_secure_installation/yum install expect -y\nexpect -c \"\nset timeout 5\nspawn mysql_secure_installation\nexpect \\\\\"Enter current password for root\\\\\"\nsend \\\\\"\\\n\\\\\"\nexpect \\\\\"Set root password\\\\\"\nsend \\\\\"y\\\n\\\\\"\nexpect \\\\\"New password\\\\\"\nsend \\\\\"\${DBPASSWORD_ADMIN}\\\n\\\\\"\nexpect \\\\\"Re-enter new password\\\\\"\nsend \\\\\"\${DBPASSWORD_ADMIN}\\\n\\\\\"\nexpect \\\\\"Remove anonymous users\\\\\"\nsend \\\\\"y\\\n\\\\\"\nexpect \\\\\"Disallow root login remotely\\\\\"\nsend \\\\\"y\\\n\\\\\"\nexpect \\\\\"Remove test database and access to it\\\\\"\nsend \\\\\"y\\\n\\\\\"\nexpect \\\\\"Reload privilege tables now\\\\\"\nsend \\\\\"y\\\n\\\\\"\nexpect \\'$\\\\\"\nexit 0\n\"/g" misp.install.sh

source misp.variables.sh

echo include_only=.jp >> /etc/yum/pluginconf.d/fastestmirror.conf

bash misp.install.sh


################################################################
#
# EXIST
#
################################################################
## Install Python 3.x
yum install -y https://centos7.iuscommunity.org/ius-release.rpm
yum install python3 python3-libs python3-devel python3-pip -y

## Git clone EXIST
cd /opt
git clone https://github.com/nict-csl/exist.git

## Create EXIST DB
export DBPASSWORD_EXIST=$(openssl rand -hex 32)
mysql -u $DBUSER_ADMIN -p$DBPASSWORD_ADMIN -e "create database intelligence_db;"
mysql -u $DBUSER_ADMIN -p$DBPASSWORD_ADMIN -e "create user 'exist'@'localhost' identified by '${DBPASSWORD_EXIST}';"
mysql -u $DBUSER_ADMIN -p$DBPASSWORD_ADMIN -e "grant ALL on intelligence_db.* to exist;"

## Install venv
cd /opt/exist
python3 -m venv venv-exist
source venv-exist/bin/activate

## Install EXIST requirements
cd /opt/exist
pip install -r requirements.txt

cp intelligence/settings.py.template intelligence/settings.py
sed -i -e "s/ALLOWED_HOSTS = \[/ALLOWED_HOSTS = \[\n     'localhost',\n     '$(ip -4 a show ens33 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')',/g" intelligence/settings.py
sed -i -e "s/YOUR_DB_USER/exist/g" intelligence/settings.py
sed -i -e "s/YOUR_DB_PASSWORD/${DBPASSWORD_EXIST}/g" intelligence/settings.py
sed -i -e "s/'HOST': ''/'HOST': 'localhost'/g" intelligence/settings.py
sed -i -e "s/\"SET CHARACTER SET utf8mb4;\"/\"SET CHARACTER SET utf8mb4;\"\n                            \"SET sql_mode='STRICT_TRANS_TABLES';\"/g" intelligence/settings.py

python3 manage.py makemigrations exploit reputation threat threat_hunter twitter twitter_hunter
python3 manage.py migrate

## Make celery config
cat <<EOL >> /etc/sysconfig/celery
# Name of nodes to start
# here we have a single node
CELERYD_NODES="localhost"
# or we could have three nodes:
#CELERYD_NODES="w1 w2 w3"

# Absolute or relative path to the 'celery' command:
CELERY_BIN="/opt/exist/venv-exist/bin/celery"

# App instance to use
# comment out this line if you don't use an app
CELERY_APP="intelligence"
# or fully qualified:
#CELERY_APP="proj.tasks:app"

# How to call manage.py
CELERYD_MULTI="multi"

# Extra command-line arguments to the worker
CELERYD_OPTS="--time-limit=300 --concurrency=8"

# - %n will be replaced with the first part of the nodename.
# - %I will be replaced with the current child process index
# and is important when using the prefork pool to avoid race conditions.
CELERYD_PID_FILE="/var/run/celery/%n.pid"
CELERYD_LOG_FILE="/var/log/celery/%n%I.log"
CELERYD_LOG_LEVEL="INFO"
EOL

cat <<EOL >> /etc/systemd/system/celery.service
[Unit]
Description=Celery Service
After=network.target

[Service]
Type=forking
User=root
Group=root
EnvironmentFile=/etc/sysconfig/celery
WorkingDirectory=/opt/exist
ExecStart=/bin/sh -c '${CELERY_BIN} multi start ${CELERYD_NODES} \
-A ${CELERY_APP} --pidfile=${CELERYD_PID_FILE} \
--logfile=${CELERYD_LOG_FILE} --loglevel=${CELERYD_LOG_LEVEL} ${CELERYD_OPTS}'
ExecStop=/bin/sh -c '${CELERY_BIN} multi stopwait ${CELERYD_NODES} \
--pidfile=${CELERYD_PID_FILE}'
ExecReload=/bin/sh -c '${CELERY_BIN} multi restart ${CELERYD_NODES} \
-A ${CELERY_APP} --pidfile=${CELERYD_PID_FILE} \
--logfile=${CELERYD_LOG_FILE} --loglevel=${CELERYD_LOG_LEVEL} ${CELERYD_OPTS}'

[Install]
WantedBy=multi-user.target
EOL

mkdir /var/log/celery; chown root:root /var/log/celery
mkdir /var/run/celery; chown root:root /var/run/celery

cat <<EOL >> /etc/tmpfiles.d/exist.conf
#Type  Path               Mode  UID        GID         Age  Argument
d      /var/run/celery    0755  root  root  -
EOL

systemctl start celery.service
systemctl enable celery.service

firewall-cmd --zone=public --add-port=8000/tcp --permanent
firewall-cmd --reload

## Add Tweet Link
sed -i -e "s/{{ tw.datetime }}/\<a href=\"https:\/\/twitter.com\/{{ tw.screen_name }}\/status\/{{ tw.id }}\"\>{{ tw.datetime }}\<\/a\>/g" apps/twitter/templates/twitter/index.html
sed -i -e "s/{{ tw.datetime }}/\<a href=\"https:\/\/twitter.com\/{{ tw.screen_name }}\/status\/{{ tw.id }}\"\>{{ tw.datetime }}\<\/a\>/g" apps/dashboard/templates/dashboard/index.html
sed -i -e "s/{{ tw.datetime }}/\<a href=\"https:\/\/twitter.com\/{{ tw.screen_name }}\/status\/{{ tw.id }}\"\>{{ tw.datetime }}\<\/a\>/g" apps/twitter_hunter/templates/twitter_hunter/tweets.html

## EXIST Service
cat <<EOL >> /etc/systemd/system/exist.service
[Unit]
Description = EXIST
After = celery.service

[Service]
ExecStart=/opt/exist/venv-exist/bin/python3 /opt/exist/manage.py runserver 0.0.0.0:8000
Restart=always
Type=simple
KillMode=control-group
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

systemctl start exist.service
systemctl enable exist.service

echo "Admin (root) DB Password: ${DBPASSWORD_ADMIN}"
echo "User  (misp) DB Password: ${DBPASSWORD_MISP}"
echo "User (exist) DB Password: ${DBPASSWORD_EXIST}"
echo "MISP default login: admin@admin.test / admin"

