#!/bin/bash

#host="localhost:8443/coop-manage"
host="manage.mnclimbingcoop.com/mncc"
hosts="manage.mnclimbingcoop.com/mncc"
action="/import/events/"
key="biLah6ingua6ahWah7Ahngoh1iyei3Baex6ohh0Doogh6mua"

file="${1}"
door="${2}"


if [ -f "${file}" ]; then

	output="${file/\.csv/.xml}"
	results="${file/\.csv/-results.xml}"
	echo '<?xml version="1.0" encoding="UTF-8" ?>' > "${output}"
	echo "<eventlog>" >> "${output}"

	cat "${file}" \
		| tr -d '\15\32' \
		| sed -E 's/^/	<event><code>/' \
		| sed -E 's/,/<\/code><date>/' \
		| sed -E 's/,/<\/date><subject>/' \
		| sed -E 's/$/<\/subject><\/event>/' \
		>> "${output}"

	echo "</eventlog>" >> "${output}"

	content_type="text/xml"

	#less "${output}"

	# Uploading events file to all listed hosts
	for host in ${hosts}; do
		echo "Sending file: ${file}"
		safe_url="https://${host}${action}${door}"
		echo "To: ${safe_url}"

		url="https://${host}${action}${door}?secret=${key}"
		echo "Uploading to: $url"
		curl ${url} \
			--insecure \
			--silent \
			--request POST \
			--header "Content-Type:${content_type}" \
			--data @"${output}" \
			--output "${results}.tmp"
	done

	rm "${output}"
	if (tidy -quiet -xml "${results}.tmp" > "${results}"); then
		rm "${results}.tmp"

		r_created=`xpath -e '//entry[@key="created"]' -q "${results}" | grep entry | sed -e 's/<\/.*//' -e 's/.*>//'`
		r_total=`xpath -e '//entry[@key="total"]' -q "${results}" | grep entry | sed -e 's/<\/.*//' -e 's/.*>//'`
		r_existing=`xpath -e '//entry[@key="existing"]' -q "${results}" | grep entry | sed -e 's/<\/.*//' -e 's/.*>//'`
		r_errors=`xpath -e '//entry[@key="errors"]' -q "${results}" | grep entry | sed -e 's/<\/.*//' -e 's/.*>//'`

		echo "Total: $r_total"
		echo "Existing: $r_existing"
		echo "Created: $r_created"
		echo "Errors: $r_errors"
	else
		cat "${results}.tmp"
		rm "${results}.tmp"
	fi

else
	echo "Usage:"
	echo "	${0} <events filename>"
fi

