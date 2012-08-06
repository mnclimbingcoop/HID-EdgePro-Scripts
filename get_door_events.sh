#!/bin/bash

now=`date +%Y%m%d-%H-%M-%S`

install_path=`dirname ${0}`
if [ "${install_path}" == "." ]; then
	install_path=`pwd`
fi

if [ ! -d /var/spool/hid ]; then
	sudo mkdir -p /var/spool/hid
fi

pushd /var/spool/hid

# Timout to try to download the events.csv file (in minutes)
events_download_timeout=5

. /etc/hid-door-creds.conf

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
	curl --insecure \
		--silent \
		--user ${username}:${password} \
		"${url}" > ${resultfile}
	
	#echo "CREATE CSV RESULTS:"
	#cat $resultfile
	
	url="https://${hostname}${events_file}"
	
	tryagain=1
	
	echo -e -n "\nDownloading events.csv..."
	while ((( $tryagain == 1 ))); do
	
		# Try to download the completed events file
		curl --insecure \
			--silent \
			--output "events_${door}_${now}.csv" \
			--write-out "HTTP_RESULT:%{http_code}" \
			--user ${username}:${password} \
			"${url}" > ${resultfile}

		#wget --output-document="events_${door}_${now}.csv" \
			#--quiet \
			#--server-response \
			#--no-check-certificate \
			#--user=$username \
			#--password=$password "$url"	2> $resultfile
	
		if (grep -q 'HTTP_RESULT:404' $resultfile); then
			tryagain=1
			echo -n -e "Not yet.\n Trying in 2 seconds..."
			sleep 2
		else
			echo "Done."
			tryagain=0
			cat $resultfile

			# Uploading door events to server
			${install_path}/upload_events.sh "events_${door}_${now}.csv" $door
		fi
		
	done
	
else
	echo "Unable to find password!"
fi

popd

rm $resultfile
