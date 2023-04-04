#!/usr/bin/env bash

if [[ "${APPLICATION_LOGS_TO_STDOUT}" != "false" ]];
then
 # push the "real" application logs to stdout with xtail in detached mode
 exec xtail /var/log/shiny-server/ &
fi

# start shiny server
exec /usr/bin/shiny-server 2>&1
