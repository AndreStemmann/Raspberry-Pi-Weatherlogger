#!/bin/bash -
#===============================================================================
#
#          FILE: weatherlogger.sh 
#
#         USAGE: ./weatherlogger.sh
#
#   DESCRIPTION: Get BME280 Sensor Data, save them in Logs and show them on Video Footage
#
#       OPTIONS: ---
#  REQUIREMENTS: Hardware: Raspi Pi Zero, Pi-Cam, Bosch BME280 
#                Software: MotioneyeOS, , Python-Script:
#  https://bitbucket.org/MattHawkinsUK/rpispy-misc/raw/master/python/bme280.py
#          BUGS: ---
#         NOTES: Logdata can further processed (e.g. Grafana, options to you)
#        AUTHOR: Andre Stemmann   
#  ORGANIZATION:
#       CREATED: 03.09.2020 19:34 
#      REVISION: 0.1
#===============================================================================
# Treat unset variables as an error
set -o nounset

TIME=$(date +%H%M)
DATE=$(date +%Y%m%d)
LOG="/data/etc/weather/current.log"

# Create Logfolder
if [ ! -d /data/etc/weather/log/"${DATE}" ]; then
        mkdir -p /data/etc/weather/log/"${DATE}"
fi

# Archive actual Logfile
if [ -f ${LOG} ]; then
        mv "${LOG}" /data/etc/weather/log/"${DATE}"/"${TIME}".log
fi

# Create new Logile for Data Input
if [ ! -f ${LOG} ]; then
        touch "${LOG}"
fi

# Check Python, execute bme280.py, blame if not
if hash >/dev/null 2>&1 python; then
        Values=( "$(python /data/etc/weather/bme280.py)" )
else
        echo "Error: Can't access Sensor!" > "${LOG}"
        exit 1
fi

# Convert Array to newline strings, trim output to two decimal places
# Store Result in Array
for i in $(echo "${Values[@]}"|tail -n3)
do
        RESULTS+=("$(echo "$i"|sed -r 's/([0-9]+\.[0-9]{2})[0-9]+/\1/g')")
done

# Write Results to Logfile
echo "${RESULTS[*]}" > "${LOG}"   

# Print Results in Video Overlay  
outputTemp=$(cat /data/etc/weather/current.log|cut -d" " -f3)
outputPres=$(cat /data/etc/weather/current.log|cut -d" " -f7)
outputHumid=$(cat /data/etc/weather/current.log|cut -d" " -f11)

curl --silent http://localhost:7999/1/config/set?text_left="Temp in C : ${outputTemp}\nHumidity in Pct : ${outputHumid}\nPressure in hPa : ${outputPres}" >> /dev/null
exit 0
