#!/bin/bash

if [[ $1 == "start" ]]; then
	rm -f /var/run/seagull/S6a.client.$2.pid
	{{ seagull_path }}/run/S6a.client.starter.sh $1 $2
elif [[ $1 == "stop" ]]; then
	{{ seagull_path }}/run/S6a.client.starter.sh $1 $2
fi
