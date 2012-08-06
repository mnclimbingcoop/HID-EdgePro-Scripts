#!/bin/bash

this_computer="Aaron's Work Laptop"
host="ajz.healthstudies.umn.edu"
path="/mncc/robot/xml"
output_xml="backupxml.xml"
secret="biLah6ingua6ahWah7Ahngoh1iyei3Baex6ohh0Doogh6mua"

url="https://${host}${path}?secret=${secret}"

# Get the backup file
echo "Downloading XML backup file ..."
curl --insecure \
	--silent \
	--user ${username}:${password} \
	"${url}" > "${output_xml}.download"

echo -n "Checking XML file for errors..."
tidy -xml -o ${output_xml} ${output_xml}.download 2> backupxml.errors
if (grep -q '0 errors' backupxml.errors); then
	echo "Passed."
	rm ${output_xml}.download
	rm backupxml.errors
else
	echo "Failed."
	cat backupxml.errors
	rm ${output_xml}
fi	

echo -n "Checking XML file size..."
filesize=`cat backupxml.xml | wc -l`
if ((( $filesize > 1200 ))); then
	echo "Passed."
else
	echo "Failed."
	echo "XML only contained $filesize lines, expected at least 1200"
	exit 0
fi

echo -n "Checking XML file for key elements..."
if (grep -q Zirbes ${output_xml}); then
	echo -n "."
else
	echo "Failed. Where's Zirbes?"
	exit 0
fi

if (grep -q Merli ${output_xml}); then
	echo -n "."
else
	echo "Failed. Where's Merli?"
	exit 0
fi

if (grep -q Johnson ${output_xml}); then
	echo -n "."
else
	echo "Failed. Where's the Johnsons?"
	exit 0
fi

echo "Passed."

if [ -e ${output_xml} ]; then
	echo "XML file passed."

	echo "Building Backup File."	
	working=bob_is_working

    if [ ! -d $working ]; then
            mkdir $working/
    fi

    cp "$output_xml" $working/backupxml.xml
    cd $working/
	echo -n "Generating SHA1 hash..."
    shasum backupxml.xml > backupxml.sum
    echo "Done."
    
    echo -n "Compressing backup file..."
    if (tar -cvzf ../backupxml.bob backupxml.???); then
    	echo "Done."
	else
		echo "Failed."
    fi
    
    cd ..
    rm -rf $working/	
	
	echo "Finished getting Backup File from server."
	if [ -e backupxml.bob ]; then
		rm $output_xml
		chmod 0600 backupxml.bob
		mv backupxml.bob /var/spool/hid
	fi
	
else
	echo "XML file failed tests, sending alert email!"
fi

