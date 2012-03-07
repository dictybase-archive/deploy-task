#!/usr/bin/env bash

# insert the startup command for deployment in the run file inside the service directory

PROJECT=$1
APP_FILE=$2

echo -e "export MOJO_MODE=production\n" >> $APP_FILE
echo -e "export PLACK_ENV=production\n" >> $APP_FILE

echo -e "exec setuidgid $USER plackup -s FCGI --nproc 4 --listen /tmp/$PROJECT.sock script/$PROJECT\n" >> $APP_FILE
