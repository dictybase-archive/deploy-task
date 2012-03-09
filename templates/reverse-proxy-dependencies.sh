#!/usr/bin/env bash

# install perl modules for reverse proxy deployment
# of web application.


cpanm=$1
APP_DIR=$2

cd $2
echo "------> Installing dependencis"
$cpanm --installdeps -n .

echo "------> Installing plack and dependencies for reverse proxy deployment"
$cpanm -n Plack Starman
