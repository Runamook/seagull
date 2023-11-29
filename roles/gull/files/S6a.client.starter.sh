#!/bin/bash
# source function library
. /etc/rc.d/init.d/functions

INSTANCE=$2
ORIGIN_REALM="s6a.sig.dra.lab"
DESTINATION_REALM="s6a.sig.dra.lab"
ORIGIN_HOST="s6a.client.$INSTANCE"
PID_DIR="/var/run/seagull"
PID_FILE=$PID_DIR/S6a.client.$INSTANCE.pid
HOST="10.0.2.254"
RATE=$3

unset http_proxy

SEAGULL_BASE=/opt/seagull/diameter/jet

CONF=/var/tmp/.S6a.client.$INSTANCE.conf.xml
SCEN=/var/tmp/.S6a.client.$INSTANCE.scen.xml
DICO=$SEAGULL_BASE/dico/S6a.dico.optimized.xml
LOG=$SEAGULL_BASE/logs/S6a.client.$INSTANCE.log

create_config () 
{
TEMPL_CONF=$SEAGULL_BASE/config/S6a.client.template.xml
TEMPL_SCEN=$SEAGULL_BASE/scen/S6a.client.template.xml

#DIAM_PORT=$(echo "$(($INSTANCE + 3867))")

rm -f $CONF
rm -f $SCEN

cp $TEMPL_CONF $CONF
cp $TEMPL_SCEN $SCEN

#sed -i "s/PORT/$DIAM_PORT/g" $CONF
sed -i "s/IP_IMSI_MSISDN/IP_IMSI_MSISDN_$INSTANCE/g" $CONF
sed -i "s/ORIGIN_HOST/$ORIGIN_HOST/g" $SCEN
sed -i "s/ORIGIN_REALM/$ORIGIN_REALM/g" $SCEN
sed -i "s/DESTINATION_REALM/$DESTINATION_REALM/g" $SCEN

echo -e "Config created for instance# $INSTANCE"
}

check_running()
{
if [ -f $PID_FILE ]; then
	echo -e "\n$PID_FILE exists\nProcess already running\n"
	exit 1
fi 
}

start ()
{
		check_running
		create_config
		PORT=$(echo "$(($INSTANCE + 22321))")

		/usr/local/bin/seagull -conf $CONF -dico $DICO -scen $SCEN -log $LOG -llevel N -ctrl $HOST:$PORT -bg &&     success || failure
		#/usr/local/bin/seagull -conf $CONF -dico $DICO -scen $SCEN -log $LOG -llevel ET -ctrl $HOST:$PORT -bg &&     success || failure
		RETVAL=$?
		if [ "$RETVAL" == 0 ]; then
			PID=$(ps aux | grep -v grep | grep -E "ctrl .*$PORT" | awk '{print $2}')	
			echo $PID > $PID_FILE
			sleep 2
			curl -s http://$HOST:$PORT/seagull/counters/all
			echo
			#echo "Started seagull to host $DIAM_PORT"
			echo "Control interface on $PORT"
		fi
		echo
}

pause ()
{
		PORT=$(echo "$(($INSTANCE + 22321))")
		curl -s http://$HOST:$PORT/seagull/command/rate?value=0 && success || failure
		echo
}

rate ()
{
		PORT=$(echo "$(($INSTANCE + 22321))")
		curl -s http://$HOST:$PORT/seagull/command/rate?value=$RATE && success || failure
		echo
}

graceful ()
{
		PORT=$(echo "$(($INSTANCE + 22321))")
		curl -s http://$HOST:$PORT/seagull/command/stop && success || failure
		echo "Stopping seagull..."
		#RETVAL=$(curl -s http://$HOST:$PORT/seagull/counters/all && echo 0 || echo 1)

		#while [ "$RETVAL" -eq "0" ]; do
		#	sleep 1
		#RETVAL=$(curl -s http://$HOST:$PORT/seagull/counters/all && echo 0 || echo 1)
		#done
		#rm -f $PID_FILE
		#echo "Stopped"
}

stats ()
{
		PORT=$(echo "$(($INSTANCE + 22321))")
		curl -s http://$HOST:$PORT/seagull/counters/all
		echo
}

stop ()
{
		killproc -p $PID_FILE -SIGUSR1
		RETVAL=$?
		[ "$RETVAL" = 0 ] && rm -f $PID_FILE || failure $"Stopping $prog"
		echo
		rm -f $PID_FILE
}

case "$1" in
		start)
				start
				;;
		stop)
				stop
				;;
		graceful)
				graceful
				;;
		pause)
				pause
				;;
		stats)
				stats
				;;
		rate)
				rate
				;;
		*)
				echo "Usage: $0 {start #|stop #|graceful #|pause #|rate instance# rate#|stats #}"
				RETVAL=1
esac 
