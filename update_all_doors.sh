#!/bash

install_path=`dirname ${0}`
if [ "${install_path}" == "." ]; then
        install_path=`pwd`
fi

# Update Door Events
${install_path}\get_door_events.sh coop
${install_path}\get_door_events.sh external

# Get new door data from management site
get_backupbob_xml.sh

# Upload door data to external door

# Upload door data to coop door

# Done!
