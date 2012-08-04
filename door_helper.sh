#!/bin/bash

if [ "$USER" == "root" ]; then
. /etc/hid-door-creds.conf
else
username=user
fi

resultfile=`mktemp`
action="/cgi-bin/vertx_xml.cgi"
open_xml='<?xml version="1.0" encoding="UTF-8"?><VertXMessage><hid:Doors action="CM" command="grantAccess"/></VertXMessage>'
lock_xml='<?xml version="1.0" encoding="UTF-8"?><VertXMessage><hid:Doors action="CM" command="lockDoor"/></VertXMessage>'
unlock_xml='<?xml version="1.0" encoding="UTF-8"?><VertXMessage><hid:Doors action="CM" command="unlockDoor"/></VertXMessage>'


# Pick which action
if [ "$2" == "lock" ]; then
	# Lock the Door
	xml="$lock_xml"
	descriptor="Locked"
	# prompt for password
	if [ "$USER" == "root" ]; then
		echo "Running as root, no password required."
	else
		password=""
	fi
elif [ "$2" == "unlock" ]; then
	# Unlock the Door
	xml="$unlock_xml"
	descriptor="Unlocked"
	if [ "$USER" == "root" ]; then
		echo "Running as root, no password required."
	else
		password=""
	fi
else
	# Default action is to grant access
	xml="$open_xml"
	descriptor="Access Granted to "
fi

# Pick Which Door
if [ "$1" == "coop" ]; then
	door=Coop
	hostname="10.19.4.130"
else
	door=External
	hostname="10.19.4.129"
fi

if [ "$password" == "" ]; then
	password=$(zenity --entry \
		--title="Enter Door Password" \
		--text="Please enter the door control password" \
		--hide-text )

fi

if [ "$password" != "" ]; then
	urlencodedxml=`perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$xml"`
	url="https://${hostname}${action}?XML=${urlencodedxml}"

	if [ "$DISPLAY" != "" ]; then
		zenity --info --text="$descriptor $door Door" &
	fi
	echo "$descriptor $door Door" 

	wget --output-document=$resultfile \
		--quiet \
		--no-check-certificate \
		--user=$username \
		--password=$password "$url"
fi

rm $resultfile
