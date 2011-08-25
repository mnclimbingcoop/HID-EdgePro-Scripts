#!/bin/bash

now=`date +%Y%m%d-%H-%M-%S`

# Timout to try to download the events.csv file (in minutes)
events_download_timeout=5

. /etc/door_creds.txt

resultfile=`mktemp`
action="/cgi-bin/vertx_xml.cgi"

list_recent='<?xml version="1.0" encoding="UTF-8"?><VertXMessage><hid:EventMessages action="LR"/></VertXMessage>'
display_recent='<?xml version="1.0" encoding="UTF-8"?> <VertXMessage> <hid:EventMessages action="DR"/> </VertXMessage>'

create_events_file='<?xml version="1.0" encoding="UTF-8"?><VertXMessage><hid:Reports action="CM" type="events"/></VertXMessage>'

events_file='/html/reports/events.csv'

xml="$create_events_file"

descriptor="Generating Events CSV for "

# Pick Which Door
if [ "$1" == "coop" ]; then
	door=Coop
	hostname="10.19.4.130"
else
	door=External
	hostname="10.19.4.129"
fi


if [ "$password" != "" ]; then

	urlencodedxml=`perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$xml"`
	url="https://${hostname}${action}?XML=${urlencodedxml}"

	echo "$descriptor $door Door" 

	# Send the command to create the events file
	wget --output-document=$resultfile \
		--quiet \
		--no-check-certificate \
		--user=$username \
		--password=$password "$url"
	
	echo "CREATE CSV RESULTS:"
	cat $resultfile
	
	url="https://${hostname}${events_file}"
	
	tryagain=1
	
	while ((( $tryagain == 1 ))); do
	
		echo -e "\nDownloading events.csv..."
		# Try to download the completed events file
		wget --output-document="events_$now.csv" \
			--quiet \
			--server-response \
			--no-check-certificate \
			--user=$username \
			--password=$password "$url"	2> $resultfile
	
		echo "DOWNLOAD CSV RESULTS:"
		if (grep -q 'HTTP/1.0 404 Not Found' $resultfile); then
			tryagain=1
			echo "Not yet... trying in 2 seconds"
			sleep 2
		else
			tryagain=0
			cat $resultfile
		fi
		
	done
	
else
	echo "Unable to find password!"
fi

rm $resultfile
