#!/bin/bash

# Usage: control_temp_em.sh 
# version 0.5
# based on https://github.com/Sepero/temp-throttle/blob/master/temp_throttle.sh


cat << EOF
Author: neapovea (neapovea at gmail)
URL: http://github.com/neapovea/

EOF

# License: GNU GPL 2.0

# Generic  function for printing an error and exiting.
err_exit () {
	echo ""
	echo "Error: $@" 1>&2
	exit 128
}

if [ $# -ne 1 ]; then
	# If temperature wasn't given, then print a message and exit.
	echo "Please supply a maximum desired temperature in Celsius." 1>&2
	echo "For example:  ${0} 60" 1>&2
	exit 2
else
	#Set the first argument as the maximum desired temperature.
	MAX_TEMP=$1
fi

### Start Initialize Global variables.

#tag for logging
log_tag='control_temp_em'

TEMP_FILE0="/sys/class/hwmon/hwmon1/device/temp1_input"

MAX_TEMP0=$(cat "/sys/class/hwmon/hwmon1/device/temp1_max")

CUR_TEMP0=$(cat $TEMP_FILE0)

MAX_TEMP0=$((MAX_TEMP0- 20000))

LOW_TEMP0=$((MAX_TEMP0 -20000))

#is fan active
FAN_CONTROL=0
ACTIVE_FANS=0

# The frequency will increase when low temperature is reached.
LOW_TEMP=$((MAX_TEMP - 5))

CORES=$(nproc) # Get number of CPU cores.
echo -e "Number of CPU cores detected: $CORES\n"
CORES=$((CORES - 1)) # Subtract 1 from $CORES for easier counting later.

# Temperatures internally are calculated to the thousandth.
MAX_TEMP=${MAX_TEMP}000
LOW_TEMP=${LOW_TEMP}000

FREQ_FILE="/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies"
FREQ_MIN="/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq"
FREQ_MAX="/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"

# Store an array of the available cpu frequencies in FREQ_LIST.
if [ -f $FREQ_FILE ]; then
	# If $FREQ_FILE exists, get frequencies from it.
	FREQ_LIST=$(cat $FREQ_FILE) || err_exit "Could not read available cpu frequencies from file $FREQ_FILE"
elif [ -f $FREQ_MIN -a -f $FREQ_MAX ]; then
	# Else if $FREQ_MIN and $FREQ_MAX exist, generate a list of frequencies between them.
	FREQ_LIST=$(seq $(cat $FREQ_MAX) -100000 $(cat $FREQ_MIN)) || err_exit "Could not compute available cpu frequencies"
else
	err_exit "Could not determine available cpu frequencies"
fi

FREQ_LIST_LEN=$(echo $FREQ_LIST | wc -w)

# CURRENT_FREQ will save the index of the currently used frequency in FREQ_LIST.
CURRENT_FREQ=2

# This is a list of possible locations to read the current system temperature.
TEMPERATURE_FILES="
/sys/class/thermal/thermal_zone0/temp
/sys/class/thermal/thermal_zone1/temp
/sys/class/thermal/thermal_zone2/temp
/sys/class/hwmon/hwmon0/temp1_input
/sys/class/hwmon/hwmon1/temp1_input
/sys/class/hwmon/hwmon2/temp1_input
/sys/class/hwmon/hwmon0/device/temp1_input
/sys/class/hwmon/hwmon1/device/temp1_input
/sys/class/hwmon/hwmon2/device/temp1_input
null
"
#charge cores temp data

# Store the first temperature location that exists in the variable TEMP_FILE.
# The location stored in $TEMP_FILE will be used for temperature readings.
for file in $TEMPERATURE_FILES; do
	TEMP_FILE=$file
	[ -f $TEMP_FILE ] && break
done

[ $TEMP_FILE == "null" ] && err_exit "The location for temperature reading was not found."


### End Initialize Global variables.


# Set the maximum frequency for all cpu cores.
set_freq () {
	FREQ_TO_SET=$(echo $FREQ_LIST | cut -d " " -f $CURRENT_FREQ)
	logger -p user.notice -t $log_tag " frequency " $FREQ_TO_SET
	for i in $(seq 0 $CORES); do
		echo $FREQ_TO_SET > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq
	done
}

# Will reduce the frequency of cpus if possible.
throttle () {
	if [ $CURRENT_FREQ -lt $FREQ_LIST_LEN ]; then
		CURRENT_FREQ=$((CURRENT_FREQ + 1))
		logger -p user.notice -t $log_tag "throttle"  
		set_freq $CURRENT_FREQ
	fi
}

# Will increase the frequency of cpus if possible.
unthrottle () {
	if [ $CURRENT_FREQ -ne 1 ]; then
		CURRENT_FREQ=$((CURRENT_FREQ - 1))
		logger -p user.notice -t $log_tag "unthrottle"  
		set_freq $CURRENT_FREQ
	fi
}

# Active fans yeehaw
activate_fan() {
	# Throttle if too hot.
	if test $FAN_CONTROL -ne 1; then
		ls /sys/devices/virtual/thermal/cooling_device*/cur_state | while read A; do  echo 1 > $A;  done
		logger -p user.notice -t $log_tag "activate_fan" $CUR_TEMP0 " "  $MAX_TEMP0  
		let FAN_CONTROL=1;
	fi

}

# Desactive fans yeehaw
deactivate_fan() {
	# Unthrottle if cool.
	if test $FAN_CONTROL -ne 0; then
		ls /sys/devices/virtual/thermal/cooling_device*/cur_state | while read A; do echo 0 > $A; 	done
		logger -p user.notice -t $log_tag "deactivate_fan" $CUR_TEMP0 " "  $LOW_TEMP0  
		let FAN_CONTROL=0;
	fi
}


get_temp () {
	# Get the system temperature.
	
 	if [ $1 -eq  0 ] ; then
		CUR_TEMP0=$(cat $TEMP_FILE0)
	else
		echo " no core found "
	fi

}

logger -p user.notice -t $log_tag "temperature Initialize" $CUR_TEMP0 " " $MAX_TEMP0 "" $LOW_TEMP0  
# Mainloop
while true; do

	get_temp 0

	if   [ $CUR_TEMP0 -gt $MAX_TEMP0  ]; then # Throttle if too hot.
		let ACTIVE_FANS=1
		logger -p user.notice -t $log_tag "temperature max" $CUR_TEMP0 " " $MAX_TEMP0 
	elif [ $CUR_TEMP0 -le $LOW_TEMP0 ]; then # Unthrottle if cool.
		let ACTIVE_FANS=0
		logger -p user.notice -t $log_tag "temperature low" $CUR_TEMP0 " " $LOW_TEMP0
	fi	

	#logger -p user.notice -t $log_tag "Active Fan" $ACTIVE_FANS  "fan control" $FAN_CONTROL

	if   [ $ACTIVE_FANS -eq 1 ]; then # Throttle if too hot.
		throttle
		activate_fan 

	elif [ $ACTIVE_FANS -eq 0 ]; then # Unthrottle if cool.
		unthrottle
		deactivate_fan
	fi

	sleep 30

done
