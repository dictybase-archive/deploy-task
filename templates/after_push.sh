#!/bin/sh

# $1 = root of the web application folder
installer=$1-dependencies
post_install=$1-daemontool
APP_DIR=$2
PROJECT=`basename $APP_DIR`
PERL_VERSION=$3
LOCAL_LIB=$PERL_VERSION\@$PROJECT
SERVICE=$APP_DIR/service
APP_SERVICE=$SERVICE/${PROJECT}runner
RUN_FILE=$APP_SERVICE/run
cpanm=$PERLBREW_ROOT/bin/cpanm
perlbrew=$PERLBREW_ROOT/bin/perlbrew

setup_daemontool() {
	! [ -d $APP_SERVICE ] && mkdir -p $APP_SERVICE
	if ! [ -e $RUN_FILE ];then 
		cd $APP_DIR
		deploy/$post_install $PROJECT $RUN_FILE $LOCAL_LIB $APP_DIR

		chmod 1755 $APP_SERVICE
		chmod 755 $RUN_FILE
		ln -s $APP_SERVICE /service/$PROJECT
	fi

}

if [ -e $cpanm ]; then
	echo "------> Upgrading cpanm"
	$cpanm --self-upgrade
else
  echo "------> Installing cpanm"
  $perlbrew install-cpanm
fi

if ! [ `$perlbrew list | grep $PROJECT` ]; then
	$perlbrew lib create $LOCAL_LIB
fi

echo "-------> using lib $LOCAL_LIB"
export PERLBREW_ROOT=$PERLBREW_ROOT
export PERLBREW_HOME=$PERLBREW_HOME
source $PERLBREW_ROOT/etc/bashrc
perlbrew use $LOCAL_LIB

cd $APP_DIR
if [ -x deploy/$installer ]; then
  deploy/$installer cpanm $APP_DIR  && setup_daemontool
fi
