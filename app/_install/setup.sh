#!/bin/bash

DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

success() {
	echo " Success!"
}

failure() {
	echo " Failed!"
}

cd "$DIR"

echo -en "MySQL username [root]: "; read NAME
NAME=${NAME:-root}

echo -en "MySQL password [vagrant]: "; read -s PASS
PASS=${PASS:-vagrant}

echo -en "\nMySQL server [localhost]: "; read SQL_SERVER
SQL_SERVER=${SQL_SERVER:-localhost}

echo -en "MySQL db name [omgcatz]: "; read DB_NAME
DB_NAME=${DB_NAME:-omgcatz}

echo -en "\nAre you going to use minion servers? [y/n]: "; read HAS_MINIONS
if [ "$HAS_MINIONS" == "y" ]; then
	while :; do
		echo -en "minion root (e.g. http://your_server.com/): "; read SERVER
		[ -z "$SERVER" ] && break
		SERVERS="$SERVERS\"$SERVER\","
	done

	MINIONS="public static \$minions = array($SERVERS);"
else
	if [ ! -d "../api/stuff/download" ]; then
		echo
		git clone "https://github.com/cadejscroggins/omgcatz-minion/" "../api/stuff/download"
		echo -e "\nRunning api/stuff/download/_install/setup.sh..."
		../api/stuff/download/_install/setup.sh
	fi
fi

# create Config class
echo "<?php class Config { public static \$server=\"$SQL_SERVER\",\$user=\"$NAME\",\$password=\"$PASS\",\$database=\"$DB_NAME\";$MINIONS }" > ../api/include/Config.php

# optionally create database
echo -en "\nCreate database $DB_NAME? [y/n]: "; read ANSWER
if [ "$ANSWER" == "y" ]; then
	echo -en "Creating database..."
	echo "create database $DB_NAME" | mysql -u"$NAME" -h"$SQL_SERVER" -p"$PASS" &> /dev/null && success || failure
fi

# optionally create tables
echo -en "\nCreate tables in $DB_NAME? [y/n]: "; read ANSWER
if [ "$ANSWER" == "y" ]; then
	echo -en "Creating tables..."
	php ./create-tables.php && success || failure

	if [ "$HAS_MINIONS" == "y" ]; then
		echo -en "Adding minion servers..."
		php ./install-minions.php && success || failure
	fi
fi
