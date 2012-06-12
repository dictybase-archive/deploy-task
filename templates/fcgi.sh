#!/bin/sh

# install perl modules for fcgi deployment
# of web application.

install_dependencies() {
	 cd $1
   carton install
}

after_install_dependencies() {
   echo "------> Installing plack and dependencies for fcgi deployment"
   cd $1
   carton install Plack FCGI FCGI::ProcManager FCGI::Engine

}

before_install_dependencies() {
  return
}
