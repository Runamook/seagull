#!/bin/bash
# source function library
. /etc/rc.d/init.d/functions

INSTANCE=$2
ORIGIN_REALM="s6a.sig.dra.lab"
DESTINATION_REALM="s6a.sig.dra.lab"
ORIGIN_HOST="s6a.server.$INSTANCE"
PID_DIR="/var/run/seagull"
PID_FILE=$PID_DIR/s6a.server.$INSTANCE.pid
HOST="10.0.2.254"
RESULTCODE1=${3:-2001}
RESULTCODE2=${4:-2001}

unset http_proxy

SEAGULL_BASE=/opt/seagull/diameter/jet

CONF=/var/tmp/.S6a.serv.$INSTANCE.conf.xml
SCEN=/var/tmp/.S6a.serv.$INSTANCE.scen.xml
DICO=$SEAGULL_BASE/dico/S6a.dico.optimized.xml
LOG=$SEAGULL_BASE/logs/S6a.serv.$INSTANCE.log

create_server_config () 
{
TEMPL_CONF=$SEAGULL_BASE/config/S6a.server.template.xml
TEMPL_SCEN=$SEAGULL_BASE/scen/S6a.server.template.xml

DIAM_PORT=$(echo "$(($INSTANCE + 3867))")

rm -f $CONF
rm -f $SCEN

cp $TEMPL_CONF $CONF
cp $TEMPL_SCEN $SCEN

sed -i "s/PORT/$DIAM_PORT/g" $CONF
sed -i "s/ORIGIN_HOST/$ORIGIN_HOST/g" $SCEN
sed -i "s/ORIGIN_REALM/$ORIGIN_REALM/g" $SCEN
sed -i "s/DESTINATION_REALM/$DESTINATION_REALM/g" $SCEN

# Assign result-codes
sed -i "s/RESULTCODE1/$RESULTCODE1/g" $SCEN
sed -i "s/RESULTCODE2/$RESULTCODE2/g" $SCEN

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
		create_server_config
		PORT=$(echo "$(($INSTANCE + 22221))")

		/usr/local/bin/seagull -conf $CONF -dico $DICO -scen $SCEN -log $LOG -llevel N -ctrl $HOST:$PORT -bg &&     success || failure
		#/usr/local/bin/seagull -conf $CONF -dico $DICO -scen $SCEN -log $LOG -llevel ET -ctrl $HOST:$PORT -bg &&     success || failure
		RETVAL=$?
		if [ "$RETVAL" == 0 ]; then
			PID=$(ps aux | grep -v grep | grep -E "ctrl .*$PORT" | awk '{print $2}')	
			echo $PID > $PID_FILE
			sleep 2
			curl -s http://$HOST:$PORT/seagull/counters/all
			echo
			echo "Started seagull on port $DIAM_PORT"
			echo "Control interface on $PORT"
		fi
		echo
}

stop ()
{
		killproc -p $PID_FILE -SIGUSR1
		RETVAL=$?
		[ "$RETVAL" = 0 ] && rm -f $PID_FILE || failure $"Stopping $prog"
		echo
}

graceful ()
{
                PORT=$(echo "$(($INSTANCE + 22221))")
                curl -s http://$HOST:$PORT/seagull/command/stop && success || failure
                echo "Stopping seagull..."
                #RETVAL=$(curl -s http://$HOST:$PORT/seagull/counters/all && echo 0 || echo 1)

                #while [ "$RETVAL" -eq "0" ]; do
                #       sleep 1
                #RETVAL=$(curl -s http://$HOST:$PORT/seagull/counters/all && echo 0 || echo 1)
                #done
                #rm -f $PID_FILE
                #echo "Stopped"
}

stats ()
{
                PORT=$(echo "$(($INSTANCE + 22221))")
                curl -s http://$HOST:$PORT/seagull/counters/all
                echo
}


case "$1" in
                start)
                                start
                                ;;
                stop)
                                stop
                                ;;
                stats)
                                stats
                                ;;
                graceful)
                                graceful
                                ;;
                *)
                                echo "Usage: $0 {start # resultcode1 resultcode2|stop #|stats #|graceful #}"
                                RETVAL=1
esac
