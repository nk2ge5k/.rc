#!/bin/bash

# env | grep XAUTHORITY >> $HOME/.Xdbus
# env | grep DBUS_SESSION_BUS_ADDRESS > $HOME/.Xdbus

source /home/nk2ge5k/.Xdbus
export DISPLAY=:0.0

RANDR=/usr/bin/xrandr
AWK=/usr/bin/awk
CAT=/usr/bin/cat

LOG_FILE=/var/log/lid-state.log

DISPLAYS=$($RANDR -q | $AWK -F '[ x+]' '/\<connected\>/{print $1}')
STATE=$($CAT /proc/acpi/button/lid/LID/state | $AWK '{print $2}')


open_lid() {
	local builtin="eDP-1"

	echo "Lid opened" | tee -a $LOG_FILE

	if [[ "$DISPLAYS" == *"$builtin"* ]]; then
		echo "Enabling $builtin" | tee -a $LOG_FILE
		$RANDR --output $builtin --auto 2>&1 | tee -a $LOG_FILE

		for display in $DISPLAYS;
		do
			if [[ "$display" == "$builtin" ]]; then
				continue
			fi

			echo "Disabling $display" | tee -a $LOG_FILE
			$RANDR --output $display --off 2>&1 | tee -a $LOG_FILE
		done


		exit 0
	fi

	echo "Laptop display is not connected" | tee -a $LOG_FILE
	exit 1
}

close_lid () {
	echo "Lid closed" | tee -a $LOG_FILE

	local external = ""
	case $DISPLAYS in
		*"DP-1"*) 
			external="DP-1";;
		*"DP-2"*) 
			external="DP-2";;
		*)
			echo "No external monitor detected" | tee -a $LOG_FILE
			exit 1;;
	esac
	
	echo "Enabling $external" | tee -a $LOG_FILE
	$RANDR --output $external --auto 2>&1 | tee -a $LOG_FILE

	for display in $DISPLAYS;
	do
		if [[ "$display" == "$external" ]]; then
			continue
		fi

		echo "Disabling $display" | tee -a $LOG_FILE
		$RANDR --output $display --off 2>&1 | tee -a $LOG_FILE
	done

}

echo "Displays: $DISPLAYS" | tee -a $LOG_FILE

case $STATE in
	"open") open_lid;;
	"closed") close_lid;;
	*)
		echo "Unexpeted lid state: $STATE" | tee -a $LOG_FILE
		exit 1
		;;
esac

exit 0
