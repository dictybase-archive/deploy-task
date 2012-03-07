#!/usr/bin/env bash

# install perl modules for fcgi deployment
# of web application.

cpanm=$1
APP_DIR=$2

cd $2
echo "------> Installing dependencis"
$cpanm --installdeps -n .

echo "------> Installing plack and dependencies for fcgi deployment"
$cpanm --installdeps -n Plack FCGI FCGI::ProcManager FCGI::Engine
